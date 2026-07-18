import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/location_service.dart';
import '../state/providers.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  bool _loading = false;
  LocationAccess? _lastAccess;

  Future<void> _continue() async {
    setState(() => _loading = true);
    try {
      final service = ref.read(locationServiceProvider);
      final current = await service.checkAccess();
      final access = current == LocationAccess.granted
          ? current
          : await service.ensureAccess();
      ref.invalidate(locationAccessProvider);
      if (!mounted) return;
      setState(() {
        _lastAccess = access;
        _loading = false;
      });
      if (access == LocationAccess.granted) context.go('/nickname');
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      showCompanionMessage(context, '권한 상태를 확인하지 못했어요. 다시 시도해 주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiresSettings =
        _lastAccess == LocationAccess.deniedForever ||
        _lastAccess == LocationAccess.serviceDisabled;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Road DNA 시작하기',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                '이동 데이터를 분석해서 더 안전한 길을 찾아드릴게요',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: CompanionColors.muted),
              ),
              const SizedBox(height: 28),
              const _PermissionCard(
                description: '이동 경로를 지도에 기록하기 위해 필요해요',
                icon: Icons.location_on_outlined,
                iconBackground: CompanionColors.greenSoft,
                iconColor: CompanionColors.green,
                title: '위치 정보',
              ),
              const SizedBox(height: 12),
              const _PermissionCard(
                description: '가속도·자이로 센서로 노면 충격을 감지해요',
                icon: Icons.sensors_rounded,
                iconBackground: CompanionColors.amberSoft,
                iconColor: CompanionColors.amber,
                title: '동작 및 센서',
              ),
              const SizedBox(height: 12),
              CompanionCard(
                color: CompanionColors.creamMuted,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                radius: 20,
                child: Text(
                  '개인의 이동경로를 추적하는 게 목적이 아니라, 익명화·집계된 도로 접근성 정보를 만드는 데만 사용해요',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CompanionColors.muted,
                    height: 1.6,
                  ),
                ),
              ),
              if (_lastAccess case final access?) ...[
                const SizedBox(height: 14),
                _PermissionStatus(access: access),
              ],
              const Spacer(),
              CompanionPrimaryButton(
                label: requiresSettings ? '기기 설정 열기' : '동의하고 계속하기',
                loading: _loading,
                onPressed: requiresSettings
                    ? () => ref.read(locationServiceProvider).openSettings()
                    : _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.description,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
  });

  final String description;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) => CompanionCard(
    padding: const EdgeInsets.all(18),
    radius: 22,
    child: Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: iconBackground,
          ),
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, color: iconColor, size: 21),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const CompanionTag(label: '필수'),
      ],
    ),
  );
}

class _PermissionStatus extends StatelessWidget {
  const _PermissionStatus({required this.access});

  final LocationAccess access;

  @override
  Widget build(BuildContext context) {
    final (title, message) = switch (access) {
      LocationAccess.denied => ('위치 권한이 거부됐어요', '다시 눌러 위치 권한을 허용해 주세요.'),
      LocationAccess.deniedForever => (
        '설정에서 권한을 허용해 주세요',
        'Road DNA 위치 권한을 ‘앱 사용 중’으로 바꿔 주세요.',
      ),
      LocationAccess.serviceDisabled => (
        '위치 서비스가 꺼져 있어요',
        '기기 설정에서 GPS를 켠 뒤 다시 시도해 주세요.',
      ),
      LocationAccess.granted => ('준비됐어요', '필요한 권한이 모두 허용됐어요.'),
    };
    final success = access == LocationAccess.granted;
    return CompanionCard(
      color: success ? CompanionColors.greenSoft : CompanionColors.amberSoft,
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Row(
        children: [
          Icon(
            success
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: success ? CompanionColors.green : CompanionColors.amber,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
