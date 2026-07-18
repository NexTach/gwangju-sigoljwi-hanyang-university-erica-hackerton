import { useQuery } from "@tanstack/react-query";
import { Alert, EmptyState, Skeleton } from "@road-dna/ui";
import { MapPinned } from "lucide-react";
import { lazy, Suspense } from "react";
import { getNearbyRoads, getOverview, getPriorities } from "./api";
import { gradeLabel } from "./types";

const RoadMap = lazy(() =>
  import("./RoadMap").then((module) => ({ default: module.RoadMap })),
);

const distance = (meters: number): string =>
  meters >= 1_000
    ? `${(meters / 1_000).toLocaleString("ko-KR", {
        maximumFractionDigits: 1,
      })} km`
    : `${meters.toLocaleString("ko-KR")} m`;

const referenceDate = (): string => {
  const parts = new Intl.DateTimeFormat("ko-KR", {
    day: "2-digit",
    month: "2-digit",
    timeZone: "Asia/Seoul",
    year: "numeric",
  }).formatToParts(new Date());
  const get = (type: Intl.DateTimeFormatPartTypes) =>
    parts.find((part) => part.type === type)?.value ?? "";
  return `${get("year")}.${get("month")}.${get("day")}`;
};

const gradeClass = (grade: string): string => {
  if (grade === "GOOD") return "is-good";
  if (grade === "POOR") return "is-poor";
  if (grade === "UNKNOWN") return "is-unknown";
  return "is-caution";
};

