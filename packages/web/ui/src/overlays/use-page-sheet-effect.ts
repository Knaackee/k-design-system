import { useEffect, type RefObject } from "react";
import type { SheetRef } from "react-modal-sheet";

/** The consumer owns the surface; never mutate the document body or its theme. */
export function usePageSheetEffect(
  sheet: RefObject<SheetRef | null>,
  rootId: string | undefined,
  open: boolean,
) {
  useEffect(() => {
    if (!rootId || !open) return;
    const root = document.getElementById(rootId);
    const controller = sheet.current;
    if (!root || !controller) return;
    const properties = [
      "transform",
      "transform-origin",
      "border-radius",
      "overflow",
      "will-change",
    ];
    const previous = properties.map((property) => [
      property,
      root.style.getPropertyValue(property),
      root.style.getPropertyPriority(property),
    ]);
    const tokens = getComputedStyle(root);
    // Resolve rem/calc overrides as well as the default px tokens.
    const measure = document.createElement("span");
    measure.style.cssText =
      "position:absolute;visibility:hidden;pointer-events:none;width:var(--k-space-layout-gutter);height:0";
    root.appendChild(measure);
    const inset = parseFloat(getComputedStyle(measure).width) || 0;
    measure.remove();
    const radius = tokens.getPropertyValue("--k-radius-overlay").trim();
    root.style.transformOrigin = "center top";
    root.style.overflow = "hidden";
    root.style.willChange = "transform";
    const update = () => {
      const progress = controller.yProgress.get();
      const scale =
        1 - ((2 * inset) / Math.max(root.clientWidth, 1)) * progress;
      root.style.transform = `translateY(${inset * progress}px) scale(${Math.max(0, scale)})`;
      root.style.borderRadius = `calc(${radius || "0px"} * ${progress})`;
    };
    const offY = controller.yProgress.on("change", update);
    window.addEventListener("resize", update);
    update();
    return () => {
      offY();
      window.removeEventListener("resize", update);
      for (const [property, value, priority] of previous) {
        if (value) root.style.setProperty(property!, value, priority);
        else root.style.removeProperty(property!);
      }
    };
  }, [open, rootId, sheet]);
}
