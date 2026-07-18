# Road DNA Design System

## 1. 원칙

Road DNA의 디자인 시스템은 TDS에서 공개한 다음 제품 원칙을 따른 독립 구현이다.

1. 일관된 컴포넌트로 사용자가 다음 행동을 예측할 수 있게 한다.
2. 큰 제목, 충분한 여백, 명확한 한 개의 주 행동으로 정보 위계를 만든다.
3. 모바일 화면은 Navigation과 Bottom CTA를 기본 골격으로 삼는다.
4. 일시적 감지는 모달이 아닌 가벼운 Toast로 알려 이동을 방해하지 않는다.
5. 다양한 텍스트 길이, 큰 글자, 키보드/VoiceOver, reduced motion을 컴포넌트
   기본 동작으로 보장한다.
6. 상태는 색만으로 전달하지 않고 아이콘·문구·수치를 함께 제공한다.

공식 TDS UI Kit과 Toss Product Sans는 앱인토스 외 사용 범위가 제한되므로
복제하거나 포함하지 않는다. 공개된 UX 원칙을 바탕으로 Road DNA의 자체 토큰,
컴포넌트, 문구 체계를 구현한다.

참고:

- <https://developers-apps-in-toss.toss.im/design/components.html>
- <https://developers-apps-in-toss.toss.im/design/consumer-ux-guide.html>
- <https://toss.tech/article/44097>

## 2. 대상과 화면의 한 가지 일

- 모바일 사용자: 휠체어·유모차 사용자와 데이터 기여 시민
- 모바일의 한 가지 일: 이동 중 측정을 안심하고 시작·종료한다.
- 관리자: 지자체 도로/복지 담당자
- 대시보드의 한 가지 일: 제한된 예산으로 먼저 개선할 구간을 결정한다.

## 3. 시각 방향

### Color

| 이름          |        값 | 역할                 |
| ------------- | --------: | -------------------- |
| Route Cobalt  | `#3563E9` | 주 행동, 활성 경로   |
| Trace Cyan    | `#19B8B2` | 센서 수집, 양호 상태 |
| Barrier Coral | `#F04452` | 높은 충격, 위험 후보 |
| Survey Amber  | `#F59F00` | 주의, 낮은 신뢰도    |
| City Ink      | `#191F28` | 주요 텍스트          |
| Map Snow      | `#F7F8FA` | 앱 배경              |

원색은 직접 UI에 사용하지 않고 의미 토큰(`content.primary`,
`status.critical.background` 등)을 통해 사용한다. 라이트/다크 모드와 고대비
조합을 모두 정의한다.

### Typography

- Display: `SUIT Variable` — 짧은 제목과 점수, 단단하고 넓은 숫자 형태
- Body: `Pretendard Variable` — 한국어 본문, 제어문, 긴 설명
- Data: `JetBrains Mono` — 센서 XYZ, 좌표, 디버그 값에만 제한 사용

서체를 불러오지 못하면 OS sans-serif/monospace로 안전하게 폴백한다.

### Layout

```text
Mobile                         Dashboard
┌ Navigation ────────────┐     ┌ Side rail ┬ Header ───────────┐
│ large title             │     │           │ decision summary  │
│ map / primary content   │     │ sections  ├ map ───┬ priority │
│                         │     │           │         │ queue    │
│ status list rows        │     │           ├ metrics ┴─────────┤
├ sticky Bottom CTA ──────┤     └───────────┴───────────────────┘
```

모바일은 4pt 기본 격자와 20px 화면 여백, 대시보드는 12-column 유동 격자를 쓴다.
콘텐츠 최대 너비는 1440px다.

### Signature: Road Scan Ribbon

한 줄의 도로 중심선이 센서 윈도우를 통과하며 양호/주의/후보 상태로 변한다.
Tracking 화면과 관리자 지도의 선택 구간에서만 사용한다. 나머지 UI는 평평하고
조용하게 유지해 이 신호가 제품의 기억점이 되도록 한다.

## 4. 토큰

`packages/design-tokens/tokens.json`이 단일 원본이다.

- Foundation: palette, typography, spacing, radius, shadow, motion, breakpoint
- Semantic: canvas/surface/content/border/action/status/map
- Component: button, list row, navigation, bottom CTA, sheet, toast, score
- Accessibility: 최소 44px 터치 영역, 2px focus ring, AA 본문 대비

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
- 지도 정보가 목록/텍스트로도 제공됨
