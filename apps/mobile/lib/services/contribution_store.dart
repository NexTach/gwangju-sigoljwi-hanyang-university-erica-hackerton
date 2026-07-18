import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ContributionSummary {
  const ContributionSummary({
    required this.acceptedEvents,
    required this.distanceMeters,
    required this.sessions,
  });

  const ContributionSummary.empty()
    : acceptedEvents = 0,
      distanceMeters = 0,
      sessions = 0;

  final int acceptedEvents;
  final double distanceMeters;
  final int sessions;
}

class ContributionStore {
  ContributionStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences;

  static const _distanceKey = 'contribution.distanceMeters';
  static const _eventKey = 'contribution.acceptedEvents';
  static const _sessionKey = 'contribution.sessions';

  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _client =>
      _preferences ??= SharedPreferencesAsync();

  Future<ContributionSummary> read() async => ContributionSummary(
    acceptedEvents: await _client.getInt(_eventKey) ?? 0,
    distanceMeters: await _client.getDouble(_distanceKey) ?? 0,
    sessions: await _client.getInt(_sessionKey) ?? 0,
  );

  Future<ContributionSummary> addSession({
    required int acceptedEvents,
    required double distanceMeters,
  }) async {
    final current = await read();
    final next = ContributionSummary(
      acceptedEvents: current.acceptedEvents + acceptedEvents,
      distanceMeters: current.distanceMeters + distanceMeters,
      sessions: current.sessions + 1,
    );
    await Future.wait([
      _client.setInt(_eventKey, next.acceptedEvents),
      _client.setDouble(_distanceKey, next.distanceMeters),
      _client.setInt(_sessionKey, next.sessions),
    ]);
    return next;
  }
}
