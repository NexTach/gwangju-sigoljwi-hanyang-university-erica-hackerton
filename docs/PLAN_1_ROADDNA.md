# Road DNA — 프로젝트 계획서# 불빛지도 — 기능 명세 및 구현 구조

## 1. 서비스 개요

- 서비스명: 불빛지도 (가칭)
- 한 줄 소개: 주민이 찍은 밤길 사진으로 골목길 위험도를 객관적으로 진단하고, 개선 민원문까지 자동으로 만들어주는 보행 안전 서비스
- 대상 주제: 지속가능한 도시와 공동체 — 밤길·골목길 등 우리 동네 보행 안전 사각지대 문제
- SDG 연계: SDG 11.7 (안전하고 포용적인 공공 공간), 부차적으로 SDG 5 (야간 보행 취약계층 보호)
- 핵심 가치: "위험을 느끼는 것"과 "행정 개선을 요청하는 것" 사이의 끊긴 고리를 기술로 연결

## 2. 기능 명세

### MVP (반드시 구현 — 데모 성립 조건)

**F1. 사진 업로드 및 조도 분석**
- 사용자가 밤길 사진을 업로드 (파일 선택 또는 모바일 카메라)
- Canvas API로 이미지를 읽어 픽셀 평균 휘도 계산
  - 휘도 공식: Y = 0.299R + 0.587G + 0.114B
- 결과를 0~255 수치와 3단계 등급으로 표시
  - 위험(빨강): 평균 휘도 40 미만
  - 주의(주황): 40 이상 90 미만
  - 양호(초록): 90 이상
  - 임계값은 실제 사진 몇 장으로 테스트 후 조정
- 하위 25% 어두운 영역 비율(암부 비율)도 함께 계산하면 "부분적으로 어두운 골목" 판별 가능 (여력 되면)

**F2. AI 위험 요소 분석**
- 업로드된 사진을 비전 AI에 전달하여 다음을 JSON으로 받음
  - 가로등 유무/작동 여부 추정
  - 시야 확보 상태 (사각 코너, 담벼락, 수풀 등)
  - 노면 상태 (파손, 장애물)
  - 종합 위험 서술 2~3문장
- 폴백(fallback) 설계: API 키가 없거나 호출 실패 시, F1의 조도 수치를 기반으로 한 규칙 기반 서술 템플릿으로 대체하여 데모가 절대 끊기지 않게 함

**F3. 민원문 자동 생성**
- 입력: 위치(텍스트 주소 입력 또는 지도 클릭 좌표), 촬영 시각, F1 조도 수치, F2 분석 결과
- 출력: 안전신문고 제출 양식에 맞는 민원문 초안
  - 구성: 발생 위치 → 현황(객관적 수치 포함) → 위험성 → 개선 요청(가로등 신설/보수, CCTV 등)
- "복사하기" 버튼 제공 → 사용자가 안전신문고 앱/웹에 붙여넣는 흐름
- 민원을 앱이 직접 제출하지 않음 (제출 주체는 시민 본인 — 발표 시 질문 대비 포인트)

**F4. 동네 위험 지도**
- Leaflet + OpenStreetMap 타일 사용 (API 키 불필요, 즉시 동작)
- 진단 완료 시 지도에 등급 색상 마커 추가 (빨강/주황/초록)
- 마커 클릭 시 사진 썸네일, 조도 수치, 진단 요약 팝업
- 저장: localStorage (로컬 실행 기준 데모용 영속화)

### 선택 기능 (시간 남으면)

- 통계 카드: 총 제보 수, 위험 지점 수, 평균 조도
- 마커 필터 (위험만 보기)
- 민원문 다국어 버전 (외국인 주민 배려 — 발표에서 확장성 언급용으로만 써도 됨)

## 3. 화면 구성 (단일 페이지)

```
[헤더] 불빛지도 로고 + 한 줄 소개
[섹션 1: 진단하기]
  사진 업로드 영역 → 분석 버튼
[섹션 2: 결과 카드]
  조도 게이지 + 등급 뱃지 | AI 위험 분석 | 민원문 미리보기 + 복사 버튼
[섹션 3: 우리 동네 지도]
  Leaflet 지도 + 누적 마커
```

모바일 우선(세로) 레이아웃으로 만들면 영상 촬영 시 실사용 느낌이 남.

## 4. 기술 구조

```
[브라우저 - 단일 HTML 파일]
 ├─ UI (HTML/CSS)
 ├─ 조도 분석 모듈 (JS + Canvas)        ← 자체 알고리즘 (기술 완성도 어필)
 ├─ AI 호출 모듈 (fetch → 비전/텍스트 API)
 │    └─ 실패 시 규칙 기반 폴백
 ├─ 민원문 생성 모듈 (AI 프롬프트 or 템플릿)
 ├─ 지도 모듈 (Leaflet + OSM)
 └─ 저장 모듈 (localStorage, JSON)
```

