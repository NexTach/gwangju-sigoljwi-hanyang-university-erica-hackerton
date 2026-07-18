import type { PriorityRoad, RoadMapItem } from "@road-dna/contracts";
import { useQuery } from "@tanstack/react-query";
import { Alert, EmptyState, Skeleton } from "@road-dna/ui";
import { MapPinned } from "lucide-react";
import {
  lazy,
  Suspense,
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import {
  getNearbyRoads,
  getOverview,
  getPriorities,
  getRoadDetail,
} from "./api";
import { RoadDetailPanel } from "./RoadDetailPanel";
import { gradeLabel, movementLabel } from "./types";

const RoadMap = lazy(() =>
  import("./RoadMap").then((module) => ({ default: module.RoadMap })),
);

const pollingInterval = 5_000;

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

const synchronizedTime = (timestamp: number): string =>
  new Intl.DateTimeFormat("ko-KR", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    timeZone: "Asia/Seoul",
  }).format(new Date(timestamp));

const gradeClass = (grade: string): string => {
  if (grade === "GOOD") return "is-good";
  if (grade === "POOR") return "is-poor";
  if (grade === "UNKNOWN") return "is-unknown";
  return "is-caution";
};

interface ComparableRoad {
  confidence: number;
  roadSegmentId: string;
  score: number | null;
}

type RoadComparator<T extends ComparableRoad> = (first: T, second: T) => number;

const scoreOrder = <T extends ComparableRoad>(first: T, second: T): number =>
  (first.score ?? Number.POSITIVE_INFINITY) -
    (second.score ?? Number.POSITIVE_INFINITY) ||
  second.confidence - first.confidence;

const priorityOrder = <T extends ComparableRoad>(
  first: T,
  second: T,
): number => {
  const firstPriority = (100 - (first.score ?? 100)) * (0.5 + first.confidence);
  const secondPriority =
    (100 - (second.score ?? 100)) * (0.5 + second.confidence);
  return secondPriority - firstPriority || scoreOrder(first, second);
};

const oneRoadPerSegment = <T extends ComparableRoad>(
  roads: T[],
  compare: RoadComparator<T>,
): T[] => {
  const selected = new Map<string, T>();
  for (const road of roads) {
    const current = selected.get(road.roadSegmentId);
    const score = road.score ?? Number.POSITIVE_INFINITY;
    const currentScore = current?.score ?? Number.POSITIVE_INFINITY;
    if (
      !current ||
      score < currentScore ||
      (score === currentScore && road.confidence > current.confidence)
    ) {
      selected.set(road.roadSegmentId, road);
    }
  }
  return [...selected.values()].sort(compare);
};

