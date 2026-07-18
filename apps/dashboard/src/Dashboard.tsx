import { useQuery } from "@tanstack/react-query";
import {
  Alert,
  Badge,
  Button,
  EmptyState,
  Metric,
  SegmentedControl,
  Skeleton,
  Surface,
} from "@road-dna/ui";
import {
  Accessibility,
  Activity,
  BarChart3,
  MapPinned,
  Moon,
  RefreshCw,
  Route,
  Sun,
  Users,
} from "lucide-react";
import { lazy, Suspense, useEffect, useMemo, useState } from "react";
import {
  getNearbyRoads,
  getOverview,
  getPriorities,
  getRoadDetail,
  isDemoMode,
} from "./api";
import { RoadDetailPanel } from "./RoadDetailPanel";
import {
  gradeLabel,
  gradeTone,
  movementLabel,
  type MovementFilter,
} from "./types";

const RoadMap = lazy(() =>
  import("./RoadMap").then((module) => ({ default: module.RoadMap })),
);

const movementItems = [
  { label: "전체", value: "ALL" },
  { label: "휠체어", value: "WHEELCHAIR" },
  { label: "유모차", value: "STROLLER" },
  { label: "도보", value: "WALKING" },
] satisfies Array<{ label: string; value: MovementFilter }>;

const distance = (meters: number): string =>
  meters >= 1_000
    ? `${(meters / 1_000).toFixed(1)} km`
    : `${meters.toLocaleString("ko-KR")} m`;

