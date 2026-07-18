import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class WalkReportStorage {
  Future<String?> read();

  Future<void> write(String value);
}

class SharedPreferencesWalkReportStorage implements WalkReportStorage {
  SharedPreferencesWalkReportStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'road_dna_walk_reports_v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(storageKey);

  @override
  Future<void> write(String value) => _preferences.setString(storageKey, value);
}

final walkReportStorageProvider = Provider<WalkReportStorage>(
  (ref) => SharedPreferencesWalkReportStorage(),
);
