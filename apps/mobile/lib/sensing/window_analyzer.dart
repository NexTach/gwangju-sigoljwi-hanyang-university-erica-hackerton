import 'dart:math' as math;

import '../core/models.dart';
import 'calibration.dart';

class GravityFilter {
  GravityFilter({
    this.maximumGap = const Duration(milliseconds: 250),
    this.timeConstant = const Duration(milliseconds: 650),
  });

  final Duration maximumGap;
  final Duration timeConstant;
  double? _gravityX;
  double? _gravityY;
  double? _gravityZ;
  DateTime? _previousAt;

  MotionSample filter(MotionSample sample) {
    final previousAt = _previousAt;
    final elapsed = previousAt == null
        ? Duration.zero
        : sample.recordedAt.difference(previousAt);
    if (elapsed <= Duration.zero || elapsed > maximumGap) {
      _gravityX = sample.x;
      _gravityY = sample.y;
      _gravityZ = sample.z;
      _previousAt = sample.recordedAt;
      return MotionSample(
        gyroX: sample.gyroX,
        gyroY: sample.gyroY,
        gyroZ: sample.gyroZ,
        recordedAt: sample.recordedAt,
        x: 0,
        y: 0,
        z: 0,
      );
    }
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final timeConstantSeconds =
        timeConstant.inMicroseconds / Duration.microsecondsPerSecond;
    final alpha = math.exp(-seconds / timeConstantSeconds);
    _gravityX = alpha * _gravityX! + (1 - alpha) * sample.x;
    _gravityY = alpha * _gravityY! + (1 - alpha) * sample.y;
    _gravityZ = alpha * _gravityZ! + (1 - alpha) * sample.z;
    _previousAt = sample.recordedAt;
    return MotionSample(
      gyroX: sample.gyroX,
      gyroY: sample.gyroY,
      gyroZ: sample.gyroZ,
      recordedAt: sample.recordedAt,
      x: sample.x - _gravityX!,
      y: sample.y - _gravityY!,
      z: sample.z - _gravityZ!,
    );
  }

  void reset() {
    _gravityX = null;
    _gravityY = null;
    _gravityZ = null;
    _previousAt = null;
  }
}

class SensorWindowAnalyzer {
  SensorWindowAnalyzer({
    required this.calibration,
    this.maximumSampleGap = const Duration(milliseconds: 160),
    this.maximumSampleRateHz = 80,
    this.minimumSampleRateHz = 18,
    this.minimumSamples = 40,
    this.minimumPeakSeparation = const Duration(milliseconds: 120),
    this.windowDuration = const Duration(seconds: 2),
    GravityFilter? gravityFilter,
  }) : _gravityFilter = gravityFilter ?? GravityFilter();

  CalibrationSettings calibration;
  final Duration maximumSampleGap;
  final double maximumSampleRateHz;
  final double minimumSampleRateHz;
  final int minimumSamples;
  final Duration minimumPeakSeparation;
  final Duration windowDuration;
  final GravityFilter _gravityFilter;
  final List<MotionSample> _samples = [];
  DateTime? _lastRawSampleAt;
  DateTime? _windowStartedAt;

