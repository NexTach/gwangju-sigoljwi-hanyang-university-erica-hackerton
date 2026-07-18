import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_profile_state.dart';
import '../ui/profile_preferences_state.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _nicknameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: ref.read(demoProfileProvider).nickname,
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.length < 2 || nickname.length > 10) {
      showCompanionMessage(context, '닉네임은 2~10자로 입력해 주세요.');
      return;
    }
    setState(() => _saving = true);
    await ref.read(demoProfileProvider.notifier).setNickname(nickname);
    if (!mounted) return;
    showCompanionMessage(context, '프로필을 저장했어요.');
    _goBack(context);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(demoProfileProvider);
    return _ProfileSettingsScaffold(
      title: '프로필 편집',
      subtitle: '길 위에서 함께 사용할 이름을 바꿀 수 있어요',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: CompanionColors.coral,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 88,
                child: Center(
                  child: Text(
                    profile.nickname.characters.first,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: CompanionColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text('닉네임', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('profile-nickname-field'),
            controller: _nicknameController,
            maxLength: 10,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              counterText: '',
              hintText: '2~10자로 입력해 주세요',
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          Text(
            '커뮤니티 글과 산책 리포트에 이 이름이 표시돼요.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 30),
          CompanionPrimaryButton(
            key: const ValueKey('save-profile-button'),
            label: '저장',
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class AccessibilitySettingsScreen extends ConsumerStatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  ConsumerState<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends ConsumerState<AccessibilitySettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(profilePreferencesProvider.notifier).restore(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(demoProfileProvider);
    final preferences = ref.watch(profilePreferencesProvider);
    final controller = ref.read(profilePreferencesProvider.notifier);
    return _ProfileSettingsScaffold(
      title: '이동수단 및 접근성',
      subtitle: '선택한 조건은 다음 경로 계산부터 바로 반영돼요',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(label: '이동수단'),
          const SizedBox(height: 10),
          for (final movement in MovementType.values) ...[
            _MovementPreferenceCard(
              movement: movement,
              selected: profile.movementType == movement,
              onTap: () async {
                await ref
                    .read(demoProfileProvider.notifier)
                    .setMovementType(movement);
                if (!context.mounted) return;
                showCompanionMessage(
                  context,
                  '${_movementTitle(movement)} 기준으로 경로를 맞췄어요.',
                );
              },
            ),
            if (movement != MovementType.values.last)
              const SizedBox(height: 10),
          ],
          const SizedBox(height: 26),
          _SectionLabel(label: '경로 선호'),
          const SizedBox(height: 10),
          _SettingsGroup(
            children: [
              _PreferenceSwitch(
                description: '포장 상태와 반복 충격 기록이 좋은 길을 우선해요',
                icon: Icons.route_rounded,
                key: const ValueKey('prefer-smooth-roads-switch'),
                onChanged: controller.setPreferSmoothRoads,
                title: '평탄한 길 우선',
                value: preferences.preferSmoothRoads,
              ),
              _PreferenceSwitch(
                description: '계단이 포함된 길을 경로 후보에서 제외해요',
                icon: Icons.stairs_rounded,
                key: const ValueKey('avoid-stairs-switch'),
                onChanged: controller.setAvoidStairs,
                title: '계단 피하기',
                value: preferences.avoidStairs,
              ),
              _PreferenceSwitch(
                description: '조금 더 멀어도 급경사가 적은 길을 찾아요',
                icon: Icons.landscape_outlined,
                key: const ValueKey('gentle-slopes-switch'),
                onChanged: controller.setPreferGentleSlopes,
                title: '완만한 경사 우선',
                value: preferences.preferGentleSlopes,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InlineNotice(
            icon: Icons.auto_awesome_rounded,
            text:
                '${_movementTitle(profile.movementType)} · '
                '${_enabledPreferenceCount(preferences)}개 경로 조건 적용 중',
          ),
        ],
      ),
    );
  }
}

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(profilePreferencesProvider.notifier).restore(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(profilePreferencesProvider);
    final controller = ref.read(profilePreferencesProvider.notifier);
    return _ProfileSettingsScaffold(
      title: '알림 설정',
      subtitle: '필요한 순간에만 소식을 받을 수 있어요',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsGroup(
            children: [
              _PreferenceSwitch(
                description: '산책 중 경로 변경과 주의 구간을 알려드려요',
                icon: Icons.navigation_outlined,
                key: const ValueKey('navigation-notifications-switch'),
                onChanged: controller.setNavigationNotifications,
                title: '이동 안내',
                value: preferences.navigationNotifications,
              ),
              _PreferenceSwitch(
                description: '반복 충격이 감지되면 진동과 알림으로 알려드려요',
                icon: Icons.vibration_rounded,
                key: const ValueKey('impact-notifications-switch'),
                onChanged: controller.setImpactNotifications,
                title: '충격 감지',
                value: preferences.impactNotifications,
              ),
              _PreferenceSwitch(
                description: '산책을 마치면 분석 결과를 알려드려요',
                icon: Icons.insights_outlined,
                key: const ValueKey('report-notifications-switch'),
                onChanged: controller.setReportNotifications,
                title: '산책 리포트',
                value: preferences.reportNotifications,
              ),
              _PreferenceSwitch(
                description: '내가 확인한 길에 새 소식이 생기면 알려드려요',
                icon: Icons.people_outline_rounded,
                key: const ValueKey('community-notifications-switch'),
                onChanged: controller.setCommunityNotifications,
                title: '동네 소식',
                value: preferences.communityNotifications,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _InlineNotice(
            icon: Icons.phone_android_rounded,
            text: '휴대전화에서 Road DNA 알림 권한이 꺼져 있으면 알림이 보이지 않을 수 있어요.',
          ),
        ],
      ),
    );
  }
}

class PrivacyTermsScreen extends ConsumerStatefulWidget {
  const PrivacyTermsScreen({super.key});

  @override
  ConsumerState<PrivacyTermsScreen> createState() => _PrivacyTermsScreenState();
}

class _PrivacyTermsScreenState extends ConsumerState<PrivacyTermsScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(profilePreferencesProvider.notifier).restore(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(profilePreferencesProvider);
    final controller = ref.read(profilePreferencesProvider.notifier);
    return _ProfileSettingsScaffold(
      title: '데이터 및 개인정보',
      subtitle: '수집 항목과 동의 내용을 언제든 확인하고 바꿀 수 있어요',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(label: '데이터 설정'),
          const SizedBox(height: 10),
          _SettingsGroup(
            children: [
              _PreferenceSwitch(
                description: '익명화한 충격 위치와 도로 점수를 동네 지도에 반영해요',
                icon: Icons.public_rounded,
                key: const ValueKey('anonymous-contributions-switch'),
                onChanged: controller.setShareAnonymousContributions,
                title: '익명 이동 데이터 공유',
                value: preferences.shareAnonymousContributions,
              ),
              _PreferenceSwitch(
                description: 'Road DNA의 새로운 기능과 캠페인 소식을 받아요',
                icon: Icons.campaign_outlined,
                key: const ValueKey('marketing-consent-switch'),
                onChanged: controller.setMarketingConsent,
                title: '마케팅 정보 수신',
                value: preferences.marketingConsent,
              ),
            ],
          ),
          const SizedBox(height: 26),
          _SectionLabel(label: '약관 및 정책'),
          const SizedBox(height: 10),
          _SettingsGroup(
            children: [
              for (final policy in _policies)
                _SettingsAction(
                  description: policy.summary,
                  icon: policy.icon,
                  onTap: () => _showPolicy(context, policy),
                  title: policy.title,
                ),
            ],
          ),
          const SizedBox(height: 14),
          const _InlineNotice(
            icon: Icons.shield_outlined,
            text: '센서 원본 신호는 기기에서 분석하며 서버에는 전송하지 않아요.',
          ),
        ],
      ),
    );
  }
}

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      await ref.read(profilePreferencesProvider.notifier).restore();
      if (!mounted || _messageController.text.isNotEmpty) return;
      _messageController.text =
          ref.read(profilePreferencesProvider).lastSupportMessage ?? '';
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.length < 10) {
      showCompanionMessage(context, '문의 내용을 10자 이상 입력해 주세요.');
      return;
    }
    setState(() => _submitting = true);
    await ref
        .read(profilePreferencesProvider.notifier)
        .saveSupportMessage(message);
    if (!mounted) return;
    setState(() => _submitting = false);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('문의 내용을 저장했어요'),
        content: const Text(
          '작성한 내용은 이 기기에 보관돼요. 답변이 필요한 경우 support@roaddna.kr로 보내주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _ProfileSettingsScaffold(
    title: '고객지원',
    subtitle: '자주 묻는 내용을 확인하거나 의견을 남겨주세요',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(label: '자주 묻는 질문'),
        const SizedBox(height: 10),
        _SettingsGroup(
          children: const [
            _SupportQuestion(
              answer:
                  '휴대전화의 위치 권한과 정확한 위치가 모두 켜져 있는지 확인해 주세요. '
                  '실내에서는 GPS 신호가 약할 수 있어요.',
              question: '산책 중 위치가 움직이지 않아요',
            ),
            _SupportQuestion(
              answer:
                  '갑작스러운 충격을 감지한 뒤 같은 위치의 반복 신호와 이동 속도를 함께 분석해요. '
                  '휴대전화를 떨어뜨린 것으로 판단하면 기록에서 제외해요.',
              question: '충격 지점은 어떻게 기록하나요?',
            ),
            _SupportQuestion(
              answer:
                  '프로필의 이동수단 및 접근성에서 평탄한 길, 계단, 경사 선호를 바꾸면 '
                  '다음 경로 계산부터 적용돼요.',
              question: '맞춤 경로 기준을 바꾸고 싶어요',
            ),
          ],
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(child: _SectionLabel(label: '문의 남기기')),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  const ClipboardData(text: 'support@roaddna.kr'),
                );
                if (!context.mounted) return;
                showCompanionMessage(context, '고객지원 이메일을 복사했어요.');
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('이메일 복사'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('support-message-field'),
          controller: _messageController,
          maxLength: 500,
          maxLines: 6,
          minLines: 4,
          decoration: const InputDecoration(
            alignLabelWithHint: true,
            hintText: '이용 중 불편했던 점이나 궁금한 내용을 적어주세요.',
            filled: true,
            fillColor: CompanionColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              borderSide: BorderSide(color: CompanionColors.creamLine),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              borderSide: BorderSide(color: CompanionColors.creamLine),
            ),
          ),
        ),
        const SizedBox(height: 12),
        CompanionPrimaryButton(
          key: const ValueKey('save-support-message-button'),
          label: '문의 내용 저장',
          loading: _submitting,
          onPressed: _submit,
        ),
      ],
    ),
  );
}

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) => _ProfileSettingsScaffold(
    title: 'Road DNA 소개',
    subtitle: '이동의 흔적으로 더 편안한 도시 길을 만들어요',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompanionCard(
          color: CompanionColors.green,
          padding: const EdgeInsets.all(24),
          radius: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.route_rounded,
                color: CompanionColors.white,
                size: 32,
              ),
              const SizedBox(height: 20),
              Text(
                '모두가 지나갈 수 있는 길은\n이동의 기록에서 시작돼요.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: CompanionColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Road DNA는 이동 중 발생한 충격과 위치를 분석해 '
                '휠체어·유모차·보행자에게 더 편안한 경로를 안내합니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: CompanionColors.white.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SettingsGroup(
          children: [
            const _SettingsValue(
              icon: Icons.android_rounded,
              title: '앱 버전',
              value: '0.1.4',
            ),
            _SettingsAction(
              description: '최근 추가된 기능과 변경 내용을 확인해요',
              icon: Icons.new_releases_outlined,
              onTap: () => _showReleaseNotes(context),
              title: '업데이트 내역',
            ),
            _SettingsAction(
              description: '앱에서 사용하는 오픈소스 소프트웨어예요',
              icon: Icons.code_rounded,
              onTap: () => showLicensePage(
                applicationIcon: const Icon(
                  Icons.route_rounded,
                  color: CompanionColors.coralAction,
                  size: 42,
                ),
                applicationLegalese: '© 2026 Road DNA',
                applicationName: 'Road DNA',
                applicationVersion: '0.1.4',
                context: context,
              ),
              title: '오픈소스 라이선스',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Made for accessible Gwangju',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: CompanionColors.green,
            letterSpacing: 0.4,
          ),
        ),
      ],
    ),
  );
}

