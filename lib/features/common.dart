import 'dart:math' as math;
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

/// Palette du cahier des charges.
abstract final class Palette {
  static const violet = Color(0xff482878);
  static const turquoise = Color(0xff25c4c0);
  static const coral = Color(0xffff7666);
  static const yellow = Color(0xffffd166);
  static const cream = Color(0xfffff7e8);
  static const night = Color(0xff242438);
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
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: dark ? Palette.cream : Palette.violet,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 96,
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: const LinearGradient(
                colors: [Palette.coral, Palette.yellow, Palette.turquoise],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(subtitle),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}

/// Apparition décalée (fondu et glissement), désactivée si l'utilisateur
/// a demandé de réduire les animations.
class Appear extends StatelessWidget {
  const Appear({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = 60 * index;
    final total = 320 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}

/// Fond de l'atelier : papier quadrillé pointillé et halos colorés.
/// Peint une seule fois, isolé du reste de l'interface.
class AtelierBackdrop extends StatelessWidget {
  const AtelierBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _BackdropPainter(
              Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.dark);
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    void halo(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    final r = size.shortestSide * .7;
    halo(
      Offset(size.width, 0),
      r,
      Palette.turquoise.withValues(alpha: dark ? .16 : .20),
    );
    halo(
      Offset(0, size.height),
      r,
      Palette.coral.withValues(alpha: dark ? .12 : .16),
    );
    halo(
      Offset(size.width * .35, size.height * .45),
      r * .6,
      Palette.violet.withValues(alpha: dark ? .18 : .06),
    );
    final dot = Paint()
      ..color = (dark ? Palette.turquoise : Palette.violet).withValues(
        alpha: dark ? .16 : .10,
      );
    const step = 26.0;
    for (var x = step / 2; x < size.width; x += step) {
      for (var y = step / 2; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.dark != dark;
}

/// Bafou : tête de robot secrétaire, écran-visage, plume en antenne
/// et clavier de machine à écrire.
class Bafou extends StatefulWidget {
  const Bafou({super.key, this.size = 92});
  final double size;
  @override
  State<Bafou> createState() => _BafouState();
}

class _BafouState extends State<Bafou> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Bafou, votre robot plume',
    image: true,
    child: RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(painter: _BafouPainter(controller)),
      ),
    ),
  );
}

class _BafouPainter extends CustomPainter {
  _BafouPainter(this.t) : super(repaint: t);
  final Animation<double> t;
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final phase = t.value * 2 * math.pi;
    final bob = math.sin(phase) * 2.5 * u;
    final blink = t.value > .9 && t.value < .94;
    final outline = Paint()
      ..color = Palette.night
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * u
      ..strokeJoin = StrokeJoin.round;
    Paint fill(Color c) => Paint()..color = c;

    canvas.save();
    canvas.translate(0, bob);

    // Plume-antenne qui oscille.
    canvas.save();
    canvas.translate(62 * u, 22 * u);
    canvas.rotate(.35 + math.sin(phase * 2) * .12);
    final feather = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-9 * u, -14 * u, 0, -26 * u)
      ..quadraticBezierTo(9 * u, -14 * u, 0, 0)
      ..close();
    canvas.drawPath(feather, fill(Palette.coral));
    canvas.drawPath(feather, outline..strokeWidth = 2.2 * u);
    canvas.drawLine(Offset.zero, Offset(0, -22 * u), outline);
    canvas.restore();
    outline.strokeWidth = 3 * u;

    // Tête avec ombre décalée violette.
    final head = RRect.fromRectAndRadius(
      Rect.fromLTWH(12 * u, 20 * u, 70 * u, 56 * u),
      Radius.circular(18 * u),
    );
    canvas.drawRRect(head.shift(Offset(5 * u, 5 * u)), fill(Palette.violet));
    canvas.drawRRect(head, fill(Palette.turquoise));
    canvas.drawRRect(head, outline);

    // Écran-visage.
    final screen = RRect.fromRectAndRadius(
      Rect.fromLTWH(22 * u, 29 * u, 50 * u, 30 * u),
      Radius.circular(10 * u),
    );
    canvas.drawRRect(screen, fill(Palette.cream));
    canvas.drawRRect(screen, outline..strokeWidth = 2.2 * u);
    final eye = fill(Palette.night);
    for (final x in [37.0, 57.0]) {
      if (blink) {
        canvas.drawLine(
          Offset((x - 3.5) * u, 41 * u),
          Offset((x + 3.5) * u, 41 * u),
          outline,
        );
      } else {
        canvas.drawCircle(Offset(x * u, 41 * u), 3.6 * u, eye);
      }
    }
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(47 * u, 47 * u),
        width: 12 * u,
        height: 8 * u,
      ),
      .2,
      math.pi - .4,
      false,
      outline..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(28 * u, 50 * u),
      2.6 * u,
      fill(Palette.coral.withValues(alpha: .7)),
    );
    canvas.drawCircle(
      Offset(66 * u, 50 * u),
      2.6 * u,
      fill(Palette.coral.withValues(alpha: .7)),
    );

    // Clavier de machine à écrire.
    for (var i = 0; i < 5; i++) {
      final key = Offset((26 + i * 10.5) * u, 67 * u);
      canvas.drawCircle(key, 3.4 * u, fill(Palette.yellow));
      canvas.drawCircle(key, 3.4 * u, outline..strokeWidth = 1.8 * u);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BafouPainter old) => false;
}
