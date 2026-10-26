import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'storage.dart';

final atelierProvider = ChangeNotifierProvider<Atelier>(
  (ref) => throw UnimplementedError('Initialiser le stockage'),
);

class Atelier extends ChangeNotifier {
  Atelier(this.store, this.data);
  final LocalStore store;
  AppData data;
  String? error;
  int _sequence = 0;
  String newId() => '${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
  Letter? byId(String id) {
    for (final l in data.letters) {
      if (l.id == id) return l;
    }
    return null;
  }

  Future<void> persist() async {
    try {
      await store.save(data);
      error = null;
    } catch (_) {
      error =
          'Enregistrement impossible. Vérifiez l’espace disque et exportez votre texte avant de fermer.';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<Letter> create({
    String title = 'Nouveau courrier',
    String text = '',
    String category = 'Vie quotidienne',
  }) async {
    final letter = Letter(
      id: newId(),
      title: title,
      text: text,
      category: category,
    );
    data.letters.insert(0, letter);
    await persist();
    return letter;
  }

  Future<void> restore(String source) async {
    final restored = AppData.decode(source);
    // Fusion : une restauration ne remplace jamais un document existant.
    for (final letter in restored.letters) {
      final copy = Letter.fromJson({...letter.toJson(), 'id': newId()});
      data.letters.add(copy);
    }
    data.searches = {...data.searches, ...restored.searches}.take(100).toList();
    data.settings.addAll(restored.settings);
    await persist();
  }
}
