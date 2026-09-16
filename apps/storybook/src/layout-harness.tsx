import { createRoot } from "react-dom/client";
import { flushSync } from "react-dom";
import {
  KInline,
  KStack,
  type KLayoutAlign,
  type KLayoutGap,
} from "@k-design-system/ui";

// Browser-only regression harness. Uses package exports, never gallery internals.
export function checkLayouts() {
  const host = document.createElement("div");
  Object.assign(host.style, {
    width: "200px",
    position: "absolute",
    top: "0",
    left: "0",
  });
  host.style.setProperty("--k-space-control-gap", "13px");
  host.style.setProperty("--k-space-content-action-gap", "17px");
  host.style.setProperty("--k-space-layout-section-gap", "29px");
  document.body.append(host);
  const root = createRoot(host);
  const children = [
    <div key="a" data-probe="a" style={{ width: 30, height: 20 }} />,
    <div key="b" data-probe="b" style={{ width: 50, height: 40 }} />,
  ];
  const rect = (id: string) =>
    host
      .querySelector<HTMLElement>(`[data-probe="${id}"]`)!
      .getBoundingClientRect();
  const near = (actual: number, expected: number, label: string) => {
    if (Math.abs(actual - expected) > 0.5)
      throw new Error(`${label}: ${actual} != ${expected}`);
  };
  let assertions = 0;
  try {
    for (const [gap, expected] of [
      ["control", 13],
      ["action", 17],
      ["section", 29],
    ] as const) {
      flushSync(() => root.render(<KStack gap={gap}>{children}</KStack>));
      const original = host.querySelector('[data-probe="a"]');
      near(rect("b").top - rect("a").bottom, expected, "stack gap");
      near(rect("a").width, 30, "natural child width");
      host.style.setProperty(
        `--k-space-${gap === "control" ? "control-gap" : gap === "action" ? "content-action-gap" : "layout-section-gap"}`,
        "19px",
      );
      near(rect("b").top - rect("a").bottom, 19, "live consumer override");
      if (host.querySelector('[data-probe="a"]') !== original)
        throw new Error("remounted child");
      flushSync(() =>
        root.render(<KInline gap={gap as KLayoutGap}>{children}</KInline>),
      );
      near(rect("b").left - rect("a").right, 19, "inline gap");
      assertions += 5;
    }
    for (const count of [0, 1]) {
      for (const Layout of [KStack, KInline]) {
        flushSync(() =>
          root.render(<Layout>{children.slice(0, count)}</Layout>),
        );
        near(
          host.firstElementChild!.getBoundingClientRect().height,
          count === 0 ? 0 : 20,
          "no phantom gaps",
        );
        assertions++;
      }
    }
    for (const align of [
      "start",
      "center",
      "end",
      "stretch",
    ] as KLayoutAlign[]) {
      flushSync(() =>
        root.render(
          <KInline align={align}>
            <div data-probe="a" style={{ width: 30, minHeight: 20 }} />
            <div data-probe="b" style={{ width: 50, height: 40 }} />
          </KInline>,
        ),
      );
      const a = rect("a"),
        b = rect("b");
      if (align === "start") near(a.top, b.top, "start");
      if (align === "center")
        near(a.top + a.height / 2, b.top + b.height / 2, "center");
      if (align === "end") near(a.bottom, b.bottom, "end");
      if (align === "stretch") near(a.height, b.height, "stretch");
      assertions++;
    }
    flushSync(() =>
      root.render(
        <KInline wrap>
          {children}
          <div data-probe="c" style={{ width: 160, height: 10 }} />
        </KInline>,
      ),
    );
    near(rect("b").left - rect("a").right, 19, "wrap horizontal gap");
    near(rect("c").top - rect("b").bottom, 19, "wrap vertical gap");
    let rejected = false;
    try {
      KInline({ wrap: true, align: "stretch" });
    } catch {
      rejected = true;
    }
    if (!rejected) throw new Error("wrapped stretch must fail");
    return assertions + 3;
  } finally {
    flushSync(() => root.unmount());
    host.remove();
  }
}
