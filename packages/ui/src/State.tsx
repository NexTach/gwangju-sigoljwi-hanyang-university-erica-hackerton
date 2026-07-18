import type { ReactNode } from "react";
import { cx } from "./utils";

export interface SkeletonProps {
  className?: string;
  height?: number | string;
  width?: number | string;
}

export function Skeleton({
  className,
  height = 20,
  width = "100%",
}: SkeletonProps) {
  return (
    <span
      aria-hidden
      className={cx("rd-skeleton", className)}
      style={{ height, width }}
    />
  );
}

export interface EmptyStateProps {
  action?: ReactNode;
  description: string;
  icon?: ReactNode;
  title: string;
}

export function EmptyState({
  action,
  description,
  icon,
  title,
}: EmptyStateProps) {
  return (
    <div className="rd-empty-state">
      {icon && <div className="rd-empty-state__icon">{icon}</div>}
      <h2>{title}</h2>
      <p>{description}</p>
      {action}
    </div>
  );
}
