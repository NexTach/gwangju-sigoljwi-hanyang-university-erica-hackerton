import 'package:flutter/material.dart';
import 'package:road_dna_design/road_dna_design.dart';

enum _DemoMovement { wheelchair, stroller, walking }

class DesignSystemCatalog extends StatefulWidget {
  const DesignSystemCatalog({
    required this.darkMode,
    required this.onDarkModeChanged,
    super.key,
  });

  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<DesignSystemCatalog> createState() => _DesignSystemCatalogState();
}

class _DesignSystemCatalogState extends State<DesignSystemCatalog> {
  _DemoMovement _movement = _DemoMovement.wheelchair;
  bool _loading = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: RdNavigation(
      actions: [
        RdIconButton(
          icon: Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: () => widget.onDarkModeChanged(!widget.darkMode),
          semanticLabel: widget.darkMode ? '라이트 모드' : '다크 모드',
        ),
      ],
      subtitle: 'Mobile component catalog',
      title: 'Road DNA Design',
    ),
    body: ListView(
      padding: const EdgeInsets.only(bottom: RdSpacing.x16),
      children: [
        _Section(
          description: '하나의 주 행동과 예측 가능한 상태',
          title: 'Actions',
          child: Wrap(
            runSpacing: RdSpacing.x3,
            spacing: RdSpacing.x3,
            children: [
              RdButton(
                label: '측정 시작',
                leading: const Icon(Icons.route_rounded, size: 20),
                loading: _loading,
                onPressed: () async {
                  setState(() => _loading = true);
                  await Future<void>.delayed(const Duration(milliseconds: 500));
                  if (mounted) setState(() => _loading = false);
                },
              ),
              RdButton(
                label: '나중에',
                onPressed: () {},
                tone: RdButtonTone.secondary,
              ),
              RdButton(
                label: '측정 종료',
                onPressed: () {},
                tone: RdButtonTone.danger,
              ),
              const RdButton(label: '사용할 수 없음', onPressed: null),
            ],
          ),
        ),
        const _Section(
          description: '색만으로 상태를 전달하지 않음',
          title: 'Feedback',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                runSpacing: RdSpacing.x2,
                spacing: RdSpacing.x2,
                children: [
                  RdBadge(label: '분석 중', dot: true, tone: RdBadgeTone.info),
                  RdBadge(label: '양호', tone: RdBadgeTone.success),
                  RdBadge(label: '주의', tone: RdBadgeTone.warning),
                  RdBadge(label: '충격 후보', tone: RdBadgeTone.critical),
                ],
              ),
              SizedBox(height: RdSpacing.x4),
              RdAlert(
                message: 'GPS 정확도가 낮아 점수에는 아직 반영하지 않았어요.',
                title: '위치 신뢰도가 낮아요',
                tone: RdFeedbackTone.warning,
              ),
            ],
          ),
        ),
        _Section(
          description: '이동 유형별 데이터는 서로 섞이지 않음',
          title: 'Selection',
          child: RdSegmentedControl<_DemoMovement>(
            onChanged: (value) => setState(() => _movement = value),
            segments: const [
              RdSegment(
                icon: Icons.accessible_forward_rounded,
                label: '휠체어',
                value: _DemoMovement.wheelchair,
              ),
              RdSegment(
                icon: Icons.child_friendly_rounded,
                label: '유모차',
                value: _DemoMovement.stroller,
              ),
              RdSegment(
                icon: Icons.directions_walk_rounded,
                label: '보행',
                value: _DemoMovement.walking,
              ),
            ],
            value: _movement,
          ),
        ),
        const _Section(
          description: '데이터가 없으면 100점이 아니라 UNKNOWN',
          title: 'Road data',
          child: RdSurface(
            tone: RdSurfaceTone.subtle,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    RdScoreGauge(score: 87, size: 132),
                    RdScoreGauge(score: null, size: 132),
                  ],
                ),
                SizedBox(height: RdSpacing.x6),
                RdConfidenceBar(value: 0.68),
                SizedBox(height: RdSpacing.x6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RdMetric(label: '분석 거리', value: '12.8 km'),
                    RdMetric(label: '후보', value: '28', trend: '이번 주 +6'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const _Section(
          description: '제품의 기억점은 분석 상태 한 곳에만 사용',
          title: 'Road Scan Ribbon',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RdRoadScanRibbon(state: RdRoadScanState.idle),
              SizedBox(height: RdSpacing.x4),
              RdRoadScanRibbon(state: RdRoadScanState.active),
              SizedBox(height: RdSpacing.x4),
              RdRoadScanRibbon(state: RdRoadScanState.impact),
            ],
          ),
        ),
        _Section(
          description: '긴 문구와 leading/trailing 조합',
          noHorizontalPadding: true,
          title: 'List rows',
          child: Column(
            children: [
              RdListRow(
                description: '휠체어 기준 · 신뢰도 68%',
                leading: const Icon(Icons.route_rounded),
                onTap: () {},
                title: '광주광역시청 앞 보행로',
              ),
              const RdListRow(
                description: '최근 7일간 14회 반복 감지',
                leading: Icon(Icons.warning_amber_rounded),
                title: '이동 충격 후보',
                trailing: RdBadge(label: '주의', tone: RdBadgeTone.warning),
              ),
            ],
          ),
        ),
        _Section(
          description: '기다림과 빈 상태도 다음 행동을 안내',
          title: 'States',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RdSkeleton(height: 20, width: 220),
              const SizedBox(height: RdSpacing.x3),
              const RdSkeleton(height: 72),
              const SizedBox(height: RdSpacing.x5),
              RdButton(
                label: 'Toast 확인',
                onPressed: () => showRdToast(
                  context,
                  message: '이동 충격 패턴을 감지했어요',
                  tone: RdFeedbackTone.warning,
                ),
                tone: RdButtonTone.secondary,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.child,
    required this.description,
    required this.title,
    this.noHorizontalPadding = false,
  });

  final Widget child;
  final String description;
  final bool noHorizontalPadding;
  final String title;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RdListHeader(description: description, title: title),
      Padding(
        padding: noHorizontalPadding
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: RdSpacing.x5),
        child: child,
      ),
    ],
  );
}
