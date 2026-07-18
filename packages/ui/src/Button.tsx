import { forwardRef, type ButtonHTMLAttributes, type ReactNode } from "react";
import { cx } from "./utils";

export type ButtonTone = "primary" | "secondary" | "danger" | "ghost";
export type ButtonSize = "small" | "medium" | "large";

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  fullWidth?: boolean;
  leading?: ReactNode;
  loading?: boolean;
  size?: ButtonSize;
  tone?: ButtonTone;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      children,
      className,
      disabled,
      fullWidth = false,
      leading,
      loading = false,
      size = "medium",
      tone = "primary",
      type = "button",
      ...props
    },
    ref,
  ) => (
    <button
      {...props}
      ref={ref}
      aria-busy={loading || undefined}
      className={cx(
        "rd-button",
        `rd-button--${tone}`,
        `rd-button--${size}`,
        fullWidth && "rd-button--full",
        className,
      )}
      disabled={disabled || loading}
      type={type}
    >
      {loading ? <span aria-hidden className="rd-spinner" /> : leading}
      <span>{children}</span>
    </button>
  ),
);

Button.displayName = "Button";
