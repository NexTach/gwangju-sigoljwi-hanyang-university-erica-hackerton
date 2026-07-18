import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ProfileNotificationChannel { navigation, impact, report, community }

@immutable
class ProfilePreferencesState {
  const ProfilePreferencesState({
    required this.avoidStairs,
    required this.communityNotifications,
    required this.impactNotifications,
    required this.marketingConsent,
    required this.navigationNotifications,
    required this.preferGentleSlopes,
    required this.preferSmoothRoads,
    required this.reportNotifications,
    required this.shareAnonymousContributions,
    this.lastSupportMessage,
  });

  const ProfilePreferencesState.initial()
    : avoidStairs = true,
      communityNotifications = false,
      impactNotifications = true,
      marketingConsent = false,
      navigationNotifications = true,
      preferGentleSlopes = true,
      preferSmoothRoads = true,
      reportNotifications = true,
      shareAnonymousContributions = true,
      lastSupportMessage = null;

  final bool avoidStairs;
  final bool communityNotifications;
  final bool impactNotifications;
  final String? lastSupportMessage;
  final bool marketingConsent;
  final bool navigationNotifications;
  final bool preferGentleSlopes;
  final bool preferSmoothRoads;
  final bool reportNotifications;
  final bool shareAnonymousContributions;

  bool allowsNotification(ProfileNotificationChannel channel) =>
      switch (channel) {
        ProfileNotificationChannel.navigation => navigationNotifications,
        ProfileNotificationChannel.impact => impactNotifications,
        ProfileNotificationChannel.report => reportNotifications,
        ProfileNotificationChannel.community => communityNotifications,
      };

  ProfilePreferencesState copyWith({
    bool? avoidStairs,
    bool? communityNotifications,
    bool? impactNotifications,
    String? lastSupportMessage,
    bool clearLastSupportMessage = false,
    bool? marketingConsent,
    bool? navigationNotifications,
    bool? preferGentleSlopes,
    bool? preferSmoothRoads,
    bool? reportNotifications,
    bool? shareAnonymousContributions,
  }) => ProfilePreferencesState(
    avoidStairs: avoidStairs ?? this.avoidStairs,
    communityNotifications:
        communityNotifications ?? this.communityNotifications,
    impactNotifications: impactNotifications ?? this.impactNotifications,
    lastSupportMessage: clearLastSupportMessage
        ? null
        : lastSupportMessage ?? this.lastSupportMessage,
    marketingConsent: marketingConsent ?? this.marketingConsent,
    navigationNotifications:
        navigationNotifications ?? this.navigationNotifications,
    preferGentleSlopes: preferGentleSlopes ?? this.preferGentleSlopes,
    preferSmoothRoads: preferSmoothRoads ?? this.preferSmoothRoads,
    reportNotifications: reportNotifications ?? this.reportNotifications,
    shareAnonymousContributions:
        shareAnonymousContributions ?? this.shareAnonymousContributions,
  );
}

class ProfilePreferencesController extends Notifier<ProfilePreferencesState> {
  static const _prefix = 'profilePreferences.';
  static const _avoidStairsKey = '${_prefix}avoidStairs';
  static const _communityNotificationsKey = '${_prefix}communityNotifications';
  static const _impactNotificationsKey = '${_prefix}impactNotifications';
  static const _lastSupportMessageKey = '${_prefix}lastSupportMessage';
  static const _marketingConsentKey = '${_prefix}marketingConsent';
  static const _navigationNotificationsKey =
      '${_prefix}navigationNotifications';
  static const _preferGentleSlopesKey = '${_prefix}preferGentleSlopes';
  static const _preferSmoothRoadsKey = '${_prefix}preferSmoothRoads';
  static const _reportNotificationsKey = '${_prefix}reportNotifications';
  static const _shareAnonymousContributionsKey =
      '${_prefix}shareAnonymousContributions';

  SharedPreferences? _preferences;
  Future<void>? _restoreInFlight;
  bool _hasRestored = false;

  @override
  ProfilePreferencesState build() => const ProfilePreferencesState.initial();

  Future<SharedPreferences> get _client async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<void> restore() {
    if (_hasRestored) return Future<void>.value();
    return _restoreInFlight ??= _restore().whenComplete(() {
      _restoreInFlight = null;
    });
  }

