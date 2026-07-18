import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../state/tracking_controller.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';

class SensorAnalysisScreen extends ConsumerWidget {
  const SensorAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final previewState = ref.watch(sensorPreviewProvider);
    final preview = previewState.value;
    final tracking = ref.watch(trackingProvider);
    final candidate = tracking.lastCandidate;
    final active = tracking.status == TrackingStatus.active;
    final sensorLoading = previewState.isLoading && preview == null;
    final sensorError = previewState.hasError;
    final hasImpact = candidate != null || (preview?.linearMagnitude ?? 0) > 4;
    final severity =
        candidate?.severity ??
        ((preview?.linearMagnitude ?? 0) / 12).clamp(0.08, 0.82);
    final location = tracking.latestLocation;
    final now = candidate?.detectedAt ?? DateTime.now();
    final recordedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final statusColor = sensorError
        ? CompanionColors.red
        : sensorLoading
        ? CompanionColors.muted
        : active
        ? CompanionColors.greenBright
        : CompanionColors.muted;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(dimension: 8),
                ),
                const SizedBox(width: 8),
                Text(
                  sensorError
                      ? '센서 연결 오류'
                      : sensorLoading
                      ? '센서 연결 중'
                      : active
                      ? '도로 분석 중'
                      : '센서 상태 확인',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.45,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Road DNA가 이동을 분석하고 있어요',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              sensorError
                  ? '이 기기에서 모션 센서를 읽지 못했어요'
                  : sensorLoading
                  ? '센서 연결을 준비하고 있어요'
                  : active
                  ? '아무것도 하지 않아도 자동으로 측정돼요'
                  : '측정을 시작하기 전에도 센서 연결 상태를 확인할 수 있어요',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: CompanionColors.muted),
            ),
            const SizedBox(height: 20),
            CompanionCard(
              padding: const EdgeInsets.all(19),
              radius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '충격 강도 (가속도 센서)',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: CompanionColors.muted,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.35,
                              ),
                        ),
                      ),
                      Text(
                        sensorError
                            ? '연결 오류'
                            : sensorLoading
                            ? '연결 중'
                            : hasImpact
                            ? '감지 기준선 초과'
                            : '정상 범위',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: sensorError
                              ? CompanionColors.red
                              : sensorLoading
                              ? CompanionColors.muted
                              : hasImpact
                              ? CompanionColors.red
                              : CompanionColors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 110,
                    child: CustomPaint(
                      painter: _SensorChartPainter(
                        hasImpact: hasImpact,
                        magnitude: preview?.linearMagnitude ?? 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview != null
                              ? 'X: ${preview.x.toStringAsFixed(2)} · Y: ${preview.y.toStringAsFixed(2)} · Z: ${preview.z.toStringAsFixed(2)}'
                              : config.demoMode &&
                                    !sensorLoading &&
                                    !sensorError
                              ? 'X: 0.23 · Y: 0.51 · Z: 10.92'
                              : 'X: — · Y: — · Z: —',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      Text(
                        'severity ${severity.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CompanionCard(
              color: sensorError
                  ? CompanionColors.coralSoft
                  : sensorLoading
                  ? CompanionColors.creamMuted
                  : hasImpact
                  ? CompanionColors.coralSoft
                  : CompanionColors.greenSoft,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              radius: 22,
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: CompanionColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 40,
                      child: Icon(
                        sensorError
                            ? Icons.sensors_off_rounded
                            : sensorLoading
                            ? Icons.hourglass_top_rounded
                            : hasImpact
                            ? Icons.error_outline_rounded
                            : Icons.check_rounded,
                        color: sensorError
                            ? CompanionColors.red
                            : sensorLoading
                            ? CompanionColors.muted
                            : hasImpact
                            ? CompanionColors.red
                            : CompanionColors.green,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sensorError
                              ? '센서 신호를 읽을 수 없어요'
                              : sensorLoading
                              ? '센서 연결을 준비하고 있어요'
                              : hasImpact
                              ? '비정상적인 이동 충격이 감지됐어요'
                              : '센서 신호가 안정적으로 수집되고 있어요',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sensorError
                              ? '기기의 센서 권한과 지원 여부를 확인해 주세요'
                              : sensorLoading
                              ? '연결되면 충격 강도를 자동으로 표시해요'
                              : hasImpact
                              ? '정확한 원인은 아직 확인되지 않았어요 (Barrier Candidate)'
                              : '중력 성분을 제거한 신호를 기기 안에서 분석해요',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: sensorError
                                    ? CompanionColors.red
                                    : sensorLoading
                                    ? CompanionColors.muted
                                    : hasImpact
                                    ? CompanionColors.red
                                    : CompanionColors.green,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CompanionCard(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
              radius: 20,
              child: Column(
                children: [
                  _SensorMetadataRow(
                    label: 'GPS 좌표',
                    value: location == null
                        ? config.demoMode
                              ? '35.1771, 126.9107'
                              : '—'
                        : '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                  ),
                  const SizedBox(height: 8),
                  _SensorMetadataRow(label: '기록 시각', value: recordedTime),
                  const SizedBox(height: 8),
                  _SensorMetadataRow(
                    label: '이동 유형',
                    value:
                        tracking.movementType?.apiName ??
                        (config.demoMode ? 'WHEELCHAIR' : '선택 전'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CompanionCard(
              color: CompanionColors.creamMuted,
              padding: const EdgeInsets.all(16),
              radius: 20,
              child: Row(
                children: [
                  SizedBox(
                    width: 37,
                    child: Stack(
                      children: const [
                        CircleAvatar(
                          backgroundColor: CompanionColors.coral,
                          radius: 11,
                        ),
                        Positioned(
                          left: 14,
                          child: CircleAvatar(
                            backgroundColor: CompanionColors.greenBright,
                            radius: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      sensorError
                          ? '센서 연결을 확인한 뒤 다시 시도해 주세요'
                          : sensorLoading
                          ? '센서 연결을 준비하고 있어요'
                          : hasImpact
                          ? '이 위치, ${math.max(1, tracking.acceptedEvents)}번째 감지예요 · 신뢰도 20% (LOW)\n더 많은 이동 데이터가 모이면 정확해져요'
                          : '센서 연결이 정상이에요 · 측정을 시작하면 도로 구간별 신뢰도를 계산해요',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: CompanionColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorMetadataRow extends StatelessWidget {
  const _SensorMetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const Spacer(),
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: CompanionColors.ink),
      ),
    ],
  );
}

class _SensorChartPainter extends CustomPainter {
  const _SensorChartPainter({required this.hasImpact, required this.magnitude});

  final bool hasImpact;
  final double magnitude;

  @override
  void paint(Canvas canvas, Size size) {
    final thresholdY = size.height * 0.64;
    final thresholdPaint = Paint()
      ..color = CompanionColors.creamLine
      ..strokeWidth = 1.5;
    const dash = 5.0;
    for (var x = 0.0; x < size.width; x += dash * 2) {
      canvas.drawLine(
        Offset(x, thresholdY),
        Offset(math.min(x + dash, size.width), thresholdY),
        thresholdPaint,
      );
    }
    final points = [
      0.76,
      0.74,
      0.78,
      0.72,
      0.76,
      0.74,
      0.56,
      hasImpact ? 0.10 : 0.52 - magnitude.clamp(0, 4) / 20,
      0.51,
      0.73,
      0.71,
      0.76,
      0.72,
    ];
    final path = Path();
    for (final (index, point) in points.indexed) {
      final offset = Offset(
        size.width * index / (points.length - 1),
        size.height * point,
      );
      if (index == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = CompanionColors.greenBright
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    if (hasImpact) {
      canvas.drawCircle(
        Offset(size.width * 7 / (points.length - 1), size.height * points[7]),
        5,
        Paint()..color = CompanionColors.red,
      );
    }
  }

  @override
  bool shouldRepaint(_SensorChartPainter oldDelegate) =>
      oldDelegate.hasImpact != hasImpact || oldDelegate.magnitude != magnitude;
}
