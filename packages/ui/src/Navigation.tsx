import { ArrowLeft } from "lucide-react";
import type { ReactNode } from "react";
import { IconButton } from "./IconButton";
import { cx } from "./utils";

export interface NavigationProps {
  actions?: ReactNode;
  className?: string;
  onBack?: () => void;
  subtitle?: string;
  title: string;
}

export function Navigation({
  actions,
  className,
  onBack,
  subtitle,
  title,
}: NavigationProps) {
  return (
    <header className={cx("rd-navigation", className)}>
      <div className="rd-navigation__leading">
        {onBack && (
          <IconButton
            aria-label="뒤로 가기"
            icon={<ArrowLeft aria-hidden size={22} />}
            onClick={onBack}
          />
        )}
        <div>
          <div className="rd-navigation__title">{title}</div>
          {subtitle && (
            <div className="rd-navigation__subtitle">{subtitle}</div>
          )}
        </div>
      </div>
      {actions && <div className="rd-navigation__actions">{actions}</div>}
    </header>
  );
}
