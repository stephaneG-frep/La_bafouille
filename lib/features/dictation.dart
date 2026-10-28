import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'common.dart';

/// Dictée en trois temps : accord, écoute avec transcription en direct,
/// puis relecture modifiable. Retourne le texte validé, ou null.
Future<String?> dictate(BuildContext context, {required String action}) async {
  if (!Platform.isAndroid) {
    notice(
      context,
      'La dictée intégrée est disponible sur Android. Sur Linux, utilisez votre outil de dictée système pour saisir du texte.',
    );
    return null;
  }
  final agreed = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Dictée vocale'),
      content: const Text(
        'Le service de reconnaissance Android peut traiter votre voix en ligne selon votre appareil. La transcription sera affichée pour validation. Autoriser le microphone ?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: const Text('Dicter'),
        ),
      ],
    ),
  );
  if (agreed != true || !context.mounted) return null;
  final text = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DictationDialog(action: action),
  );
  return text == null || text.trim().isEmpty ? null : text.trim();
}

class DictationDialog extends StatefulWidget {
  const DictationDialog({super.key, required this.action});
  final String action;
  @override
  State<DictationDialog> createState() => _DictationState();
}

class _DictationState extends State<DictationDialog> {
  final speech = SpeechToText();
  final words = TextEditingController();
  bool listening = false;
  String? error;
  @override
  void initState() {
    super.initState();
    listen();
  }

  @override
  void dispose() {
    speech.cancel();
    // Le service est un singleton : on détache les écouteurs de ce dialogue.
    speech.errorListener = null;
    speech.statusListener = null;
    words.dispose();
    super.dispose();
  }

  Future<void> listen() async {
    setState(() {
      error = null;
      listening = true;
    });
    try {
      final ok = await speech.initialize();
      // initialize() ne remplace pas les écouteurs après le premier appel.
      speech.statusListener = (s) {
        if (mounted && s != SpeechToText.listeningStatus) {
          setState(() => listening = false);
        }
      };
      speech.errorListener = (_) {
        if (mounted) {
          setState(() {
            listening = false;
            error = 'Reconnaissance interrompue. Vous pouvez recommencer.';
          });
        }
      };
      if (!ok) {
        throw const FormatException('Service vocal indisponible');
      }
      final before = words.text.trim();
      await speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: 'fr_FR',
          partialResults: true,
        ),
        onResult: (r) {
          if (!mounted) return;
          setState(() {
            words.text = [
              before,
              r.recognizedWords,
            ].where((s) => s.isNotEmpty).join(' ');
            if (r.finalResult) listening = false;
          });
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          listening = false;
          error = 'Microphone refusé ou service vocal indisponible.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Row(
      children: [
        Icon(
          listening ? Icons.mic : Icons.mic_none,
          color: listening ? Palette.coral : null,
        ),
        const SizedBox(width: 12),
        Text(listening ? 'Je vous écoute…' : 'Vérifiez votre dictée'),
      ],
    ),
    content: SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (listening) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: words,
            readOnly: listening,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'La transcription apparaît ici. Corrigez-la au besoin.',
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Refuser'),
      ),
      if (listening)
        OutlinedButton(onPressed: speech.stop, child: const Text('Arrêter'))
      else
        OutlinedButton(
          onPressed: listen,
          child: const Text('Continuer à dicter'),
        ),
      FilledButton(
        onPressed: listening ? null : () => Navigator.pop(context, words.text),
        child: Text(widget.action),
      ),
    ],
  );
}
