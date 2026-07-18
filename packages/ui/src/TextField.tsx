import { forwardRef, useId, type InputHTMLAttributes } from "react";
import { cx } from "./utils";

export interface TextFieldProps extends InputHTMLAttributes<HTMLInputElement> {
  error?: string;
  helpText?: string;
  label: string;
  suffix?: string;
}

export const TextField = forwardRef<HTMLInputElement, TextFieldProps>(
  (
    { className, error, helpText, id: providedId, label, suffix, ...props },
    ref,
  ) => {
    const generatedId = useId();
    const id = providedId ?? generatedId;
    const descriptionId = `${id}-description`;

    return (
      <label className={cx("rd-field", error && "is-error", className)}>
        <span className="rd-field__label">{label}</span>
        <span className="rd-field__control">
          <input
            {...props}
            ref={ref}
            aria-describedby={error || helpText ? descriptionId : undefined}
            aria-invalid={Boolean(error)}
            id={id}
          />
          {suffix && <span className="rd-field__suffix">{suffix}</span>}
        </span>
        {(error || helpText) && (
          <span
            className="rd-field__description"
            id={descriptionId}
            role={error ? "alert" : undefined}
          >
            {error ?? helpText}
          </span>
        )}
      </label>
    );
  },
);

TextField.displayName = "TextField";
