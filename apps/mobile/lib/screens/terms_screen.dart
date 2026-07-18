import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/profile_preferences_state.dart';

class TermsScreen extends ConsumerStatefulWidget {
  const TermsScreen({super.key});

  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  bool _ageAgreed = true;
  bool _locationAgreed = true;
  bool _marketingAgreed = false;
  bool _privacyAgreed = true;
  bool _serviceAgreed = true;

  bool get _requiredAgreed =>
      _ageAgreed && _serviceAgreed && _privacyAgreed && _locationAgreed;

  bool get _allAgreed => _requiredAgreed && _marketingAgreed;

  void _toggleAll() {
    final next = !_allAgreed;
    setState(() {
      _ageAgreed = next;
      _serviceAgreed = next;
      _privacyAgreed = next;
      _locationAgreed = next;
      _marketingAgreed = next;
    });
  }

  void _showTerms(_TermsDetail detail) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CompanionColors.cream,
      clipBehavior: Clip.antiAlias,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: _TermsDetailSheet(detail: detail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 22),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BackLink(onTap: () => context.go('/permission')),
                  const SizedBox(height: 22),
                  Text(
                    '약관에 동의해주세요',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '여러분의 개인정보와 이동 데이터를\n안전하게 지켜드릴게요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CompanionColors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    key: const ValueKey('terms-agreement-all'),
                    checked: _allAgreed,
                    child: CompanionCard(
                      onTap: _toggleAll,
                      padding: const EdgeInsets.all(18),
                      radius: 22,
                      semanticLabel: '전체 약관 모두 동의',
                      child: Row(
                        children: [
                          _AgreementMark(checked: _allAgreed, filled: true),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '모두 동의',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '필수 및 선택 약관에 모두 동의합니다',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Column(
                      children: [
                        _AgreementRow(
                          checked: _ageAgreed,
                          label: '(필수) 만 14세 이상입니다',
                          onChanged: (value) =>
                              setState(() => _ageAgreed = value),
                          semanticsKey: const ValueKey('terms-agreement-age'),
                        ),
                        _AgreementRow(
                          checked: _serviceAgreed,
                          label: '(필수) 서비스 이용약관 동의',
                          onChanged: (value) =>
                              setState(() => _serviceAgreed = value),
                          onView: () => _showTerms(_serviceTerms),
                          semanticsKey: const ValueKey(
                            'terms-agreement-service',
                          ),
                          viewKey: const ValueKey('terms-view-service'),
                        ),
                        _AgreementRow(
                          checked: _privacyAgreed,
                          label: '(필수) 개인정보 처리방침 동의',
                          onChanged: (value) =>
                              setState(() => _privacyAgreed = value),
                          onView: () => _showTerms(_privacyTerms),
                          semanticsKey: const ValueKey(
                            'terms-agreement-privacy',
                          ),
                          viewKey: const ValueKey('terms-view-privacy'),
                        ),
                        _AgreementRow(
                          checked: _locationAgreed,
                          label: '(필수) 위치·센서 정보 수집 동의',
                          onChanged: (value) =>
                              setState(() => _locationAgreed = value),
                          onView: () => _showTerms(_locationTerms),
                          semanticsKey: const ValueKey(
                            'terms-agreement-location',
                          ),
                          viewKey: const ValueKey('terms-view-location'),
                        ),
                        _AgreementRow(
                          checked: _marketingAgreed,
                          label: '(선택) 마케팅 정보 수신 동의',
                          onChanged: (value) =>
                              setState(() => _marketingAgreed = value),
                          onView: () => _showTerms(_marketingTerms),
                          semanticsKey: const ValueKey(
                            'terms-agreement-marketing',
                          ),
                          viewKey: const ValueKey('terms-view-marketing'),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 20),
                  CompanionPrimaryButton(
                    label: '다음',
                    onPressed: _requiredAgreed
                        ? () async {
                            await ref
                                .read(profilePreferencesProvider.notifier)
                                .setMarketingConsent(_marketingAgreed);
                            if (!context.mounted) return;
                            context.go('/nickname');
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Semantics(
      button: true,
      excludeSemantics: true,
      label: '돌아가기',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const SizedBox(
          height: 44,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chevron_left_rounded,
                color: CompanionColors.coralAction,
                size: 22,
              ),
              SizedBox(width: 2),
              Text(
                '돌아가기',
                style: TextStyle(
                  color: CompanionColors.coralAction,
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.checked,
    required this.label,
    required this.onChanged,
    this.onView,
    this.semanticsKey,
    this.showDivider = true,
    this.viewKey,
  });

  final bool checked;
  final String label;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onView;
  final Key? semanticsKey;
  final bool showDivider;
  final Key? viewKey;

  @override
  Widget build(BuildContext context) => Material(
    color: CompanionColors.white,
    child: InkWell(
      onTap: () => onChanged(!checked),
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(color: CompanionColors.creamMuted),
                )
              : null,
        ),
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
        child: Row(
          children: [
            Semantics(
              key: semanticsKey,
              checked: checked,
              child: _AgreementMark(checked: checked),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: checked ? CompanionColors.ink : CompanionColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onView != null)
              TextButton(
                key: viewKey,
                onPressed: onView,
                style: companionButtonStyle(
                  TextButton.styleFrom(
                    foregroundColor: CompanionColors.muted,
                    minimumSize: const Size(48, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                child: const Text('보기'),
              ),
          ],
        ),
      ),
    ),
  );
}

class _TermsDetailSheet extends StatelessWidget {
  const _TermsDetailSheet({required this.detail});

  final _TermsDetail detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 12),
      Center(
        child: Container(
          height: 4,
          width: 40,
          decoration: BoxDecoration(
            color: CompanionColors.creamLine,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.category,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: CompanionColors.coralAction,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            IconButton(
              key: const ValueKey('terms-detail-close'),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: '약관 상세 닫기',
              icon: const Icon(Icons.close_rounded),
              color: CompanionColors.ink,
            ),
          ],
        ),
      ),
      const Divider(height: 1, color: CompanionColors.creamLine),
      Expanded(
        child: SingleChildScrollView(
          key: const ValueKey('terms-detail-scroll'),
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: detail.accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(detail.icon, color: detail.iconColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '핵심 요약',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: detail.iconColor),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            detail.summary,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: CompanionColors.ink,
                                  height: 1.55,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              for (var index = 0; index < detail.sections.length; index++) ...[
                _TermsDetailSection(section: detail.sections[index]),
                if (index != detail.sections.length - 1)
                  const SizedBox(height: 24),
              ],
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: CompanionColors.creamLine),
                  borderRadius: BorderRadius.circular(18),
                  color: CompanionColors.white,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: CompanionColors.coralAction,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '해커톤 데모용 요약이며 정식 법률 문서가 아닙니다. '
                        '실제 서비스 출시 전에는 관련 법률 검토와 정식 약관, '
                        '문의·삭제 요청 창구가 별도로 마련되어야 합니다.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: CompanionColors.muted,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _TermsDetailSection extends StatelessWidget {
  const _TermsDetailSection({required this.section});

  final _TermsSection section;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(section.title, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 10),
      for (var index = 0; index < section.items.length; index++) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 5,
              width: 5,
              margin: const EdgeInsets.only(top: 7),
              decoration: const BoxDecoration(
                color: CompanionColors.coralAction,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                section.items[index],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: CompanionColors.muted,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
        if (index != section.items.length - 1) const SizedBox(height: 9),
      ],
    ],
  );
}

@immutable
class _TermsDetail {
  const _TermsDetail({
    required this.accentColor,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.sections,
    required this.summary,
    required this.title,
  });

  final Color accentColor;
  final String category;
  final IconData icon;
  final Color iconColor;
  final List<_TermsSection> sections;
  final String summary;
  final String title;
}

@immutable
class _TermsSection {
  const _TermsSection({required this.items, required this.title});

  final List<String> items;
  final String title;
}

const _serviceTerms = _TermsDetail(
  accentColor: CompanionColors.coralSoft,
  category: '필수 약관',
  icon: Icons.route_outlined,
  iconColor: CompanionColors.coralAction,
  title: '서비스 이용약관',
  summary:
      'Road DNA는 이동 유형과 주변 도로 데이터를 바탕으로 걷기 편한 경로를 '
      '비교하고, 산책 중 감지된 도로 상태를 이웃과 함께 확인하는 해커톤 데모입니다.',
  sections: [
    _TermsSection(
      title: '수집·이용 항목',
      items: [
        '데모 로그인 선택, 닉네임, 휠체어·유모차·보행 중 선택한 이동 유형을 이용합니다. '
            '구글·카카오 버튼은 현재 실제 계정 인증을 수행하지 않습니다.',
        '경로 비교 결과, 산책 세션과 리포트, 도로 점수, 직접 작성한 커뮤니티 글과 '
            '확인 반응을 서비스 화면 구성에 이용합니다.',
      ],
    ),
    _TermsSection(
      title: '이용 목적',
      items: [
        '이동 유형에 맞는 경로 비교, 위험 가능 구간 안내, 산책 기록 요약과 '
            '주변 도로 정보 제공에 이용합니다.',
        '커뮤니티에 직접 등록한 도로 상황을 다른 이용자에게 보여주고, '
            '여러 사람의 확인을 통해 상태를 갱신하는 데 이용합니다.',
      ],
    ),
    _TermsSection(
      title: '이용 시 유의사항',
      items: [
        'Road DNA Score와 위험 알림은 센서·위치 기반의 실험적 참고 정보이며 '
            '도로의 안전이나 통행 가능성을 보장하지 않습니다.',
        '보행 환경을 판단하는 유일한 안전 수단으로 사용하면 안 돼요. '
            '현장 표지와 실제 도로 상태를 함께 확인해주세요.',
      ],
    ),
    _TermsSection(
      title: '보유·삭제 및 철회',
      items: [
        '닉네임과 이동 유형은 기기에 저장되며 로그아웃하거나 앱 데이터를 삭제하면 '
            '초기화됩니다. 데모에서 추가한 리포트와 커뮤니티 글은 앱 실행 중에만 유지됩니다.',
        '익명 UUID는 재실행 시 같은 기기를 구분하기 위해 앱의 보안 저장소에 남으며, '
            '앱 데이터 삭제 또는 앱 제거 시 함께 삭제됩니다.',
        '동의하지 않으면 서비스를 시작하지 않을 수 있고, 동의 후에는 로그아웃하거나 '
            '앱을 삭제해 이용을 중단할 수 있습니다.',
      ],
    ),
  ],
);

const _privacyTerms = _TermsDetail(
  accentColor: CompanionColors.greenSoft,
  category: '필수 약관',
  icon: Icons.shield_outlined,
  iconColor: CompanionColors.green,
  title: '개인정보 처리방침',
  summary:
      '실명 계정 대신 기기에서 만든 익명 UUID를 사용하고, 도로 상태를 알려주는 데 '
      '필요한 최소 정보만 처리합니다. 현재 데모 로그인은 외부 계정과 연결되지 않습니다.',
  sections: [
    _TermsSection(
      title: '수집·이용 항목',
      items: [
        '기기에서 생성한 익명 UUID, 닉네임, 이동 유형, 세션 시각을 처리합니다.',
        '검증된 충격 후보가 있을 때 위치 좌표·정확도·속도와 센서 요약 특징을 처리합니다. '
            '작성한 커뮤니티 글과 산책 리포트도 데모 화면에서 사용합니다.',
        '구글·카카오 계정 정보, 이메일, 전화번호, 주소록은 수집하지 않습니다. '
            '사진 추가 기능도 현재는 화면 시연만 하며 실제 사진 파일을 저장하거나 전송하지 않습니다.',
      ],
    ),
    _TermsSection(
      title: '이용 목적',
      items: [
        '익명 사용자의 산책 세션을 연결하고, 이동 유형별 도로 점수와 '
            '경로 비교 결과를 만드는 데 이용합니다.',
        '닉네임은 프로필과 직접 작성한 커뮤니티 글에 표시하며, '
            '리포트 데이터는 산책 결과를 다시 확인하는 데 이용합니다.',
      ],
    ),
    _TermsSection(
      title: '최소 처리 원칙',
      items: [
        '가속도·자이로 원본 스트림과 전체 연속 이동 경로는 서버에 보내지 않습니다. '
            '일반 센서 구간은 기기에서 바로 폐기합니다.',
        '지도에는 개인의 경로 대신 약 10m 반경 도로 구간의 집계 결과를 표시합니다.',
      ],
    ),
    _TermsSection(
      title: '보유·삭제 및 철회',
      items: [
        '현재 해커톤 데모에서 작성한 리포트와 커뮤니티 데이터는 앱 실행 메모리에만 '
            '있으며 앱을 다시 시작하면 초기 데모 데이터로 돌아갑니다.',
        'API 연동 모드의 상세 후보 이벤트·세션·도로 통과 정보는 기본 90일 후 삭제합니다. '
            '개인을 식별하지 않는 도로 점수·신뢰도·집계 건수는 통계로 남을 수 있습니다.',
        '닉네임과 이동 유형은 로그아웃으로 삭제할 수 있습니다. 익명 UUID까지 지우려면 '
            '기기 설정에서 앱 데이터를 삭제하거나 앱을 제거해야 합니다.',
      ],
    ),
  ],
);

const _locationTerms = _TermsDetail(
  accentColor: CompanionColors.amberSoft,
  category: '필수 약관',
  icon: Icons.sensors_rounded,
  iconColor: CompanionColors.amber,
  title: '위치·센서 정보 수집 동의',
  summary:
      '산책 중 현재 위치와 움직임 센서를 사용해 도로 충격 후보를 찾습니다. '
      '약관 동의만으로 기기 권한이 켜지지는 않으며, 운영체제 권한을 별도로 허용해야 합니다.',
  sections: [
    _TermsSection(
      title: '수집·이용 항목',
      items: [
        '현재 위치의 위도·경도, GPS 정확도와 이동 속도, 산책 세션 시각과 이동 유형을 이용합니다.',
        '가속도·자이로 원본은 기기 안에서 짧은 구간으로 분석하고, 후보가 확인된 경우에만 '
            '충격 강도와 요약 특징을 해당 시점의 위치와 연결합니다.',
      ],
    ),
    _TermsSection(
      title: '이용 목적',
      items: [
        '지도에서 현재 위치를 보여주고 목적지까지 경로를 비교하며, '
            '산책 중 주의할 수 있는 도로 구간을 미리 안내합니다.',
        '여러 익명 사용자의 후보를 도로 구간 단위로 집계해 이동 유형별 '
            'Road DNA Score와 신뢰도를 계산하는 데 이용합니다.',
      ],
    ),
    _TermsSection(
      title: '처리 방식',
      items: [
        '현재 데모 모드에서는 센서 후보를 실제 서버로 전송하지 않습니다. '
            'API 연동 모드에서도 원본 센서 스트림이나 전체 연속 경로는 전송하지 않습니다.',
        '위치 정확도가 낮거나 정지 상태인 후보, 기기 낙하 가능성이 있는 후보는 '
            '도로 상태 데이터로 바로 확정하지 않습니다.',
      ],
    ),
    _TermsSection(
      title: '보유·삭제 및 철회',
      items: [
        '현재 데모의 측정값은 산책 화면 동작에만 사용됩니다. '
            '산책 측정을 끝내면 더 이상 센서·위치를 읽지 않습니다.',
        'API 연동 시 전송된 상세 후보와 세션 정보는 기본 90일 보관 후 삭제하고, '
            '도로 구간의 익명 집계 점수는 통계로 유지할 수 있습니다.',
        '언제든 산책 측정을 중지하고 기기 설정에서 위치·동작 센서 권한을 해제할 수 있습니다. '
            '권한을 해제하면 경로와 측정 기능 일부가 동작하지 않을 수 있습니다.',
      ],
    ),
  ],
);

const _marketingTerms = _TermsDetail(
  accentColor: CompanionColors.coralSoft,
  category: '선택 약관',
  icon: Icons.notifications_none_rounded,
  iconColor: CompanionColors.coralAction,
  title: '마케팅 정보 수신 동의',
  summary:
      '새 기능, 지역 도로 정보 캠페인과 이벤트 소식을 받는 데 선택적으로 동의하는 항목입니다. '
      '동의하지 않아도 Road DNA의 데모 기능을 이용할 수 있습니다.',
  sections: [
    _TermsSection(
      title: '수집·이용 항목',
      items: [
        '정식 서비스에서는 동의 여부와 선택한 알림 채널의 주소 또는 푸시 토큰을 '
            '이용할 수 있습니다.',
        '현재 앱에서는 연락처와 푸시 토큰을 수집하지 않고, '
            '선택 상태만 기기에 저장해 프로필에서 언제든 바꿀 수 있습니다.',
      ],
    ),
    _TermsSection(
      title: '이용 목적',
      items: [
        'Road DNA의 새 기능, 서비스 업데이트, 지역별 도로 정보 참여 캠페인과 '
            '이벤트 안내를 전달하는 목적으로만 이용합니다.',
        '서비스 이용에 꼭 필요한 안전·운영 안내는 마케팅 동의 여부와 별도로 제공될 수 있습니다.',
      ],
    ),
    _TermsSection(
      title: '발송 기준',
      items: [
        '현재 데모에서는 실제 광고성 메시지를 발송하지 않습니다.',
        '정식 서비스에서는 발신자, 광고 표시, 수신 거부 방법과 야간 발송 여부를 '
            '메시지에 명확히 표시해야 합니다.',
      ],
    ),
    _TermsSection(
      title: '보유·삭제 및 철회',
      items: [
        '현재 데모의 선택 상태는 별도로 저장하지 않으며 약관 화면을 벗어나면 유지되지 않습니다.',
        '언제든 선택을 해제할 수 있고, 정식 서비스에서는 앱 알림 설정이나 '
            '각 메시지의 수신 거부 기능으로 철회할 수 있어야 합니다.',
        '철회한 뒤에는 법령상 보존 의무가 있는 수신 동의·철회 기록을 제외한 '
            '마케팅 발송 정보를 지체 없이 삭제해야 합니다.',
      ],
    ),
  ],
);

class _AgreementMark extends StatelessWidget {
  const _AgreementMark({required this.checked, this.filled = false});

  final bool checked;
  final bool filled;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    alignment: Alignment.center,
    duration: const Duration(milliseconds: 140),
    height: filled ? 22 : 20,
    width: filled ? 22 : 20,
    decoration: BoxDecoration(
      color: checked && filled
          ? CompanionColors.coralAction
          : Colors.transparent,
      shape: filled ? BoxShape.circle : BoxShape.rectangle,
    ),
    child: Icon(
      Icons.check_rounded,
      color: checked
          ? filled
                ? CompanionColors.white
                : CompanionColors.coralAction
          : CompanionColors.faint,
      size: filled ? 14 : 19,
    ),
  );
}
