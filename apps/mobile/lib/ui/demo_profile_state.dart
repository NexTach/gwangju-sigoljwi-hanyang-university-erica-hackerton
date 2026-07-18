import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models.dart';

@immutable
class DemoProfileState {
  const DemoProfileState({
    required this.movementType,
    required this.nickname,
    required this.onboardingCompleted,
  });

  const DemoProfileState.initial()
    : movementType = MovementType.wheelchair,
      nickname = '미나',
      onboardingCompleted = false;

  final MovementType movementType;
  final String nickname;
  final bool onboardingCompleted;

  DemoProfileState copyWith({
    MovementType? movementType,
    String? nickname,
    bool? onboardingCompleted,
  }) => DemoProfileState(
    movementType: movementType ?? this.movementType,
    nickname: nickname ?? this.nickname,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
  );
}

class _DemoProfileStore {
  _DemoProfileStore([SharedPreferences? preferences])
    : _preferences = preferences;

  static const _completedKey = 'demoProfile.onboardingCompleted';
  static const _movementKey = 'demoProfile.movementType';
  static const _nicknameKey = 'demoProfile.nickname';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _client async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<DemoProfileState?> read() async {
    final preferences = await _client;
    final completed = preferences.getBool(_completedKey) ?? false;
    if (!completed) return null;

    final nickname = preferences.getString(_nicknameKey);
    final movementName = preferences.getString(_movementKey);
    if (nickname == null ||
        nickname.trim().length < 2 ||
        nickname.trim().length > 10 ||
        movementName == null) {
      return null;
    }

    final movementType = MovementType.values.firstWhere(
      (movement) => movement.name == movementName,
      orElse: () => MovementType.wheelchair,
    );
    return DemoProfileState(
      movementType: movementType,
      nickname: nickname.trim(),
      onboardingCompleted: true,
    );
  }

  Future<void> write(DemoProfileState profile) async {
    final preferences = await _client;
    await Future.wait([
      preferences.setString(_movementKey, profile.movementType.name),
      preferences.setString(_nicknameKey, profile.nickname),
    ]);
    await preferences.setBool(_completedKey, true);
  }

  Future<void> clear() async {
    final preferences = await _client;
    await Future.wait([
      preferences.remove(_completedKey),
      preferences.remove(_movementKey),
      preferences.remove(_nicknameKey),
    ]);
  }
}

class DemoProfileController extends Notifier<DemoProfileState> {
  final _store = _DemoProfileStore();

  @override
  DemoProfileState build() => const DemoProfileState.initial();

  Future<bool> restore() async {
    final restored = await _store.read();
    state = restored ?? const DemoProfileState.initial();
    return restored != null;
  }

  Future<void> completeOnboarding(MovementType movementType) async {
    final completed = state.copyWith(
      movementType: movementType,
      onboardingCompleted: true,
    );
    await _store.write(completed);
    state = completed;
  }

  Future<void> setMovementType(MovementType movementType) async {
    final next = state.copyWith(movementType: movementType);
    state = next;
    if (next.onboardingCompleted) {
      await _store.write(next);
    }
  }

  Future<void> setNickname(String nickname) async {
    final normalized = nickname.trim();
    if (normalized.length >= 2 && normalized.length <= 10) {
      final next = state.copyWith(nickname: normalized);
      state = next;
      if (next.onboardingCompleted) {
        await _store.write(next);
      }
    }
  }

  Future<void> reset() async {
    state = const DemoProfileState.initial();
    await _store.clear();
  }
}

final demoProfileProvider =
    NotifierProvider<DemoProfileController, DemoProfileState>(
      DemoProfileController.new,
    );
