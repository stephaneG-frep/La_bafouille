class Correction {
  const Correction(
    this.start,
    this.end,
    this.original,
    this.replacement,
    this.rule, [
    this.detail = '',
  ]);
  final int start, end;
  final String original, replacement, rule, detail;
}

/// Règle locale : motif, remplacement (`$1` reprend un groupe capturé),
/// explication simple, explication détaillée avec exemple.
typedef Rule = (RegExp, String, String, String);

const _letter = r'A-Za-zÀ-ÖØ-öø-ÿŒœ';
const _apos = r'[’\x27]';

RegExp _word(String pattern) =>
    RegExp('(?<![$_letter])$pattern(?![$_letter])', caseSensitive: false);

class LocalCorrector {
  static final rules = <Rule>[
    // Conjugaison
    (
      _word('je vous est'),
      'je vous ai',
      'Au passé composé, « je » demande l’auxiliaire avoir : j’ai. Exemple : je vous ai écrit.',
      'Le passé composé se forme avec l’auxiliaire avoir ou être conjugué au présent, suivi du participe passé. Avec « je », avoir donne « j’ai » (jamais « est », qui correspond à « il » ou « elle »). Astuce : remplacez par l’imparfait ; « je vous avais envoyé » sonne juste, donc il faut « ai ».',
    ),
    (
      _word('je peut'),
      'je peux',
      'Pouvoir au présent : je peux, tu peux, il peut.',
      'Aux deux premières personnes du singulier, pouvoir, vouloir et valoir se terminent par -x : je peux, tu veux, je vaux. Le -t n’apparaît qu’à la troisième personne : il peut.',
    ),
    (
      _word('je suis aller'),
      'je suis allé',
      'Le participe passé est « allé » ; ajouter un e si le sujet est féminin.',
      'Après l’auxiliaire être, on emploie le participe passé (allé), pas l’infinitif (aller). Astuce : remplacez par un verbe du 3e groupe ; « je suis venu » et non « je suis venir ». Le participe s’accorde avec le sujet : je suis allée, nous sommes allés.',
    ),
    (
      _word('(il|elle|on) à'),
      r'$1 a',
      '« a » sans accent est le verbe avoir : il a, elle a, on a.',
      'Après un pronom sujet, il faut un verbe : « a » (avoir). « À » avec accent est une préposition (écrire à quelqu’un). Astuce : si l’on peut dire « avait », on écrit « a ». Exemple : elle a reçu (elle avait reçu).',
    ),
    (
      _word('si j${_apos}aurais'),
      'si j’avais',
      'Après « si » de condition, on n’emploie pas le conditionnel.',
      'Dans une hypothèse, « si » est suivi de l’imparfait, et le conditionnel va dans l’autre partie de la phrase : « Si j’avais su, je serais venu. » La forme « si j’aurais » est fautive.',
    ),
    (
      _word(
        '(me|te|se|nous|vous) (rappelle|rappelles|rappelons|rappelez|rappellent|rappeler) de (ce|cet|cette|ces|la|le|les|mon|ma|mes|ton|ta|tes|son|sa|ses|notre|nos|votre|vos|leur|leurs)',
      ),
      r'$1 $2 $3',
      'On se rappelle quelque chose, sans « de ».',
      '« Se rappeler » est transitif direct : je me rappelle cette date, je me la rappelle. On dit en revanche « se souvenir de » : je me souviens de cette date. « De » reste admis devant un infinitif (je me rappelle d’avoir écrit) et devant un pronom de personne (je me rappelle de vous).',
    ),
    (
      _word('pallier à'),
      'pallier',
      '« Pallier » se construit sans « à » : pallier un manque.',
      '« Pallier » signifie atténuer, compenser provisoirement. Il est transitif direct : on pallie une difficulté. La construction « pallier à » vient de « remédier à », mais reste considérée comme fautive dans un courrier soigné.',
    ),
    // Orthographe et homophones
    (
      _word('malgrés'),
      'malgré',
      'La préposition « malgré » est invariable et ne prend pas de s.',
      'Les prépositions (malgré, parmi, selon, pendant) ne s’accordent jamais. Exemple : malgré les retards, malgré tout.',
    ),
    (
      _word('parmis'),
      'parmi',
      '« Parmi » s’écrit sans s final.',
      '« Parmi » est une préposition invariable : parmi les pièces jointes. Le s vient sans doute de l’analogie avec « jamais » ou « depuis ».',
    ),
    (
      _word('sa va'),
      'ça va',
      '« Ça » signifie « cela ». « Sa » indique la possession : sa lettre.',
      'Astuce : si l’on peut remplacer par « cela », on écrit « ça ». Si l’on peut remplacer par « son » ou « ses », on écrit « sa » : sa lettre (son courrier).',
    ),
    (
      _word('quelque soit (la|une|cette|ma|ta|sa|notre|votre|leur)'),
      r'quelle que soit $1',
      'Devant « être », on écrit « quel que » en deux mots, accordé : quelle que soit la date.',
      '« Quel » s’accorde avec le sujet du verbe être : quel que soit le motif, quelle que soit la date, quels que soient les frais, quelles que soient les conditions.',
    ),
    (
      _word('quelque soit'),
      'quel que soit',
      'Devant « être », on écrit « quel que » en deux mots, accordé.',
      '« Quel » s’accorde avec le sujet du verbe être : quel que soit le motif, quelle que soit la date, quels que soient les frais, quelles que soient les conditions.',
    ),
    (
      _word('comme même'),
      'quand même',
      'L’expression correcte est « quand même ».',
      '« Quand même » signifie malgré tout. « Comme même » est une déformation orale. Dans un courrier soigné, préférez « pourtant » ou « néanmoins ».',
    ),
    (
      _word('voir même'),
      'voire',
      '« Voire » (et même) s’écrit avec un e, et se suffit à lui-même.',
      '« Voire » signifie « et même » : un retard de plusieurs jours, voire de plusieurs semaines. « Voir » est le verbe. « Voire même » est un pléonasme, toléré à l’oral mais à éviter à l’écrit.',
    ),
    // Style
    (
      RegExp('au jour d${_apos}aujourd${_apos}hui', caseSensitive: false),
      'aujourd’hui',
      'Cette expression est redondante : « aujourd’hui » suffit.',
      '« Aujourd’hui » contient déjà « hui », ancien mot pour « ce jour ». « Au jour d’aujourd’hui » répète donc trois fois la même idée. Préférez « aujourd’hui » ou « actuellement ».',
    ),
    (
      _word('malgré que'),
      'bien que',
      'Dans un registre soigné, préférez « bien que ».',
      '« Malgré que » est critiqué par l’usage soutenu, sauf dans « malgré que j’en aie ». « Bien que » et « quoique » sont suivis du subjonctif : bien que la facture soit réglée.',
    ),
    // Répétitions
    (
      RegExp(
        '(?<![$_letter])(?!nous[^$_letter]|vous[^$_letter])([$_letter]+)\\s+\\1(?![$_letter])',
        caseSensitive: false,
      ),
      r'$1',
      'Mot répété deux fois de suite.',
      'Une répétition immédiate est souvent une faute de frappe (« le le », « de de »). Exception : les verbes pronominaux, où « nous nous » et « vous vous » sont corrects (nous nous sommes rencontrés).',
    ),
    // Ponctuation
    (
      RegExp(' {2,}'),
      ' ',
      'Espaces multiples remplacées par une seule.',
      'En typographie, une seule espace sépare les mots. Pour aligner des éléments, utilisez la mise en page plutôt que des espaces répétées.',
    ),
    (
      RegExp('(?<=[${_letter}0-9])([!?;])(?=[$_letter])'),
      '\u00a0\$1 ',
      'Il manque une espace avant et après ce signe.',
      'Les signes doubles (! ? ;) sont précédés d’une espace insécable et suivis d’une espace : « Merci ! Je reste disponible. »',
    ),
    (
      RegExp('(?<=[ \u00a0])([!?;])(?=[$_letter])'),
      '\$1 ',
      'Il manque une espace après ce signe.',
      'Après ! ? ou ;, on met une espace avant le mot suivant.',
    ),
    (
      RegExp('(?<=[${_letter}0-9])([!?;])'),
      ' \$1',
      'Il manque une espace avant ! ? ou ;.',
      'Les signes doubles (! ? ; :) sont précédés d’une espace en français, idéalement insécable pour qu’ils ne passent pas seuls à la ligne. Exemple : « Merci ! », « Pourquoi ? ». La virgule et le point n’en prennent pas.',
    ),
    (
      RegExp('(?<=[$_letter]):(?=\\s)'),
      ' :',
      'Il manque une espace avant les deux-points.',
      'Les deux-points sont précédés d’une espace insécable et suivis d’une espace : « Objet : réclamation ».',
    ),
    (
      RegExp(' +(?=[,.](?!\\.))'),
      '',
      'Pas d’espace avant une virgule ou un point.',
      'La virgule et le point se collent au mot qui précède et sont suivis d’une espace : « Madame, Monsieur, ».',
    ),
    (
      RegExp(',(?=[$_letter])'),
      ', ',
      'Une espace suit toujours la virgule.',
      'Après une virgule, on met une espace avant le mot suivant. Exception : les nombres décimaux (3,5 €).',
    ),
  ];

