import 'package:flutter/material.dart';

import 'companion_theme.dart';
import 'companion_widgets.dart';

enum CompanionMapStyle { home, tracking, report }

class CompanionMapArtwork extends StatefulWidget {
  const CompanionMapArtwork({
    this.height = 190,
    this.onRoadTap,
    this.showLabels = true,
    this.style = CompanionMapStyle.home,
    super.key,
  });

  final double height;
  final VoidCallback? onRoadTap;
  final bool showLabels;
  final CompanionMapStyle style;

  @override
  State<CompanionMapArtwork> createState() => _CompanionMapArtworkState();
}

class _CompanionMapArtworkState extends State<CompanionMapArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulseController
        ..stop()
        ..value = 0.4;
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: widget.onRoadTap != null,
    label: widget.style == CompanionMapStyle.tracking
        ? '현재 이동 경로 지도'
        : '광주 북구 용봉동 접근성 지도',
    child: Material(
      borderRadius: BorderRadius.circular(
        widget.style == CompanionMapStyle.tracking ? 0 : 28,
      ),
      clipBehavior: Clip.antiAlias,
      color: CompanionColors.creamMap,
      child: InkWell(
        onTap: widget.onRoadTap,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => CustomPaint(
              painter: _CompanionMapPainter(
                pulse: _pulseController.value,
                style: widget.style,
              ),
              child: child,
            ),
            child: widget.showLabels
                ? Stack(
                    children: [
                      if (widget.style == CompanionMapStyle.home)
                        const Positioned(
                          left: 14,
                          top: 14,
                          child: CompanionTag(
                            label: '광주 북구 · 용봉동',
                            backgroundColor: CompanionColors.white,
                            foregroundColor: CompanionColors.ink,
                          ),
                        ),
                      if (widget.style == CompanionMapStyle.home)
                        const Positioned(
                          bottom: 14,
                          left: 14,
                          child: CompanionTag(
                            label: '근처에 편안한 경로 3개',
                            backgroundColor: CompanionColors.white,
                            foregroundColor: CompanionColors.green,
                            icon: Icons.circle,
                          ),
                        ),
                      if (widget.style == CompanionMapStyle.tracking)
                        const Positioned(
                          bottom: 58,
                          left: 98,
                          child: CompanionTag(
                            label: '40m 앞 단차 주의',
                            backgroundColor: CompanionColors.ink,
                            foregroundColor: CompanionColors.white,
                          ),
                        ),
                    ],
                  )
                : null,
          ),
        ),
      ),
    ),
  );
}

class _CompanionMapPainter extends CustomPainter {
  const _CompanionMapPainter({required this.pulse, required this.style});

  final double pulse;
  final CompanionMapStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 334;
    final sy = size.height / 190;
    final linePaint = Paint()
      ..color = CompanionColors.creamLine
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    for (final y in [46.0, 108.0, 164.0]) {
      canvas.drawLine(Offset(0, y * sy), Offset(size.width, y * sy), linePaint);
    }
    for (final x in [66.0, 172.0, 272.0]) {
      canvas.drawLine(
        Offset(x * sx, 0),
        Offset(x * sx, size.height),
        linePaint,
      );
    }

    final routeColor = style == CompanionMapStyle.tracking
        ? CompanionColors.coral
        : CompanionColors.greenBright;
    final route = Path()
      ..moveTo(38 * sx, 164 * sy)
      ..lineTo(38 * sx, 108 * sy)
      ..lineTo(172 * sx, 108 * sy)
      ..lineTo(172 * sx, 46 * sy)
      ..lineTo(300 * sx, 46 * sy);
    canvas.drawPath(
      route,
      Paint()
        ..color = routeColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke,
    );

    canvas
      ..drawCircle(
        Offset(38 * sx, 164 * sy),
        7,
        Paint()..color = CompanionColors.coral,
      )
      ..drawCircle(
        Offset(172 * sx, 108 * sy),
        8,
        Paint()..color = CompanionColors.amberBright,
      );
    final destination = Offset(300 * sx, 46 * sy);
    final pulseRadius = 8 + 12 * pulse;
    canvas
      ..drawCircle(
        destination,
        pulseRadius,
        Paint()
          ..color =
              (style == CompanionMapStyle.tracking
                      ? CompanionColors.coral
                      : CompanionColors.ink)
                  .withValues(alpha: 0.20 * (1 - pulse)),
      )
      ..drawCircle(
        destination,
        7,
        Paint()
          ..color = style == CompanionMapStyle.report
              ? CompanionColors.green
              : CompanionColors.ink,
      );

    final labelStyle = TextStyle(
      color: CompanionColors.muted.withValues(alpha: 0.8),
      fontSize: 9,
      fontWeight: FontWeight.w700,
    );
    TextPainter(
        text: TextSpan(text: '용봉로', style: labelStyle),
        textDirection: TextDirection.ltr,
      )
      ..layout()
      ..paint(canvas, Offset(76 * sx, 30 * sy));
    TextPainter(
        text: TextSpan(text: '전남대학교', style: labelStyle),
        textDirection: TextDirection.ltr,
      )
      ..layout()
      ..paint(canvas, Offset(178 * sx, 90 * sy));
  }

  @override
  bool shouldRepaint(_CompanionMapPainter oldDelegate) =>
      oldDelegate.pulse != pulse || oldDelegate.style != style;
}
