import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/state.dart';
import 'common.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key, this.initialFilter = 'Tous'});
  final String initialFilter;
  @override
  ConsumerState<LibraryPage> createState() => _LibraryState();
}

class _LibraryState extends ConsumerState<LibraryPage> {
  String query = '';
  late String filter = widget.initialFilter;
  @override
  void didUpdateWidget(covariant LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      filter = widget.initialFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(atelierProvider);
    final letters =
        a.data.letters
            .where(
              (l) =>
                  (filter == 'Corbeille' ? l.deleted : !l.deleted) &&
                  (filter != 'Favoris' || l.favorite) &&
                  (filter != 'Brouillons' || !l.done) &&
                  (filter != 'Terminés' || l.done) &&
                  '${l.title} ${l.text} ${l.category}'.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList()
          ..sort((a, b) => b.updated.compareTo(a.updated));
    return PageBody(
      title: 'Mes correspondances',
      subtitle: 'Vos textes, leurs versions, et le plaisir de les retrouver.',
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Rechercher un titre, un texte ou une catégorie',
          ),
          onChanged: (s) => setState(() => query = s),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final f in [
              'Tous',
              'Brouillons',
              'Terminés',
              'Favoris',
              'Corbeille',
            ])
              ChoiceChip(
                label: Text(f),
                selected: filter == f,
                onSelected: (_) => setState(() => filter = f),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (letters.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Aucun courrier ici pour le moment. Créez votre première bafouille depuis l’accueil.',
            ),
          ),
        for (final l in letters)
          Card(
            child: ListTile(
              isThreeLine: true,
              leading: Icon(l.done ? Icons.mark_email_read : Icons.drafts),
              title: Text(l.title),
              subtitle: Text(
                '${l.category} • ${l.done ? 'Terminé' : 'Brouillon'}\n${l.text.replaceAll('\n', ' ')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: l.deleted ? null : () => context.go('/editor/${l.id}'),
              trailing: PopupMenuButton<String>(
                tooltip: 'Actions du courrier',
                onSelected: (v) => guarded(context, () async {
                  switch (v) {
                    case 'favorite':
                      l.favorite = !l.favorite;
                    case 'delete':
                      l.deleted = true;
                    case 'restore':
                      l.deleted = false;
                    case 'duplicate':
                      await a.create(
                        title: '${l.title} — copie',
                        text: l.text,
                        category: l.category,
                      );
                      return;
                  }
                  await a.persist();
                }),
                itemBuilder: (_) => [
                  if (!l.deleted) ...[
                    PopupMenuItem(
                      value: 'favorite',
                      child: Text(
                        l.favorite
                            ? 'Retirer des favoris'
                            : 'Ajouter aux favoris',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Text('Dupliquer'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Mettre à la corbeille'),
                    ),
                  ] else
                    const PopupMenuItem(
                      value: 'restore',
                      child: Text('Restaurer'),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class TemplatesPage extends ConsumerStatefulWidget {
  const TemplatesPage({super.key});
  @override
  ConsumerState<TemplatesPage> createState() => _TemplatesState();
}

class _TemplatesState extends ConsumerState<TemplatesPage> {
  late final Future<List<dynamic>> templates = rootBundle
      .loadString('assets/templates.json')
      .then((s) => jsonDecode(s) as List);
  String query = '';
  @override
  Widget build(BuildContext context) => PageBody(
    title: 'La bibliothèque des départs',
    subtitle:
        '54 modèles personnalisables. Remplacez les champs entre crochets avant l’envoi.',
    children: [
      TextField(
        decoration: const InputDecoration(
          labelText: 'Chercher un modèle ou une catégorie',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (s) => setState(() => query = s),
      ),
      const SizedBox(height: 20),
      FutureBuilder<List<dynamic>>(
        future: templates,
        builder: (context, s) {
          if (s.hasError) {
            return const Text('Impossible de charger les modèles.');
          }
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              for (final t in s.data!.where(
                (t) => '${t['title']} ${t['category']}'.toLowerCase().contains(
                  query.toLowerCase(),
                ),
              ))
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(t['title']),
                    subtitle: Text(t['category']),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => guarded(context, () async {
                      final l = await ref
                          .read(atelierProvider)
                          .create(
                            title: t['title'],
                            text: t['text'],
                            category: t['category'],
                          );
                      if (context.mounted) context.go('/editor/${l.id}');
                    }),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
