import 'dart:convert';

const categories = [
  'Administration',
  'Travail',
  'Banque',
  'Assurance',
  'Logement',
  'Consommation',
  'Famille',
  'Associations',
  'Vie quotidienne',
];

/// Squelette d'une lettre française : les crochets signalent
/// les informations à compléter, rien n'est inventé.
const letterSkeleton = '''[Prénom et nom]
[Adresse]
[Téléphone ou courriel]

[Destinataire]
[Adresse du destinataire]

[Ville], le [date]

Objet : [objet du courrier]
Référence : [numéro de dossier, de contrat ou de client, si nécessaire]

Madame, Monsieur,

[Exposez la situation et les faits.]

[Précisez votre demande et, si besoin, le délai souhaité.]

Je vous prie d’agréer, Madame, Monsieur, l’expression de mes salutations distinguées.

[Signature]

Pièces jointes : [liste, ou supprimez cette ligne]''';

/// Copie stricte : un élément non textuel est rejeté dès le décodage.
List<String> stringList(Object? value) {
  if (value == null) return [];
  if (value is! List || value.any((e) => e is! String)) {
    throw const FormatException('Liste de textes invalide');
  }
  return List<String>.from(value);
}

class Letter {
  Letter({
    required this.id,
    this.title = 'Nouveau courrier',
    this.text = '',
    this.category = 'Vie quotidienne',
    this.alignment = 'left',
    this.favorite = false,
    this.done = false,
    this.deleted = false,
    List<String>? versions,
    DateTime? updated,
  }) : versions = versions ?? [],
       updated = updated ?? DateTime.now();
  final String id;
  String title, text, category, alignment;
  bool favorite, done, deleted;
  List<String> versions;
  DateTime updated;
  void revise(String next) {
    if (next == text) return;
    if (text.isNotEmpty && (versions.isEmpty || versions.last != text)) {
      versions.add(text);
    }
    if (versions.length > 100) versions.removeAt(0);
    text = next;
    updated = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'text': text,
    'category': category,
    'alignment': alignment,
    'favorite': favorite,
    'done': done,
    'deleted': deleted,
    'versions': versions,
    'updated': updated.toIso8601String(),
  };
  factory Letter.fromJson(Map<String, dynamic> j) {
    if (j['id'] is! String || j['text'] is! String || j['title'] is! String) {
      throw const FormatException('Document invalide');
    }
    return Letter(
      id: j['id'],
      title: j['title'],
      text: j['text'],
      category: j['category'] is String
          ? j['category'] as String
          : 'Vie quotidienne',
      alignment: ['left', 'center', 'right', 'justify'].contains(j['alignment'])
          ? j['alignment'] as String
          : 'left',
      favorite: j['favorite'] == true,
      done: j['done'] == true,
      deleted: j['deleted'] == true,
      versions: stringList(j['versions']),
      updated: DateTime.tryParse(
        j['updated'] is String ? j['updated'] as String : '',
      ),
    );
  }
}

class AppData {
  AppData({
    List<Letter>? letters,
    Map<String, dynamic>? settings,
    List<String>? searches,
  }) : letters = letters ?? [],
       settings = settings ?? {},
       searches = searches ?? [];
  List<Letter> letters;
  Map<String, dynamic> settings;
  List<String> searches;
  String encode() => jsonEncode({
    'format': 'la-bafouille',
    'version': 1,
    'letters': letters.map((e) => e.toJson()).toList(),
    'settings': {
      for (final k in ['dark', 'provider', 'model', 'ollama', 'welcomed'])
        if (settings.containsKey(k)) k: settings[k],
    },
    'searches': searches,
  });
  factory AppData.decode(String source) {
    final j = jsonDecode(source);
    if (j is! Map ||
        j['format'] != 'la-bafouille' ||
        j['version'] != 1 ||
        j['letters'] is! List) {
      throw const FormatException('Sauvegarde La Bafouille non reconnue');
    }
    final letters = (j['letters'] as List)
        .map(
          (e) => e is Map
              ? Letter.fromJson(Map<String, dynamic>.from(e))
              : throw const FormatException('Document invalide'),
        )
        .toList();
    if (letters.map((e) => e.id).toSet().length != letters.length) {
      throw const FormatException('Identifiants de documents en double');
    }
    if (j['settings'] != null && j['settings'] is! Map) {
      throw const FormatException('Paramètres invalides');
    }
    final settings = Map<String, dynamic>.from(j['settings'] as Map? ?? {});
    for (final key in ['dark', 'welcomed']) {
      if (settings[key] != null && settings[key] is! bool) {
        throw const FormatException('Paramètres invalides');
      }
    }
    for (final key in ['provider', 'model', 'ollama']) {
      if (settings[key] != null && settings[key] is! String) {
        throw const FormatException('Paramètres invalides');
      }
    }
    settings.removeWhere(
      (k, _) =>
          !['dark', 'provider', 'model', 'ollama', 'welcomed'].contains(k),
    );
    return AppData(
      letters: letters,
      settings: settings,
      searches: stringList(j['searches']),
    );
  }
}
