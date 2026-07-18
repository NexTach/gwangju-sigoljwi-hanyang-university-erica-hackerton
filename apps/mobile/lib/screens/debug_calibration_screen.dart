import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:road_dna_design/road_dna_design.dart';

import '../sensing/calibration.dart';
import '../state/providers.dart';
import '../state/tracking_controller.dart';

class DebugCalibrationScreen extends ConsumerStatefulWidget {
  const DebugCalibrationScreen({super.key});

  @override
  ConsumerState<DebugCalibrationScreen> createState() =>
      _DebugCalibrationScreenState();
}

class _DebugCalibrationScreenState
    extends ConsumerState<DebugCalibrationScreen> {
  final _lowController = TextEditingController();
  final _mediumController = TextEditingController();
  final _highController = TextEditingController();
  final _dropController = TextEditingController();
  final _rmsController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _lowController.dispose();
    _mediumController.dispose();
    _highController.dispose();
    _dropController.dispose();
    _rmsController.dispose();
    super.dispose();
  }

  void _populate(CalibrationSettings settings) {
    if (_initialized) return;
    _initialized = true;
    _lowController.text = settings.lowImpactPeak.toStringAsFixed(1);
    _mediumController.text = settings.mediumImpactPeak.toStringAsFixed(1);
    _highController.text = settings.highImpactPeak.toStringAsFixed(1);
    _dropController.text = settings.dropPeak.toStringAsFixed(1);
    _rmsController.text = settings.vibrationRms.toStringAsFixed(2);
  }

  Future<void> _save() async {
    final settings = CalibrationSettings(
      dropPeak: double.tryParse(_dropController.text) ?? -1,
      highImpactPeak: double.tryParse(_highController.text) ?? -1,
      lowImpactPeak: double.tryParse(_lowController.text) ?? -1,
      mediumImpactPeak: double.tryParse(_mediumController.text) ?? -1,
      vibrationRms: double.tryParse(_rmsController.text) ?? -1,
    );
    if (!settings.isValid) {
      setState(() => _error = '낮음 < 중간 < 높음 < 낙하 순서와 0보다 큰 RMS를 확인해 주세요.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    await ref.read(calibrationStoreProvider).write(settings);
    ref.invalidate(calibrationProvider);
    if (!mounted) return;
    setState(() => _saving = false);
    showRdToast(
      context,
      message: '다음 측정부터 새 보정값을 적용해요.',
      tone: RdFeedbackTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final calibration = ref.watch(calibrationProvider);
    final sensorPreview = ref.watch(sensorPreviewProvider);
    final preview = sensorPreview.value;
    return Scaffold(
      appBar: RdNavigation(
        onBack: () => context.pop(),
        subtitle: '개발·현장 테스트 전용',
        title: '센서 보정',
      ),
      body: calibration.when(
        data: (settings) {
          _populate(settings);
          return ListView(
            padding: const EdgeInsets.all(RdSpacing.x5),
            children: [
              RdAlert(
                message:
                    '기본값은 초기 탐색값일 뿐 확정 기준이 아니에요. 실제 휠체어·유모차에 고정한 반복 주행으로 조정하고 기록해 주세요.',
                title: '임계치를 현장에서 보정해 주세요',
                tone: RdFeedbackTone.warning,
              ),
              const SizedBox(height: RdSpacing.x5),
              RdSurface(
                tone: RdSurfaceTone.subtle,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '현재 합성 가속도',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        RdBadge(
                          dot: preview != null,
                          label: sensorPreview.hasError
                              ? '읽기 실패'
                              : preview == null
                              ? '연결 중'
                              : '실시간',
                          tone: preview != null
                              ? RdBadgeTone.success
                              : sensorPreview.hasError
                              ? RdBadgeTone.critical
                              : RdBadgeTone.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: RdSpacing.x4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${(preview?.linearMagnitude ?? 0).toStringAsFixed(2)} m/s²',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                    const SizedBox(height: RdSpacing.x2),
                    LinearProgressIndicator(
                      minHeight: 10,
                      value: ((preview?.linearMagnitude ?? 0) / 25).clamp(0, 1),
                    ),
                    const SizedBox(height: RdSpacing.x3),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        preview == null
                            ? '센서 신호를 기다리고 있어요.'
                            : 'X ${preview.x.toStringAsFixed(2)} · Y ${preview.y.toStringAsFixed(2)} · Z ${preview.z.toStringAsFixed(2)}\n'
                                  '원시 ${preview.rawMagnitude.toStringAsFixed(2)} m/s² · ${preview.sampleRateHz.toStringAsFixed(1)} Hz',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.rdColors.contentSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (sensorPreview.hasError) ...[
                const SizedBox(height: RdSpacing.x3),
                const RdAlert(
                  message: '기기에서 가속도 센서 신호를 받지 못했어요.',
                  title: '센서 연결을 확인해 주세요',
                  tone: RdFeedbackTone.critical,
                ),
              ],
              const SizedBox(height: RdSpacing.x6),
              Text(
                '2초 창 임계치',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: RdSpacing.x1),
              Text(
                '단위는 중력 제거 후 합성 가속도(m/s²)예요.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.rdColors.contentSecondary,
                ),
              ),
              const SizedBox(height: RdSpacing.x4),
              RdTextField(
                controller: _lowController,
                label: '낮은 충격 시작',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffix: 'm/s²',
              ),
              const SizedBox(height: RdSpacing.x3),
              RdTextField(
                controller: _mediumController,
                label: '중간 충격 시작',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffix: 'm/s²',
              ),
              const SizedBox(height: RdSpacing.x3),
              RdTextField(
                controller: _highController,
                label: '높은 충격 시작',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffix: 'm/s²',
              ),
              const SizedBox(height: RdSpacing.x3),
              RdTextField(
                controller: _dropController,
                label: '단발 낙하 보류',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffix: 'm/s²',
              ),
              const SizedBox(height: RdSpacing.x3),
              RdTextField(
                controller: _rmsController,
                label: '반복 진동 RMS',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffix: 'm/s²',
              ),
              if (_error != null) ...[
                const SizedBox(height: RdSpacing.x3),
                RdAlert(
                  message: _error!,
                  title: '보정값을 확인해 주세요',
                  tone: RdFeedbackTone.critical,
                ),
              ],
              const SizedBox(height: RdSpacing.x5),
              RdButton(
                fullWidth: true,
                label: '보정값 저장',
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: RdSpacing.x3),
              RdButton(
                fullWidth: true,
                label: '탐색 기본값으로 초기화',
                onPressed: () async {
                  await ref.read(calibrationStoreProvider).reset();
                  _initialized = false;
                  ref.invalidate(calibrationProvider);
                },
                tone: RdButtonTone.ghost,
              ),
              if (ref.watch(trackingProvider).status ==
                  TrackingStatus.active) ...[
                const SizedBox(height: RdSpacing.x6),
                RdButton(
                  fullWidth: true,
                  label: '테스트 충격 1회 주입',
                  leading: const Icon(Icons.bolt_rounded),
                  onPressed: () =>
                      ref.read(trackingProvider.notifier).injectDebugImpact(),
                  tone: RdButtonTone.secondary,
                ),
              ],
              if (kDebugMode || config.demoMode) ...[
                const SizedBox(height: RdSpacing.x3),
                RdButton(
                  fullWidth: true,
                  label: '모바일 디자인 시스템 카탈로그',
                  onPressed: () => context.push('/design-system'),
                  tone: RdButtonTone.ghost,
                ),
              ],
            ],
          );
        },
        error: (error, stackTrace) => RdEmptyState(
          description: error.toString(),
          icon: Icons.tune_rounded,
          title: '보정값을 불러오지 못했어요',
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(RdSpacing.x5),
          child: Column(
            children: [
              RdSkeleton(height: 120),
              SizedBox(height: RdSpacing.x4),
              RdSkeleton(height: 64),
              SizedBox(height: RdSpacing.x3),
              RdSkeleton(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