class _ProfileSettingsScaffold extends StatelessWidget {
  const _ProfileSettingsScaffold({
    required this.child,
    required this.subtitle,
    required this.title,
  });

  final Widget child;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        children: [
          CompanionScreenHeader(
            onBack: () => _goBack(context),
            subtitle: subtitle,
            title: title,
          ),
          const SizedBox(height: 26),
          child,
        ],
      ),
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: Material(
      color: CompanionColors.white,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Divider(
                color: CompanionColors.creamMuted,
                height: 1,
                indent: 58,
              ),
          ],
        ],
      ),
    ),
  );
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.description,
    required this.icon,
    required this.onChanged,
    required this.title,
    required this.value,
    super.key,
  });

  final String description;
  final IconData icon;
  final ValueChanged<bool> onChanged;
  final String title;
  final bool value;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: const EdgeInsets.fromLTRB(16, 7, 10, 7),
    secondary: Icon(icon, color: CompanionColors.green, size: 21),
    subtitle: Text(description, style: Theme.of(context).textTheme.bodySmall),
    title: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    value: value,
    onChanged: onChanged,
  );
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
    required this.description,
    required this.icon,
    required this.onTap,
    required this.title,
  });

  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final String title;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.fromLTRB(16, 7, 12, 7),
    leading: Icon(icon, color: CompanionColors.green, size: 21),
    onTap: onTap,
    subtitle: Text(description, style: Theme.of(context).textTheme.bodySmall),
    title: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      color: CompanionColors.muted,
      size: 19,
    ),
  );
}

