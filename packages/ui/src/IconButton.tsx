import { forwardRef, type ButtonHTMLAttributes, type ReactNode } from "react";
import { cx } from "./utils";

export interface IconButtonProps extends Omit<
  ButtonHTMLAttributes<HTMLButtonElement>,
  "children"
> {
  "aria-label": string;
  icon: ReactNode;
  size?: "small" | "medium" | "large";
  tone?: "neutral" | "primary" | "danger";
}

export const IconButton = forwardRef<HTMLButtonElement, IconButtonProps>(
  (
    {
      className,
      icon,
      size = "medium",
      tone = "neutral",
      type = "button",
      ...props
    },
    ref,
  ) => (
    <button
      {...props}
      ref={ref}
      className={cx(
        "rd-icon-button",
        `rd-icon-button--${size}`,
        `rd-icon-button--${tone}`,
        className,
      )}
      type={type}
    >
      {icon}
    </button>
  ),
);

IconButton.displayName = "IconButton";