- 파일 구성: `index.html` 하나로 시작 → 시간 되면 `style.css`, `app.js` 분리 (소스코드 제출 시 깔끔함)
- 데이터 구조 예시:

```json
{
  "id": "r-001",
  "lat": 37.29, "lng": 126.83,
  "timestamp": "2026-07-18T22:30",
  "brightness": 32,
  "grade": "danger",
  "aiAnalysis": "가로등이 확인되지 않으며...",
  "complaint": "안녕하십니까. ..."
}
```

- AI API 키 처리: 코드 상단에 `const API_KEY = ""` 상수로 분리하고, 제출 소스에는 빈 값 + 주석으로 발급 안내. 키가 빈 값이면 자동으로 폴백 모드 동작.

## 5. AI 프롬프트 설계 (심사 기준 "AI 협업 및 논리성" 대응)

프롬프트를 2단계 체인으로 설계하고, 이 설계 과정 자체를 보고서에 기록한다.

**1단계 — 사진 분석 프롬프트 (비전)**
- 역할 부여: "야간 보행 안전 전문가"
- 출력 형식 강제: JSON 스키마 명시 (streetlight, visibility, road, summary)
- 개선 과정 기록 예시: "처음에는 자유 서술로 받았더니 형식이 매번 달라져서, JSON 스키마를 명시하고 '스키마 외 텍스트 금지'를 추가함" — 이런 시행착오가 심사 기준이 요구하는 "비판적 검토와 보완"의 증거가 됨

**2단계 — 민원문 생성 프롬프트 (텍스트)**
- 입력: 1단계 JSON + 조도 수치 + 위치/시각
- 조건: 공손한 민원 문체, 객관적 수치 인용, 구체적 개선 요청 1~2개, 300자 내외
- 개선 과정 기록 예시: "초안이 과장된 표현('매우 위험')을 남발 → 수치 기반 표현만 쓰도록 제약 추가"

## 6. 작업 분담 및 타임라인 (오늘 저녁 ~ 내일 09:00)

| 시간        | 작업                                                      |
|-------------|-----------------------------------------------------------|
| ~20:00      | 역할 분담 확정, index.html 뼈대 + UI                      |
| 20:00~22:00 | F1 조도 분석 + F4 지도 (병렬), F2/F3 프롬프트 설계        |
| 22:00~24:00 | AI 연동 + 폴백, 전체 흐름 연결                            |
| 24:00~      | 실제 밤길 사진 3~5장 촬영 및 테스트 (임계값 튜닝)         |
| 내일 오전   | 보고서 마무리, 영상 촬영·편집, 09:30까지 구글폼 제출 준비 |

역할 예시(4인 기준): 프론트 UI 1, 조도·지도 로직 1, AI 프롬프트·연동 1, 보고서·영상 1. 보고서의 "사회성 및 협업" 항목에 이 분담표를 그대로 넣는다.

## 7. 데모 시나리오 (3분 영상 구성안)

1. (30초) 문제 제기: 어두운 골목 실제 영상 + "민원을 쓰려면 뭐라고 써야 할까?"
2. (90초) 시연: 사진 업로드 → 조도 수치·등급 → AI 분석 → 민원문 생성 → 복사 → 지도에 마커 누적
3. (40초) 차별점: 기존 안심이 앱 등은 '보여주는' 서비스, 불빛지도는 '개선하는' 서비스
4. (20초) SDG 11.7 연계 및 확장 계획(지자체 데이터 연동)

## 8. 발표 질문 대비

- Q. 조도 기준이 자의적이지 않나? → 실측 사진으로 임계값을 보정했고, 절대 기준이 아니라 상대 비교·우선순위 도구임을 설명
- Q. 안심이 앱과 뭐가 다른가? → 기존 데이터 조회 vs 주민 참여형 측정 + 행정 액션 연결
- Q. 허위 제보는? → 사진 원본 첨부가 필수라 검증 가능, 향후 관리자 검수 기능으로 확장

**Document Version:** v1.1 (재정리본)
**Project Type:** 해커톤 MVP / 접근성 데이터 플랫폼
**Platform:** Flutter Mobile App + Backend API + Admin Web Dashboard

> **한 줄 정의:** Road DNA는 휠체어·유모차 등의 이동 과정에서 발생하는 스마트폰 센서 데이터를 분석하여 도로의 이동 장벽을 발견하고, 접근성 데이터를 구축하는 크라우드센싱 기반 플랫폼이다.

**슬로건:** "이동의 흔적이 도시의 장벽을 발견하다."
**핵심 메시지:** 우리가 움직인 길이, 모두가 이동할 수 있는 지도가 됩니다.

---

## 1. 문제 정의

