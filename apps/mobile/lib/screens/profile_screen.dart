import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/providers.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_profile_state.dart';
import '../ui/profile_avatar_state.dart';
import '../ui/profile_preferences_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.logout_rounded,
          color: CompanionColors.coralAction,
        ),
        title: const Text('로그아웃할까요?'),
        content: const Text('이 기기의 프로필과 맞춤 설정이 초기화돼요. 산책 기록은 그대로 남아 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await Future.wait([
      ref.read(demoProfileProvider.notifier).reset(),
      ref.read(profileAvatarProvider.notifier).reset(),
      ref.read(profilePreferencesProvider.notifier).reset(),
    ]);
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final profile = ref.watch(demoProfileProvider);
    final contribution = ref.watch(contributionProvider).value;
    final distanceMeters = contribution?.distanceMeters ?? 0;
    final analyzedDistance = distanceMeters > 0
        ? distanceMeters
        : config.demoMode
        ? 8500.0
        : 0.0;
    final sessions = contribution?.sessions ?? 0;
    final events = contribution?.acceptedEvents ?? 0;
    final displayedSessions = sessions > 0
        ? sessions
        : config.demoMode
        ? 4
        : 0;
    final displayedEvents = events > 0
        ? events
        : config.demoMode
        ? 3
        : 0;
    final sharedRoutes = sessions > 0
        ? (sessions / 2).ceil()
        : config.demoMode
        ? 3
        : 0;
    final movementLabel = switch (profile.movementType) {
      final movement when movement.apiName == 'WHEELCHAIR' => '휠체어 이용자',
      final movement when movement.apiName == 'STROLLER' => '유모차 이용자',
      _ => '보행 기여자',
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
          children: [
            Row(
              children: [
                _ProfileAvatarEditor(nickname: profile.nickname, size: 68),
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
                          '발견된 이동 장애 가능 구간 $displayedEvents곳',
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
                    value: '$displayedSessions',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileMetric(
                    label: '공유한 경로',
                    value: '$sharedRoutes',
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
                    icon: Icons.manage_accounts_outlined,
                    label: '프로필 편집',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _ProfileMenuRow(
                    icon: Icons.accessible_forward_rounded,
                    label: '이동수단 및 접근성',
                    onTap: () => context.push('/profile/accessibility'),
                  ),
                  _ProfileMenuRow(
                    icon: Icons.notifications_none_rounded,
                    label: '알림 설정',
                    onTap: () => context.push('/profile/notifications'),
                  ),
                  _ProfileMenuRow(
                    icon: Icons.shield_outlined,
                    label: '데이터 및 개인정보',
                    onTap: () => context.push('/profile/privacy'),
                  ),
                  _ProfileMenuRow(
                    icon: Icons.support_agent_rounded,
                    label: '고객지원',
                    onTap: () => context.push('/profile/support'),
                  ),
                  _ProfileMenuRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Road DNA 소개',
                    onTap: () => context.push('/profile/about'),
                  ),
                  _ProfileMenuRow(
                    danger: true,
                    icon: Icons.logout_rounded,
                    label: '로그아웃',
                    onTap: () => _logout(context, ref),
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

class _ProfileAvatarEditor extends ConsumerStatefulWidget {
  const _ProfileAvatarEditor({required this.nickname, required this.size});

  final String nickname;
  final double size;

  @override
  ConsumerState<_ProfileAvatarEditor> createState() =>
      _ProfileAvatarEditorState();
}

class _ProfileAvatarEditorState extends ConsumerState<_ProfileAvatarEditor> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(profileAvatarProvider.notifier).restore(),
    );
  }

  Future<void> _selectAvatar() async {
    final selected = await showModalBottomSheet<ProfileAvatarStyle>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.88,
        ),
        child: _ProfileAvatarPicker(
          nickname: widget.nickname,
          selected: ref.read(profileAvatarProvider),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await ref.read(profileAvatarProvider.notifier).select(selected);
    if (mounted) showCompanionMessage(context, '프로필 사진을 바꿨어요.');
  }

  @override
  Widget build(BuildContext context) {
    final avatar = ref.watch(profileAvatarProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Semantics(
          key: ValueKey('profile-avatar-display-${avatar.name}'),
          image: true,
          label: '${_avatarLabel(avatar)} 프로필 사진',
          child: _ProfileAvatarVisual(
            nickname: widget.nickname,
            size: widget.size,
            style: avatar,
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Semantics(
            button: true,
            label: '프로필 사진 편집',
            child: SizedBox.square(
              dimension: 30,
              child: IconButton.filled(
                key: const ValueKey('profile-avatar-edit-button'),
                icon: const Icon(Icons.edit_rounded, size: 14),
                onPressed: _selectAvatar,
                padding: EdgeInsets.zero,
                style: companionButtonStyle(
                  IconButton.styleFrom(
                    backgroundColor: CompanionColors.coralAction,
                    foregroundColor: CompanionColors.white,
                    shape: const CircleBorder(
                      side: BorderSide(color: CompanionColors.cream, width: 3),
                    ),
                  ),
                ),
                tooltip: '프로필 사진 편집',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatarPicker extends StatelessWidget {
  const _ProfileAvatarPicker({required this.nickname, required this.selected});

  final String nickname;
  final ProfileAvatarStyle selected;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      key: const ValueKey('profile-avatar-picker-scroll'),
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('프로필 사진 선택', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            '마음에 드는 아바타를 골라주세요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final tileWidth = (constraints.maxWidth - spacing * 2) / 3;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final style in ProfileAvatarStyle.values)
                    SizedBox(
                      width: tileWidth,
                      child: Semantics(
                        button: true,
                        label: '${_avatarLabel(style)} 아바타 선택',
                        selected: style == selected,
                        child: InkWell(
                          key: ValueKey('profile-avatar-${style.name}'),
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.of(context).pop(style),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: style == selected
                                    ? CompanionColors.coralAction
                                    : CompanionColors.creamLine,
                                width: style == selected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              color: CompanionColors.white,
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    6,
                                    12,
                                    6,
                                    10,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _ProfileAvatarVisual(
                                          nickname: nickname,
                                          size: 54,
                                          style: style,
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          _avatarLabel(style),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (style == selected)
                                  const Positioned(
                                    right: 7,
                                    top: 7,
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: CompanionColors.coralAction,
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            '선택한 아바타는 이 기기에 저장돼요.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _ProfileAvatarVisual extends StatelessWidget {
  const _ProfileAvatarVisual({
    required this.nickname,
    required this.size,
    required this.style,
  });

  final String nickname;
  final double size;
  final ProfileAvatarStyle style;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = _avatarAppearance(style);
    final initial = nickname.trim().isEmpty
        ? '?'
        : nickname.trim().characters.first;
    return DecoratedBox(
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: icon == null
              ? Text(
                  initial,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: foreground,
                    fontSize: size * 0.38,
                  ),
                )
              : Icon(icon, color: foreground, size: size * 0.46),
        ),
      ),
    );
  }
}

(Color, Color, IconData?) _avatarAppearance(ProfileAvatarStyle style) =>
    switch (style) {
      ProfileAvatarStyle.initial => (
        CompanionColors.coral,
        CompanionColors.white,
        null,
      ),
      ProfileAvatarStyle.walking => (
        CompanionColors.greenSoft,
        CompanionColors.green,
        Icons.directions_walk_rounded,
      ),
      ProfileAvatarStyle.wheelchair => (
        CompanionColors.coralSoft,
        CompanionColors.coralAction,
        Icons.accessible_forward_rounded,
      ),
      ProfileAvatarStyle.stroller => (
        CompanionColors.amberSoft,
        CompanionColors.amber,
        Icons.child_friendly_rounded,
      ),
      ProfileAvatarStyle.navigation => (
        CompanionColors.green,
        CompanionColors.white,
        Icons.navigation_rounded,
      ),
      ProfileAvatarStyle.neighborhood => (
        CompanionColors.creamMuted,
        CompanionColors.ink,
        Icons.map_rounded,
      ),
    };

String _avatarLabel(ProfileAvatarStyle style) => switch (style) {
  ProfileAvatarStyle.initial => '이니셜',
  ProfileAvatarStyle.walking => '산책',
  ProfileAvatarStyle.wheelchair => '휠체어',
  ProfileAvatarStyle.stroller => '유모차',
  ProfileAvatarStyle.navigation => '길 찾기',
  ProfileAvatarStyle.neighborhood => '동네 지도',
};

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
