import type { ReactNode } from "react";
import { cx } from "./utils";

export interface BottomCTAProps {
  children: ReactNode;
  className?: string;
  description?: string;
  secondary?: ReactNode;
}

export function BottomCTA({
  children,
  className,
  description,
  secondary,
}: BottomCTAProps) {
  return (
    <aside className={cx("rd-bottom-cta", className)}>
      <div className="rd-bottom-cta__inner">
        {description && (
          <p className="rd-bottom-cta__description">{description}</p>
        )}
        <div className="rd-bottom-cta__actions">
          {secondary}
          {children}
        </div>
      </div>
    </aside>
  );
}
