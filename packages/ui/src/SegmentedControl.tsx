import { cx } from "./utils";

export interface SegmentItem<T extends string> {
  description?: string;
  icon?: React.ReactNode;
  label: string;
  value: T;
}

export interface SegmentedControlProps<T extends string> {
  ariaLabel: string;
  className?: string;
  items: Array<SegmentItem<T>>;
  onChange: (value: T) => void;
  value: T;
}

export function SegmentedControl<T extends string>({
  ariaLabel,
  className,
  items,
  onChange,
  value,
}: SegmentedControlProps<T>) {
  return (
    <div
      aria-label={ariaLabel}
      className={cx("rd-segmented", className)}
      role="radiogroup"
    >
      {items.map((item) => {
        const selected = item.value === value;
        return (
          <button
            key={item.value}
            aria-checked={selected}
            className={cx("rd-segmented__item", selected && "is-selected")}
            onClick={() => onChange(item.value)}
            role="radio"
            type="button"
          >
            {item.icon && (
              <span aria-hidden className="rd-segmented__icon">
                {item.icon}
              </span>
            )}
            <span>{item.label}</span>
            {item.description && (
              <span className="rd-segmented__description">
                {item.description}
              </span>
            )}
          </button>
        );
      })}
    </div>
  );
}
