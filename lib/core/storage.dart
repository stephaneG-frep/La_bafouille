import 'dart:io';
import 'models.dart';

/// Écritures sérialisées, fichier temporaire puis renommage atomique.
/// La dernière version valide est conservée séparément.
class LocalStore {
  LocalStore(this.directory);
  final Directory directory;
  Future<void> _pending = Future.value();
  File get file => File('${directory.path}/bibliotheque.json');
  File get backup => File('${directory.path}/bibliotheque.precedente.json');
  Future<AppData> read() async {
    if (!await file.exists()) return AppData();
    try {
      return AppData.decode(await file.readAsString());
    } catch (_) {
      // Pas de remplacement silencieux : récupération explicite dans l'interface.
      throw const FormatException(
        'Bibliothèque illisible. Restaurez une sauvegarde ; les fichiers originaux sont conservés.',
      );
    }
  }

  Future<void> save(AppData data) {
    final snapshot = data.encode();
    final next = _pending.then((_) async {
      await directory.create(recursive: true);
      if (await file.exists()) {
        final previous = await file.readAsString();
        AppData.decode(previous);
        await backup.writeAsString(previous, flush: true);
      }
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(snapshot, flush: true);
      await tmp.rename(file.path);
    });
    _pending = next.catchError((Object _) {});
    return next;
  }
}
