import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class CalibrationSettings {
  const CalibrationSettings({
    required this.dropPeak,
    required this.highImpactPeak,
    required this.lowImpactPeak,
    required this.mediumImpactPeak,
    required this.vibrationRms,
  });

  const CalibrationSettings.exploratory()
    : dropPeak = 22,
      highImpactPeak = 5.5,
      lowImpactPeak = 1.8,
      mediumImpactPeak = 3.5,
      vibrationRms = 1.15;

  final double dropPeak;
  final double highImpactPeak;
  final double lowImpactPeak;
  final double mediumImpactPeak;
  final double vibrationRms;

  bool get isValid =>
      lowImpactPeak > 0 &&
      mediumImpactPeak > lowImpactPeak &&
      highImpactPeak > mediumImpactPeak &&
      dropPeak > highImpactPeak &&
      vibrationRms > 0;

  CalibrationSettings copyWith({
    double? dropPeak,
    double? highImpactPeak,
    double? lowImpactPeak,
    double? mediumImpactPeak,
    double? vibrationRms,
  }) => CalibrationSettings(
    dropPeak: dropPeak ?? this.dropPeak,
    highImpactPeak: highImpactPeak ?? this.highImpactPeak,
    lowImpactPeak: lowImpactPeak ?? this.lowImpactPeak,
    mediumImpactPeak: mediumImpactPeak ?? this.mediumImpactPeak,
    vibrationRms: vibrationRms ?? this.vibrationRms,
  );
}

class CalibrationStore {
  CalibrationStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _dropKey = 'calibration.dropPeak';
  static const _highKey = 'calibration.highImpactPeak';
  static const _lowKey = 'calibration.lowImpactPeak';
  static const _mediumKey = 'calibration.mediumImpactPeak';
  static const _rmsKey = 'calibration.vibrationRms';

  final SharedPreferencesAsync _preferences;

  Future<CalibrationSettings> read() async {
    const defaults = CalibrationSettings.exploratory();
    final settings = CalibrationSettings(
      dropPeak: await _preferences.getDouble(_dropKey) ?? defaults.dropPeak,
      highImpactPeak:
          await _preferences.getDouble(_highKey) ?? defaults.highImpactPeak,
      lowImpactPeak:
          await _preferences.getDouble(_lowKey) ?? defaults.lowImpactPeak,
      mediumImpactPeak:
          await _preferences.getDouble(_mediumKey) ??
          defaults.mediumImpactPeak,
      vibrationRms:
          await _preferences.getDouble(_rmsKey) ?? defaults.vibrationRms,
    );
    return settings.isValid ? settings : defaults;
  }

  Future<void> write(CalibrationSettings settings) async {
    if (!settings.isValid) {
      throw ArgumentError('Calibration thresholds must increase in order.');
    }
    await Future.wait([
      _preferences.setDouble(_dropKey, settings.dropPeak),
      _preferences.setDouble(_highKey, settings.highImpactPeak),
      _preferences.setDouble(_lowKey, settings.lowImpactPeak),
      _preferences.setDouble(_mediumKey, settings.mediumImpactPeak),
      _preferences.setDouble(_rmsKey, settings.vibrationRms),
    ]);
  }

  Future<void> reset() async {
    for (final key in [_dropKey, _highKey, _lowKey, _mediumKey, _rmsKey]) {
      await _preferences.remove(key);
    }
  }
}
