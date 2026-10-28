import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:la_bafouille/core/ai.dart';
import 'package:la_bafouille/core/correction.dart';
import 'package:la_bafouille/core/exports.dart';
import 'package:la_bafouille/core/models.dart';
import 'package:la_bafouille/core/state.dart';
import 'package:la_bafouille/core/storage.dart';
import 'package:la_bafouille/core/version.dart';
import 'package:la_bafouille/features/language.dart';

void main() {
  test('La version affichée correspond à pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('version: $appVersion+'));
  });
  test(
    'Création, sauvegarde atomique, réouverture, versions et restauration sans écrasement',
    () async {
      final dir = await Directory.systemTemp.createTemp('bafouille_test_');
      addTearDown(() => dir.delete(recursive: true));
      final store = LocalStore(dir);
      final a = Atelier(store, await store.read());
      final l = await a.create(title: 'Essai', text: 'Original');
      l.revise('Modifié');
      await a.persist();
      final read = await store.read();
      expect(read.letters.single.text, 'Modifié');
      expect(read.letters.single.versions, ['Original']);
      expect(await store.backup.exists(), true);
      final backup = a.data.encode();
      await a.restore(backup);
      expect(a.data.letters.length, 2);
      expect(a.data.letters.map((e) => e.id).toSet().length, 2);
      a.data.letters.first.deleted = true;
      await a.persist();
      expect((await store.read()).letters.first.deleted, true);
      a.data.letters.first.deleted = false;
      await a.persist();
      expect((await store.read()).letters.first.deleted, false);
    },
  );
  test('Sauvegardes sans secrets et rejet des formats invalides', () {
    final a = AppData(
      settings: {
        'key': 'SECRET',
        'token': 'SECRET',
        'model': 'local',
        'dark': true,
      },
    );
    expect(a.encode(), isNot(contains('SECRET')));
    expect(() => AppData.decode('{}'), throwsFormatException);
    expect(
      () => AppData.decode(
        '{"format":"la-bafouille","version":1,"letters":[],"settings":{"dark":"oui"}}',
      ),
      throwsFormatException,
    );
  });
  test(
    'Une sauvegarde malformée est rejetée sans bloquer la bibliothèque',
    () async {
      final dir = await Directory.systemTemp.createTemp('bafouille_malforme_');
      addTearDown(() => dir.delete(recursive: true));
      final a = Atelier(LocalStore(dir), AppData());
      await a.create(title: 'A', text: 'x');
      for (final bad in [
        '{"format":"la-bafouille","version":1,"letters":[{"id":"1","title":"t","text":"y","versions":[1]}]}',
        '{"format":"la-bafouille","version":1,"letters":[],"searches":[true]}',
        '{"format":"la-bafouille","version":1,"letters":[42]}',
        '{"format":"la-bafouille","version":1,"letters":[],"settings":[]}',
      ]) {
        await expectLater(a.restore(bad), throwsFormatException);
      }
      expect(a.data.letters.length, 1);
      await a.persist();
    },
  );
  test('La restauration n’importe pas l’adresse du serveur Ollama', () async {
    final dir = await Directory.systemTemp.createTemp('bafouille_ollama_');
    addTearDown(() => dir.delete(recursive: true));
    final a = Atelier(
      LocalStore(dir),
      AppData(settings: {'ollama': 'http://localhost:11434'}),
    );
    await a.restore(
      '{"format":"la-bafouille","version":1,"letters":[],"settings":{"ollama":"https://exemple.invalid","dark":true}}',
    );
    expect(a.data.settings['ollama'], 'http://localhost:11434');
    expect(a.data.settings['dark'], true);
  });
  test('Suppression définitive, y compris dans la copie de secours', () async {
    final dir = await Directory.systemTemp.createTemp('bafouille_purge_');
    addTearDown(() => dir.delete(recursive: true));
    final store = LocalStore(dir);
    final a = Atelier(store, AppData());
    final gone = await a.create(title: 'Secret', text: 'Confidentiel');
    final kept = await a.create(title: 'Garde', text: 'Public');
    gone.deleted = true;
    await a.persist();
    await a.purge([gone.id]);
    expect(a.byId(gone.id), isNull);
    expect(a.byId(kept.id), isNotNull);
    expect(await store.file.readAsString(), isNot(contains('Confidentiel')));
    expect(await store.backup.readAsString(), isNot(contains('Confidentiel')));
  });
  test('Les écritures concurrentes sont sérialisées', () async {
    final dir = await Directory.systemTemp.createTemp('bafouille_queue_');
    addTearDown(() => dir.delete(recursive: true));
    final store = LocalStore(dir);
    final data = AppData();
    final writes = <Future<void>>[];
    for (var i = 0; i < 12; i++) {
      data.letters.add(Letter(id: '$i'));
      writes.add(store.save(data));
    }
    await Future.wait(writes);
    expect((await store.read()).letters.length, 12);
  });
  test('Une bibliothèque corrompue est conservée', () async {
    final dir = await Directory.systemTemp.createTemp('bafouille_corrupt_');
    addTearDown(() => dir.delete(recursive: true));
    final store = LocalStore(dir);
    await store.file.writeAsString('corrompu');
    await expectLater(store.read(), throwsFormatException);
    await expectLater(store.save(AppData()), throwsFormatException);
    expect(await store.file.readAsString(), 'corrompu');
  });
  test(
    'Corrections indépendantes, acceptation, refus et original conservé',
    () {
      const original = 'Je vous est envoyé les documents, malgrés le retard.';
      final c = LocalCorrector.inspect(original);
      expect(c.length, 2);
      expect(LocalCorrector.apply(original, []), original);
      expect(
        LocalCorrector.apply(original, [c.first]),
        'Je vous ai envoyé les documents, malgrés le retard.',
      );
      expect(
        LocalCorrector.apply(original, c),
        'Je vous ai envoyé les documents, malgré le retard.',
      );
      expect(original, contains('est'));
    },
  );
  test('Correcteur enrichi : homophones, ponctuation, répétitions', () {
    String fix(String t) =>
        LocalCorrector.apply(t, LocalCorrector.inspect(t)).replaceAll(' ', ' ');
    expect(
      fix('Il à reçu le le dossier,merci!'),
      'Il a reçu le dossier, merci !',
    );
    expect(
      fix('Quelque soit la date , voir même demain.'),
      'Quelle que soit la date, voire demain.',
    );
    expect(fix('Je me rappelle de cette date.'), 'Je me rappelle cette date.');
    // Usages corrects laissés intacts.
    for (final ok in [
      'Nous nous sommes vus. Je me rappelle de vous.',
      'Merci ! Pourquoi ? Objet : relance, 3,5 € et http://exemple.fr ...',
    ]) {
      expect(LocalCorrector.inspect(ok), isEmpty, reason: ok);
    }
    // Les corrections ne se chevauchent jamais et ont une explication détaillée.
    final c = LocalCorrector.inspect('Si j’aurais su,il à pallier à tout  !');
    for (var i = 1; i < c.length; i++) {
      expect(c[i].start, greaterThanOrEqualTo(c[i - 1].end));
    }
    expect(c.every((e) => e.detail.isNotEmpty), true);
  });
  test('Le nouveau courrier suit la structure d’une lettre française', () {
    for (final part in [
      '], le [date]',
      'Objet :',
      'Madame, Monsieur,',
      '[Signature]',
      'Pièces jointes',
    ]) {
      expect(letterSkeleton, contains(part));
    }
  });
  test('Mémento : fiches valides et questions du cahier des charges', () async {
    final data =
        jsonDecode(File('assets/lexique.json').readAsStringSync()) as List;
    final all = [
      for (final e in data)
        Entry(
          e['mot'] as String,
          e['rubrique'] as String,
          e['texte'] as String,
        ),
    ];
    expect(all.length, greaterThanOrEqualTo(80));
    expect(all.map((e) => e.word).toSet().length, all.length);
    expect(all.every((e) => sections.contains(e.section)), true);
    for (final s in sections) {
      expect(all.where((e) => e.section == s), isNotEmpty, reason: s);
    }
    String top(String q) => searchLexicon(all, q, null).first.word;
    expect(top('Trouve un mot plus élégant que problème.'), 'problème');
    expect(top('Comment conjuguer acquérir au subjonctif ?'), 'acquérir');
    expect(
      top('Quelle formule utiliser pour terminer une lettre au préfet ?'),
      'préfet, maire et autorités',
    );
    expect(top('quel que'), 'quel que / quelque');
    expect(fold('Cœur À ÉTÉ'), 'coeur a ete');
    expect(
      searchLexicon(all, '', 'Homophones').length,
      all.where((e) => e.section == 'Homophones').length,
    );
  });
  test('PDF, DOCX et HTML valides sans injection', () async {
    final l = Letter(
      id: '1',
      title: 'Lettre',
      text: 'Bonjour & <script>\nTexte français.',
    );
    final pdf = await Exports.pdf(l);
    expect(ascii.decode(pdf.take(5).toList()), '%PDF-');
    final zip = ZipDecoder().decodeBytes(Exports.docx(l));
    expect(zip.findFile('[Content_Types].xml'), isNotNull);
    final xml = utf8.decode(zip.findFile('word/document.xml')!.content);
    expect(xml, contains('&lt;script&gt;'));
    expect(xml, contains('Texte français.'));
    expect(Exports.html(l), isNot(contains('<script>')));
  });
  test('54 modèles distincts avec champs et neuf catégories', () {
    final list =
        jsonDecode(File('assets/templates.json').readAsStringSync()) as List;
    expect(list.length, 54);
    expect(list.map((e) => e['category']).toSet().length, 9);
    expect(list.map((e) => e['title']).toSet().length, 54);
    for (final t in list) {
      expect(t['text'], contains('[Signature]'));
      expect((t['text'] as String).length, greaterThan(450));
    }
  });
  for (final p in providers) {
    test('Adaptateur $p : requête et réponse', () async {
      final client = MockClient((r) async {
        final body = jsonDecode(r.body);
        expect(body.toString(), contains('Bonjour'));
        if (p == 'Anthropic') expect(r.headers['x-api-key'], 'cle-test');
        if (p == 'Gemini') expect(r.headers['x-goog-api-key'], 'cle-test');
        if (p == 'OpenAI' || p == 'Mistral') {
          expect(r.headers['authorization'], 'Bearer cle-test');
          expect(
            r.url.host,
            p == 'OpenAI' ? 'api.openai.com' : 'api.mistral.ai',
          );
        }
        if (p == 'Grok' || p == 'Perplexity') {
          expect(r.headers['authorization']?.startsWith('Bearer '), true);
          expect(r.url.host, p == 'Grok' ? 'api.x.ai' : 'api.perplexity.ai');
          expect(
            r.url.path,
            p == 'Grok' ? '/v1/chat/completions' : '/chat/completions',
          );
        }
        return http.Response(
          jsonEncode(switch (p) {
            'Anthropic' => {
              'content': [
                {'type': 'text', 'text': 'Réponse'},
              ],
            },
            'Gemini' => {
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Réponse'},
                    ],
                  },
                },
              ],
            },
            'Ollama' => {
              'message': {'content': 'Réponse'},
            },
            _ => {
              'choices': [
                {
                  'message': {'content': 'Réponse'},
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final ai = AiService(client: client);
      addTearDown(ai.dispose);
      expect(
        await ai.generate(
          AiConfig(provider: p, model: 'modele-test', key: 'cle-test'),
          'Bonjour',
        ),
        'Réponse',
      );
    });
  }
  test('Sans clé, aucune requête distante', () async {
    var called = false;
    final ai = AiService(
      client: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(ai.dispose);
    await expectLater(
      ai.generate(const AiConfig(provider: 'OpenAI', model: 'test'), 'bonjour'),
      throwsA(isA<AiFailure>()),
    );
    expect(called, false);
  });
  for (final status in [401, 403, 404, 429, 500]) {
    test('Erreur API $status sans fuite du corps', () async {
      final ai = AiService(
        client: MockClient((_) async => http.Response('SECRET', status)),
      );
      addTearDown(ai.dispose);
      try {
        await ai.generate(
          const AiConfig(provider: 'Ollama', model: 'test'),
          'bonjour',
        );
        fail('Erreur attendue');
      } on AiFailure catch (e) {
        expect(e.message, isNot(contains('SECRET')));
      }
    });
  }
  test('Réponse malformée et modèle absent gérés', () async {
    final ai = AiService(
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    addTearDown(ai.dispose);
    await expectLater(
      ai.generate(const AiConfig(provider: 'Ollama', model: 'test'), 'bonjour'),
      throwsA(isA<AiFailure>()),
    );
    await expectLater(
      ai.generate(const AiConfig(provider: 'Ollama', model: ''), 'bonjour'),
      throwsA(isA<AiFailure>()),
    );
  });
}
