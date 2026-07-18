import { fireEvent, render, screen } from "@testing-library/react";
import { useState } from "react";
import { describe, expect, it, vi } from "vitest";
import { BottomSheet, Button, ScoreGauge, SegmentedControl } from "./index";

describe("Button", () => {
  it("prevents duplicate actions while loading", () => {
    render(<Button loading>저장</Button>);
    expect(screen.getByRole("button", { name: "저장" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "저장" })).toHaveAttribute(
      "aria-busy",
      "true",
    );
  });
});

describe("ScoreGauge", () => {
  it("announces missing data as unknown rather than 100", () => {
    render(<ScoreGauge score={null} />);
    expect(
      screen.getByRole("img", { name: /데이터 없음/ }),
    ).toBeInTheDocument();
    expect(screen.queryByText("100")).not.toBeInTheDocument();
  });
});

describe("SegmentedControl", () => {
  it("exposes selection semantics", () => {
    function Example() {
      const [value, setValue] = useState<"WHEELCHAIR" | "STROLLER">(
        "WHEELCHAIR",
      );
      return (
        <SegmentedControl
          ariaLabel="이동 유형"
          items={[
            { label: "휠체어", value: "WHEELCHAIR" },
            { label: "유모차", value: "STROLLER" },
          ]}
          onChange={setValue}
          value={value}
        />
      );
    }

    render(<Example />);
    fireEvent.click(screen.getByRole("radio", { name: "유모차" }));
    expect(screen.getByRole("radio", { name: "유모차" })).toHaveAttribute(
      "aria-checked",
      "true",
    );
  });
});

describe("BottomSheet", () => {
  it("closes with Escape", () => {
    const onClose = vi.fn();
    render(
      <BottomSheet onClose={onClose} open title="이동 유형 선택">
        내용
      </BottomSheet>,
    );
    fireEvent.keyDown(window, { key: "Escape" });
    expect(onClose).toHaveBeenCalledOnce();
  });
});
