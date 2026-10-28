import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../core/ai.dart';
import '../core/state.dart';
import 'common.dart';
import 'dictation.dart';

Future<AiConfig?> consentConfig(BuildContext context, Atelier a) async {
  final p = a.data.settings['provider'] as String? ?? 'Ollama';
  final model = a.data.settings['model'] as String? ?? '';
  if (model.isEmpty) {
    notice(
      context,
      'Configurez d’abord votre fournisseur et son modèle dans Paramètres.',
    );
    return null;
  }
  final ollama =
      a.data.settings['ollama'] as String? ?? 'http://localhost:11434';
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('Envoyer à $p ?'),
      content: Text(
        'La demande, le contexte affiché et l’historique de cette conversation seront transmis à $p (modèle : $model). ${p == 'Ollama' ? 'Adresse du serveur : $ollama\nVérifiez qu’elle désigne bien votre propre serveur.' : 'Cet appel peut être facturé par votre fournisseur.'}\n\nRelisez les données personnelles avant de continuer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: const Text('Autoriser cet envoi'),
        ),
      ],
    ),
  );
  if (ok != true) return null;
  final key = p == 'Ollama'
      ? ''
      : await const FlutterSecureStorage().read(key: 'api_$p') ?? '';
  return AiConfig(provider: p, model: model, key: key, ollama: ollama);
}

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({
    super.key,
    this.mode = 'chat',
    this.documentId,
    this.initialPrompt = '',
    this.autoSend = false,
  });
  final String mode, initialPrompt;

  /// Demande validée ailleurs (dictée) : on enchaîne sur l'envoi,
  /// toujours précédé du dialogue de consentement.
  final bool autoSend;
  final String? documentId;
  @override
  ConsumerState<AssistantPage> createState() => _AssistantState();
}

class _AssistantState extends ConsumerState<AssistantPage> {
  late final TextEditingController prompt = TextEditingController(
    text: widget.initialPrompt,
  );
  final ai = AiService();
  final selected = <String>{'Naturel'};
  final messages = <(String, String)>[];
  final proposals = <String>[];
  bool busy = false;
  String? failure;
  int count = 2;

