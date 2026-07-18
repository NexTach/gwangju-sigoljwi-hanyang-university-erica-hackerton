import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/providers.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_profile_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editNickname(
    BuildContext context,
    WidgetRef ref,
    String currentNickname,
  ) async {
    final controller = TextEditingController(text: currentNickname);
    final nickname = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 10, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '뭐라고 불러드릴까요?',
                  style: Theme.of(sheetContext).textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                TextField(
                  autofocus: true,
                  controller: controller,
                  maxLength: 10,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    counterText: '',
                    helperText: '2~10자로 입력해주세요',
                  ),
                  onSubmitted: (_) =>
                      _submitNickname(sheetContext, controller.text),
                ),
                const SizedBox(height: 20),
                CompanionPrimaryButton(
                  label: '저장',
                  onPressed: () =>
                      _submitNickname(sheetContext, controller.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
    if (nickname == null) return;
    await ref.read(demoProfileProvider.notifier).setNickname(nickname);
  }

  void _submitNickname(BuildContext context, String value) {
    final nickname = value.trim();
    if (nickname.length < 2 || nickname.length > 10) {
      showCompanionMessage(context, '닉네임은 2~10자로 입력해 주세요.');
      return;
    }
    Navigator.of(context).pop(nickname);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(demoProfileProvider);
    final contribution = ref.watch(contributionProvider).value;
    final distanceMeters = contribution?.distanceMeters ?? 0;
    final analyzedDistance = distanceMeters > 0 ? distanceMeters : 1800.0;
    final sessions = contribution?.sessions ?? 0;
    final events = contribution?.acceptedEvents ?? 0;
    final movementLabel = switch (profile.movementType) {
      final movement when movement.apiName == 'WHEELCHAIR' => '휠체어 이용자',
      final movement when movement.apiName == 'STROLLER' => '유모차 이용자',
      _ => '보행 기여자',
    };

    return Scaffold(
      bottomNavigationBar: const CompanionBottomNav(
        current: CompanionTab.profile,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        color: CompanionColors.coral,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: 68,
                        child: Center(
                          child: Text(
                            profile.nickname.characters.first,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(color: CompanionColors.white),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Semantics(
                        button: true,
                        label: '프로필 이름 편집',
                        child: SizedBox.square(
                          dimension: 30,
                          child: IconButton.filled(
                            icon: const Icon(Icons.edit_rounded, size: 14),
                            onPressed: () =>
                                _editNickname(context, ref, profile.nickname),
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor: CompanionColors.coralAction,
                              foregroundColor: CompanionColors.white,
                              shape: const CircleBorder(
                                side: BorderSide(
                                  color: CompanionColors.cream,
                                  width: 3,
                                ),
                              ),
                            ),
                            tooltip: '프로필 이름 편집',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.nickname,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      CompanionTag(
                        backgroundColor: CompanionColors.greenSoft,
                        foregroundColor: CompanionColors.green,
                        label: movementLabel,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CompanionCard(
              padding: const EdgeInsets.all(21),
              radius: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY IMPACT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: CompanionColors.greenBright,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '당신의 이동으로\n${(analyzedDistance / 1000).toStringAsFixed(1)}km의 새로운 길이 분석됐어요',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          color: CompanionColors.amberSoft,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(
                          dimension: 30,
                          child: Icon(
                            Icons.error_outline_rounded,
                            color: CompanionColors.amber,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '발견된 이동 장애 가능 구간 ${events > 0 ? events : 3}곳',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ProfileMetric(
                    label: '누적 산책',
                    value: '${sessions > 0 ? sessions : 142}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileMetric(
                    label: '공유한 경로',
                    value: '${sessions > 0 ? (sessions / 2).ceil() : 37}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  _ProfileMenuRow(
                    icon: Icons.accessible_forward_rounded,
                    label: '접근성 설정',
                    onTap: () => showCompanionMessage(
                      context,
                      '$movementLabel로 맞춤 경로를 안내하고 있어요.',
                    ),
                  ),
                  _ProfileMenuRow(
                    icon: Icons.notifications_none_rounded,
                    label: '알림 설정',
                    onTap: () =>
                        showCompanionMessage(context, '이동 안내 알림이 켜져 있어요.'),
                  ),
                  _ProfileMenuRow(
                    icon: Icons.shield_outlined,
                    label: '데이터 및 개인정보',
                    onTap: () => showCompanionMessage(
                      context,
                      '원본 센서 신호는 기기 밖으로 전송하지 않아요.',
                    ),
                  ),
                  _ProfileMenuRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Road DNA 소개',
                    onTap: () => showCompanionMessage(
                      context,
                      '이동의 흔적으로 더 편안한 도시 길을 만들어요.',
                    ),
                  ),
                  _ProfileMenuRow(
                    danger: true,
                    icon: Icons.logout_rounded,
                    label: '로그아웃',
                    onTap: () async {
                      await ref.read(demoProfileProvider.notifier).reset();
                      if (!context.mounted) return;
                      context.go('/login');
                    },
                    showDivider: false,
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

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => CompanionCard(
    padding: const EdgeInsets.all(17),
    radius: 22,
    child: Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.showDivider = true,
  });

  final bool danger;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Material(
    color: CompanionColors.white,
    child: InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(color: CompanionColors.creamMuted),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 15),
        child: Row(
          children: [
            Icon(
              icon,
              color: danger ? CompanionColors.red : CompanionColors.muted,
              size: 19,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: danger ? CompanionColors.red : CompanionColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: CompanionColors.muted,
              size: 18,
            ),
          ],
        ),
      ),
    ),
  );
}
