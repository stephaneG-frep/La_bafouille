import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/state.dart';
import 'common.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomePage> {
  final prompt = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(atelierProvider).data.settings['welcomed'] != true) {
        welcome();
      }
    });
  }

  Future<void> welcome() async {
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Bienvenue dans votre atelier !'),
        content: const Text(
          '1. Créez un courrier ou choisissez un modèle.\n\n2. Écrivez : vos brouillons restent sur cet appareil.\n\n3. Exportez ou sauvegardez votre bibliothèque.\n\nBafou nécessite une IA configurée. Aucun courrier ne lui est transmis sans votre accord.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Entrer dans l’atelier'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    final a = ref.read(atelierProvider);
    a.data.settings['welcomed'] = true;
    await guarded(context, a.persist);
  }

  @override
  void dispose() {
    prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(atelierProvider);
    return PageBody(
      title: 'Les idées viennent de vous.\nLes mots prennent vie ici.',
      subtitle: 'VOTRE ATELIER D’ÉCRITURE • LOCAL PAR DÉFAUT',
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff482878), Color(0xff242438)],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Bafou(size: 68),
                  SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Tu racontes,\nLa Bafouille rédige !',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: prompt,
                minLines: 2,
                maxLines: 5,
                style: const TextStyle(color: Color(0xff242438)),
                decoration: const InputDecoration(
                  fillColor: Color(0xfffff7e8),
                  hintText: 'Qu’est-ce qu’on écrit aujourd’hui ?',
                  hintStyle: TextStyle(color: Color(0xff555568)),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xffffd166),
                  foregroundColor: const Color(0xff242438),
                ),
                onPressed: () => context.go(
                  Uri(
                    path: '/assistant',
                    queryParameters: {'mode': 'letter', 'prompt': prompt.text},
                  ).toString(),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Préparer avec Bafou'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '${a.data.letters.where((l) => !l.deleted).length} courriers dans votre atelier',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 1050
                ? 3
                : c.maxWidth > 570
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3.2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                tile(
                  'Nouveau courrier',
                  'Une page à vous',
                  Icons.edit_note,
                  const Color(0xffff7666),
                  () => guarded(context, () async {
                    final l = await a.create();
                    if (context.mounted) context.go('/editor/${l.id}');
                  }),
                ),
                tile(
                  'Correction et orthographe',
                  'Le labo des mots',
                  Icons.spellcheck,
                  const Color(0xff25c4c0),
                  () => context.go('/correction'),
                ),
                tile(
                  'Discuter avec Bafou',
                  'Un coup de plume',
                  Icons.forum,
                  const Color(0xffffd166),
                  () => context.go('/assistant'),
                ),
                tile(
                  'Laboratoire des styles',
                  'Jusqu’à trois variations',
                  Icons.palette,
                  const Color(0xffff7666),
                  () => context.go('/assistant?mode=styles'),
                ),
                tile(
                  'Dictionnaire et conjugaison',
                  'Comprendre les mots',
                  Icons.menu_book,
                  const Color(0xff25c4c0),
                  () => context.go('/dictionary'),
                ),
                tile(
                  'Mes correspondances',
                  'Retrouver ses écrits',
                  Icons.folder,
                  const Color(0xffffd166),
                  () => context.go('/library'),
                ),
                tile(
                  'Mes brouillons',
                  'Reprendre le fil',
                  Icons.drafts,
                  const Color(0xffff7666),
                  () => context.go('/library?filter=Brouillons'),
                ),
                tile(
                  'Modèles de courriers',
                  '54 points de départ',
                  Icons.auto_stories,
                  const Color(0xff25c4c0),
                  () => context.go('/templates'),
                ),
                tile(
                  'Paramètres',
                  'Votre atelier, vos choix',
                  Icons.tune,
                  const Color(0xffffd166),
                  () => context.go('/settings'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Vos mots vous appartiennent. Aucune transmission automatique. Aucun abonnement intégré.',
        ),
      ],
    );
  }

  Widget tile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              foregroundColor: const Color(0xff242438),
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