기존 지도 서비스는 목적지까지의 거리와 예상 시간을 중심으로 경로를 제공한다. 그러나 휠체어·유모차 등 이동약자에게는 단순한 거리보다 **노면 상태, 턱, 경사, 이동 장애 요소**가 실제 이동 가능성을 결정한다.

현재 접근성 정보는 대부분 사람이 직접 발견하고 → 신고하고 → 관리자가 확인해 등록하는 구조라 데이터 구축과 지속적인 업데이트에 한계가 있다.

> **"사람이 직접 장애물을 신고하지 않아도, 이동하는 것만으로 도시의 장벽을 발견할 수 없을까?"**

```text
기존 방식
장애물 발견 → 사용자 직접 신고 → 관리자 확인 → 데이터 등록

Road DNA
사용자 이동 → 센서 자동 수집 → 이상 이동 패턴 감지 → 위치 데이터 결합
→ 다수 데이터 집계 → 접근성 정보 생성
```

### 차별점

- 기존 접근성 지도: 사람이 등록한 시설 정보 중심, 수동 제보 기반
- Road DNA: **이동 자체가 센서가 되어** 기존 지도에 없는 도로의 물리적 접근성을 자동·지속 업데이트

---

## 2. 제품 목표

### Product Goal

**사용자의 이동 자체를 도시 접근성 데이터로 변환한다.**

### MVP Goal (해커톤에서 증명할 핵심 가설)

> 스마트폰 센서 데이터를 이용하여 이동 중 발생하는 비정상적인 충격을 감지하고, 발생 위치를 지도에 기록할 수 있는가?

### Success Criteria

| 목표 | 성공 기준 |
|---|---|
| 센서 수집 | 이동 중 가속도 데이터 실시간 수집 |
| 위치 수집 | GPS 기반 현재 위치 확보 |
| 이상 감지 | 설정된 로직으로 충격 후보 탐지 |
| 데이터 연결 | 충격 이벤트와 GPS 좌표 연결 |
| 지도 시각화 | 감지된 이벤트 지도 표시 |
| 데이터 집계 | 동일 구간 이벤트 집계 |
| 접근성 평가 | Road DNA Score 산출 |

---

## 3. 타겟 사용자

| Persona | Need | Pain Point |
|---|---|---|
| A. 휠체어 사용자 | 실제 이동 가능한 경로를 알고 싶다 | 지도상 가능해 보여도 턱·불량 노면으로 이동 불가 |
| B. 유모차 사용자 | 유모차 이동이 편한 경로를 찾고 싶다 | 계단·턱·노면 정보 부족 |
| C. 데이터 기여 시민 | 복잡한 신고 없이 접근성 개선에 기여하고 싶다 | — |
| D. 지자체 관리자 | 개선 우선순위를 데이터로 파악하고 싶다 | 민원 기반의 사후 대응 |

**이동 모드 구분(중요):** 일반 보행자의 주머니 속 스마트폰 진동만으로 휠체어가 느끼는 노면 접근성을 판단하기 어렵다. 따라서 스마트폰을 휠체어·유모차에 **고정한 상태로 수집하는 모드**와 일반 시민 기여 모드를 구분한다.

```text
Wheelchair Sensor Mode / Stroller Sensor Mode / Contributor Mode
```

`WALKING` 데이터는 접근성 데이터에 직접 혼합하지 않고 별도 분류한다.

---

## 4. 시스템 아키텍처

```text
┌─────────────────────────────┐
│       Flutter Mobile App    │
│ GPS / Accelerometer / Gyro  │
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│       Edge Processing       │
│ Filtering / Window Analysis │
│ Anomaly Detection           │
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│          Backend API        │
└──────────────┬──────────────┘
       ┌───────┴────────┐
       ▼                ▼
┌────────────┐    ┌─────────────┐
│ PostgreSQL │    │   PostGIS   │
└──────┬─────┘    └──────┬──────┘
       └────────┬────────┘
                ▼
        Road DNA Engine
                │
       ┌────────┴────────┐
       ▼                 ▼
 Accessibility Map   Admin Dashboard
       │
       ▼
 Accessibility Route
```

핵심 파이프라인: **Sensor → Detection → Location → Aggregation → Score**

### 기술 스택

| 영역 | 기술 |
|---|---|
| App | Flutter |
| 센서 | Accelerometer, Gyroscope |
| 위치 | GPS |
| 지도 | Kakao Map / Naver Map / Mapbox |
| 감지 | 센서 기반 이상 탐지 (Threshold → 향후 ML) |
| Backend | Spring Boot / Node.js |
| DB | PostgreSQL + PostGIS |
| Dashboard | React |

---

## 5. MVP 범위

### P0 — Must Have (해커톤에서 반드시 구현)

| ID | 기능 |
|---|---|
| P0-01 | 현재 위치 지도 표시 |
| P0-02 | 이동 유형 선택 |
| P0-03 | 측정 시작/종료 |
| P0-04 | 가속도 센서 수집 |
| P0-05 | GPS 수집 |
| P0-06 | 이상 충격 감지 |
| P0-07 | 이벤트 서버 전송 |
| P0-08 | 위험 후보 지도 표시 |
| P0-09 | Road DNA Score |

