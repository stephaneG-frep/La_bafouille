import 'package:flutter/material.dart';

void notice(BuildContext context, String message) {
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<void> guarded(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (_) {
    if (context.mounted) {
      notice(
        context,
        'L’opération n’a pas abouti. Vérifiez les permissions, la configuration et l’espace disponible.',
      );
    }
  }
}

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title, subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      Text(subtitle),
      const SizedBox(height: 24),
      ...children,
    ],
  );
}

class Bafou extends StatefulWidget {
  const Bafou({super.key, this.size = 92});
  final double size;
  @override
  State<Bafou> createState() => _BafouState();
}

class _BafouState extends State<Bafou> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Bafou, votre robot plume',
    image: true,
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          MediaQuery.disableAnimationsOf(context) ? 0 : 4 * controller.value,
        ),
        child: child,
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: const Color(0xff25c4c0),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xff242438), width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0xff482878), offset: Offset(5, 5)),
          ],
        ),
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 10,
              right: 7,
              child: Icon(Icons.edit, color: Color(0xff482878), size: 28),
            ),
            Text(
              '• ▿ •',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xff242438),
              ),
            ),
            Positioned(
              bottom: 8,
              child: Icon(Icons.keyboard, size: 25, color: Color(0xff482878)),
            ),
          ],
        ),
      ),
    ),
  );
}
