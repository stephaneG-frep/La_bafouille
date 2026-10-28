import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../core/models.dart';
import '../core/markup.dart';
import '../core/exports.dart';
import '../core/state.dart';
import 'common.dart';
import 'dictation.dart';

Future<void> saveBytes(
  BuildContext context,
  String name,
  Uint8List bytes,
) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Enregistrer le fichier',
    fileName: name,
    bytes: bytes,
  );
  if (path != null && !Platform.isAndroid && !Platform.isIOS) {
    await File(path).writeAsBytes(bytes, flush: true);
  }
  if (path != null && context.mounted) notice(context, 'Fichier enregistré.');
}

/// Ouvre la messagerie par défaut (Linux) avec l'objet et le texte préremplis.
Future<void> openMail(String subject, String body) async {
  final uri =
      'mailto:?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}';
  final result = await Process.run('xdg-open', [uri]);
  if (result.exitCode != 0) {
    throw const ProcessException('xdg-open', []);
  }
}

class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key, required this.id});
  final String id;
  @override
  ConsumerState<EditorPage> createState() => _EditorState();
}

class _EditorState extends ConsumerState<EditorPage> {
  late TextEditingController title, text;
  late Letter? letter;
  late Atelier atelier;
  bool preview = false;
  final undo = UndoHistoryController();
  late final tts = FlutterTts();
  Timer? timer;
  String status = 'Enregistré';
  TextAlign alignment = TextAlign.left;
  @override
  void initState() {
    super.initState();
    atelier = ref.read(atelierProvider);
    letter = atelier.byId(widget.id);
    alignment = switch (letter?.alignment) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      'justify' => TextAlign.justify,
      _ => TextAlign.left,
    };
    title = TextEditingController(text: letter?.title ?? '');
    text = TextEditingController(text: letter?.text ?? '');
    text.addListener(changed);
    title.addListener(changed);
  }

  void changed() {
    if (letter == null) return;
    setState(() => status = 'Enregistrement en cours…');
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 700), save);
  }

  Future<void> save() async {
    if (letter == null) return;
    timer?.cancel();
    letter!.title = title.text.trim().isEmpty
        ? 'Sans titre'
        : title.text.trim();
    letter!.revise(text.text);
    letter!.alignment = alignment.name;
    try {
      await ref.read(atelierProvider).persist();
      if (mounted) setState(() => status = 'Enregistré sur cet appareil');
    } catch (_) {
      if (mounted) {
        setState(
          () => status = 'Échec de l’enregistrement — exportez votre texte',
        );
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    text.removeListener(changed);
    title.removeListener(
      changed,
    ); // Dernière sauvegarde lors de la fermeture de cet écran.
    final l = letter;
    if (l != null) {
      l.title = title.text.trim().isEmpty ? 'Sans titre' : title.text.trim();
      l.revise(text.text);
      l.alignment = alignment.name;
      atelier.persist().catchError((Object _) {});
    }
    title.dispose();
    text.dispose();
    undo.dispose();
    if (Platform.isAndroid) tts.stop();
    super.dispose();
  }

  void wrap(String marker) {
    final s = text.selection;
    final start = s.isValid ? s.start : text.text.length;
    final end = s.isValid ? s.end : start;
    final selected = text.text.substring(start, end);
    text.value = TextEditingValue(
      text: text.text.replaceRange(start, end, '$marker$selected$marker'),
      selection: TextSelection(
        baseOffset: start + marker.length,
        extentOffset: end + marker.length,
      ),
    );
  }

  Future<void> replace() async {
    final find = TextEditingController(), replacement = TextEditingController();
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Rechercher et remplacer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: find,
              decoration: const InputDecoration(
                labelText: 'Rechercher (respecte la casse)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: replacement,
              decoration: const InputDecoration(labelText: 'Remplacer par'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remplacer tout'),
          ),
        ],
      ),
    );
    if (yes == true && find.text.isNotEmpty) {
      text.text = text.text.replaceAll(find.text, replacement.text);
    }
    // Contrôleurs libérés après la fermeture et l’animation de la boîte de dialogue.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    find.dispose();
    replacement.dispose();
  }

  Future<void> history() async {
    await save();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Versions précédentes'),
        content: SizedBox(
          width: 600,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (letter!.versions.isEmpty)
                const Text(
                  'Les versions apparaîtront après vos modifications.',
                ),
              for (final version in letter!.versions.reversed)
                ListTile(
                  title: Text(
                    version,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.restore),
                  onTap: () {
                    text.text = version;
                    Navigator.pop(c);
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> pdf() async {
    final font = pw.Font.ttf(
      await rootBundle.load('assets/LiberationSans-Regular.ttf'),
    );
    return Exports.pdf(
      letter!,
      font: font,
      bold: pw.Font.ttf(
        await rootBundle.load('assets/LiberationSans-Bold.ttf'),
      ),
      italic: pw.Font.ttf(
        await rootBundle.load('assets/LiberationSans-Italic.ttf'),
      ),
      boldItalic: pw.Font.ttf(
        await rootBundle.load('assets/LiberationSans-BoldItalic.ttf'),
      ),
    );
  }

  Future<void> export(String format) async {
    await save();
    if (!mounted) return;
    await guarded(context, () async {
      final name = letter!.title.replaceAll(RegExp(r'[^a-zA-Z0-9À-ÿ _-]'), '_');
      final bytes = switch (format) {
        'PDF' => await pdf(),
        'DOCX' => Exports.docx(letter!),
        'HTML' => Uint8List.fromList(utf8.encode(Exports.html(letter!))),
        _ => Uint8List.fromList(utf8.encode(plainText(letter!.text))),
      };
      if (mounted) {
        await saveBytes(context, '$name.${format.toLowerCase()}', bytes);
      }
    });
  }

  /// Insère la dictée validée à la position du curseur.
  Future<void> dictateHere() async {
    final s = text.selection;
    final words = await dictate(context, action: 'Insérer');
    if (words == null || !mounted) return;
    final pos = s.isValid ? s.end : text.text.length;
    final before = text.text.substring(0, pos);
    final insert =
        '${before.isEmpty || before.endsWith('\n') || before.endsWith(' ') ? '' : ' '}$words';
    text.value = TextEditingValue(
      text: text.text.replaceRange(pos, pos, insert),
      selection: TextSelection.collapsed(offset: pos + insert.length),
    );
  }

  Future<void> readAloud() async {
    await guarded(context, () async {
      if (Platform.isAndroid) {
        await tts.setLanguage('fr-FR');
        await tts.speak(text.text);
      } else {
        final p = await Process.start('espeak-ng', ['-v', 'fr', '--stdin']);
        p.stdin.write(text.text);
        await p.stdin.close();
        final code = await p.exitCode;
        if (code != 0) throw const ProcessException('espeak-ng', []);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (letter == null) {
      return const Center(child: Text('Courrier introuvable.'));
    }
    return PageBody(
      title: 'Le bureau de rédaction',
      subtitle: status,
      children: [
        TextField(
          controller: title,
          decoration: const InputDecoration(labelText: 'Titre du courrier'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: letter!.category,
          decoration: const InputDecoration(labelText: 'Catégorie'),
          items: [
            for (final c in {...categories, letter!.category})
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (v) {
            if (v == null) return;
            letter!.category = v;
            changed();
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Enregistrer'),
            ),
            OutlinedButton.icon(
              onPressed: () => guarded(context, () async {
                await save();
                if (context.mounted) context.go('/assistant?doc=${letter!.id}');
              }),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Bafou'),
            ),
            OutlinedButton.icon(
              onPressed: history,
              icon: const Icon(Icons.history),
              label: const Text('Versions'),
            ),
            PopupMenuButton<String>(
              tooltip: 'Exporter le courrier',
              onSelected: export,
              itemBuilder: (_) => [
                for (final f in ['PDF', 'DOCX', 'TXT', 'HTML'])
                  PopupMenuItem(value: f, child: Text(f)),
              ],
              child: const Chip(
                avatar: Icon(Icons.file_download_outlined),
                label: Text('Exporter'),
              ),
            ),
            FilterChip(
              label: const Text('Terminé'),
              selected: letter!.done,
              onSelected: (v) => guarded(context, () async {
                setState(() => letter!.done = v);
                await save();
              }),
            ),
            FilterChip(
              label: const Text('Favori'),
              selected: letter!.favorite,
              onSelected: (v) => guarded(context, () async {
                setState(() => letter!.favorite = v);
                await save();
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              children: [
                IconButton(
                  tooltip: 'Annuler',
                  onPressed: undo.undo,
                  icon: const Icon(Icons.undo),
                ),
                IconButton(
                  tooltip: 'Rétablir',
                  onPressed: undo.redo,
                  icon: const Icon(Icons.redo),
                ),
                IconButton(
                  tooltip: 'Gras (balisage **texte**)',
                  onPressed: () => wrap('**'),
                  icon: const Icon(Icons.format_bold),
                ),
                IconButton(
                  tooltip: 'Italique (balisage *texte*)',
                  onPressed: () => wrap('*'),
                  icon: const Icon(Icons.format_italic),
                ),
                IconButton(
                  tooltip: 'Souligné (balisage HTML)',
                  onPressed: () {
                    final s = text.selection;
                    if (!s.isValid) return;
                    text.text = text.text.replaceRange(
                      s.start,
                      s.end,
                      '<u>${s.textInside(text.text)}</u>',
                    );
                  },
                  icon: const Icon(Icons.format_underlined),
                ),
                IconButton(
                  tooltip: 'Liste',
                  onPressed: () {
                    final s = text.selection;
                    final pos = s.isValid ? s.start : text.text.length;
                    text.text = text.text.replaceRange(pos, pos, '\n• ');
                  },
                  icon: const Icon(Icons.format_list_bulleted),
                ),
                IconButton(
                  tooltip: 'Alignement du document',
                  onPressed: () {
                    setState(
                      () => alignment = switch (alignment) {
                        TextAlign.left => TextAlign.center,
                        TextAlign.center => TextAlign.right,
                        TextAlign.right => TextAlign.justify,
                        _ => TextAlign.left,
                      },
                    );
                    changed();
                  },
                  icon: const Icon(Icons.format_align_center),
                ),
                IconButton(
                  tooltip: 'Rechercher et remplacer',
                  onPressed: replace,
                  icon: const Icon(Icons.find_replace),
                ),
                IconButton(
                  tooltip: 'Copier le texte',
                  onPressed: () => guarded(context, () async {
                    await Clipboard.setData(ClipboardData(text: text.text));
                    if (context.mounted) notice(context, 'Texte copié.');
                  }),
                  icon: const Icon(Icons.copy),
                ),
                IconButton(
                  tooltip: 'Dicter',
                  onPressed: dictateHere,
                  icon: const Icon(Icons.mic_none),
                ),
                IconButton(
                  tooltip: 'Lire à voix haute',
                  onPressed: readAloud,
                  icon: const Icon(Icons.volume_up_outlined),
                ),
                IconButton(
                  tooltip: 'Imprimer',
                  onPressed: () => guarded(context, () async {
                    await save();
                    await Printing.layoutPdf(onLayout: (_) => pdf());
                  }),
                  icon: const Icon(Icons.print_outlined),
                ),
                IconButton(
                  tooltip: Platform.isAndroid
                      ? 'Partager via une application'
                      : 'Envoyer par courriel',
                  onPressed: () => guarded(context, () async {
                    await save();
                    if (Platform.isAndroid) {
                      await Share.share(
                        plainText(text.text),
                        subject: title.text,
                      );
                    } else {
                      await openMail(title.text, plainText(text.text));
                    }
                  }),
                  icon: Icon(
                    Platform.isAndroid
                        ? Icons.share_outlined
                        : Icons.forward_to_inbox_outlined,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Text(
          'Mise en forme légère : **gras**, *italique*, <u>souligné</u>. L’aperçu et les exports PDF, DOCX et HTML interprètent ces marques.',
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Aperçu mis en forme'),
          value: preview,
          onChanged: (v) => setState(() => preview = v),
        ),
        if (preview)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    for (final run in parseMarkup(text.text))
                      TextSpan(
                        text: run.text,
                        style: TextStyle(
                          fontWeight: run.bold
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontStyle: run.italic
                              ? FontStyle.italic
                              : FontStyle.normal,
                          decoration: run.underline
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                  ],
                ),
                textAlign: alignment,
                style: const TextStyle(fontSize: 17, height: 1.7),
              ),
            ),
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 500),
          child: TextField(
            controller: text,
            undoController: undo,
            textAlign: alignment,
            keyboardType: TextInputType.multiline,
            minLines: 20,
            maxLines: null,
            style: const TextStyle(fontSize: 17, height: 1.7),
            decoration: const InputDecoration(
              hintText: 'Madame, Monsieur,\n\nÀ vous de jouer…',
              alignLabelWithHint: true,
              labelText: 'Votre courrier',
              contentPadding: EdgeInsets.all(24),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${text.text.trim().isEmpty ? 0 : text.text.trim().split(RegExp(r"\s+")).length} mots • ${text.text.length} caractères',
        ),
      ],
    );
  }
}