  Future<void> _restore() async {
    final preferences = await _client;
    state = ProfilePreferencesState(
      avoidStairs: preferences.getBool(_avoidStairsKey) ?? state.avoidStairs,
      communityNotifications:
          preferences.getBool(_communityNotificationsKey) ??
          state.communityNotifications,
      impactNotifications:
          preferences.getBool(_impactNotificationsKey) ??
          state.impactNotifications,
      lastSupportMessage: preferences.getString(_lastSupportMessageKey),
      marketingConsent:
          preferences.getBool(_marketingConsentKey) ?? state.marketingConsent,
      navigationNotifications:
          preferences.getBool(_navigationNotificationsKey) ??
          state.navigationNotifications,
      preferGentleSlopes:
          preferences.getBool(_preferGentleSlopesKey) ??
          state.preferGentleSlopes,
      preferSmoothRoads:
          preferences.getBool(_preferSmoothRoadsKey) ?? state.preferSmoothRoads,
      reportNotifications:
          preferences.getBool(_reportNotificationsKey) ??
          state.reportNotifications,
      shareAnonymousContributions:
          preferences.getBool(_shareAnonymousContributionsKey) ??
          state.shareAnonymousContributions,
    );
    _hasRestored = true;
  }

  Future<void> setAvoidStairs(bool value) =>
      _update(state.copyWith(avoidStairs: value));

  Future<void> setCommunityNotifications(bool value) =>
      _update(state.copyWith(communityNotifications: value));

  Future<void> setImpactNotifications(bool value) =>
      _update(state.copyWith(impactNotifications: value));

  Future<void> setMarketingConsent(bool value) =>
      _update(state.copyWith(marketingConsent: value));

  Future<void> setNavigationNotifications(bool value) =>
      _update(state.copyWith(navigationNotifications: value));

  Future<void> setPreferGentleSlopes(bool value) =>
      _update(state.copyWith(preferGentleSlopes: value));

  Future<void> setPreferSmoothRoads(bool value) =>
      _update(state.copyWith(preferSmoothRoads: value));

  Future<void> setReportNotifications(bool value) =>
      _update(state.copyWith(reportNotifications: value));

  Future<void> setShareAnonymousContributions(bool value) =>
      _update(state.copyWith(shareAnonymousContributions: value));

  Future<void> saveSupportMessage(String message) {
    final normalized = message.trim();
    return _update(
      state.copyWith(
        clearLastSupportMessage: normalized.isEmpty,
        lastSupportMessage: normalized.isEmpty ? null : normalized,
      ),
    );
  }

  Future<void> reset() async {
    final preferences = await _client;
    await Future.wait([
      preferences.remove(_avoidStairsKey),
      preferences.remove(_communityNotificationsKey),
      preferences.remove(_impactNotificationsKey),
      preferences.remove(_lastSupportMessageKey),
      preferences.remove(_marketingConsentKey),
      preferences.remove(_navigationNotificationsKey),
      preferences.remove(_preferGentleSlopesKey),
      preferences.remove(_preferSmoothRoadsKey),
      preferences.remove(_reportNotificationsKey),
      preferences.remove(_shareAnonymousContributionsKey),
    ]);
    state = const ProfilePreferencesState.initial();
    _hasRestored = true;
  }

  Future<void> _update(ProfilePreferencesState next) async {
    state = next;
    final preferences = await _client;
    await Future.wait([
      preferences.setBool(_avoidStairsKey, next.avoidStairs),
      preferences.setBool(
        _communityNotificationsKey,
        next.communityNotifications,
      ),
      preferences.setBool(_impactNotificationsKey, next.impactNotifications),
      if (next.lastSupportMessage == null)
        preferences.remove(_lastSupportMessageKey)
      else
        preferences.setString(_lastSupportMessageKey, next.lastSupportMessage!),
      preferences.setBool(_marketingConsentKey, next.marketingConsent),
      preferences.setBool(
        _navigationNotificationsKey,
        next.navigationNotifications,
      ),
      preferences.setBool(_preferGentleSlopesKey, next.preferGentleSlopes),
      preferences.setBool(_preferSmoothRoadsKey, next.preferSmoothRoads),
      preferences.setBool(_reportNotificationsKey, next.reportNotifications),
      preferences.setBool(
        _shareAnonymousContributionsKey,
        next.shareAnonymousContributions,
      ),
    ]);
  }
}

final profilePreferencesProvider =
    NotifierProvider<ProfilePreferencesController, ProfilePreferencesState>(
      ProfilePreferencesController.new,
    );