  ImpactCandidate? add(MotionSample rawSample) {
    final lastRawSampleAt = _lastRawSampleAt;
    if (lastRawSampleAt != null) {
      final gap = rawSample.recordedAt.difference(lastRawSampleAt);
      if (gap <= Duration.zero || gap > maximumSampleGap) {
        _resetWindow();
      }
    }
    _lastRawSampleAt = rawSample.recordedAt;
    final sample = _gravityFilter.filter(rawSample);
    _windowStartedAt ??= sample.recordedAt;
    _samples.add(sample);
    if (sample.recordedAt.difference(_windowStartedAt!) < windowDuration) {
      return null;
    }

    final samples = List<MotionSample>.unmodifiable(_samples);
    final startedAt = _windowStartedAt!;
    _samples.clear();
    _windowStartedAt = null;
    final duration = samples.last.recordedAt.difference(startedAt);
    final seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;
    final sampleRate = seconds <= 0 ? 0 : (samples.length - 1) / seconds;
    if (samples.length < minimumSamples ||
        sampleRate < minimumSampleRateHz ||
        sampleRate > maximumSampleRateHz) {
      return null;
    }

    final magnitudes = samples.map((sample) => sample.magnitude).toList();
    final gyros = samples.map((sample) => sample.gyroMagnitude).toList();
    final mean =
        magnitudes.reduce((sum, value) => sum + value) / magnitudes.length;
    final variance =
        magnitudes
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((sum, value) => sum + value) /
        magnitudes.length;
    final maxPeak = magnitudes.reduce(math.max);
    final rms = math.sqrt(
      magnitudes
              .map((value) => value * value)
              .reduce((sum, value) => sum + value) /
          magnitudes.length,
    );
    final gyroRms = math.sqrt(
      gyros.map((value) => value * value).reduce((sum, value) => sum + value) /
          gyros.length,
    );
    final peakCount = _countSeparatedPeaks(
      magnitudes,
      samples,
      threshold: calibration.lowImpactPeak,
    );
    final activityThreshold = math.min(
      calibration.lowImpactPeak * 0.55,
      calibration.vibrationRms * 0.8,
    );
    final vibrationPeakCount = _countSeparatedPeaks(
      magnitudes,
      samples,
      threshold: activityThreshold,
    );
    final activeSampleRatio =
        magnitudes.where((value) => value >= activityThreshold).length /
        magnitudes.length;

    final features = SensorWindowFeatures(
      duration: duration,
      gyroRms: gyroRms,
      maxPeak: maxPeak,
      mean: mean,
      peakCount: peakCount,
      rms: rms,
      standardDeviation: math.sqrt(variance),
    );
    final isPossibleDrop = maxPeak >= calibration.dropPeak && peakCount <= 1;
    final hasRepeatedImpacts =
        peakCount >= 2 &&
        rms >= calibration.vibrationRms * 0.45 &&
        maxPeak - mean >= calibration.lowImpactPeak * 0.45 &&
        activeSampleRatio >= 0.08;
    final hasSustainedVibration =
        rms >= calibration.vibrationRms &&
        vibrationPeakCount >= 3 &&
        activeSampleRatio >= 0.20;
    final isCandidate =
        isPossibleDrop || hasRepeatedImpacts || hasSustainedVibration;
    if (!isCandidate) return null;

    final peakScore = _normalize(
      maxPeak,
      calibration.lowImpactPeak,
      calibration.highImpactPeak,
    );
    final vibrationScore = _normalize(
      rms,
      calibration.vibrationRms,
      calibration.vibrationRms * 3,
    );
    final gyroScore = _normalize(gyroRms, 0.8, 5);
    final severity =
        (peakScore * 0.75 + vibrationScore * 0.15 + gyroScore * 0.1).clamp(
          0.0,
          1.0,
        );
    final impactLevel = maxPeak >= calibration.highImpactPeak
        ? ImpactLevel.high
        : maxPeak >= calibration.mediumImpactPeak
        ? ImpactLevel.medium
        : ImpactLevel.low;

    return ImpactCandidate(
      anomalyScore: severity,
      detectedAt: samples[magnitudes.indexOf(maxPeak)].recordedAt,
      features: features,
      impactLevel: impactLevel,
      isPossibleDrop: isPossibleDrop,
      severity: severity,
    );
  }

  void reset() {
    _lastRawSampleAt = null;
    _resetWindow();
  }

  void _resetWindow() {
    _samples.clear();
    _windowStartedAt = null;
    _gravityFilter.reset();
  }

  double _normalize(double value, double minimum, double maximum) =>
      ((value - minimum) / (maximum - minimum)).clamp(0.0, 1.0);

  int _countSeparatedPeaks(
    List<double> magnitudes,
    List<MotionSample> samples, {
    required double threshold,
  }) {
    DateTime? lastPeakAt;
    var count = 0;
    for (var index = 1; index < magnitudes.length - 1; index += 1) {
      final isLocalPeak =
          magnitudes[index] >= threshold &&
          magnitudes[index] > magnitudes[index - 1] &&
          magnitudes[index] >= magnitudes[index + 1];
      if (!isLocalPeak) continue;

      final recordedAt = samples[index].recordedAt;
      if (lastPeakAt != null &&
          recordedAt.difference(lastPeakAt) < minimumPeakSeparation) {
        continue;
      }
      count += 1;
      lastPeakAt = recordedAt;
    }
    return count;
  }
}
