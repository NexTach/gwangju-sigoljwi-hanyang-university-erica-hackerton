import {
  type ButtonHTMLAttributes,
  type HTMLAttributes,
  type ReactNode,
} from "react";
import { ChevronRight } from "lucide-react";
import { cx } from "./utils";

export interface ListHeaderProps extends HTMLAttributes<HTMLDivElement> {
  action?: ReactNode;
  description?: string;
  title: string;
}

export function ListHeader({
  action,
  className,
  description,
  title,
  ...props
}: ListHeaderProps) {
  return (
    <div {...props} className={cx("rd-list-header", className)}>
      <div>
        <h2 className="rd-list-header__title">{title}</h2>
        {description && (
          <p className="rd-list-header__description">{description}</p>
        )}
      </div>
      {action}
    </div>
  );
}

export interface ListRowProps extends Omit<
  ButtonHTMLAttributes<HTMLButtonElement>,
  "title"
> {
  description?: ReactNode;
  leading?: ReactNode;
  title: ReactNode;
  trailing?: ReactNode;
}

export function ListRow({
  className,
  description,
  disabled,
  leading,
  onClick,
  title,
  trailing,
  ...props
}: ListRowProps) {
  const content = (
    <>
      {leading && <span className="rd-list-row__leading">{leading}</span>}
      <span className="rd-list-row__content">
        <span className="rd-list-row__title">{title}</span>
        {description && (
          <span className="rd-list-row__description">{description}</span>
        )}
      </span>
      <span className="rd-list-row__trailing">
        {trailing}
        {onClick && !trailing && <ChevronRight aria-hidden size={20} />}
      </span>
    </>
  );

  if (onClick) {
    return (
      <button
        {...props}
        className={cx("rd-list-row", "rd-list-row--interactive", className)}
        disabled={disabled}
        onClick={onClick}
        type="button"
      >
        {content}
      </button>
    );
  }

  return <div className={cx("rd-list-row", className)}>{content}</div>;
}
