import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/correction.dart';
import '../core/state.dart';
import 'common.dart';

/// « avant → après », avec le contexte immédiat quand la correction ne porte
/// que sur des espaces ou de la ponctuation, sinon invisibles.
String describe(String text, Correction c) {
  if (RegExp(r'[^\s\p{P}]', unicode: true).hasMatch(c.original)) {
    return '${c.original} → ${c.replacement}';
  }
  final before = RegExp(r'\S*$').stringMatch(text.substring(0, c.start)) ?? '';
  final after = RegExp(r'^\S*').stringMatch(text.substring(c.end)) ?? '';
  String show(String s) => '$before$s$after'.replaceAll('\u00a0', ' ');
  return '« ${show(c.original)} » → « ${show(c.replacement)} »';
}

class CorrectionPage extends ConsumerStatefulWidget {
  const CorrectionPage({super.key});
  @override
  ConsumerState<CorrectionPage> createState() => _CorrectionState();
}

class _CorrectionState extends ConsumerState<CorrectionPage> {
  final input = TextEditingController();
  String original = '', result = '';
  List<Correction> corrections = [];
  final accepted = <int>{};
  bool analyzed = false;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void analyze() {
    setState(() {
      original = input.text;
      corrections = LocalCorrector.inspect(original);
      accepted.clear();
      result = original;
      analyzed = true;
    });
  }

  void update() {
    result = LocalCorrector.apply(original, [
      for (final i in accepted) corrections[i],
    ]);
  }

