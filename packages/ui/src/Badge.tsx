import type { HTMLAttributes, ReactNode } from "react";
import { cx } from "./utils";

export interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  children: ReactNode;
  dot?: boolean;
  tone?: "neutral" | "info" | "success" | "warning" | "critical";
}

export function Badge({
  children,
  className,
  dot = false,
  tone = "neutral",
  ...props
}: BadgeProps) {
  return (
    <span {...props} className={cx("rd-badge", `rd-badge--${tone}`, className)}>
      {dot && <span aria-hidden className="rd-badge__dot" />}
      {children}
    </span>
  );
}
