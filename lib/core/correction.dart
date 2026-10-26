class Correction {
  const Correction(
    this.start,
    this.end,
    this.original,
    this.replacement,
    this.rule,
  );
  final int start, end;
  final String original, replacement, rule;
}

class LocalCorrector {
  static final rules = <(RegExp, String, String)>[
    (
      RegExp(r'\bje vous est\b', caseSensitive: false),
      'je vous ai',
      'Au passé composé, « je » demande l’auxiliaire avoir : j’ai. Exemple : je vous ai écrit.',
    ),
    (
      RegExp(r'\bmalgrés\b', caseSensitive: false),
      'malgré',
      'La préposition « malgré » est invariable et ne prend pas de s.',
    ),
    (
      RegExp(r'\bparmis\b', caseSensitive: false),
      'parmi',
      '« Parmi » s’écrit sans s final.',
    ),
    (
      RegExp(r'\bsa va\b', caseSensitive: false),
      'ça va',
      '« Ça » signifie « cela ». « Sa » indique la possession : sa lettre.',
    ),
    (
      RegExp(r'\bje peut\b', caseSensitive: false),
      'je peux',
      'Pouvoir au présent : je peux, tu peux, il peut.',
    ),
    (
      RegExp(r'\bje suis aller\b', caseSensitive: false),
      'je suis allé',
      'Le participe passé est « allé » ; ajouter un e si le sujet est féminin.',
    ),
    (
      RegExp(
        r'\b(?:au jour d’aujourd’hui|au jour d\x27aujourd\x27hui)\b',
        caseSensitive: false,
      ),
      'aujourd’hui',
      'Cette expression est redondante : « aujourd’hui » suffit.',
    ),
  ];
  static List<Correction> inspect(String text) {
    final result = <Correction>[];
    for (final (pattern, replacement, rule) in rules) {
      for (final match in pattern.allMatches(text)) {
        final original = match.group(0)!;
        final adjusted = original[0] == original[0].toUpperCase()
            ? replacement[0].toUpperCase() + replacement.substring(1)
            : replacement;
        result.add(
          Correction(match.start, match.end, original, adjusted, rule),
        );
      }
    }
    result.sort((a, b) => a.start.compareTo(b.start));
    return result;
  }

  static String apply(String text, Iterable<Correction> accepted) {
    final sorted = accepted.toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    var end = text.length;
    for (final c in sorted) {
      if (c.end > end || text.substring(c.start, c.end) != c.original) {
        throw const FormatException(
          'Le texte original a changé. Relancez la correction.',
        );
      }
      text = text.replaceRange(c.start, c.end, c.replacement);
      end = c.start;
    }
    return text;
  }
}
