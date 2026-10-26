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

void main() {
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