  static List<Correction> inspect(String text) {
    final found = <(int, Correction)>[];
    for (final (index, (pattern, replacement, rule, detail)) in rules.indexed) {
      for (final match in pattern.allMatches(text)) {
        final original = match.group(0)!;
        var adjusted = replacement.replaceAllMapped(
          RegExp(r'\$(\d)'),
          (m) => match.group(int.parse(m.group(1)!)) ?? '',
        );
        if (adjusted.isNotEmpty &&
            original[0] != original[0].toLowerCase() &&
            original[0] == original[0].toUpperCase()) {
          adjusted = adjusted[0].toUpperCase() + adjusted.substring(1);
        }
        if (adjusted == original) continue;
        found.add((
          index,
          Correction(match.start, match.end, original, adjusted, rule, detail),
        ));
      }
    }
    // À position égale, la correction la plus longue puis la règle la plus
    // spécifique (déclarée en premier) l'emporte.
    found.sort(
      (a, b) => a.$2.start != b.$2.start
          ? a.$2.start.compareTo(b.$2.start)
          : a.$2.end != b.$2.end
          ? b.$2.end.compareTo(a.$2.end)
          : a.$1.compareTo(b.$1),
    );
    // Une seule correction par passage : elles restent applicables ensemble.
    final result = <Correction>[];
    for (final (_, c) in found) {
      if (result.isEmpty || c.start >= result.last.end) result.add(c);
    }
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