### P1 — Should Have (시간이 허용되면)

| ID | 기능 |
|---|---|
| P1-01 | 자이로스코프 분석 |
| P1-02 | 다수 사용자 신뢰도 |
| P1-03 | 접근성 경로 비교 |
| P1-04 | 사용자 기여도 |
| P1-05 | 관리자 대시보드 |

### P2 — Future (해커톤 이후)

- AI 장애물 자동 분류 / 사진 기반 장애물 검증
- 실제 휠체어 이동 학습 데이터 / 실시간 접근성 내비게이션
- 지자체 API / 지도 플랫폼 API / IoT 휠체어 센서
- 도시 접근성 Digital Twin

**P0만 완성돼도 발표 시연은 가능하다.**

---

## 6. 기능 명세

### F-001 회원/익명 사용자

MVP에서는 회원가입 없이 익명 UUID를 생성한다.

```text
App 최초 실행 → Device Anonymous UUID 생성 → Local Secure Storage 저장
```

- 최초 실행 시 UUID 생성, 재실행 시 유지
- 서버에 개인정보 전송하지 않음

### F-002 이동 유형 선택

`WHEELCHAIR` / `STROLLER` / `WALKING` — MVP 핵심 데이터는 WHEELCHAIR, STROLLER.

### F-003 측정 세션

```text
[측정 시작] → POST /sessions → Session ID 발급 → GPS + Sensor Tracking ON
[측정 종료] → Tracking OFF → PATCH /sessions/{id}/end
```

### F-004 센서 수집

- 수집: Accelerometer X/Y/Z, Gyroscope X/Y/Z, Timestamp
- 권장 Sampling Rate: 20~50Hz (기기 성능에 따라 조정)
- 원본 센서 데이터 전체를 서버로 전송하지 않는다:

```text
RAW SENSOR → Local Filtering → Window Analysis(2초) → Anomaly Candidate → 서버 전송
```

### F-005 이상 충격 감지

중력 영향 제거 후 합성 가속도 계산:

```text
Magnitude = √(x² + y² + z²)
```

- Window: 2초 / Feature: Mean, Std, Max Peak, Peak Count, RMS
- 결과 분류: `NORMAL` / `LOW_IMPACT` / `MEDIUM_IMPACT` / `HIGH_IMPACT`
- Threshold(T1/T2/T3)는 임의 확정하지 않고 **직접 테스트로 Calibration**한다
- MVP에서는 `CURB`, `POTHOLE`처럼 장애물 종류를 확정하지 않는다 → `UNKNOWN_IMPACT` / `MOVEMENT BARRIER CANDIDATE`로 표현

### F-006 Barrier Candidate 생성 + 오탐 방지

```text
Impact Detection
→ 현재 GPS 이동 중인가?          ├─ NO → 제외
→ 비정상적으로 큰 단발성 충격인가? ├─ YES → 휴대폰 낙하 가능성 → 제외/보류
→ 이동 중 반복적 진동인가?
→ GPS Accuracy 확인 (기준 이하면 보류 또는 낮은 신뢰도 부여)
→ Barrier Candidate 생성
```

오탐 방지는 이 프로젝트의 **가장 중요한 개발 포인트**다. 발전형은 GPS Speed, Accelerometer, Gyroscope, Screen State, Movement Type을 종합 판단한다.

### F-007 지도

- 표시: 현재 위치, Road DNA Road Layer, Barrier Candidate, Accessibility Score
- Marker 클릭 시: 구간명, Road DNA Score, Confidence, 최근 감지 시각

### F-008 Road DNA Score

```text
Base Score = 100
Impact Penalty    = Impact Frequency × Severity Weight
Vibration Penalty = Vibration Level × Weight

Road DNA Score = Clamp(Base - Impact Penalty - Vibration Penalty, 0, 100)
```

| 점수 | 등급 |
|---|---|
| 80~100 | GOOD |
| 60~79 | NORMAL |
| 40~59 | CAUTION |
| 0~39 | POOR |

- 이동 유형별로 별도 점수를 저장한다 (`wheelchair` / `stroller` / `walking`)
- **데이터가 없으면 100점이 아니라 `UNKNOWN`** — 서비스 신뢰성의 핵심 원칙
- 검증된 접근성 표준 점수라고 주장하지 않고 MVP 내부 지표로 정의한다

Confidence:

```text
Confidence = Data Volume Weight + Unique User Weight + Repeatability Weight + Recency Weight
```

예: 1명 감지 → 20 (LOW), 5명 → 65 (MEDIUM), 20명 → 92 (HIGH)

### 접근성 경로 추천 (P1)

