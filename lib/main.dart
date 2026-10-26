import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'core/state.dart';
import 'core/storage.dart';
import 'features/home.dart';
import 'features/library.dart';
import 'features/editor.dart';
import 'features/assistant.dart';
import 'features/language.dart';
import 'features/settings.dart';
import 'features/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final dir = await getApplicationSupportDirectory();
    final store = LocalStore(Directory('${dir.path}/atelier'));
    final atelier = Atelier(store, await store.read());
    runApp(
      ProviderScope(
        overrides: [atelierProvider.overrideWith((ref) => atelier)],
        child: const BafouilleApp(),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber, size: 64),
                  const Text(
                    'Impossible d’ouvrir la bibliothèque. Les fichiers sont conservés. Vérifiez les permissions ou restaurez bibliotheque.precedente.json en suivant INSTALLATION.md.',
                  ),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: main, child: const Text('Réessayer')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AtelierShell(path: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomePage()),
        GoRoute(
          path: '/library',
          builder: (_, state) => LibraryPage(
            initialFilter: state.uri.queryParameters['filter'] ?? 'Tous',
          ),
        ),
        GoRoute(path: '/templates', builder: (_, _) => const TemplatesPage()),
        GoRoute(
          path: '/editor/:id',
          builder: (_, state) => EditorPage(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/assistant',
          builder: (_, state) => AssistantPage(
            mode: state.uri.queryParameters['mode'] ?? 'chat',
            documentId: state.uri.queryParameters['doc'],
            initialPrompt: state.uri.queryParameters['prompt'] ?? '',
          ),
        ),
        GoRoute(path: '/correction', builder: (_, _) => const CorrectionPage()),
        GoRoute(path: '/dictionary', builder: (_, _) => const DictionaryPage()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
        GoRoute(path: '/help', builder: (_, _) => const HelpPage()),
      ],
    ),
  ],
);

class BafouilleApp extends ConsumerWidget {
  const BafouilleApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(atelierProvider).data.settings['dark'] == true;
    ThemeData theme(Brightness b) => ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff482878),
        brightness: b,
        secondary: const Color(0xff25c4c0),
      ),
      scaffoldBackgroundColor: b == Brightness.light
          ? const Color(0xfffff7e8)
          : const Color(0xff191925),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
    return MaterialApp.router(
      title: 'La Bafouille',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}

class AtelierShell extends ConsumerWidget {
  const AtelierShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;
  static const destinations = [
    ('/', Icons.dashboard_outlined, 'L’atelier'),
    ('/library', Icons.folder_outlined, 'Courriers'),
    ('/templates', Icons.auto_stories_outlined, 'Modèles'),
    ('/correction', Icons.spellcheck, 'Labo des mots'),
    ('/assistant', Icons.forum_outlined, 'Bafou'),
    ('/settings', Icons.tune, 'Paramètres'),
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = destinations.indexWhere((e) => e.$1 == path);
    final error = ref.watch(atelierProvider).error;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'LA BAFOUILLE',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            actions: [
              IconButton(
                tooltip: 'Guide d’utilisation',
                onPressed: () => context.go('/help'),
                icon: const Icon(Icons.help_outline),
              ),
            ],
          ),
          drawer: wide
              ? null
              : Drawer(
                  child: SafeArea(
                    child: ListView(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Votre atelier d’écriture',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                        for (final d in destinations)
                          ListTile(
                            leading: Icon(d.$2),
                            title: Text(d.$3),
                            selected: path == d.$1,
                            onTap: () {
                              Navigator.pop(context);
                              context.go(d.$1);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
          body: Column(
            children: [
              if (error != null)
                MaterialBanner(
                  content: Text(error),
                  actions: [
                    TextButton(
                      onPressed: () => guarded(
                        context,
                        () => ref.read(atelierProvider).persist(),
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              Expanded(
                child: Row(
                  children: [
                    if (wide)
                      NavigationRail(
                        extended: true,
                        selectedIndex: index < 0 ? 0 : index,
                        onDestinationSelected: (i) =>
                            context.go(destinations[i].$1),
                        leading: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Bafou(size: 70),
                        ),
                        destinations: [
                          for (final d in destinations)
                            NavigationRailDestination(
                              icon: Icon(d.$2),
                              label: Text(d.$3),
                            ),
                        ],
                      ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
