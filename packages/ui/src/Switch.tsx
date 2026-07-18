import { cx } from "./utils";

export interface SwitchProps {
  checked: boolean;
  className?: string;
  disabled?: boolean;
  label: string;
  onChange: (checked: boolean) => void;
}

export function Switch({
  checked,
  className,
  disabled = false,
  label,
  onChange,
}: SwitchProps) {
  return (
    <label className={cx("rd-switch", disabled && "is-disabled", className)}>
      <span>{label}</span>
      <button
        aria-checked={checked}
        className="rd-switch__track"
        disabled={disabled}
        onClick={() => onChange(!checked)}
        role="switch"
        type="button"
      >
        <span className="rd-switch__thumb" />
      </button>
    </label>
  );
}
