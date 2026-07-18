import type { HTMLAttributes, ReactNode } from "react";
import { cx } from "./utils";

export interface SurfaceProps extends HTMLAttributes<HTMLElement> {
  as?: "article" | "aside" | "div" | "section";
  children: ReactNode;
  padding?: "none" | "small" | "medium" | "large";
  tone?: "default" | "subtle" | "elevated";
}

export function Surface({
  as: Element = "section",
  children,
  className,
  padding = "medium",
  tone = "default",
  ...props
}: SurfaceProps) {
  return (
    <Element
      {...props}
      className={cx(
        "rd-surface",
        `rd-surface--${tone}`,
        `rd-surface--padding-${padding}`,
        className,
      )}
    >
      {children}
    </Element>
  );
}
