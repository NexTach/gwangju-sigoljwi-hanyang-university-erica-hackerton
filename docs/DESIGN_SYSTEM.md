# Road DNA Design System

## 1. 원칙

Road DNA의 디자인 시스템은 `claude-design/Road DNA mobile application/Road DNA - Companion.dc.html`
시안을 기준으로 한 독립 구현이다.

1. 일관된 컴포넌트로 사용자가 다음 행동을 예측할 수 있게 한다.
2. 큰 제목, 충분한 여백, 명확한 한 개의 주 행동으로 정보 위계를 만든다.
3. 모바일 화면은 Navigation과 Bottom CTA를 기본 골격으로 삼는다.
4. 일시적 감지는 모달이 아닌 가벼운 Toast로 알려 이동을 방해하지 않는다.
5. 다양한 텍스트 길이, 큰 글자, 키보드/VoiceOver, reduced motion을 컴포넌트
   기본 동작으로 보장한다.
6. 상태는 색만으로 전달하지 않고 아이콘·문구·수치를 함께 제공한다.

프로토타입의 따뜻한 시각 언어는 유지하되, 정적 보드에서 부족했던 키보드 조작,
화면 읽기 이름, 본문 대비, 반응형 레이아웃을 실제 컴포넌트에서 보완한다.

## 2. 대상과 화면의 한 가지 일

- 모바일 사용자: 휠체어·유모차 사용자와 데이터 기여 시민
- 모바일의 한 가지 일: 이동 중 측정을 안심하고 시작·종료한다.
- 관리자: 지자체 도로/복지 담당자
- 대시보드의 한 가지 일: 제한된 예산으로 먼저 개선할 구간을 결정한다.

## 3. 시각 방향

### Color

| 이름             |        값 | 역할                           |
| ---------------- | --------: | ------------------------------ |
| Companion Coral  | `#FF5A36` | 브랜드, 스플래시, 주요 강조    |
| Action Coral     | `#D33B20` | AA 대비가 필요한 주 행동       |
| Accessible Green | `#4F9A72` | 편안한 구간, 수용 완료         |
| Caution Amber    | `#F5A623` | 주의, 낮은 신뢰도              |
| Barrier Red      | `#E14F3D` | 반복 충격 및 이동 장애 후보    |
| City Ink         | `#2E2A26` | 주요 텍스트                    |
| Warm Cream       | `#FBF6F0` | 앱과 대시보드의 기본 배경      |
| Linen            | `#F1EBE3` | 보조 표면, 선택 전 컨트롤 배경 |

원색은 직접 UI에 사용하지 않고 의미 토큰(`content.primary`,
`status.critical.background` 등)을 통해 사용한다. 라이트/다크 모드와 고대비
조합을 모두 정의한다.

### Typography

- Display/Body: `Pretendard Variable` — 친근한 한국어 제목, 본문, 제어문
- Data: `JetBrains Mono` — 센서 XYZ, 좌표, 디버그 값에만 제한 사용

서체를 불러오지 못하면 OS sans-serif/monospace로 안전하게 폴백한다.

### Layout

```text
Mobile                         Dashboard
┌ greeting / context ─────┐     ┌ brand + reference date ──────┐
│ coral primary action     │     │ four rounded KPI cards       │
│ score + schematic map    │     ├ rounded map ┬ priority table │
│ status / report cards    │     │             │                │
├ floating five-tab nav ───┤     └─────────────┴────────────────┘
```

모바일은 4pt 기본 격자와 20px 화면 여백, 대시보드는 12-column 유동 격자를 쓴다.
모바일 5탭 내비게이션은 모든 탭 화면에서 유지되며, 선택 표시가 이동하고
본문은 짧은 수평 이동과 페이드로 전환된다.
로그인 브랜드 버튼은 높이·radius·아이콘 슬롯·타이포 구조를 공유하고,
공식 심볼과 브랜드 표면색만 구분한다. 로그인 캐러셀은 이웃 카드가 노출되지 않는
단일 카드 fade-through로 자동·스와이프·순환 전환한다.
콘텐츠 최대 너비는 1440px다.

### Signature: Companion Route

코랄 시작점에서 출발한 경로가 녹색 안전 구간과 주황색 전환점을 지나가는 단순한
지도 선형을 홈, 측정, 리포트에서 반복한다. 물결형 로고는 이 경로의 축약형이다.
이 한 가지 모티프 외의 장식은 줄이고 둥근 흰 카드와 넉넉한 여백을 유지한다.

## 4. 토큰

`packages/design-tokens/tokens.json`이 단일 원본이다.

- Foundation: palette, typography, spacing, radius, shadow, motion, breakpoint
- Semantic: canvas/surface/content/border/action/status/map
- Component: button, list row, navigation, bottom CTA, sheet, toast, score
- Accessibility: 최소 44px 터치 영역, 2px focus ring, AA 본문 대비

라이트 모드의 `content.tertiary`도 가장 밝은 `surface.subtle` 위에서 WCAG AA
4.5:1을 만족한다. 비활성 컨트롤은 전체 투명도를 낮추지 않고
`surface.subtle`/`content.tertiary` 조합을 사용해 상태와 가독성을 함께
유지한다.

`pnpm --filter @road-dna/design-tokens build`로 CSS 변수와 TypeScript 상수를
생성하며, 동기화 검사는 테스트에서 수행한다.

## 5. 컴포넌트 계약

| 분류       | 컴포넌트                                  | 필수 상태                              |
| ---------- | ----------------------------------------- | -------------------------------------- |
| Action     | Button, IconButton, BottomCTA             | default/pressed/focus/disabled/loading |
| Navigation | Navigation, Tabs, FloatingTabBar          | active/inactive/back                   |
| Selection  | SegmentedControl, Switch, TextField       | selected/error/disabled                |
| Content    | ListHeader, ListRow, Surface, Metric      | multiline/leading/trailing             |
| Feedback   | Badge, Alert, Toast, BottomSheet          | info/success/warning/critical          |
| Data       | ScoreGauge, ConfidenceBar, RoadScanRibbon | unknown/good/caution/poor              |
| State      | Skeleton, EmptyState, ErrorState          | loading/empty/retry                    |

컴포넌트는 제품별 색이나 간격 상수를 받지 않는다. 필요한 변형은 의미가 분명한
`tone`, `size`, `state` API로만 제공한다.

## 6. UX Writing

- 행동은 결과를 이름으로 쓴다: `측정 시작`, `측정 종료`, `다시 시도`
- 완료 문구는 같은 동사를 유지한다: `측정을 종료했어요`
- 후보를 확정 사실처럼 쓰지 않는다: `이동 충격 패턴을 감지했어요`
- 데이터 없음은 양호로 포장하지 않는다: `아직 분석된 이동 데이터가 없어요`
- 오류는 복구 방법을 포함한다: `위치 권한을 켠 뒤 다시 시도해 주세요`

## 7. 접근성 완료 기준

- 본문/컨트롤 WCAG 2.2 AA 대비
- 모든 동작 요소 키보드 접근 및 보이는 focus 상태
- Icon-only control에 접근 가능한 이름
- 화면 읽기 순서가 시각 순서와 일치
- 200% 글자 확대에서 CTA와 핵심 정보가 잘리지 않음
- `prefers-reduced-motion`에서 Ribbon과 sheet 전환 제거
- 일반 탭의 Material splash·검정 highlight는 쓰지 않는다. 선택 상태는 컴포넌트
  자체의 색·위치 변화로 알리고 키보드 focus는 coral 표시로 유지한다.
- 지도 정보가 목록/텍스트로도 제공됨
