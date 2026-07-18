import { CircleAlert, CircleCheck, Info } from "lucide-react";
import type { ReactNode } from "react";
import { cx } from "./utils";

export interface ToastProps {
  action?: ReactNode;
  className?: string;
  message: string;
  tone?: "neutral" | "success" | "warning";
}

export function Toast({
  action,
  className,
  message,
  tone = "neutral",
}: ToastProps) {
  const Icon =
    tone === "success" ? CircleCheck : tone === "warning" ? CircleAlert : Info;
  return (
    <div
      className={cx("rd-toast", `rd-toast--${tone}`, className)}
      role="status"
    >
      <Icon aria-hidden size={20} />
      <span>{message}</span>
      {action}
    </div>
  );
}

export function ToastRegion({ children }: { children: ReactNode }) {
  return (
    <div
      aria-label="알림"
      aria-live="polite"
      className="rd-toast-region"
      role="region"
    >
      {children}
    </div>
  );
}
