import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../rd_tokens.dart';

enum RdRoadGrade { good, normal, caution, poor, unknown }

RdRoadGrade rdRoadGrade(int? score) {
  if (score == null) return RdRoadGrade.unknown;
  if (score >= 80) return RdRoadGrade.good;
  if (score >= 60) return RdRoadGrade.normal;
  if (score >= 40) return RdRoadGrade.caution;
  return RdRoadGrade.poor;
}

extension on RdRoadGrade {
  String get label => switch (this) {
    RdRoadGrade.good => '양호',
    RdRoadGrade.normal => '보통',
    RdRoadGrade.caution => '주의',
    RdRoadGrade.poor => '불편',
    RdRoadGrade.unknown => '데이터 없음',
  };
}

class RdScoreGauge extends StatelessWidget {
  const RdScoreGauge({
    required this.score,
    this.label = 'Road DNA 점수',
    this.size = 152,
    super.key,
  });

  final String label;
  final int? score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.rdColors;
    final grade = rdRoadGrade(score);
    final color = switch (grade) {
      RdRoadGrade.good => colors.mapGood,
      RdRoadGrade.normal => colors.mapNormal,
      RdRoadGrade.caution => colors.mapCaution,
      RdRoadGrade.poor => colors.mapPoor,
      RdRoadGrade.unknown => colors.mapUnknown,
    };
    final semanticValue = score == null
        ? '$label: 데이터 없음'
        : '$label: $score점, ${grade.label}';

    return Semantics(
      image: true,
      label: semanticValue,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: _ScorePainter(
                  color: color,
                  progress: (score ?? 0) / 100,
                  trackColor: colors.border,
                ),
                size: Size.square(size),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score?.toString() ?? '—',
                    style: size >= 180
                        ? Theme.of(context).textTheme.displayLarge
                        : Theme.of(context).textTheme.displayMedium,
                  ),
                  Text(
                    grade.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.contentSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScorePainter extends CustomPainter {
  const _ScorePainter({
    required this.color,
    required this.progress,
    required this.trackColor,
  });

  final Color color;
  final double progress;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.07;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = color
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ScorePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor;
}

class RdConfidenceBar extends StatelessWidget {
  const RdConfidenceBar({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    final normalized = value.clamp(0.0, 1.0);
    final label = normalized >= 0.8
        ? '높음'
        : normalized >= 0.5
        ? '보통'
        : '낮음';
    final percentage = (normalized * 100).round();
    final colors = context.rdColors;

    return Semantics(
      label: '신뢰도 $percentage%, $label',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '신뢰도',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.contentSecondary,
                    ),
                  ),
                ),
                Text(
                  '$percentage% · $label',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: RdSpacing.x2),
            ClipRRect(
              borderRadius: BorderRadius.circular(RdRadius.pill),
              child: LinearProgressIndicator(
                backgroundColor: colors.border,
                color: colors.actionPrimary,
                minHeight: 8,
                value: normalized,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RdMetric extends StatelessWidget {
  const RdMetric({
    required this.label,
    required this.value,
    this.trend,
    super.key,
  });

  final String label;
  final String? trend;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: context.rdColors.contentSecondary,
        ),
      ),
      Text(value, style: Theme.of(context).textTheme.headlineLarge),
      if (trend != null)
        Text(
          trend!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.rdColors.statusSuccess,
          ),
        ),
    ],
  );
}

enum RdRoadScanState { idle, active, impact }

class RdRoadScanRibbon extends StatefulWidget {
  const RdRoadScanRibbon({required this.state, super.key});

  final RdRoadScanState state;

  @override
  State<RdRoadScanRibbon> createState() => _RdRoadScanRibbonState();
}

class _RdRoadScanRibbonState extends State<RdRoadScanRibbon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant RdRoadScanRibbon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.state == RdRoadScanState.active) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = widget.state == RdRoadScanState.impact ? 1 : 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.rdColors;
    final (label, scanColor) = switch (widget.state) {
      RdRoadScanState.idle => ('분석 대기', colors.mapUnknown),
      RdRoadScanState.active => ('도로 분석 중', colors.mapGood),
      RdRoadScanState.impact => ('이동 충격 패턴 감지', colors.mapPoor),
    };

    return Semantics(
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(RdRadius.pill),
              child: ColoredBox(
                color: colors.border,
                child: SizedBox(
                  height: 8,
                  width: 96,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => Align(
                      alignment: widget.state == RdRoadScanState.active
                          ? Alignment(_controller.value * 2 - 1, 0)
                          : widget.state == RdRoadScanState.impact
                          ? Alignment.center
                          : Alignment.centerLeft,
                      child: ColoredBox(
                        color: scanColor,
                        child: SizedBox(
                          height: 8,
                          width: widget.state == RdRoadScanState.impact
                              ? 96
                              : 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: RdSpacing.x3),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.contentSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
