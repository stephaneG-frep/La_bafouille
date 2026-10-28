import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/models.dart';
import '../core/state.dart';
import 'common.dart';
import 'dictation.dart';

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

  void ask(String request, {bool send = false}) => context.go(
    Uri(
      path: '/assistant',
      queryParameters: {
        'mode': 'letter',
        'prompt': request,
        if (send) 'send': '1',
      },
    ).toString(),
  );

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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Palette.violet, Color(0xff35295e), Palette.night],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Palette.night, width: 3),
            boxShadow: const [
              BoxShadow(color: Palette.turquoise, offset: Offset(6, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Bafou(size: 84),
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
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Palette.yellow,
                      foregroundColor: Palette.night,
                    ),
                    onPressed: () => ask(prompt.text),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Préparer avec Bafou'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.cream,
                      side: const BorderSide(color: Palette.cream),
                    ),
                    onPressed: () async {
                      final words = await dictate(
                        context,
                        action: 'Envoyer à Bafou',
                      );
                      if (words == null || !mounted) return;
                      final typed = prompt.text.trim();
                      ask(typed.isEmpty ? words : '$typed\n$words', send: true);
                    },
                    icon: const Icon(Icons.mic_none),
                    label: const Text('Dicter ma demande'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(switch (a.data.letters.where((l) => !l.deleted).length) {
          0 => 'Aucun courrier dans votre atelier pour l’instant',
          1 => '1 courrier dans votre atelier',
          final n => '$n courriers dans votre atelier',
        }, style: Theme.of(context).textTheme.titleMedium),
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
                for (final (i, t) in [
                  tile(
                    'Nouveau courrier',
                    'Lettre structurée à compléter',
                    Icons.edit_note,
                    const Color(0xffff7666),
                    () => guarded(context, () async {
                      final l = await a.create(text: letterSkeleton);
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
                ].indexed)
                  Appear(index: i, child: t),
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
  ) => _Tile(
    title: title,
    subtitle: subtitle,
    icon: icon,
    color: color,
    onTap: onTap,
  );
}

/// Tuile rétro : dégradé, contour encré, ombre décalée qui se creuse au survol.
class _Tile extends StatefulWidget {
  const _Tile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    final lift = hover ? 2.0 : 0.0;
    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.subtitle}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hover = true),
        onExit: (_) => setState(() => hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(-lift, -lift, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.night, width: 2.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(widget.color, Colors.white, .35)!,
                widget.color,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Palette.violet,
                offset: Offset(4 + lift, 4 + lift),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.onTap,
              onFocusChange: (f) => setState(() => hover = f),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Palette.night, width: 2),
                      ),
                      child: Icon(widget.icon, color: Palette.night),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Palette.night,
                            ),
                          ),
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xff3a3a52),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Palette.night,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
