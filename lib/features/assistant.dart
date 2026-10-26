import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../core/ai.dart';
import '../core/state.dart';
import 'common.dart';

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
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('Envoyer à $p ?'),
      content: Text(
        'La demande, le contexte affiché et l’historique de cette conversation seront transmis à $p (modèle : $model). ${p == 'Ollama' ? 'Vérifiez que l’adresse désigne bien votre serveur local.' : 'Cet appel peut être facturé par votre fournisseur.'}\n\nRelisez les données personnelles avant de continuer.',
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
  return AiConfig(
    provider: p,
    model: model,
    key: key,
    ollama: a.data.settings['ollama'] as String? ?? 'http://localhost:11434',
  );
}

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({
    super.key,
    this.mode = 'chat',
    this.documentId,
    this.initialPrompt = '',
  });
  final String mode, initialPrompt;
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
            'Les propositions restent séparées de votre document. Copiez des passages pour les fusionner dans l’éditeur.',
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < proposals.length; i++)
            Card(
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
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton(
                          onPressed: busy ? null : () => accept(proposals[i]),
                          child: const Text('Utiliser ce texte'),
                        ),
                        TextButton(
                          onPressed: () => Clipboard.setData(
                            ClipboardData(text: proposals[i]),
                          ),
                          child: const Text('Copier'),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => proposals.removeAt(i)),
                          child: const Text('Refuser'),
                        ),
                      ],
                    ),
                  ],
                ),
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