```text
Route Cost = Distance Weight + Accessibility Penalty
```

> ⚡ 빠른 경로: 8분 · 접근성 43
> ♿ Road DNA 추천: 11분 · 접근성 91
> "3분 더 걸리지만 이동이 편리한 경로입니다."

---

## 7. API 명세

Base URL: `/api/v1`

| Method | Endpoint | 기능 |
|---|---|---|
| POST | `/sessions` | 이동 측정 세션 생성 |
| PATCH | `/sessions/{sessionId}/end` | 측정 종료 |
| POST | `/sessions/{sessionId}/events` | 이상 충격 후보 등록 |
| GET | `/roads/nearby` | 주변 도로 데이터 |
| GET | `/roads/{roadSegmentId}` | 도로 상세 |
| GET | `/routes` | 접근성 경로 조회 |

### POST `/sessions`

```json
// Request
{
  "anonymousUserId": "uuid",
  "movementType": "WHEELCHAIR",
  "startedAt": "2026-07-18T13:00:00Z"
}
// Response 201
{ "sessionId": "session_uuid", "status": "ACTIVE" }
```

### PATCH `/sessions/{sessionId}/end`

```json
// Request
{ "endedAt": "2026-07-18T13:30:00Z" }
// Response
{ "sessionId": "session_uuid", "status": "COMPLETED" }
```

### POST `/sessions/{sessionId}/events`

```json
// Request
{
  "latitude": 35.1595,
  "longitude": 126.8526,
  "gpsAccuracy": 4.2,
  "severity": 0.82,
  "peakValue": 3.42,
  "movementType": "WHEELCHAIR",
  "detectedAt": "2026-07-18T13:10:00Z"
}
// Response
{ "eventId": "event_uuid", "roadSegmentId": "road_uuid", "status": "ACCEPTED" }
```

### GET `/roads/nearby`

Query: `latitude`, `longitude`, `radius`, `movementType`

```json
{
  "roads": [
    { "roadSegmentId": "road_001", "score": 72, "confidence": 0.82, "eventCount": 14 }
  ]
}
```

### GET `/roads/{roadSegmentId}`

```json
{
  "roadSegmentId": "road_001",
  "roadName": "Example Road",
  "scores": { "wheelchair": 52, "stroller": 71, "walking": 92 },
  "confidence": 0.91,
  "eventCount": 82,
  "updatedAt": "2026-07-18T13:00:00Z"
}
```

### GET `/routes`

Query: `originLat`, `originLng`, `destinationLat`, `destinationLng`, `movementType`

```json
{
  "routes": [
    { "type": "FASTEST", "distance": 500, "duration": 480, "accessibilityScore": 43 },
    { "type": "ACCESSIBLE", "distance": 620, "duration": 660, "accessibilityScore": 91 }
  ]
}
```

---

## 8. DB 설계

**권장 DB: PostgreSQL + PostGIS** — `ST_DWithin()`(공간 검색), `ST_ClosestPoint()`(최근접 도로) 등 GIS 연산 활용.

```text
ANONYMOUS_USER (user_id, created_at)
   │ 1:N
MOVEMENT_SESSION (session_id, user_id, movement_type, status, started_at, ended_at)
   │ 1:N
SENSOR_EVENT (event_id, session_id, road_segment_id, latitude, longitude,
              gps_accuracy, severity, peak_value, detected_at)
   │ N:1
ROAD_SEGMENT (road_segment_id, geometry, road_name)
   │ 1:N
ROAD_SCORE (score_id, road_segment_id, movement_type, score, confidence,
            event_count, updated_at)
```

- GPS 좌표 하나를 장애물로 확정하지 않고, 반경 5~10m 데이터를 하나의 **Road Segment**로 묶어 집계한다.

---

## 9. 화면 설계 (Flutter)

| # | 화면 | Route | 핵심 |
|---|---|---|---|
| 01 | Splash | `/splash` | UUID 확인/생성 → 권한 확인 → Home |
| 02 | Permission | `/permission` | Location + Motion Sensor 권한, 거부 시 기능 제한 안내 |
| 03 | Home Map | `/home` | 지도, 현재 위치, Road DNA Layer, Barrier Marker, CTA **[Road DNA 측정 시작]** |
| 04 | Movement Type | Bottom Sheet | ♿ 휠체어 / 👶 유모차 / 🚶 보행 선택 → 세션 생성 |
| 05 | Tracking | `/tracking` | 이동 거리·분석 도로·발견 후보 표시, [측정 종료] |
| 06 | Detection Feedback | Toast | "⚠ 이동 충격 패턴 감지" — Modal 금지, 이동 방해 없는 Bottom Toast |
| 07 | Road Detail | — | Road DNA Score, 유형별 점수, 감지 이벤트 수, 신뢰도 |
| 08 | Route Comparison | — | FASTEST vs ROAD DNA 추천 경로 비교, [Road DNA 경로 선택] |