export function Dashboard() {
  const overview = useQuery({
    queryFn: () => getOverview(),
    queryKey: ["dashboard", "overview"],
    refetchInterval: 30_000,
    staleTime: 15_000,
  });
  const priorities = useQuery({
    queryFn: () => getPriorities(),
    queryKey: ["dashboard", "priorities"],
    refetchInterval: 30_000,
    staleTime: 15_000,
  });
  const roads = useQuery({
    queryFn: () => getNearbyRoads(),
    queryKey: ["roads", "nearby"],
    refetchInterval: 30_000,
    staleTime: 15_000,
  });
  const anyError = overview.error ?? priorities.error ?? roads.error;
  const detectedCandidateCount = priorities.data?.roads.length;

  return (
    <div className="dashboard-shell">
      <a className="skip-link" href="#dashboard-content">
        본문으로 건너뛰기
      </a>

      <main className="dashboard-canvas" id="dashboard-content">
        <header className="dashboard-header">
          <div className="dashboard-brand">
            <span className="dashboard-brand__mark" aria-hidden>
              <svg fill="none" viewBox="0 0 40 40">
                <path
                  d="M6 28c8 2 11-16 18-17s8 9 10-3"
                  stroke="currentColor"
                  strokeLinecap="round"
                  strokeWidth="5"
                />
                <circle cx="6" cy="28" fill="currentColor" r="4" />
              </svg>
            </span>
            <div>
              <span>Road DNA for Cities</span>
              <h1>광주광역시 북구</h1>
            </div>
          </div>

          <div className="dashboard-header__meta">
            <span>{referenceDate()} 기준</span>
          </div>
        </header>

        {anyError && (
          <Alert title="최신 데이터를 불러오지 못했어요" tone="critical">
            {anyError.message} API 연결과 CORS 설정을 확인해 주세요.
          </Alert>
        )}

        <section aria-label="광주광역시 북구 접근성 핵심 지표">
          <div className="metric-grid">
            {overview.isPending ? (
              Array.from({ length: 4 }, (_, index) => (
                <article
                  className={`metric-card ${
                    index === 0 ? "metric-card--featured" : ""
                  }`}
                  key={index}
                >
                  <Skeleton height={94} />
                </article>
              ))
            ) : overview.data ? (
              <>
                <article className="metric-card metric-card--featured">
                  <span className="metric-card__label">
                    Gwangju Accessibility Index
                  </span>
                  <strong className="metric-card__value">
                    {overview.data.accessibilityIndex === null
                      ? "—"
                      : overview.data.accessibilityIndex.toLocaleString(
                          "ko-KR",
                        )}
                  </strong>
                  <span className="metric-card__note metric-card__note--good">
                    {overview.data.roadCount.toLocaleString("ko-KR")}개 도로
                    구간의 익명 신호 기반
                  </span>
                </article>

                <article className="metric-card">
                  <span className="metric-card__label">이번 달 분석 거리</span>
                  <strong className="metric-card__value">
                    {distance(overview.data.analyzedDistanceMeters)}
                  </strong>
                  <span className="metric-card__note">
                    이동 유형별 도로 분석
                  </span>
                </article>

                <article className="metric-card">
                  <span className="metric-card__label">이동 장애 후보</span>
                  <strong className="metric-card__value">
                    {detectedCandidateCount === undefined
                      ? "—"
                      : `${detectedCandidateCount.toLocaleString("ko-KR")}건`}
                  </strong>
                  <span className="metric-card__note">
                    우선 검토가 필요한 구간
                  </span>
                </article>

                <article className="metric-card">
                  <span className="metric-card__label">High Confidence</span>
                  <strong className="metric-card__value">
                    {overview.data.highConfidenceRoadCount.toLocaleString(
                      "ko-KR",
                    )}
                    곳
                  </strong>
                  <span className="metric-card__note">
                    신뢰도 기준 충족 구간
                  </span>
                </article>
              </>
            ) : null}
          </div>
        </section>

        <section className="operations-grid">
          <article
            aria-label="접근성 현황 지도"
            className="map-card"
            id="road-map"
          >
            {roads.isPending ? (
              <Skeleton className="map-skeleton" height={320} />
            ) : roads.data?.roads.length ? (
              <Suspense
                fallback={<Skeleton className="map-skeleton" height={320} />}
              >
                <RoadMap roads={roads.data.roads} />
              </Suspense>
            ) : (
              <EmptyState
                description="이 지역에 아직 분석할 수 있는 센서 신호가 없어요."
                icon={<MapPinned aria-hidden size={32} />}
                title="지도 데이터가 없어요"
              />
            )}
          </article>

          <article className="priority-card" id="priorities">
            <header className="card-heading">
              <div>
                <h2>개선 우선순위</h2>
              </div>
            </header>

            <div className="priority-table-wrap">
              {priorities.isPending ? (
                <div className="priority-loading">
                  {Array.from({ length: 5 }, (_, index) => (
                    <Skeleton height={52} key={index} />
                  ))}
                </div>
              ) : priorities.data?.roads.length ? (
                <table className="priority-table">
                  <thead>
                    <tr>
                      <th scope="col">구간</th>
                      <th scope="col">Score</th>
                      <th scope="col">신뢰도</th>
                      <th scope="col">반복감지</th>
                    </tr>
                  </thead>
                  <tbody>
                    {priorities.data.roads.map((road) => (
                      <tr key={`${road.roadSegmentId}-${road.movementType}`}>
                        <td>
                          <span className="priority-road-label">
                            <i aria-hidden className={gradeClass(road.grade)} />
                            <span>
                              <strong>{road.roadName}</strong>
                            </span>
                          </span>
                        </td>
                        <td>
                          <strong
                            className={`priority-score ${gradeClass(road.grade)}`}
                          >
                            {road.score}
                          </strong>
                          <small className="mobile-table-label">
                            {gradeLabel[road.grade]}
                          </small>
                        </td>
                        <td>
                          {Math.round(road.confidence * 100)}%
                          <small className="mobile-table-label">신뢰도</small>
                        </td>
                        <td>
                          {road.eventCount.toLocaleString("ko-KR")}회
                          <small className="mobile-table-label">반복감지</small>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              ) : (
                <EmptyState
                  description="점수가 계산되려면 수용된 센서 신호가 필요해요."
                  title="개선 후보가 아직 없어요"
                />
              )}
            </div>
          </article>
        </section>
      </main>
    </div>
  );
}
