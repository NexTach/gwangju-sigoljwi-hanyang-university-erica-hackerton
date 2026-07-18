import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:road_dna_design/road_dna_design.dart';

import '../services/location_service.dart';
import '../state/providers.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  bool _loading = false;
  LocationAccess? _lastAccess;

  Future<void> _request() async {
    setState(() => _loading = true);
    final access = await ref.read(locationServiceProvider).ensureAccess();
    ref.invalidate(locationAccessProvider);
    if (!mounted) return;
    setState(() {
      _lastAccess = access;
      _loading = false;
    });
    if (access == LocationAccess.granted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final requiresSettings =
        _lastAccess == LocationAccess.deniedForever ||
        _lastAccess == LocationAccess.serviceDisabled;
    return Scaffold(
      appBar: const RdNavigation(title: '측정 준비'),
      bottomNavigationBar: RdBottomCta(
        description: '권한은 도로 분석 중에만 사용하며 원본 센서 데이터는 전송하지 않아요.',
        primary: RdButton(
          fullWidth: true,
          label: requiresSettings ? '기기 설정 열기' : '권한 허용하고 시작',
          loading: _loading,
          onPressed: _loading
              ? null
              : requiresSettings
              ? () => ref.read(locationServiceProvider).openSettings()
              : _request,
          size: RdButtonSize.large,
        ),
        secondary: RdButton(
          label: '둘러보기',
          onPressed: () => context.go('/home'),
          size: RdButtonSize.large,
          tone: RdButtonTone.ghost,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(RdSpacing.x5),
        children: [
          const SizedBox(height: RdSpacing.x5),
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.rdColors.actionSecondary,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 80,
              child: Icon(
                Icons.sensors_rounded,
                color: context.rdColors.actionSecondaryContent,
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: RdSpacing.x6),
          Text(
            '움직임을 도로 정보로\n바꾸기 위해 필요해요',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: RdSpacing.x2),
          Text(
            '측정을 시작하면 휴대폰 안에서 센서 신호를 분석하고, 충격 후보가 나온 위치만 익명으로 전송해요.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.rdColors.contentSecondary,
            ),
          ),
          const SizedBox(height: RdSpacing.x8),
          const RdListRow(
            description: '현재 위치와 이동 여부를 확인해 오탐을 줄여요.',
            leading: Icon(Icons.location_on_outlined),
            title: '위치 권한',
            trailing: RdBadge(label: '필수', tone: RdBadgeTone.info),
          ),
          const RdListRow(
            description: '가속도·자이로 신호는 2초 창으로 기기 안에서 분석해요.',
            leading: Icon(Icons.vibration_rounded),
            title: '모션 센서',
            trailing: RdBadge(label: '기기 내 처리', tone: RdBadgeTone.success),
          ),
          const SizedBox(height: RdSpacing.x5),
          if (_lastAccess == LocationAccess.denied)
            const RdAlert(
              message: '다음 요청에서 위치 권한을 허용하거나 측정 없이 지도를 둘러볼 수 있어요.',
              title: '위치 권한이 거부됐어요',
              tone: RdFeedbackTone.warning,
            ),
          if (_lastAccess == LocationAccess.deniedForever)
            const RdAlert(
              message: '기기 설정에서 Road DNA의 위치 권한을 ‘앱 사용 중’으로 바꿔 주세요.',
              title: '설정에서 권한을 허용해 주세요',
              tone: RdFeedbackTone.warning,
            ),
          if (_lastAccess == LocationAccess.serviceDisabled)
            const RdAlert(
              message: 'GPS를 켠 뒤 Road DNA로 돌아오면 다시 확인할게요.',
              title: '위치 서비스가 꺼져 있어요',
              tone: RdFeedbackTone.warning,
            ),
          if (config.demoMode)
            const Padding(
              padding: EdgeInsets.only(top: RdSpacing.x4),
              child: RdAlert(
                message: 'GPS와 모션 센서 대신 재현 가능한 시뮬레이터를 사용해요.',
                title: '명시적 데모 모드',
              ),
            ),
        ],
      ),
    );
  }
}