- 실시간 센서값은 메인 UI에 과도하게 노출하지 않는다.
- 개발/시연 모드에서는 **Debug Panel**(가속도 XYZ, Magnitude, GPS, Detection) 제공 — 라이브 시연에 유용.

### Home Map 상태

```dart
currentLocation
nearbyRoads
barrierMarkers
selectedRoad
```

### Flutter 프로젝트 구조

```text
lib/
├── core/          # constants, permissions, network, utils
├── features/      # map, tracking, sensor, road, route
├── data/          # models, repositories, datasources
├── services/      # sensor_service, location_service, detection_service, api_service
└── main.dart
```

**센서 로직과 UI 로직은 반드시 분리한다.**

---

## 10. 감지 알고리즘

MVP는 AI라고 과장하지 않고 **센서 기반 이상 탐지 알고리즘**으로 시작한다.

```text
START TRACKING
initialize sensorBuffer, gpsLocation

WHILE tracking:
    sensorData = READ_ACCELEROMETER()
    linearAcceleration = REMOVE_GRAVITY(sensorData)
    magnitude = SQRT(x² + y² + z²)
    ADD magnitude TO sensorBuffer

    IF bufferDuration >= WINDOW_SIZE:
        mean, std, maxPeak, peakCount, rms = ANALYZE(sensorBuffer)
        anomalyScore = CALCULATE_ANOMALY(std, maxPeak, peakCount, rms)

        IF anomalyScore > THRESHOLD:
            gps = GET_CURRENT_LOCATION()
            IF gps.accuracy <= GPS_LIMIT AND CHECK_USER_MOVEMENT():
                event = CREATE_BARRIER_CANDIDATE(gps, anomalyScore, maxPeak, movementType)
                SEND_EVENT_TO_SERVER(event)

        CLEAR sensorBuffer
```

### Road Score 집계

```text
FUNCTION calculateRoadScore(segment, movementType):
    events = GET_EVENTS(segment, movementType)
    IF events.count == 0: RETURN UNKNOWN

    frequency = events.count / totalTraversalCount
    averageSeverity = AVERAGE(events.severity)
    impactPenalty = frequency × averageSeverity × IMPACT_WEIGHT

    RETURN CLAMP(100 - impactPenalty, 0, 100)
```

### 향후 ML 확장

```text
Sensor Time-Series → Labeling(NORMAL/ROUGH_SURFACE/CURB/POTHOLE/SLOPE)
→ Feature Engineering → Model Training → Classification Model → Probability
```

발표 멘트: "현재 MVP에서는 센서 기반 이상 탐지를 구현했으며, 서비스 운영을 통해 실제 이동 데이터를 확보한 후 시계열 머신러닝 모델로 확장할 계획입니다."

---

## 11. 개인정보 설계

서버가 알 필요 없는 데이터는 수집하지 않는다.

```text
❌ 집에서 출발했다 / 사용자 전체 이동 기록 영구 보관
⭕ 도로 구간 A에서 진동 이벤트 발생 / Road Segment #152 / Severity 0.72
```

- 원본 이동경로를 계속 보관하지 않고 분석 후 **도로 단위 데이터로 집계**
- 원칙: **최소수집 · 익명화 · 집계 · 보관기간 제한**
- 발표 멘트: "개인의 이동경로를 추적하는 것이 목적이 아니라, 익명화·집계된 도로 접근성 정보를 구축하는 것을 목적으로 설계했습니다."

---

## 12. 개발 계획

### Jira Epic / 백로그

| Epic | 티켓 | SP | 우선순위 |
|---|---|---|---|
| 01 Project Setup | RD-001 Flutter 초기 세팅 | 2 | Highest |
| | RD-002 Backend 구축 (API 서버, DB, Health Check) | 3 | Highest |
| 02 Location | RD-101 GPS 권한 / RD-102 위치 수집 / RD-103 지도 표시 / RD-104 이동 중 업데이트 | 2/3/3/3 | |
| 03 Sensor | RD-201 Accelerometer / RD-202 Gyroscope / RD-203 Window Buffer / RD-204 Gravity Filtering / RD-205 Magnitude | 3/2/3/3/2 | RD-201·203 Highest |
| 04 Detection | RD-301 Peak Detection / RD-302 Anomaly Score / RD-303 이동 여부 검증 / RD-304 GPS Accuracy 검증 / RD-305 Barrier Candidate | 3/5/3/2/3 | RD-301·302·305 Highest |
| 05 Session | RD-401 이동 유형 / RD-402 세션 생성 / RD-403 측정 시작 / RD-404 측정 종료 | 2/3/3/2 | RD-403·404 Highest |
| 06 Backend | RD-501 Session API / RD-502 Event API / RD-503 Road Segment Mapping / RD-504 Road Score API / RD-505 Nearby API | 3/5/5/5/3 | RD-502 Highest |
| 07 Map | RD-601 Road DNA Map / RD-602 Barrier Marker / RD-603 Marker Detail / RD-604 Score 시각화 | 5/3/2/3 | RD-601·602 Highest |
| 08 Routing | RD-701 기본 경로 / RD-702 Segment 분석 / RD-703 접근성 Cost 계산 / RD-704 경로 비교 UI | 5/5/8/3 | |
| 09 Admin | RD-801 관리자 지도 / RD-802 Heatmap / RD-803 통계 Dashboard | 5/5/3 | |

