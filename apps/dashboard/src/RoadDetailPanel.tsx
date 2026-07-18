import type { RoadDetailResponse } from "@road-dna/contracts";
import {
  Badge,
  Button,
  ConfidenceBar,
  ScoreGauge,
  Skeleton,
} from "@road-dna/ui";
import { X } from "lucide-react";
import { gradeLabel, gradeTone, movementLabel } from "./types";

interface RoadDetailPanelProps {
  data?: RoadDetailResponse;
  error?: Error | null;
  isPending: boolean;
  onClose: () => void;
}

export function RoadDetailPanel({
  data,
  error,
  isPending,
  onClose,
}: RoadDetailPanelProps) {
  return (
    <aside
      aria-label="도로 구간 상세"
      className="road-detail-panel"
      data-open={Boolean(data) || isPending || Boolean(error)}
    >
      <header className="road-detail-panel__header">
        <div>
          <span className="eyebrow">구간 분석</span>
          <h2>{data?.roadName ?? "도로 정보를 불러오는 중"}</h2>
        </div>
        <Button
          aria-label="도로 상세 닫기"
          onClick={onClose}
          size="small"
          tone="ghost"
        >
          <X aria-hidden size={18} />
        </Button>
      </header>
      {isPending && (
        <div className="road-detail-panel__loading">
          <Skeleton height={148} />
          <Skeleton height={84} />
          <Skeleton height={84} />
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
            <span>누적 감지 {data.eventCount.toLocaleString("ko-KR")}건</span>
            <span>
              최근 갱신{" "}
              {new Intl.DateTimeFormat("ko-KR", {
                hour: "2-digit",
                minute: "2-digit",
              }).format(new Date(data.updatedAt))}
            </span>
          </div>
          <div className="road-detail-panel__scores">
            {data.scores.map((score) => (
              <section className="movement-score" key={score.movementType}>
                <div className="movement-score__heading">
                  <div>
                    <span>{movementLabel[score.movementType]}</span>
                    <Badge tone={gradeTone[score.grade]}>
                      {gradeLabel[score.grade]}
                    </Badge>
                  </div>
                  <span>{score.eventCount}건</span>
                </div>
                <div className="movement-score__visual">
                  <ScoreGauge score={score.score} size="small" />
                  <ConfidenceBar value={score.confidence} />
                </div>
              </section>
            ))}
          </div>
          <p className="road-detail-panel__notice">
            Road DNA 점수는 휴대폰 센서 기반 내부 지표예요. 법정 접근성 인증이나
            안전 보장을 의미하지 않아요.
          </p>
        </>
      )}
    </aside>
  );
}
