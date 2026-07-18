import { CircleAlert, CircleCheck, CircleX, Info } from "lucide-react";
import type { ReactNode } from "react";
import { cx } from "./utils";

export type AlertTone = "info" | "success" | "warning" | "critical";

const iconByTone = {
  critical: CircleX,
  info: Info,
  success: CircleCheck,
  warning: CircleAlert,
};

export interface AlertProps {
  action?: ReactNode;
  children: ReactNode;
  className?: string;
  title: string;
  tone?: AlertTone;
}

export function Alert({
  action,
  children,
  className,
  title,
  tone = "info",
}: AlertProps) {
  const Icon = iconByTone[tone];
  return (
    <div
      className={cx("rd-alert", `rd-alert--${tone}`, className)}
      role={tone === "critical" ? "alert" : "status"}
    >
      <Icon aria-hidden className="rd-alert__icon" size={20} />
      <div className="rd-alert__content">
        <strong>{title}</strong>
        <p>{children}</p>
      </div>
      {action && <div className="rd-alert__action">{action}</div>}
    </div>
  );
}
