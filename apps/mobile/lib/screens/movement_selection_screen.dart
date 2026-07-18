import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_profile_state.dart';

class MovementSelectionScreen extends ConsumerStatefulWidget {
  const MovementSelectionScreen({super.key});

  @override
  ConsumerState<MovementSelectionScreen> createState() =>
      _MovementSelectionScreenState();
}

class _MovementSelectionScreenState
    extends ConsumerState<MovementSelectionScreen> {
  late MovementType _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(demoProfileProvider).movementType;
  }

  void _next() {
    ref.read(demoProfileProvider.notifier).setMovementType(_selected);
    context.push('/routes?movement=${_selected.apiName}');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CompanionScreenHeader(
              subtitle: '나에게 맞는 가장 안전한 길을 찾아드릴게요',
              title: '이동 방식을 알려주세요',
            ),
            const SizedBox(height: 26),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final movement in MovementType.values) ...[
                      _MovementOption(
                        movement: movement,
                        selected: movement == _selected,
                        onTap: () => setState(() => _selected = movement),
                      ),
                      if (movement != MovementType.values.last)
                        const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CompanionPrimaryButton(label: '다음', onPressed: _next),
          ],
        ),
      ),
    ),
  );
}

class _MovementOption extends StatelessWidget {
  const _MovementOption({
    required this.movement,
    required this.onTap,
    required this.selected,
  });

  final MovementType movement;
  final VoidCallback onTap;
  final bool selected;

  String get _title => switch (movement) {
    MovementType.wheelchair => '휠체어',
    MovementType.stroller => '유모차',
    MovementType.walking => '일반 보행',
  };

  String get _description => switch (movement) {
    MovementType.wheelchair => '단차와 경사를 피한 경로로 안내해요',
    MovementType.stroller => '평탄하고 진동이 적은 길을 우선해요',
    MovementType.walking => '가장 빠르고 균형 잡힌 경로예요',
  };

  @override
  Widget build(BuildContext context) => CompanionCard(
    border: selected ? CompanionColors.coral : null,
    onTap: onTap,
    padding: const EdgeInsets.all(18),
    radius: 24,
    semanticLabel: '$_title 선택',
    selected: selected,
    child: Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? CompanionColors.coralSoft
                : CompanionColors.creamMuted,
          ),
          child: SizedBox.square(
            dimension: 52,
            child: Icon(
              movement.icon,
              color: selected ? CompanionColors.coral : CompanionColors.muted,
              size: 25,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(_description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AnimatedContainer(
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 160),
          height: 24,
          width: 24,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? CompanionColors.coral
                  : CompanionColors.creamLine,
              width: 2,
            ),
            color: selected ? CompanionColors.coral : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: selected
              ? const Icon(
                  Icons.check_rounded,
                  color: CompanionColors.white,
                  size: 15,
                )
              : null,
        ),
      ],
    ),
  );
}
