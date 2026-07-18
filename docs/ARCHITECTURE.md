# Road DNA 기술 아키텍처

## 1. 구현 범위

`PLAN_1_ROADDNA.md`의 Definition of Done을 종단 시나리오로 삼는다.

```text
Flutter 앱
  데모 로그인 → 권한/약관 → 익명 UUID → 닉네임/이동 유형
  → 저장된 이동 유형으로 경로 비교 → 측정 세션
  → 20~50Hz 센서 윈도우 분석 → GPS/이동 검증
  → Barrier Candidate 전송
        │
        ▼
Fastify API
  세션/이벤트 검증 → 10m Road Segment 집계
  → 이동 유형별 Score/Confidence 갱신
        │
        ├── Flutter 접근성 지도/도로 상세
        └── React City DNA 관리자 대시보드
```

P0 전체와 발표에 필요한 P1(자이로스코프, 신뢰도, 경로 비교, 기여도,
관리자 대시보드)을 구현한다. 실제 센서가 없는 개발 환경에서도 같은 흐름을 검증할
수 있도록 시연 데이터 모드를 제공하되, UI에서 시연 데이터임을 명확히 표시한다.

## 2. 모노레포

| 경로                     | 책임                                       |
| ------------------------ | ------------------------------------------ |
| `apps/mobile`            | Flutter 센서 수집, 로컬 감지, 사용자 지도  |
| `apps/api`               | Fastify REST API, 집계/점수/경로 엔진      |
| `apps/dashboard`         | React 관리자 지도와 통계                   |
| `apps/design-system`     | 웹 디자인 시스템 카탈로그와 시각 회귀 기준 |
| `packages/design-tokens` | 웹/모바일 공통 디자인 토큰의 단일 원본     |
| `packages/ui`            | Road DNA React 디자인 시스템               |
| `packages/contracts`     | API 스키마와 공유 타입                     |
| `deploy`                 | Docker Compose, DB 초기화, 내부 nginx, CD  |

## 3. 기술 선택

- Node.js 22+ / pnpm workspace
- Fastify 5 + TypeBox: OpenAPI와 런타임 요청 검증을 같은 스키마로 유지
- MySQL 8: 전용 `road_dna` 스키마, `POINT SRID 4326`과
  `ST_Distance_Sphere`로 10m 이내 세그먼트 집계
- Redis: 짧은 중복 이벤트 방지 키를 TTL 기반으로 저장
- React 19 + Vite 8 + TanStack Query + MapLibre GL
- Flutter stable + Riverpod + go_router + flutter_map
- OpenStreetMap raster tiles: MVP에서 별도 지도 키 없이 개발. 운영 트래픽은 별도
  타일 공급자 계약 또는 자체 타일 서버로 교체 가능하도록 `ROAD_DNA_TILE_URL`로 분리

## 4. 데이터 원칙

- 개인의 원본 센서 스트림과 전체 이동 경로를 서버에 저장하지 않는다.
- 서버에는 익명 UUID, 세션 메타데이터, 검증된 후보 이벤트만 저장한다.
- `WALKING` 점수는 휠체어/유모차 점수와 절대 혼합하지 않는다.
- 이벤트가 없는 구간은 `100`이 아니라 `UNKNOWN`이다.
- 후보 이벤트를 장애물 종류로 단정하지 않고 `UNKNOWN_IMPACT`로 기록한다.
- 위치 정확도가 기준을 벗어나거나 정지 상태인 이벤트는 `HELD` 또는 `REJECTED`로
  기록하고 점수 집계에서 제외한다.

## 5. 점수와 신뢰도

```text
frequency       = accepted events / max(traversal count, unique contributors, 1)
severityWeight  = average severity × 38
vibrationWeight = normalized RMS × 12
impactPenalty   = min(80, frequency × severityWeight + vibrationWeight)
score           = clamp(round(100 - impactPenalty), 0, 100)
```

신뢰도는 데이터 양 35%, 고유 기여자 30%, 반복성 20%, 최신성 15%의 합으로
계산한다. 결과와 함께 샘플 수를 항상 노출해 내부 MVP 지표를 검증된 표준처럼
오해하지 않도록 한다.

## 6. 배포

기본 운영 경로는 사용자가 제공한 온프레미스 서버다. 하나의 Compose 프로젝트에
API, Dashboard, 전용 Postgres가 아닌 **기존 MySQL의 전용 `road_dna` 스키마**,
기존 Redis를 연결한다. nginx의 기존 virtual host에는 `/road-dna/` 경로만
추가하고 다른 location과 server block은 유지한다. Cloudflare Flexible TLS를
고려해 원본 서버는 HTTP로 제공하고 `X-Forwarded-Proto`를 신뢰한다.

GitHub Actions CD는 `main` push 또는 수동 실행으로 배포한다.
서버의 DB 자격 증명은 `0600` 전용 `.env`에만 두고, Actions에는 제한된 SSH
접속 정보만 저장한다.
