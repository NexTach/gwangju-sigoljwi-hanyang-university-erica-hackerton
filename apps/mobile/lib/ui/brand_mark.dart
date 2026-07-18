import 'package:flutter/material.dart';
import 'package:road_dna_design/road_dna_design.dart';

class RoadDnaBrandMark extends StatelessWidget {
  const RoadDnaBrandMark({
    this.backgroundColor,
    this.foregroundColor,
    this.showAccentDot = true,
    this.size = 64,
    super.key,
  });

  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showAccentDot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final background = backgroundColor ?? RdPalette.coral500;
    final foreground = foregroundColor ?? RdPalette.white;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.28),
                color: background,
              ),
              child: CustomPaint(
                painter: _RoadDnaMarkPainter(color: foreground),
              ),
            ),
          ),
          if (showAccentDot)
            Positioned(
              right: -size * 0.07,
              top: -size * 0.07,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: size * 0.04,
                  ),
                  color: RdPalette.amber500,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(dimension: size * 0.25),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoadDnaMarkPainter extends CustomPainter {
  const _RoadDnaMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 40;
    canvas.save();
    canvas.scale(scale);

    final route = Path()
      ..moveTo(6, 28)
      ..cubicTo(14, 30, 17, 12, 24, 11)
      ..cubicTo(29, 10.3, 30.5, 17.2, 34, 8);
    canvas.drawPath(
      route,
      Paint()
        ..color = color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 4.8
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(const Offset(6, 28), 3.6, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoadDnaMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
