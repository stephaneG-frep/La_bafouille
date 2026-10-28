import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/ai.dart';
import '../core/state.dart';
import '../core/version.dart';
import 'assistant.dart';
import 'editor.dart';
import 'common.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<SettingsPage> {
  final key = TextEditingController(),
      model = TextEditingController(),
      url = TextEditingController();
  String provider = 'Ollama';
  bool busy = false;
  String info = '';
  static const secure = FlutterSecureStorage();
  @override
  void initState() {
    super.initState();
    final s = ref.read(atelierProvider).data.settings;
    provider = s['provider'] as String? ?? 'Ollama';
    if (!providers.contains(provider)) provider = 'Ollama';
    model.text = s['model'] as String? ?? '';
    url.text = s['ollama'] as String? ?? 'http://localhost:11434';
  }

  @override
  void dispose() {
    key.dispose();
    model.dispose();
    url.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (model.text.trim().isEmpty) {
      throw const AiFailure('Renseignez un modèle.');
    }
    if (key.text.trim().isNotEmpty) {
      await secure.write(key: 'api_$provider', value: key.text.trim());
      key.clear();
    }
    final a = ref.read(atelierProvider);
    a.data.settings.addAll({
      'provider': provider,
      'model': model.text.trim(),
      'ollama': url.text.trim(),
    });
    await a.persist();
    if (mounted) {
      setState(
        () => info =
            'Configuration enregistrée. Les clés restent dans le coffre sécurisé.',
      );
    }
  }

  Future<void> operation(Future<void> Function() action) async {
    setState(() {
      busy = true;
      info = '';
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(
          () => info = e is AiFailure
              ? e.message
              : 'Opération impossible. Vérifiez le coffre de clés du système, les permissions et les paramètres.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> testConnection() async {
    await save();
    if (!mounted) return;
    final config = await consentConfig(context, ref.read(atelierProvider));
    if (config == null) return;
    final ai = AiService();
    try {
      final result = await ai.generate(
        config,
        'Réponds seulement : connexion réussie.',
      );
      if (mounted) setState(() => info = 'Réponse reçue : $result');
    } finally {
      ai.dispose();
    }
  }

  Future<void> restore() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (picked == null) return;
    final bytes =
        picked.files.single.bytes ??
        await File(picked.files.single.path!).readAsBytes();
    if (bytes.length > 50000000) {
      throw const FormatException('Sauvegarde trop volumineuse');
    }
    if (!mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Restaurer la bibliothèque ?'),
        content: const Text(
          'Les documents seront ajoutés comme copies. Vos documents actuels seront conservés. Les paramètres non sensibles du fichier seront importés. Aucune clé API ni adresse de serveur ne sera importée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await ref.read(atelierProvider).restore(utf8.decode(bytes));
      if (mounted) {
        setState(
          () => info =
              'Sauvegarde restaurée. Les documents sont disponibles dans Courriers.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(atelierProvider);
    return PageBody(
      title: 'Les réglages de l’atelier',
      subtitle:
          'Vos données sur votre appareil. Vos clés dans le coffre du système.',
      children: [
        SwitchListTile(
          title: const Text('Mode sombre'),
          subtitle: const Text('Une ambiance nocturne pour écrire'),
          value: a.data.settings['dark'] == true,
          onChanged: (v) => guarded(context, () async {
            a.data.settings['dark'] = v;
            await a.persist();
          }),
        ),
        const SizedBox(height: 20),
        Text(
          'Le moteur de Bafou',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: provider,
          decoration: const InputDecoration(labelText: 'Fournisseur IA'),
          items: [
            for (final p in providers)
              DropdownMenuItem(value: p, child: Text(p)),
          ],
          onChanged: busy
              ? null
              : (v) => setState(() {
                  provider = v!;
                  model.clear();
                  key.clear();
                  info = 'Choisissez un modèle disponible chez $provider.';
                }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: model,
          decoration: InputDecoration(
            labelText: 'Identifiant exact du modèle',
            helperText: switch (provider) {
              'Grok' => 'Saisissez un modèle xAI accessible à votre compte.',
              'Perplexity' =>
                'Saisissez un modèle Perplexity accessible à votre compte.',
              'Ollama' => 'Saisissez le nom exact du modèle installé.',
              _ => 'Saisissez un modèle accessible à votre compte fournisseur.',
            },
          ),
        ),
        const SizedBox(height: 12),
        if (provider == 'Ollama')
          TextField(
            controller: url,
            decoration: const InputDecoration(
              labelText: 'Adresse du serveur Ollama',
              helperText:
                  'Émulateur Android : http://10.0.2.2:11434. Téléphone : utilisez une adresse HTTPS.',
            ),
          )
        else
          TextField(
            controller: key,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Nouvelle clé API',
              helperText:
                  'Laissez vide pour conserver la clé déjà enregistrée.',
            ),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: busy ? null : () => operation(save),
              child: const Text('Enregistrer la configuration'),
            ),
            OutlinedButton(
              onPressed: busy ? null : () => operation(testConnection),
              child: const Text('Tester la connexion'),
            ),
            if (provider != 'Ollama')
              TextButton(
                onPressed: busy
                    ? null
                    : () => operation(() async {
                        await secure.delete(key: 'api_$provider');
                        if (mounted) {
                          setState(
                            () => info = 'Clé supprimée du coffre sécurisé.',
                          );
                        }
                      }),
                child: const Text('Supprimer la clé'),
              ),
          ],
        ),
        if (busy) const LinearProgressIndicator(),
        if (info.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SelectableText(info),
          ),
        const SizedBox(height: 28),
        Text(
          'Sauvegardes et confidentialité',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'La bibliothèque est enregistrée localement après chaque modification. La version précédente du fichier est conservée automatiquement. Exportez régulièrement une copie sur un support distinct. Les sauvegardes JSON contiennent vos courriers en clair : conservez-les dans un emplacement privé. Elles ne contiennent aucune clé API.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => operation(() async {
                await saveBytes(
                  context,
                  'La_Bafouille_sauvegarde.json',
                  Uint8List.fromList(utf8.encode(a.data.encode())),
                );
              }),
              icon: const Icon(Icons.backup_outlined),
              label: const Text('Exporter la bibliothèque'),
            ),
            OutlinedButton.icon(
              onPressed: () => operation(restore),
              icon: const Icon(Icons.restore),
              label: const Text('Restaurer une sauvegarde'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SelectableText('Dossier local : ${a.store.directory.path}'),
        const SizedBox(height: 20),
        const Text(
          'La Bafouille $appVersion • Aucune télémétrie intégrée\nLe traitement distant est déclenché uniquement par vos actions et après consentement. La disponibilité et la facturation des modèles dépendent du fournisseur.',
        ),
      ],
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  @override
  Widget build(BuildContext context) => const PageBody(
    title: 'Le petit guide de l’atelier',
    subtitle: 'De la première idée au courrier prêt à partir.',
    children: [
      ExpansionTile(
        initiallyExpanded: true,
        title: Text('1. Rédiger et retrouver un courrier'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Depuis l’accueil, choisissez Nouveau courrier ou l’un des 54 modèles. Remplacez les champs entre crochets. Donnez un titre à votre texte. Les modifications sont enregistrées après une courte pause de saisie. Vérifiez l’indication « Enregistré ». Retrouvez le texte dans Courriers ou Brouillons. Le statut Terminé est un repère : il n’envoie rien.',
            ),
          ),
        ],
      ),
      ExpansionTile(
        title: Text('2. Utiliser Bafou et les styles'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Configurez un fournisseur et le nom exact d’un modèle dans Paramètres. Pour un fournisseur distant, renseignez votre propre clé. Pour Ollama, démarrez votre serveur et installez un modèle. Chaque envoi demande votre accord et peut coûter des crédits chez un fournisseur distant. Décrivez les faits et le ton souhaité. Depuis l’éditeur, Bafou reçoit le document en contexte. Comparez la proposition puis acceptez ou refusez. Le laboratoire propose jusqu’à trois versions. Copiez des passages pour les fusionner dans l’éditeur.',
            ),
          ),
        ],
      ),
      ExpansionTile(
        title: Text('3. Corriger et apprendre'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Le labo des mots conserve le texte original. Analysez localement, puis cochez les corrections que vous acceptez. Les cases décochées sont des refus. Vous pouvez toutes les annuler. L’icône en forme de toque ouvre l’explication détaillée de chaque règle, et des mini-exercices permettent de s’entraîner. L’enregistrement conserve l’original dans les versions. Le correcteur local est limité ; une analyse IA approfondie est disponible avec configuration et consentement. Le dictionnaire local est un petit mémento, complété par les questions à Bafou.',
            ),
          ),
        ],
      ),
      ExpansionTile(
        title: Text('4. Exporter, imprimer et partager'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Dans l’éditeur, choisissez Exporter puis PDF, DOCX, TXT ou HTML et un emplacement. Le PDF est au format A4. L’icône imprimante ouvre le service d’impression. Android permet le partage vers une application de messagerie installée. Sur Linux, l’icône d’enveloppe ouvre votre messagerie avec l’objet et le texte préremplis ; pour envoyer un PDF, exportez-le puis joignez-le au message. Le gras (**texte**), l’italique (*texte*) et le souligné (<u>texte</u>) sont interprétés dans l’aperçu et les exports PDF, DOCX et HTML. Le TXT conserve uniquement le texte.',
            ),
          ),
        ],
      ),
      ExpansionTile(
        title: Text('5. Sauvegarder et restaurer'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Paramètres → Exporter la bibliothèque produit un fichier JSON avec documents, versions et réglages non sensibles. Conservez-le dans un lieu sûr : il n’est pas chiffré. Après réinstallation, utilisez Restaurer. Les documents sont ajoutés comme copies afin de préserver votre bibliothèque actuelle. Ressaisissez les clés API si nécessaire. Une suppression depuis Courriers déplace le document dans la corbeille, où il peut être restauré.',
            ),
          ),
        ],
      ),
      ExpansionTile(
        title: Text('6. Dicter et écouter'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sur Android, le microphone demande l’autorisation d’utiliser la reconnaissance vocale du système. Relisez la transcription puis validez son insertion. Le service Android peut utiliser Internet. La lecture vocale utilise la voix française disponible sur l’appareil. Sur Linux, la lecture nécessite espeak-ng ; la dictée intégrée n’est pas disponible.',
            ),
          ),
        ],
      ),
      ExpansionTile(
        title: Text('7. Confidentialité et limites'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Les courriers restent locaux jusqu’à une action de partage ou d’envoi IA. Vérifiez les faits, les coordonnées, les dates et les montants avant tout envoi. Les textes ne sont pas des avis juridiques professionnels. En cas d’échec d’enregistrement, copiez ou exportez votre texte avant de fermer. N’insérez jamais de clé API dans un courrier.',
            ),
          ),
        ],
      ),
    ],
  );
}