class _SettingsValue extends StatelessWidget {
  const _SettingsValue({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
    leading: Icon(icon, color: CompanionColors.green, size: 21),
    title: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    trailing: Text(value, style: Theme.of(context).textTheme.labelMedium),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      color: CompanionColors.muted,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CompanionColors.greenSoft,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: CompanionColors.green, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: CompanionColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MovementPreferenceCard extends StatelessWidget {
  const _MovementPreferenceCard({
    required this.movement,
    required this.onTap,
    required this.selected,
  });

  final MovementType movement;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => CompanionCard(
    border: selected ? CompanionColors.coral : null,
    onTap: onTap,
    padding: const EdgeInsets.all(16),
    radius: 20,
    semanticLabel: '${_movementTitle(movement)} 이동수단',
    selected: selected,
    child: Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? CompanionColors.coralSoft
                : CompanionColors.creamMuted,
            borderRadius: BorderRadius.circular(15),
          ),
          child: SizedBox.square(
            dimension: 44,
            child: Icon(
              movement.icon,
              color: selected
                  ? CompanionColors.coralAction
                  : CompanionColors.muted,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _movementTitle(movement),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                _movementDescription(movement),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Icon(
          selected
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: selected ? CompanionColors.coralAction : CompanionColors.faint,
        ),
      ],
    ),
  );
}

class _SupportQuestion extends StatelessWidget {
  const _SupportQuestion({required this.answer, required this.question});

  final String answer;
  final String question;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
    collapsedIconColor: CompanionColors.muted,
    iconColor: CompanionColors.coralAction,
    shape: const Border(),
    title: Text(
      question,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(answer, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}

class _Policy {
  const _Policy({
    required this.body,
    required this.icon,
    required this.summary,
    required this.title,
  });

  final String body;
  final IconData icon;
  final String summary;
  final String title;
}

const _policies = [
  _Policy(
    body:
        'Road DNA는 접근 가능한 경로 안내, 이동 중 충격 분석, 산책 리포트 제공을 위해 '
        '서비스를 운영합니다.\n\n이용자는 측정을 언제든 중지할 수 있으며 다른 사람의 권리를 '
        '침해하는 내용은 커뮤니티에 게시할 수 없습니다.',
    icon: Icons.description_outlined,
    summary: '서비스 이용 조건과 이용자의 권리를 확인해요',
    title: '서비스 이용약관',
  ),
  _Policy(
    body:
        '기기에 저장하는 정보: 닉네임, 이동수단, 경로 선호, 알림 설정.\n\n'
        '서버로 전송할 수 있는 정보: 익명 식별자, 충격이 감지된 위치, 도로 구간, 충격 단계. '
        '가속도·자이로 센서의 원본 신호는 기기에서 분석한 뒤 폐기합니다.',
    icon: Icons.privacy_tip_outlined,
    summary: '어떤 정보를 수집하고 보관하는지 확인해요',
    title: '개인정보 처리방침',
  ),
  _Policy(
    body:
        '위치 정보는 산책 경로 기록과 충격 발생 도로 구간 확인에 사용합니다. '
        '산책 측정을 시작한 동안에만 위치를 처리하며 측정을 종료하면 추적을 멈춥니다.\n\n'
        '위치 권한은 휴대전화 설정에서 언제든 철회할 수 있습니다.',
    icon: Icons.location_on_outlined,
    summary: '산책 중 위치 정보가 쓰이는 방식을 확인해요',
    title: '위치기반서비스 이용약관',
  ),
];

int _enabledPreferenceCount(ProfilePreferencesState preferences) => [
  preferences.preferSmoothRoads,
  preferences.avoidStairs,
  preferences.preferGentleSlopes,
].where((enabled) => enabled).length;

String _movementDescription(MovementType movement) => switch (movement) {
  MovementType.wheelchair => '단차와 급경사를 적극적으로 피해요',
  MovementType.stroller => '진동이 적고 완만한 길을 우선해요',
  MovementType.walking => '안전성과 이동 시간을 균형 있게 봐요',
};

String _movementTitle(MovementType movement) => switch (movement) {
  MovementType.wheelchair => '휠체어',
  MovementType.stroller => '유모차',
  MovementType.walking => '일반 보행',
};

void _goBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/profile');
  }
}

void _showPolicy(BuildContext context, _Policy policy) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.58,
        maxChildSize: 0.88,
        minChildSize: 0.38,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          children: [
            Icon(policy.icon, color: CompanionColors.green, size: 30),
            const SizedBox(height: 16),
            Text(
              policy.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(policy.body, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            CompanionPrimaryButton(
              label: '확인',
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showReleaseNotes(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Road DNA 0.1.4',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const _ReleaseNote(text: '용봉동 실제 보행도로 기반 경로 안내'),
            const _ReleaseNote(text: '이동 중 충격 지점 자동 감지와 산책 리포트'),
            const _ReleaseNote(text: '휠체어·유모차·보행 맞춤 경로 비교'),
            const SizedBox(height: 18),
            CompanionPrimaryButton(
              label: '확인',
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReleaseNote extends StatelessWidget {
  const _ReleaseNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: CompanionColors.green,
          size: 18,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}
