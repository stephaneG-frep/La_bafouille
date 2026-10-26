import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/correction.dart';
import '../core/state.dart';
import 'common.dart';

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
              title: Text(
                '${corrections[i].original} → ${corrections[i].replacement}',
              ),
              subtitle: Text(
                '${corrections[i].rule}\nCochez pour accepter ; décochez pour refuser.',
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
        const ExpansionTile(
          title: Text('Mini-exercice : ces ou ses ?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Complétez : « Elle range … lettres dans son tiroir. »\n\nRéponse : « ses » si les lettres lui appartiennent. « Ces » désigne des lettres que l’on montre. Test : peut-on dire « les siennes » ?',
              ),
            ),
          ],
        ),
      ],
    ],
  );
}

const lexicon = <String, String>{
  'ces / ses':
      'CES est un déterminant démonstratif : ces lettres-ci. SES est un déterminant possessif : ses lettres, les siennes. Au singulier : cette lettre / sa lettre.',
  'a / à':
      'A est le verbe avoir : il a écrit (on peut dire « il avait écrit »). À est une préposition : écrire à quelqu’un.',
  'problème':
      'Difficulté ou question à résoudre. Selon le contexte : difficulté, obstacle, souci, question, désaccord. « Incident » convient à un événement ponctuel. Contraires possibles selon le sens : solution, facilité.',
  'acquérir':
      'Obtenir ou devenir propriétaire de quelque chose. Synonymes selon le contexte : obtenir, acheter, apprendre. Contraire : perdre, céder.\nSubjonctif présent : que j’acquière, que tu acquières, qu’il/elle acquière, que nous acquérions, que vous acquériez, qu’ils/elles acquièrent.',
  'être':
      'Présent : je suis, tu es, il/elle est, nous sommes, vous êtes, ils/elles sont.\nImparfait : j’étais, tu étais, il était, nous étions, vous étiez, ils étaient.\nParticipe passé : été.',
  'avoir':
      'Présent : j’ai, tu as, il/elle a, nous avons, vous avez, ils/elles ont.\nSubjonctif : que j’aie, que tu aies, qu’il ait, que nous ayons, que vous ayez, qu’ils aient.\nParticipe passé : eu.',
  'formules de politesse':
      'Courriel professionnel : « Bien cordialement » ou « Cordialement ».\nLettre formelle : « Je vous prie d’agréer, Madame, Monsieur, l’expression de mes salutations distinguées. »\nAdaptez l’appel à la fonction exacte du destinataire : « Madame la Préfète » ou « Monsieur le Préfet ».',
  'pièce jointe':
      'Document accompagnant un courrier ou un message. Dans une lettre : « Pièces jointes : copie de la facture, justificatif de paiement ». Ne mentionnez que les pièces réellement fournies.',
  'échéance':
      'Date à laquelle une obligation doit être exécutée ou une somme réglée. Synonymes selon le contexte : date limite, terme. Indiquez une date exacte seulement si elle est connue.',
  'expressions à éviter':
      '« Au jour d’aujourd’hui » → « aujourd’hui ».\n« Suite à » peut être remplacé, dans un registre soigné, par « à la suite de ».\n« Vous n’avez rien fait » → précisez les faits observables : « Je n’ai pas reçu de réponse à ma demande du [date]. »',
  'diplomatique':
      'Qui fait preuve de tact dans une relation. Synonymes : mesuré, conciliant, délicat. Antonymes selon le contexte : abrupt, maladroit. Exemple : « Pourrions-nous convenir d’une solution ? »',
};

class DictionaryPage extends ConsumerStatefulWidget {
  const DictionaryPage({super.key});
  @override
  ConsumerState<DictionaryPage> createState() => _DictionaryState();
}

class _DictionaryState extends ConsumerState<DictionaryPage> {
  final query = TextEditingController();
  String searched = '';
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> search() async {
    setState(() => searched = query.text.trim().toLowerCase());
    if (searched.isEmpty) return;
    final a = ref.read(atelierProvider);
    a.data.searches = [
      query.text,
      ...a.data.searches.where((s) => s != query.text),
    ].take(100).toList();
    await guarded(context, a.persist);
  }

  @override
  Widget build(BuildContext context) {
    final matches = lexicon.entries.where(
      (e) =>
          searched.isEmpty ||
          e.key.contains(searched) ||
          e.value.toLowerCase().contains(searched),
    );
    return PageBody(
      title: 'Le cabinet des curiosités linguistiques',
      subtitle:
          'Un mémento hors ligne et des recherches approfondies avec Bafou.',
      children: [
        TextField(
          controller: query,
          onSubmitted: (_) => search(),
          decoration: InputDecoration(
            labelText: 'Un mot, une règle, une conjugaison',
            suffixIcon: IconButton(
              tooltip: 'Rechercher',
              onPressed: search,
              icon: const Icon(Icons.search),
            ),
          ),
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
        const Text(
          'Ce mémento contient 11 fiches vérifiables ; ce n’est pas un dictionnaire exhaustif.',
        ),
        const SizedBox(height: 12),
        if (matches.isEmpty)
          const Text(
            'Aucune fiche locale correspondante. Vous pouvez consulter Bafou.',
          ),
        for (final e in matches)
          Card(
            child: ExpansionTile(
              title: Text(e.key),
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: SelectableText(e.value),
                ),
              ],
            ),
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
}
