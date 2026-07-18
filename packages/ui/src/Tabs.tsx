import { cx } from "./utils";

export interface TabItem {
  badge?: string | number;
  id: string;
  label: string;
}

export interface TabsProps {
  activeId: string;
  ariaLabel: string;
  className?: string;
  items: TabItem[];
  onChange: (id: string) => void;
}

export function Tabs({
  activeId,
  ariaLabel,
  className,
  items,
  onChange,
}: TabsProps) {
  return (
    <div
      aria-label={ariaLabel}
      className={cx("rd-tabs", className)}
      role="tablist"
    >
      {items.map((item) => {
        const selected = item.id === activeId;
        return (
          <button
            key={item.id}
            aria-selected={selected}
            className={cx("rd-tabs__tab", selected && "is-active")}
            onClick={() => onChange(item.id)}
            role="tab"
            type="button"
          >
            {item.label}
            {item.badge !== undefined && (
              <span className="rd-tabs__badge">{item.badge}</span>
            )}
          </button>
        );
      })}
    </div>
  );
}