  @override
  Widget build(BuildContext context) => PageBody(
    title: 'Le labo des mots',
    subtitle:
        'Comprendre, choisir, progresser. Votre texte original reste toujours intact.',
    children: [
      TextField(
        controller: input,
        minLines: 5,
        maxLines: 12,
        decoration: const InputDecoration(
          labelText: 'Votre texte',
          hintText: 'Je vous est envoyé les documents hier.',
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        children: [
          FilledButton.icon(
            onPressed: analyze,
            icon: const Icon(Icons.spellcheck),
            label: const Text('Analyser localement'),
          ),
          OutlinedButton(
            onPressed: () => context.go(
              Uri(
                path: '/assistant',
                queryParameters: {
                  'prompt':
                      'Corrige ce texte sans changer son style. Présente le texte corrigé puis explique chaque correction avec une règle et un exemple. Ne modifie rien directement.\n${input.text}',
                },
              ).toString(),
            ),
            child: const Text('Analyse approfondie avec une IA'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const Text(
        'Le correcteur hors ligne détecte un ensemble limité de fautes courantes. L’absence de suggestion ne garantit pas un texte sans erreur. Les accords dépendant du contexte doivent être vérifiés.',
      ),
      if (analyzed) ...[
        const SizedBox(height: 24),
        Text(
          'Original conservé',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SelectableText(original),
        const SizedBox(height: 16),
        if (corrections.isEmpty)
          const Text(
            'Aucune des fautes connues du correcteur local n’a été trouvée.',
          ),
        for (var i = 0; i < corrections.length; i++)
          Card(
            child: CheckboxListTile(
              value: accepted.contains(i),
              onChanged: (v) => setState(() {
                v == true ? accepted.add(i) : accepted.remove(i);
                update();
              }),
              title: Text(describe(original, corrections[i])),
              subtitle: Text(
                '${corrections[i].rule}\nCochez pour accepter ; décochez pour refuser.',
              ),
              secondary: corrections[i].detail.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Explication détaillée',
                      icon: const Icon(Icons.school_outlined),
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: Text(describe(original, corrections[i])),
                          content: Text(corrections[i].detail),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text('Compris'),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Votre version corrigée',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SelectableText(result),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            FilledButton(
              onPressed: () => guarded(context, () async {
                final l = await ref
                    .read(atelierProvider)
                    .create(title: 'Texte corrigé', text: original);
                l.revise(result);
                await ref.read(atelierProvider).persist();
                if (context.mounted) context.go('/editor/${l.id}');
              }),
              child: const Text('Enregistrer avec l’original'),
            ),
            TextButton(
              onPressed: () => setState(() {
                accepted.clear();
                update();
              }),
              child: const Text('Refuser toutes les corrections'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Exercises(),
      ],
    ],
  );
}

const exercises = <(String, String, String)>[
  (
    'ces ou ses ?',
    'Elle range … lettres dans son tiroir.',
    '« ses » si les lettres lui appartiennent (les siennes). « Ces » désigne des lettres que l’on montre : ces lettres-ci.',
  ),
  (
    'a ou à ?',
    'Il … envoyé sa réponse … la mairie.',
    '« Il a envoyé » (on peut dire « il avait envoyé ») ; « à la mairie » est une préposition.',
  ),
  (
    'quel que ou quelque ?',
    '… soient vos raisons, je reste disponible.',
    '« Quelles que soient » : devant être, « quel » s’écrit séparé et s’accorde avec « raisons ».',
  ),
  (
    'participe ou infinitif ?',
    'Je vous ai (envoyer / envoyé) le contrat et je souhaite le (signer / signé).',
    '« Envoyé » après l’auxiliaire avoir ; « signer » après un verbe conjugué. Astuce : remplacez par « mordre / mordu ».',
  ),
  (
    'si + imparfait',
    'Si vous (pourriez / pouviez) me répondre avant vendredi, je vous en serais reconnaissant.',
    '« Si vous pouviez » : après « si » de condition, l’imparfait ; le conditionnel va dans l’autre partie (« je vous en serais »).',
  ),
];

class Exercises extends StatefulWidget {
  const Exercises({super.key});
  @override
  State<Exercises> createState() => _ExercisesState();
}

class _ExercisesState extends State<Exercises> {
  int index = 0;
  bool shown = false;
  @override
  Widget build(BuildContext context) {
    final (topic, question, answer) = exercises[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mini-exercice ${index + 1}/${exercises.length} : $topic',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Complétez : « $question »'),
            if (shown) ...[
              const SizedBox(height: 8),
              Text('Réponse : $answer'),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => setState(() => shown = !shown),
                  child: Text(shown ? 'Masquer la réponse' : 'Voir la réponse'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    index = (index + 1) % exercises.length;
                    shown = false;
                  }),
                  child: const Text('Exercice suivant'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Entry {
  const Entry(this.word, this.section, this.text);
  final String word, section, text;
}

const sections = [
  'Conjugaison',
  'Homophones',
  'Définitions et synonymes',
  'Formules de politesse',
  'Vocabulaire administratif',
  'Vocabulaire professionnel',
  'Expressions françaises',
  'Expressions à éviter',
];

const _stopWords = {
  'au',
  'aux',
  'de',
  'des',
  'du',
  'la',
  'le',
  'les',
  'un',
  'une',
  'et',
  'ou',
  'en',
  'a',
  'pour',
  'par',
  'sur',
  'que',
  'qui',
  'quoi',

  'comment',
  'est',
  'ce',
  'cette',
  'mot',
  'dire',
  'ecrire',
  'on',
  'je',
  'mon',
  'ma',
  'plus',
  'trouve',
  'utiliser',
  'faut',
  'il',
  'entre',
  'difference',
};

/// Minuscules sans accents, pour une recherche tolérante.
String fold(String s) {
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ’';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy\'';
  final b = StringBuffer();
  final lower = s.toLowerCase().replaceAll('œ', 'oe').replaceAll('æ', 'ae');
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    b.write(i < 0 ? ch : to[i]);
  }
  return b.toString();
}

/// Classe les fiches : un terme présent dans le titre compte dix fois plus
/// que dans le texte, et un terme rare plus qu'un terme courant.
/// Les mots outils sont ignorés.
List<Entry> searchLexicon(List<Entry> all, String query, String? section) {
  final pool = all.where((e) => section == null || e.section == section);
  final stems = fold(query)
      .split(RegExp(r"[^a-z0-9]+"))
      .where((t) => t.length > 1 && !_stopWords.contains(t))
      // Seule la marque du pluriel est retirée : « formules » → « formule ».
      .map(
        (t) => t.length > 3 && RegExp(r'[sx]$').hasMatch(t)
            ? t.substring(0, t.length - 1)
            : t,
      )
      .toSet();
  if (stems.isEmpty) return pool.toList();
  final folded = [for (final e in all) (fold(e.word), fold(e.text))];
  final weight = {
    for (final t in stems)
      t: math.log(
        (all.length + 1) /
            (folded.where((f) => f.$1.contains(t) || f.$2.contains(t)).length +
                1),
      ),
  };
  final scored = <(double, Entry)>[];
  for (final e in pool) {
    final word = fold(e.word), text = fold(e.text);
    var score = 0.0;
    for (final t in stems) {
      if (word.contains(t)) {
        score += 10 * weight[t]!;
      } else if (text.contains(t)) {
        score += weight[t]!;
      }
    }
    if (score > 0) scored.add((score, e));
  }
  scored.sort((a, b) => b.$1.compareTo(a.$1));
  return [for (final (_, e) in scored) e];
}

Future<List<Entry>> loadLexicon() async {
  final data = jsonDecode(await rootBundle.loadString('assets/lexique.json'));
  return [
    for (final e in data as List)
      Entry(e['mot'] as String, e['rubrique'] as String, e['texte'] as String),
  ];
}

class DictionaryPage extends ConsumerStatefulWidget {
  const DictionaryPage({super.key});
  @override
  ConsumerState<DictionaryPage> createState() => _DictionaryState();
}

class _DictionaryState extends ConsumerState<DictionaryPage> {
  final query = TextEditingController();
  late final Future<List<Entry>> lexicon = loadLexicon();
  String searched = '';
  String? section;
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> search() async {
    setState(() => searched = query.text.trim());
    if (searched.isEmpty) return;
    final a = ref.read(atelierProvider);
    a.data.searches = [
      searched,
      ...a.data.searches.where((s) => s != searched),
    ].take(100).toList();
    await guarded(context, a.persist);
  }

  @override
  Widget build(BuildContext context) => PageBody(
    title: 'Le cabinet des curiosités linguistiques',
    subtitle:
        'Un mémento hors ligne et des recherches approfondies avec Bafou.',
    children: [
      TextField(
        controller: query,
        onSubmitted: (_) => search(),
        decoration: InputDecoration(
          labelText: 'Un mot, une règle, une question',
          hintText: 'Ex. : acquérir au subjonctif, lettre au préfet, problème',
          suffixIcon: IconButton(
            tooltip: 'Rechercher',
            onPressed: search,
            icon: const Icon(Icons.search),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Toutes les rubriques'),
            selected: section == null,
            onSelected: (_) => setState(() => section = null),
          ),
          for (final s in sections)
            ChoiceChip(
              label: Text(s),
              selected: section == s,
              onSelected: (_) => setState(() => section = s),
            ),
        ],
      ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: () => context.go(
          Uri(
            path: '/assistant',
            queryParameters: {
              'prompt':
                  'Question de français : ${query.text}. Donne une réponse pédagogique, des exemples, et indique tes incertitudes.',
            },
          ).toString(),
        ),
        child: const Text('Demander à Bafou (IA configurée)'),
      ),
      const SizedBox(height: 20),
      FutureBuilder<List<Entry>>(
        future: lexicon,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Impossible de charger le mémento.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          final matches = searchLexicon(all, searched, section);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ce mémento contient ${all.length} fiches vérifiables ; ce n’est pas un dictionnaire exhaustif.',
              ),
              const SizedBox(height: 12),
              if (matches.isEmpty)
                const Text(
                  'Aucune fiche locale correspondante. Vous pouvez consulter Bafou.',
                ),
              for (final e in matches)
                Card(
                  child: ExpansionTile(
                    initiallyExpanded:
                        searched.isNotEmpty && identical(e, matches.first),
                    title: Text(e.word),
                    subtitle: Text(e.section),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: SelectableText(e.text),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 20),
      const Text('Recherches récentes'),
      Wrap(
        spacing: 8,
        children: [
          for (final s in ref.watch(atelierProvider).data.searches.take(15))
            ActionChip(
              label: Text(s),
              onPressed: () {
                query.text = s;
                search();
              },
            ),
        ],
      ),
    ],
  );
}
