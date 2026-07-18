import { cx } from "./utils";

export type RoadGrade = "GOOD" | "NORMAL" | "CAUTION" | "POOR" | "UNKNOWN";

export interface ScoreGaugeProps {
  className?: string;
  label?: string;
  score: number | null;
  size?: "small" | "medium" | "large";
}

export const getRoadGrade = (score: number | null): RoadGrade => {
  if (score === null) return "UNKNOWN";
  if (score >= 80) return "GOOD";
  if (score >= 60) return "NORMAL";
  if (score >= 40) return "CAUTION";
  return "POOR";
};

const gradeLabel: Record<RoadGrade, string> = {
  CAUTION: "주의",
  GOOD: "양호",
  NORMAL: "보통",
  POOR: "불편",
  UNKNOWN: "데이터 없음",
};

export function ScoreGauge({
  className,
  label = "Road DNA 점수",
  score,
  size = "medium",
}: ScoreGaugeProps) {
  const grade = getRoadGrade(score);
  const normalized = score ?? 0;

  return (
    <div
      aria-label={`${label}: ${score === null ? "데이터 없음" : `${score}점, ${gradeLabel[grade]}`}`}
      className={cx(
        "rd-score",
        `rd-score--${grade.toLowerCase()}`,
        `rd-score--${size}`,
        className,
      )}
      role="img"
    >
      <svg aria-hidden className="rd-score__ring" viewBox="0 0 120 120">
        <circle className="rd-score__track" cx="60" cy="60" r="52" />
        {score !== null && (
          <circle
            className="rd-score__value"
            cx="60"
            cy="60"
            pathLength="100"
            r="52"
            strokeDasharray={`${normalized} 100`}
          />
        )}
      </svg>
      <div className="rd-score__content">
        <strong>{score ?? "—"}</strong>
        <span>{gradeLabel[grade]}</span>
      </div>
    </div>
  );
}

export interface ConfidenceBarProps {
  className?: string;
  value: number;
}

export function ConfidenceBar({ className, value }: ConfidenceBarProps) {
  const normalized = Math.min(1, Math.max(0, value));
  const grade =
    normalized >= 0.8 ? "높음" : normalized >= 0.5 ? "보통" : "낮음";

  return (
    <div
      aria-label={`신뢰도 ${Math.round(normalized * 100)}%, ${grade}`}
      className={cx("rd-confidence", className)}
    >
      <div className="rd-confidence__header">
        <span>신뢰도</span>
        <strong>
          {Math.round(normalized * 100)}% · {grade}
        </strong>
      </div>
      <div aria-hidden className="rd-confidence__track">
        <span style={{ width: `${normalized * 100}%` }} />
      </div>
    </div>
  );
}

export interface MetricProps {
  className?: string;
  label: string;
  trend?: string;
  value: string;
}

export function Metric({ className, label, trend, value }: MetricProps) {
  return (
    <div className={cx("rd-metric", className)}>
      <span className="rd-metric__label">{label}</span>
      <strong className="rd-metric__value">{value}</strong>
      {trend && <span className="rd-metric__trend">{trend}</span>}
    </div>
  );
}

export interface RoadScanRibbonProps {
  className?: string;
  state: "idle" | "active" | "impact";
}

export function RoadScanRibbon({ className, state }: RoadScanRibbonProps) {
  const label =
    state === "active"
      ? "도로 분석 중"
      : state === "impact"
        ? "이동 충격 패턴 감지"
        : "분석 대기";

  return (
    <div
      aria-label={label}
      className={cx("rd-ribbon", `rd-ribbon--${state}`, className)}
      role="status"
    >
      <span aria-hidden className="rd-ribbon__road">
        <span className="rd-ribbon__scan" />
      </span>
      <span className="rd-ribbon__label">{label}</span>
    </div>
  );
}