### Sprint 계획

| Sprint | 티켓 | 목표 |
|---|---|---|
| 1. Core Proof | RD-001, 101, 102, 201, 203, 205, 301 | 휴대폰을 움직이면 센서값 변화가 보인다 |
| 2. Core Experience | RD-302, 305, 402, 403, 404, 502 | 이동 중 충격을 감지하면 서버에 저장된다 |
| 3. Visualization | RD-103, 601, 602, 604 | 충격 발생 위치가 실제 지도에 나타난다 |
| 4. Winning Features | RD-503, 504, 703, 704, 801 | 데이터가 도시 문제 해결로 연결되는 모습 |

### 일자별 개발 순서

- **DAY 1:** Flutter 앱 — 센서값 실시간 출력, GPS 수집, 지도 표시
- **DAY 2:** Window 분석 → 충격 감지 → GPS 매핑 → Backend 전송
- **DAY 3:** 지도 Marker → Road DNA Score → 이동 유형 → 접근성 Map UI
- **DAY 4:** Dashboard → 데이터 시각화 → Demo Data 구축 → 발표 시연 안정화

일정이 더 짧다면 **센서 수집 → 충격 감지 → 지도 표시**부터 무조건 끝낸다.

### 최종 개발 우선순위

```text
1. SENSOR      실제 센서값을 받을 수 있는가?
2. DETECTION   평지와 충격 상황의 데이터 차이가 발생하는가?
3. LOCATION    충격 순간의 위치를 얻을 수 있는가?
4. MAP         발생 위치를 지도에 표시할 수 있는가?
5. AGGREGATION 동일 구간의 여러 데이터를 합칠 수 있는가?
6. SCORE       도로 접근성을 수치화할 수 있는가?
7. ROUTING     접근성이 높은 경로를 추천할 수 있는가?
8. DASHBOARD   지자체 활용 모습을 보여줄 수 있는가?
```

1~3이 작동하면 MVP 성공, 4~5까지 되면 출품 완성도 높음, 6까지 작동하면 강력한 결과물.

---

## 13. Definition of Done

```text
앱 실행 → 이동 유형 선택 → 측정 시작 → 실제 이동 → 센서 데이터 수집
→ 비정상 충격 발생 → 앱에서 이상 감지 → GPS 위치 결합 → 서버 전송
→ 지도 Marker 생성 → Road DNA Score 반영
```

이 플로우가 **발표 현장에서 처음부터 끝까지 실제 작동하면 MVP 완료**다.

---

## 14. 발표 전략

### 라이브 데모 시나리오

1. "현재 Road DNA가 제 이동 데이터를 분석하고 있습니다." — **ROAD ANALYSIS ACTIVE**
2. 평평한 곳 이동 → `ROAD STATUS: GOOD 92`
3. 준비한 울퉁불퉁한 구간 이동 → `⚠ UNUSUAL ROAD IMPACT DETECTED` → 지도에 🔴 생성
4. "방금 발생한 충격 데이터가 GPS와 결합돼 이동 장애 후보로 기록됐습니다."
5. 관리자 대시보드 전환 — 방금 찍힌 위치 표시
6. "이 데이터가 여러 사용자에게 반복 수집되면 신뢰도가 올라갑니다." — Score `92 → 67`

발표 오프닝 슬라이드:

```text
일반 지도:        학교 ───────── 카페   5분
휠체어의 현실:    학교 ──── 🚧 턱 ──── X   이동 불가
```

> "지도에는 이 길이 존재합니다. 하지만 누군가에게는 존재하지 않는 길입니다."

### 3분 발표 대본 (요지)

- 지도에서 5분 거리가 누군가에게는 갈 수 없는 길이라면?
- 기존 지도는 빠른 길만 안내하고, 턱·노면 파손은 알려주지 못한다
- 이런 정보는 누군가 직접 신고해야만 등록된다 → "이동하는 것만으로 발견할 수 없을까?"
- Road DNA는 가속도 센서와 GPS로 진동·충격 데이터를 분석하고, 반복 감지 시 이동 장애 가능 구간으로 판단, 도로마다 Road DNA Score를 생성한다
- 휠체어·유모차 사용자에게 빠른 길이 아닌 **실제로 이동하기 좋은 길**을 추천
- 지자체는 City DNA Dashboard로 개선 우선순위를 데이터로 판단
- "한 사람의 이동이 하나의 데이터가 되고, 그 데이터가 다른 사람의 길이 되고, 결국 도시를 바꾸는 데이터가 됩니다."