  /// Contexte de la dernière demande, réutilisé pour régénérer une proposition.
  String lastBase = '';
  @override
  void initState() {
    super.initState();
    if (widget.autoSend) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) send();
      });
    }
  }

  Future<void> dictateRequest() async {
    final words = await dictate(context, action: 'Ajouter à ma demande');
    if (words == null || !mounted) return;
    final current = prompt.text.trim();
    prompt.text = current.isEmpty ? words : '$current\n$words';
  }

  @override
  void dispose() {
    prompt.dispose();
    ai.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (busy || prompt.text.trim().isEmpty) return;
    final a = ref.read(atelierProvider);
    final l = widget.documentId == null ? null : a.byId(widget.documentId!);
    setState(() {
      busy = true;
      failure = null;
    });
    try {
      final config = await consentConfig(context, a);
      if (config == null) return;
      final question = prompt.text.trim();
      final history = messages.map((m) => '${m.$1} : ${m.$2}').join('\n');
      final base =
          'Document actuel :\n${l?.text ?? "Aucun document ouvert"}\n\nConversation :\n$history\n\nDemande : $question\nStyles : ${selected.join(", ")}';
      lastBase = base;
      final results = <String>[];
      final n = widget.mode == 'styles' ? count : 1;
      for (var i = 0; i < n; i++) {
        results.add(
          await ai.generate(
            config,
            '$base\n${widget.mode == 'letter'
                ? 'Prépare un courrier structuré ou pose les questions indispensables.'
                : widget.mode == 'styles'
                ? 'Propose uniquement la version ${i + 1} du texte, avec une approche distincte.'
                : 'Réponds à la demande. Si une réécriture est demandée, donne le texte proposé.'}',
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        messages.add(('Vous', question));
        for (final result in results) {
          messages.add(('Bafou', result));
        }
        proposals
          ..clear()
          ..addAll(results);
        prompt.clear();
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => failure = e is AiFailure
              ? e.message
              : 'Impossible d’accéder au coffre de clés ou au fournisseur. Vérifiez les paramètres.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Remplace une seule proposition par une nouvelle version (nouvel accord).
  Future<void> regenerate(int i) async {
    if (busy || lastBase.isEmpty) return;
    setState(() {
      busy = true;
      failure = null;
    });
    try {
      final config = await consentConfig(context, ref.read(atelierProvider));
      if (config == null) return;
      final result = await ai.generate(
        config,
        '$lastBase\nPropose une nouvelle version, nettement différente de celle-ci :\n${proposals[i]}',
      );
      if (!mounted) return;
      setState(() {
        messages.add(('Bafou', result));
        proposals[i] = result;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => failure = e is AiFailure
              ? e.message
              : 'Impossible d’accéder au coffre de clés ou au fournisseur. Vérifiez les paramètres.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Retouche manuelle : modifier un paragraphe ou y coller un passage
  /// copié d'une autre proposition.
  Future<void> edit(int i) async {
    final c = TextEditingController(text: proposals[i]);
    final next = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Retoucher la proposition ${i + 1}'),
        content: SizedBox(
          width: 700,
          child: TextField(
            controller: c,
            minLines: 10,
            maxLines: 20,
            decoration: const InputDecoration(
              helperText:
                  'Modifiez un paragraphe ou collez un passage copié d’une autre proposition.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, c.text),
            child: const Text('Valider la retouche'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    c.dispose();
    if (next != null && next.trim().isNotEmpty && mounted) {
      setState(() => proposals[i] = next.trim());
    }
  }

  Widget proposalCard(int i) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proposition ${i + 1}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SelectableText(proposals[i]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton(
                onPressed: busy ? null : () => accept(proposals[i]),
                child: const Text('Utiliser ce texte'),
              ),
              TextButton(
                onPressed: busy ? null : () => edit(i),
                child: const Text('Retoucher'),
              ),
              TextButton(
                onPressed: busy ? null : () => regenerate(i),
                child: const Text('Nouvelle proposition'),
              ),
              TextButton(
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: proposals[i])),
                child: const Text('Copier'),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() => proposals.removeAt(i)),
                child: const Text('Refuser'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> accept(String proposal) async {
    final a = ref.read(atelierProvider);
    final l = widget.documentId == null ? null : a.byId(widget.documentId!);
    if (l == null) {
      await guarded(context, () async {
        final created = await a.create(
          title: 'Proposition de Bafou',
          text: proposal,
        );
        if (mounted) context.go('/editor/${created.id}');
      });
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Comparer avant de remplacer'),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VERSION ACTUELLE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SelectableText(l.text),
                const Divider(),
                const Text(
                  'PROPOSITION',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SelectableText(proposal),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Refuser'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Accepter et conserver l’ancienne version'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await guarded(context, () async {
        l.revise(proposal);
        await a.persist();
        if (mounted) context.go('/editor/${l.id}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(atelierProvider);
    final l = widget.documentId == null ? null : a.byId(widget.documentId!);
    return PageBody(
      title: widget.mode == 'styles'
          ? 'Le laboratoire des styles'
          : 'Un tête-à-tête avec Bafou',
      subtitle:
          'Fournisseur : ${a.data.settings['provider'] ?? 'Ollama'} • Aucune modification sans votre validation.',
      children: [
        if (l != null)
          ExpansionTile(
            title: Text('Contexte transmis : ${l.title}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(l.text),
              ),
            ],
          ),
        const Text('Choisissez les nuances de votre plume'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in styles)
              FilterChip(
                label: Text(s),
                selected: selected.contains(s),
                onSelected: busy
                    ? null
                    : (v) => setState(() {
                        v ? selected.add(s) : selected.remove(s);
                      }),
              ),
          ],
        ),
        if (widget.mode == 'styles')
          DropdownButton<int>(
            value: count,
            items: [
              for (final n in [1, 2, 3])
                DropdownMenuItem(
                  value: n,
                  child: Text(
                    '$n proposition${n > 1 ? 's' : ''} (autant d’appels IA)',
                  ),
                ),
            ],
            onChanged: busy ? null : (v) => setState(() => count = v!),
          ),
        const SizedBox(height: 20),
        for (final m in messages)
          Card(
            color: m.$1 == 'Vous'
                ? Theme.of(context).colorScheme.secondaryContainer
                : null,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.$1,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(m.$2),
                ],
              ),
            ),
          ),
        if (proposals.isNotEmpty) ...[
          const Text(
            'Les propositions restent séparées de votre document. Retouchez-les, copiez des passages de l’une à l’autre, puis utilisez votre préférée. L’ancienne version reste dans l’historique.',
          ),
          const SizedBox(height: 12),
          // Comparateur côte à côte sur grand écran.
          LayoutBuilder(
            builder: (context, c) => c.maxWidth >= 900 && proposals.length > 1
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < proposals.length; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: i < proposals.length - 1 ? 12 : 0,
                            ),
                            child: proposalCard(i),
                          ),
                        ),
                    ],
                  )
                : Column(
                    children: [
                      for (var i = 0; i < proposals.length; i++)
                        proposalCard(i),
                    ],
                  ),
          ),
        ],
        if (failure != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              failure!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        TextField(
          controller: prompt,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Votre demande à Bafou',
            hintText:
                'Racontez les faits, le destinataire et le résultat souhaité…',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: busy ? null : send,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(busy ? 'Bafou réfléchit…' : 'Préparer l’envoi'),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : dictateRequest,
              icon: const Icon(Icons.mic_none),
              label: const Text('Dicter'),
            ),
            TextButton(
              onPressed: () => context.go('/settings'),
              child: const Text('Configurer l’IA'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Vérifiez toujours les faits et les champs à compléter. Un courrier généré ne constitue pas un conseil juridique professionnel.',
        ),
      ],
    );
  }
}
