# Road DNA

휠체어·유모차 이동 중 스마트폰 센서 신호를 기기에서 분석하고, 검증된 충격
후보만 도로 구간 단위로 집계하는 접근성 크라우드센싱 플랫폼입니다.

> 이동의 흔적이 도시의 장벽을 발견하다.

## 서비스

- 운영 대시보드: <https://kimtaeeun.site/road-dna/>
- API 상태: <https://kimtaeeun.site/road-dna/health>
- OpenAPI: <https://kimtaeeun.site/road-dna/docs/>

Road DNA 점수는 익명 센서 후보를 집계한 MVP 내부 지표이며 법정 접근성 인증이
아닙니다. 데이터가 없는 구간은 `100`이 아니라 `UNKNOWN`으로 유지합니다.

## 구현 범위

| 영역          | 구현                                                                                              |
| ------------- | ------------------------------------------------------------------------------------------------- |
| Flutter       | 익명 UUID, 위치 권한, GPS, 25Hz 가속도·자이로, 2초 창 분석, 측정 세션, 지도, 경로 비교, 보정 패널 |
| API           | 세션·이벤트·도로·경로·대시보드 REST API, TypeBox 검증, OpenAPI                                    |
| 데이터        | MySQL 8 `POINT SRID 4326`, 10m 도로 집계, 이동유형별 점수/신뢰도, Redis 중복 방지                 |
| Dashboard     | 준실시간 지표, 실제 용봉동 도로 레이어, 개선 우선순위, 도로 상세                                  |
| Design System | 웹·Flutter 공통 토큰, 라이트/다크, WCAG AA, 44px 터치 영역, 상태 컴포넌트                         |
| Delivery      | 비루트 멀티스테이지 이미지, GHCR, GitHub Actions CI/CD, 온프레미스 nginx                          |

## 저장소 구조

```text
apps/
  api/                 Fastify API
  dashboard/           React 관리자 대시보드
  design-system/       웹 컴포넌트 카탈로그
  mobile/              Flutter 앱
packages/
  contracts/           공유 API 계약
  design-tokens/       토큰 단일 원본
  road_dna_design/     Flutter 디자인 시스템
  ui/                  React 디자인 시스템
deploy/                운영 이미지·Compose·nginx 내부 프록시
docs/                  계획·아키텍처·운영·보정·개인정보 문서
```

## 로컬 실행

Node.js 22+와 pnpm 10.13.1이 필요합니다.

```bash
pnpm install --frozen-lockfile
pnpm check
pnpm build
pnpm dev
```

API는 MySQL 환경 변수가 없으면 메모리 저장소로 실행됩니다. 명시적 시연
데이터가 필요하면 `DEMO_MODE=true`를 사용합니다. Dashboard의 시연 데이터도
`VITE_DEMO_MODE=true`일 때만 활성화됩니다.

운영 배포에서는 API와 Dashboard가 실제 MySQL 집계를 사용합니다. 배포 때마다
용봉동 8개 기준 도로와 누락된 이동 유형 데이터만 멱등 동기화하며, 모바일에서
공유된 익명 충격 후보는 같은 도로 ID로 집계되어 Dashboard의 5초 폴링 주기 안에
반영됩니다.

Flutter:

```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

모바일 앱은 용봉동 경로·자동 GPS·센서 흐름을 포함한 단일 기본 환경으로
실행됩니다. 주변 도로·경로·GPS는 기기의 내장 시나리오를 사용하고, 익명 이동
데이터 공유가 켜져 있을 때 세션과 충격 후보만 운영 API에 실패 허용 방식으로
동기화합니다. 서버가 일시적으로 응답하지 않아도 산책과 리포트는 계속 동작합니다.
별도의 실행 모드나 패키지 변형은 없습니다.

```bash
flutter build apk --debug
```

Android는 빌드 유형과 관계없이 하나의 패키지를 사용하며 앱 이름은
`Road DNA`입니다.

로컬 API에 연결해야 할 때만 URL을 덮어씁니다.

```bash
flutter run \
  --dart-define=ROAD_DNA_API_URL=http://10.0.2.2:3000
```

## 핵심 문서

- [기술 아키텍처](docs/ARCHITECTURE.md)
- [테스트 전략](docs/TESTING.md)
- [디자인 시스템](docs/DESIGN_SYSTEM.md)
- [센서 보정 가이드](docs/CALIBRATION.md)
- [개인정보·보관 정책](docs/PRIVACY.md)
- [운영·배포 런북](docs/OPERATIONS.md)
- [원본 구현 계획](docs/PLAN_1_ROADDNA.md)

## 라이선스

[BSD 3-Clause License](LICENSE)