export function Dashboard() {
  const [movement, setMovement] = useState<MovementFilter>("ALL");
  const [selectedRoadId, setSelectedRoadId] = useState<string | null>(null);
  const [darkMode, setDarkMode] = useState(false);
  const movementType = movement === "ALL" ? undefined : movement;
  const overview = useQuery({
    queryFn: () => getOverview(movementType),
    queryKey: ["dashboard", "overview", movement],
    refetchInterval: 30_000,
    staleTime: 15_000,
  });
  const priorities = useQuery({
    queryFn: () => getPriorities(movementType),
    queryKey: ["dashboard", "priorities", movement],
    refetchInterval: 30_000,
    staleTime: 15_000,
  });
  const roads = useQuery({
    queryFn: () => getNearbyRoads(movementType),
    queryKey: ["roads", "nearby", movement],
    refetchInterval: 30_000,
    staleTime: 15_000,
  });
  const detail = useQuery({
    enabled: Boolean(selectedRoadId),
    queryFn: () => getRoadDetail(selectedRoadId!),
    queryKey: ["roads", "detail", selectedRoadId],
    staleTime: 15_000,
  });
  const isFetching =
    overview.isFetching || priorities.isFetching || roads.isFetching;
  const anyError = overview.error ?? priorities.error ?? roads.error;
  const updatedAt = useMemo(
    () =>
      roads.data?.roads
        .map((road) => road.updatedAt)
        .sort()
        .at(-1) ?? null,
    [roads.data],
  );

  useEffect(() => {
    document.documentElement.dataset.rdTheme = darkMode ? "dark" : "light";
  }, [darkMode]);

  return (
    <div className="dashboard-shell">
      <a className="skip-link" href="#dashboard-content">
        본문으로 건너뛰기
      </a>
      <aside className="dashboard-sidebar">
        <div className="dashboard-brand" aria-label="Road DNA">
          <span className="dashboard-brand__mark">
            <Route aria-hidden />
          </span>
          <span>
            <strong>Road DNA</strong>
            <small>도시 접근성 관제센터</small>
          </span>
        </div>
        <nav aria-label="주요 메뉴">
          <a aria-current="page" href="#overview">
            <BarChart3 aria-hidden size={20} />
            도시 현황
          </a>
          <a href="#road-map">
            <MapPinned aria-hidden size={20} />
            도로 지도
          </a>
          <a href="#priorities">
            <Accessibility aria-hidden size={20} />
            개선 우선순위
          </a>
        </nav>
        <div className="dashboard-sidebar__foot">
          <span className="live-dot" />
          <span>30초마다 자동 갱신</span>
        </div>
      </aside>

      <main id="dashboard-content">
        <header className="dashboard-topbar">
          <div>
            <span className="eyebrow">광주광역시 · 상무지구</span>
            <h1>도시 접근성 현황</h1>
            <p>
              이동 센서 신호를 도로 구간 단위로 모아 개선이 필요한 곳을 먼저
              보여드려요.
            </p>
          </div>
          <div className="dashboard-topbar__actions">
            {isDemoMode && <Badge tone="info">명시적 데모 데이터</Badge>}
            <Button
              aria-label={darkMode ? "밝은 화면 사용" : "어두운 화면 사용"}
              leading={
                darkMode ? (
                  <Sun aria-hidden size={18} />
                ) : (
                  <Moon aria-hidden size={18} />
                )
              }
              onClick={() => setDarkMode((value) => !value)}
              size="small"
              tone="secondary"
            >
              {darkMode ? "라이트" : "다크"}
            </Button>
            <Button
              aria-label="대시보드 새로고침"
              disabled={isFetching}
              leading={<RefreshCw aria-hidden size={18} />}
              onClick={() =>
                void Promise.all([
                  overview.refetch(),
                  priorities.refetch(),
                  roads.refetch(),
                ])
              }
              size="small"
              tone="secondary"
            >
              새로고침
            </Button>
          </div>
        </header>

        <section aria-labelledby="movement-filter-title" className="filter-row">
          <div>
            <h2 id="movement-filter-title">이동 유형</h2>
            <p>같은 길도 이동 방식에 따라 불편도가 달라요.</p>
          </div>
          <SegmentedControl
            ariaLabel="이동 유형 필터"
            items={movementItems}
            onChange={(value) => {
              setMovement(value);
              setSelectedRoadId(null);
            }}
            value={movement}
          />
        </section>

        {anyError && (
          <Alert title="최신 데이터를 불러오지 못했어요" tone="critical">
            {anyError.message} API 연결과 CORS 설정을 확인해 주세요.
          </Alert>
        )}

        <section aria-labelledby="overview-title" id="overview">
          <div className="section-heading">
            <div>
              <span className="eyebrow">한눈에 보기</span>
              <h2 id="overview-title">{movementLabel[movement]} 접근성 지표</h2>
            </div>
            <span className="freshness">
              {updatedAt
                ? `최근 신호 ${new Intl.RelativeTimeFormat("ko", {
                    numeric: "auto",
                  }).format(
                    Math.round(
                      (new Date(updatedAt).getTime() - Date.now()) / 60_000,
                    ),
                    "minute",
                  )}`
                : "수집 대기 중"}
            </span>
          </div>
          <div className="metric-grid">
            {overview.isPending ? (
              Array.from({ length: 4 }, (_, index) => (
                <Surface key={index} className="metric-card">
                  <Skeleton height={88} />
                </Surface>
              ))
            ) : overview.data ? (
              <>
                <Surface className="metric-card metric-card--featured">
                  <span className="metric-card__icon">
                    <Accessibility aria-hidden />
                  </span>
                  <Metric
                    label="도시 접근성 지수"
                    trend="Road DNA 내부 지표"
                    value={
                      overview.data.accessibilityIndex === null
                        ? "—"
                        : `${overview.data.accessibilityIndex}점`
                    }
                  />
                </Surface>
                <Surface className="metric-card">
                  <span className="metric-card__icon">
                    <Route aria-hidden />
                  </span>
                  <Metric
                    label="분석한 도로"
                    trend={`${overview.data.roadCount}개 구간`}
                    value={distance(overview.data.analyzedDistanceMeters)}
                  />
                </Surface>
                <Surface className="metric-card">
                  <span className="metric-card__icon">
                    <Users aria-hidden />
                  </span>
                  <Metric
                    label="활성 기여자"
                    trend="익명 참여자"
                    value={`${overview.data.activeContributors.toLocaleString("ko-KR")}명`}
                  />
                </Surface>
                <Surface className="metric-card">
                  <span className="metric-card__icon">
                    <Activity aria-hidden />
                  </span>
                  <Metric
                    label="수용된 감지"
                    trend={`고신뢰 구간 ${overview.data.highConfidenceRoadCount}개`}
                    value={`${overview.data.acceptedEventCount.toLocaleString("ko-KR")}건`}
                  />
                </Surface>
              </>
            ) : null}
          </div>
        </section>

        <section className="operations-grid">
          <Surface className="map-card" id="road-map" padding="none">
            <div className="card-heading">
              <div>
                <span className="eyebrow">Road DNA map</span>
                <h2>구간별 접근성 지도</h2>
              </div>
              <Badge
                dot
                tone={roads.data?.roads.length ? "success" : "neutral"}
              >
                {roads.data?.roads.length ?? 0}개 신호
              </Badge>
            </div>
            {roads.isPending ? (
              <Skeleton className="map-skeleton" height={520} />
            ) : roads.data?.roads.length ? (
              <Suspense
                fallback={<Skeleton className="map-skeleton" height={520} />}
              >
                <RoadMap
                  onSelect={setSelectedRoadId}
                  roads={roads.data.roads}
                  selectedRoadId={selectedRoadId}
                />
              </Suspense>
            ) : (
              <EmptyState
                description="이 지역에 아직 분석할 수 있는 센서 신호가 없어요."
                icon={<MapPinned aria-hidden size={32} />}
                title="지도 데이터가 없어요"
              />
            )}
          </Surface>

          <Surface className="priority-card" id="priorities" padding="none">
            <div className="card-heading">
              <div>
                <span className="eyebrow">우선 개선 후보</span>
                <h2>먼저 살펴볼 도로</h2>
              </div>
            </div>
            <div className="priority-list">
              {priorities.isPending
                ? Array.from({ length: 5 }, (_, index) => (
                    <div className="priority-skeleton" key={index}>
                      <Skeleton height={72} />
                    </div>
                  ))
                : priorities.data?.roads.map((road, index) => (
                    <button
                      className="priority-row"
                      data-selected={road.roadSegmentId === selectedRoadId}
                      key={`${road.roadSegmentId}-${road.movementType}`}
                      onClick={() => setSelectedRoadId(road.roadSegmentId)}
                      type="button"
                    >
                      <span className="priority-row__rank">
                        {String(index + 1).padStart(2, "0")}
                      </span>
                      <span className="priority-row__content">
                        <strong>{road.roadName}</strong>
                        <small>
                          {movementLabel[road.movementType]} · 감지{" "}
                          {road.eventCount}건 · 신뢰도{" "}
                          {Math.round(road.confidence * 100)}%
                        </small>
                      </span>
                      <span className="priority-row__score">
                        <strong>{road.score}</strong>
                        <Badge tone={gradeTone[road.grade]}>
                          {gradeLabel[road.grade]}
                        </Badge>
                      </span>
                    </button>
                  ))}
              {!priorities.isPending && !priorities.data?.roads.length && (
                <EmptyState
                  description="점수가 계산되려면 수용된 센서 신호가 필요해요."
                  title="개선 후보가 아직 없어요"
                />
              )}
            </div>
          </Surface>
        </section>

        <footer className="dashboard-footer">
          <p>
            Road DNA 점수는 익명 센서 신호를 집계한 실험적 내부 지표이며 법정
            접근성 인증이 아닙니다.
          </p>
          <span>개인 이동 경로 원본은 저장하지 않아요.</span>
        </footer>
      </main>

      {selectedRoadId && (
        <RoadDetailPanel
          data={detail.data}
          error={detail.error}
          isPending={detail.isPending}
          onClose={() => setSelectedRoadId(null)}
        />
      )}
    </div>
  );
}
