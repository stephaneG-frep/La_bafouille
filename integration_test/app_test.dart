import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:la_bafouille/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Démarrage natif et ouverture de la bibliothèque', (
    tester,
  ) async {
    await app.main();
    await tester.pump(const Duration(seconds: 2));
    if (find.text('Entrer dans l’atelier').evaluate().isNotEmpty) {
      await tester.tap(find.text('Entrer dans l’atelier'));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('LA BAFOUILLE'), findsOneWidget);
    app.router.go('/library');
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Mes correspondances'), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
