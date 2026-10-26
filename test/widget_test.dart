import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_bafouille/main.dart';
import 'package:la_bafouille/core/models.dart';
import 'package:la_bafouille/core/state.dart';
import 'package:la_bafouille/core/storage.dart';

void main() {
  for (final size in [const Size(412, 915), const Size(1440, 1000)]) {
    testWidgets('Démarrage hors connexion et navigation ${size.width}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dir = Directory(
        '${Directory.systemTemp.path}/bafouille_widget_${size.width}',
      );
      final a = Atelier(LocalStore(dir), AppData(settings: {'welcomed': true}));
      router.go('/');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [atelierProvider.overrideWith((ref) => a)],
          child: const BafouilleApp(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('LA BAFOUILLE'), findsOneWidget);
      expect(find.text('Tu racontes,\nLa Bafouille rédige !'), findsOneWidget);
      expect(tester.takeException(), isNull);
      router.go('/correction');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Le labo des mots'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'Je vous est envoyé les documents.',
      );
      await tester.tap(find.text('Analyser localement'));
      await tester.pump();
      expect(find.textContaining('Je vous est → Je vous ai'), findsOneWidget);
      expect(tester.takeException(), isNull);
      router.go('/settings');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Les réglages de l’atelier'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
