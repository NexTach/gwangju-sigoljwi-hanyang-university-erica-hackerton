import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models.dart';

@immutable
class DemoProfileState {
  const DemoProfileState({required this.movementType, required this.nickname});

  const DemoProfileState.initial()
    : movementType = MovementType.wheelchair,
      nickname = '미나';

  final MovementType movementType;
  final String nickname;

  DemoProfileState copyWith({MovementType? movementType, String? nickname}) =>
      DemoProfileState(
        movementType: movementType ?? this.movementType,
        nickname: nickname ?? this.nickname,
      );
}

class DemoProfileController extends Notifier<DemoProfileState> {
  @override
  DemoProfileState build() => const DemoProfileState.initial();

  void setMovementType(MovementType movementType) {
    state = state.copyWith(movementType: movementType);
  }

  void setNickname(String nickname) {
    final normalized = nickname.trim();
    if (normalized.length >= 2 && normalized.length <= 10) {
      state = state.copyWith(nickname: normalized);
    }
  }

  void reset() {
    state = const DemoProfileState.initial();
  }
}

final demoProfileProvider =
    NotifierProvider<DemoProfileController, DemoProfileState>(
      DemoProfileController.new,
    );
