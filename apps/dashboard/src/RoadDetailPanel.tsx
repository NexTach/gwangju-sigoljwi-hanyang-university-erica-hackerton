import type { RoadDetailResponse } from "@road-dna/contracts";
import { Skeleton } from "@road-dna/ui";
import { X } from "lucide-react";
import { useEffect, useRef } from "react";
import { gradeLabel, movementLabel } from "./types";

interface RoadDetailPanelProps {
  data?: RoadDetailResponse;
  error?: Error | null;
  isPending: boolean;
  onClose: () => void;
}

const gradeClass = (grade: string): string => {
  if (grade === "GOOD") return "is-good";
  if (grade === "POOR") return "is-poor";
  if (grade === "UNKNOWN") return "is-unknown";
  return "is-caution";
};

const impactLabel: Record<string, string> = {
  HIGH_IMPACT: "강한 단일 충격",
  LOW_IMPACT: "약한 노면 진동",
  MEDIUM_IMPACT: "반복적인 노면 진동",
};

export function RoadDetailPanel({
  data,
  error,
  isPending,
  onClose,
}: RoadDetailPanelProps) {
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    closeRef.current?.focus();
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    window.addEventListener("keydown", closeOnEscape);
    return () => window.removeEventListener("keydown", closeOnEscape);
  }, [onClose]);

  return (
    <aside
      aria-labelledby="road-detail-title"
      aria-modal="true"
      className="road-detail-panel"
      role="dialog"
    >
      <header className="road-detail-panel__header">
        <div>
          <span>구간 분석</span>
          <h2 id="road-detail-title">
            {data?.roadName ?? "도로 정보를 불러오는 중"}
          </h2>
        </div>
        <button
          aria-label="도로 상세 닫기"
          className="detail-close-button"
          onClick={onClose}
          ref={closeRef}
          type="button"
        >
          <X aria-hidden size={19} />
        </button>
      </header>

      {isPending && (
        <div className="road-detail-panel__loading">
          <Skeleton height={118} />
          <Skeleton height={118} />
          <Skeleton height={118} />
        </div>
      )}

      {error && (
        <div className="road-detail-panel__error" role="alert">
          <strong>구간을 불러오지 못했어요</strong>
          <p>{error.message}</p>
        </div>
      )}

      {data && (
        <>
          <div className="road-detail-panel__meta">
            <span>누적 감지</span>
            <strong>{data.eventCount.toLocaleString("ko-KR")}건</strong>
            <small>
              최근 갱신{" "}
              {new Intl.DateTimeFormat("ko-KR", {
                hour: "2-digit",
                minute: "2-digit",
              }).format(new Date(data.updatedAt))}
            </small>
          </div>

          <div className="road-detail-panel__scores">
            {data.scores.map((score) => {
              const numericScore = score.score ?? 0;
              const confidence = Math.round(score.confidence * 100);
              return (
                <section className="movement-score" key={score.movementType}>
                  <div className="movement-score__heading">
                    <div>
                      <strong>{movementLabel[score.movementType]}</strong>
                      <span className={gradeClass(score.grade)}>
                        {gradeLabel[score.grade]}
                      </span>
                    </div>
                    <strong className={gradeClass(score.grade)}>
                      {score.score ?? "—"}
                    </strong>
                  </div>
                  <div
                    aria-label={`접근성 점수 ${score.score ?? "데이터 없음"}점`}
                    className="score-track"
                    role="img"
                  >
                    <i
                      className={gradeClass(score.grade)}
                      style={{ width: `${numericScore}%` }}
                    />
                  </div>
                  <div className="movement-score__confidence">
                    <span>신뢰도 {confidence}%</span>
                    <span>
                      {score.eventCount.toLocaleString("ko-KR")}회 감지
                    </span>
                  </div>
                </section>
              );
            })}
          </div>

          {data.recentEvents.length > 0 && (
            <section
              aria-labelledby="recent-events-title"
              className="recent-events"
            >
              <h3 id="recent-events-title">최근 감지 기록</h3>
              <ul>
                {data.recentEvents.slice(0, 3).map((event) => (
                  <li key={event.detectedAt}>
                    <i
                      aria-hidden
                      className={
                        event.impactLevel === "HIGH_IMPACT"
                          ? "is-poor"
                          : "is-caution"
                      }
                    />
                    <span>
                      {impactLabel[event.impactLevel] ?? "노면 진동 감지"}
                    </span>
                    <time dateTime={event.detectedAt}>
                      {new Intl.DateTimeFormat("ko-KR", {
                        hour: "2-digit",
                        minute: "2-digit",
                      }).format(new Date(event.detectedAt))}
                    </time>
                  </li>
                ))}
              </ul>
            </section>
          )}

          <p className="road-detail-panel__notice">
            Road DNA 점수는 휴대폰 센서 기반 내부 지표예요. 법정 접근성 인증이나
            안전 보장을 의미하지 않아요.
          </p>
        </>
      )}
    </aside>
  );
}