### 심사위원 예상 질문 & 답변

| 질문 | 답변 핵심 |
|---|---|
| 폰을 떨어뜨려도 장애물로 인식하나? | 단일 이벤트로 판단하지 않음. GPS·충격 패턴·다수 사용자 데이터를 결합해 신뢰도 계산. '확정'이 아닌 '이동 장애 가능성 높은 구간'으로 표현 |
| 폰을 드는 방식이 달라 정확한가? | 절대값 비교가 아닌 개인 평상시 패턴 기준선 대비 상대 변화량 분석. 향후 다양한 기기 데이터로 개선 |
| GPS 오차는? | 단일 좌표 확정 대신 반경 구간 단위 집계. 이후 Map Matching 적용 계획 |
| 개인정보 문제는? | 핵심 데이터는 신원이 아닌 센서 패턴·공간 정보. 최소수집·익명화·집계·보관기간 제한 ("완벽히 문제없다"고 말하지 않기) |
| 기존 지도와 차이는? | 사람이 등록한 시설 정보가 아니라 이동 과정 자체에서 수집한 도로의 물리적 접근성을 지속 업데이트 |
| 사용자가 없으면 데이터도 없지 않나? (Cold Start) | 초기엔 공공 접근성·도로 데이터 활용 + 특정 지역 MVP 운영으로 축적. 사용자 증가에 따라 정확도 상승 구조 |
| 해커톤 기간에 구현 가능한가? | 전체 서비스가 아닌 핵심 가설 검증 MVP. 센서 수집 → 이상 감지 → 지도 표시를 실제 시연으로 증명 |

**원칙: 큰 꿈은 보여주되, MVP는 작아야 한다.**

---

## 15. 비즈니스 모델 & 확장 로드맵

### 비즈니스 모델

사용자는 **무료**. 핵심 고객은 B2G/B2B.

- **B2G:** 지자체 대상 **City Accessibility Dashboard SaaS** — 취약 지역 분석·개선 우선순위 제공
- **B2B:** 지도·내비게이션 서비스 대상 **Accessibility API** 판매

```text
시민 무료 사용 → 접근성 데이터 축적 → 지자체 분석 서비스
→ 도시 인프라 개선 → 시민 혜택 (데이터 선순환)
```

### 관리자 대시보드 구성 (P1)

- 상단: **Gwangju Accessibility Index** (예: 72.8)
- 지도: 🔴 접근성 취약 / 🟠 개선 필요 / 🟢 양호
- 지표: 이번 달 분석 거리, 이동 장애 후보 건수, HIGH Confidence 지점 수
- 개선 우선순위 테이블: 구간별 DNA Score · 신뢰도 · 반복 감지 횟수

### 확장 로드맵

1. **교통약자 접근성 지도** — 휠체어·유모차 센서 데이터로 이동 장벽 발견, 접근성 경로 추천
2. **시민 참여형 크라우드센싱** — 자전거·전동휠체어 등으로 확장, 이동수단별 개인화 Road DNA
3. **AI 도로 문제 자동 분류** — 이상 구간에서만 선택적으로 사진·확인 데이터 보완
4. **지자체 도시 관리 플랫폼** — 민원 후 대응이 아닌 데이터 기반 선제 발견 (개선 전후 비교)
5. **지도·모빌리티 플랫폼 API** — `휠체어 접근성 경로` 같은 새로운 길찾기 제공
6. **스마트시티 디지털 트윈** — "지금 이 도로를 누가 얼마나 편하게 이동할 수 있는가"의 데이터화

---

## 16. 팀 공유용 최종 목표

> **Road DNA MVP의 목표는 완벽한 휠체어 내비게이션을 만드는 것이 아니다.**
>
> 증명해야 할 것은 '이동 과정에서 발생하는 센서 데이터를 이용해 기존 지도에 존재하지 않는 도로 접근성 정보를 만들어낼 수 있다'는 것이다.
>
> MVP에서는 **센서 수집 → 이상 충격 감지 → GPS 매핑 → 지도 시각화**를 실제 구현하고, 이후 **다수 사용자 데이터 집계 → Road DNA Score → 접근성 경로 추천 → 지자체 도시 관리 플랫폼**으로 확장한다.

개발 목표 단계:

> **1차:** 휴대폰 센서 데이터를 수집한다.
> **2차:** 이동 중 비정상 충격을 감지한다.
> **3차:** 감지 순간의 위치를 지도에 찍는다.
> **4차:** 여러 감지 데이터를 도로 구간별로 집계한다.
> **5차:** 도로마다 Road DNA Score를 만든다.
> **6차:** Score 기반으로 접근성이 높은 경로를 추천한다.