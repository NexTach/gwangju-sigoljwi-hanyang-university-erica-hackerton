import 'package:flutter/material.dart';
import 'package:road_dna_design/road_dna_design.dart';

class RoadDnaBrandMark extends StatelessWidget {
  const RoadDnaBrandMark({this.size = 64, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.28),
      color: RdPalette.gray950,
    ),
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: const _RoadDnaMarkPainter()),
    ),
  );
}

class _RoadDnaMarkPainter extends CustomPainter {
  const _RoadDnaMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 1024;
    canvas.save();
    canvas.scale(scale);

    final route = Path()
      ..moveTo(292, 732)
      ..cubicTo(292, 626, 384, 617, 384, 510)
      ..cubicTo(384, 403, 476, 394, 476, 287)
      ..lineTo(684, 287);
    canvas.drawPath(
      route,
      Paint()
        ..color = RdPalette.white
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 92
        ..style = PaintingStyle.stroke,
    );

    void drawEndpoint(Offset center, Color color) {
      canvas
        ..drawCircle(
          center,
          97,
          Paint()
            ..color = RdPalette.white
            ..style = PaintingStyle.fill,
        )
        ..drawCircle(
          center,
          59,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
    }

    drawEndpoint(const Offset(292, 732), RdPalette.cobalt500);
    drawEndpoint(const Offset(684, 287), RdPalette.cyan500);

    final barrier = Path()
      ..moveTo(671, 615)
      ..lineTo(724, 560)
      ..lineTo(777, 615)
      ..lineTo(830, 560);
    canvas.drawPath(
      barrier,
      Paint()
        ..color = RdPalette.amber500
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 42
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoadDnaMarkPainter oldDelegate) => false;
}