export function Dashboard() {
  const [selectedRoadId, setSelectedRoadId] = useState<string | null>(null);
  const selectionTriggerRef = useRef<HTMLElement | null>(null);
  const overview = useQuery({
    queryFn: () => getOverview(),
    queryKey: ["dashboard", "overview"],
    placeholderData: (previousData) => previousData,
    refetchInterval: pollingInterval,
    staleTime: pollingInterval - 1_000,
  });
  const priorities = useQuery({
    queryFn: () => getPriorities(),
    queryKey: ["dashboard", "priorities"],
    placeholderData: (previousData) => previousData,
    refetchInterval: pollingInterval,
    staleTime: pollingInterval - 1_000,
  });
  const roads = useQuery({
    queryFn: () => getNearbyRoads(),
    queryKey: ["roads", "nearby"],
    placeholderData: (previousData) => previousData,
    refetchInterval: pollingInterval,
    staleTime: pollingInterval - 1_000,
  });
  const detail = useQuery({
    enabled: Boolean(selectedRoadId),
    queryFn: () => getRoadDetail(selectedRoadId!),
    queryKey: ["roads", "detail", selectedRoadId],
    refetchInterval: selectedRoadId ? pollingInterval : false,
    staleTime: pollingInterval - 1_000,
  });
  const anyError = overview.error ?? priorities.error ?? roads.error;
  const visiblePriorities = useMemo(
    () =>
      oneRoadPerSegment<PriorityRoad>(
        priorities.data?.roads ?? [],
        priorityOrder,
      ),
    [priorities.data?.roads],
  );
  const visibleRoads = useMemo(
    () => oneRoadPerSegment<RoadMapItem>(roads.data?.roads ?? [], scoreOrder),
    [roads.data?.roads],
  );
  const displayedRoadCount = overview.data?.roadCount ?? visibleRoads.length;
  const isSynchronizing =
    overview.isFetching || priorities.isFetching || roads.isFetching;
  const hasConnectedData = Boolean(
    overview.data && priorities.data && roads.data,
  );
  const lastSynchronizedAt = Math.max(
    overview.dataUpdatedAt,
    priorities.dataUpdatedAt,
    roads.dataUpdatedAt,
  );
  const connectionLabel = anyError
    ? "서버 재연결 중"
    : isSynchronizing && !hasConnectedData
      ? "서버 연결 중"
      : isSynchronizing
        ? "데이터 동기화 중"
        : "서버 연결됨";
  const connectionClass = anyError
    ? "is-error"
    : isSynchronizing
      ? "is-syncing"
      : "is-connected";

  const selectRoad = useCallback(
    (roadSegmentId: string, trigger?: HTMLElement) => {
      const activeElement = document.activeElement;
      selectionTriggerRef.current =
        trigger ??
        (activeElement instanceof HTMLElement ? activeElement : null);
      setSelectedRoadId(roadSegmentId);
    },
    [],
  );

  const closeRoadDetail = useCallback(() => {
    const trigger = selectionTriggerRef.current;
    const roadSegmentId = selectedRoadId;
    setSelectedRoadId(null);
    window.requestAnimationFrame(() => {
      if (trigger?.isConnected) {
        trigger.focus({ preventScroll: true });
        return;
      }
      if (!roadSegmentId) return;
      document
        .querySelector<HTMLElement>(
          `[data-road-id="${roadSegmentId}"] .priority-road-label`,
        )
        ?.focus({ preventScroll: true });
    });
  }, [selectedRoadId]);

  useEffect(() => {
    if (!selectedRoadId) return undefined;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, [selectedRoadId]);

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
            <div
              aria-label={`${connectionLabel}${
                lastSynchronizedAt
                  ? `, 최근 동기화 ${synchronizedTime(lastSynchronizedAt)}`
                  : ""
              }`}
              className={`dashboard-sync ${connectionClass}`}
            >
              <i aria-hidden />
              <span>{connectionLabel}</span>
              {lastSynchronizedAt > 0 && (
                <time dateTime={new Date(lastSynchronizedAt).toISOString()}>
                  {synchronizedTime(lastSynchronizedAt)}
                </time>
              )}
            </div>
            <span className="dashboard-reference-date">
              {referenceDate()} 기준
            </span>
          </div>
        </header>

        {anyError && (
          <Alert title="최신 데이터를 연결하지 못했어요" tone="critical">
            네트워크나 데이터 서버 상태를 확인해 주세요. 5초 뒤 자동으로 다시
            시도합니다.
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
                  <div className="metric-card__featured-body">
                    <div>
                      <strong className="metric-card__value">
                        {overview.data.accessibilityIndex === null
                          ? "—"
                          : overview.data.accessibilityIndex.toLocaleString(
                              "ko-KR",
                            )}
                      </strong>
                      <span className="metric-card__note metric-card__note--good">
                        {displayedRoadCount.toLocaleString("ko-KR")}개 도로
                        구간의 익명 신호 기반
                      </span>
                    </div>
                    <svg
                      aria-hidden
                      className="companion-route"
                      fill="none"
                      viewBox="0 0 104 54"
                    >
                      <path
                        className="companion-route__rail"
                        d="M6 43c19 4 23-27 43-27 17 0 19 20 32 20 9 0 12-12 17-28"
                        pathLength="100"
                      />
                      <path
                        className="companion-route__line"
                        d="M6 43c19 4 23-27 43-27 17 0 19 20 32 20 9 0 12-12 17-28"
                        pathLength="100"
                      />
                      <circle
                        className="companion-route__start"
                        cx="6"
                        cy="43"
                        r="4"
                      />
                      <circle
                        className="companion-route__caution"
                        cx="78"
                        cy="36"
                        r="3.5"
                      />
                      <circle
                        className="companion-route__end"
                        cx="98"
                        cy="8"
                        r="4"
                      />
                    </svg>
                  </div>
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
                    {overview.data.acceptedEventCount.toLocaleString("ko-KR")}건
                  </strong>
                  <span className="metric-card__note">
                    수용된 이동 충격 신호
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
            ) : visibleRoads.length ? (
              <Suspense
                fallback={<Skeleton className="map-skeleton" height={320} />}
              >
                <RoadMap
                  onSelect={selectRoad}
                  roads={visibleRoads}
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
              ) : visiblePriorities.length ? (
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
                    {visiblePriorities.map((road) => (
                      <tr
                        data-road-id={road.roadSegmentId}
                        data-selected={road.roadSegmentId === selectedRoadId}
                        key={road.roadSegmentId}
                        onClick={(event) => {
                          const trigger =
                            event.currentTarget.querySelector<HTMLElement>(
                              ".priority-road-label",
                            );
                          selectRoad(road.roadSegmentId, trigger ?? undefined);
                        }}
                      >
                        <td>
                          <button
                            aria-controls="road-detail-panel"
                            aria-expanded={
                              road.roadSegmentId === selectedRoadId
                            }
                            aria-label={`${road.roadName}, ${
                              movementLabel[road.movementType]
                            } 기준 ${road.score}점, 상세 보기`}
                            className="priority-road-label"
                            onClick={(event) => {
                              event.stopPropagation();
                              selectRoad(
                                road.roadSegmentId,
                                event.currentTarget,
                              );
                            }}
                            type="button"
                          >
                            <i aria-hidden className={gradeClass(road.grade)} />
                            <span>
                              <strong>{road.roadName}</strong>
                              <small>
                                {movementLabel[road.movementType]} ·{" "}
                                {gradeLabel[road.grade]}
                              </small>
                            </span>
                          </button>
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

      {selectedRoadId && (
        <div className="road-detail-layer">
          <button
            aria-label="도로 상세 닫기"
            className="road-detail-backdrop"
            onClick={closeRoadDetail}
            tabIndex={-1}
            type="button"
          />
          <RoadDetailPanel
            data={detail.data}
            error={detail.error}
            isPending={detail.isPending}
            onClose={closeRoadDetail}
          />
        </div>
      )}
    </div>
  );
}
