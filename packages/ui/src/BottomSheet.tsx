import { X } from "lucide-react";
import { useEffect, useId, useRef, type ReactNode } from "react";
import { IconButton } from "./IconButton";
import { cx } from "./utils";

export interface BottomSheetProps {
  children: ReactNode;
  className?: string;
  description?: string;
  footer?: ReactNode;
  onClose: () => void;
  open: boolean;
  title: string;
}

export function BottomSheet({
  children,
  className,
  description,
  footer,
  onClose,
  open,
  title,
}: BottomSheetProps) {
  const titleId = useId();
  const descriptionId = useId();
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (!open) return undefined;

    const previousOverflow = document.body.style.overflow;
    const previousActive = document.activeElement as HTMLElement | null;
    document.body.style.overflow = "hidden";
    closeRef.current?.focus();

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    window.addEventListener("keydown", handleKeyDown);

    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener("keydown", handleKeyDown);
      previousActive?.focus();
    };
  }, [onClose, open]);

  if (!open) return null;

  return (
    <div className="rd-sheet-layer">
      <button
        aria-label="시트 닫기"
        className="rd-sheet-scrim"
        onClick={onClose}
        type="button"
      />
      <section
        aria-describedby={description ? descriptionId : undefined}
        aria-labelledby={titleId}
        aria-modal="true"
        className={cx("rd-sheet", className)}
        role="dialog"
      >
        <div aria-hidden className="rd-sheet__handle" />
        <header className="rd-sheet__header">
          <div>
            <h2 id={titleId}>{title}</h2>
            {description && <p id={descriptionId}>{description}</p>}
          </div>
          <IconButton
            ref={closeRef}
            aria-label="닫기"
            icon={<X aria-hidden size={20} />}
            onClick={onClose}
          />
        </header>
        <div className="rd-sheet__body">{children}</div>
        {footer && <footer className="rd-sheet__footer">{footer}</footer>}
      </section>
    </div>
  );
}
