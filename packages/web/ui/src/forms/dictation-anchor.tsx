import { useLayoutEffect, useRef, type RefObject } from "react";
import { KDictationAnchor, KDictationState } from "./dictation-action.js";

/** Measure native text with the same wrapping, padding, direction and font. */
export function KDictationFieldAnchor({
  target,
  offset,
  state,
}: {
  target: RefObject<HTMLInputElement | HTMLTextAreaElement | null>;
  offset?: number;
  state: KDictationState;
}) {
  const overlay = useRef<HTMLSpanElement>(null);
  useLayoutEffect(() => {
    const field = target.current;
    const anchor = overlay.current;
    if (!field || !anchor) return;
    const mirror = field.ownerDocument.createElement("div");
    const marker = field.ownerDocument.createElement("span");
    field.ownerDocument.body.append(mirror);
    const update = () => {
      const style = getComputedStyle(field);
      for (const property of [
        "box-sizing",
        "font-family",
        "font-size",
        "font-weight",
        "font-style",
        "font-variant",
        "font-feature-settings",
        "letter-spacing",
        "line-height",
        "text-align",
        "text-indent",
        "text-transform",
        "direction",
        "tab-size",
        "padding-top",
        "padding-right",
        "padding-bottom",
        "padding-left",
        "border-top-width",
        "border-right-width",
        "border-bottom-width",
        "border-left-width",
      ])
        mirror.style.setProperty(property, style.getPropertyValue(property));
      Object.assign(mirror.style, {
        position: "fixed",
        visibility: "hidden",
        borderStyle: "solid",
        width: `${field.offsetWidth}px`,
        whiteSpace: field.tagName === "TEXTAREA" ? "pre-wrap" : "pre",
        overflowWrap: "break-word",
        top: "0",
        left: "0",
      });
      const position = Math.max(
        0,
        Math.min(
          offset ?? field.selectionStart ?? field.value.length,
          field.value.length,
        ),
      );
      mirror.textContent = field.value.slice(0, position);
      marker.textContent = "\u200b";
      mirror.append(
        marker,
        field.ownerDocument.createTextNode(field.value.slice(position)),
      );
      const rect = marker.getBoundingClientRect();
      const origin = mirror.getBoundingClientRect();
      const fieldRect = field.getBoundingClientRect();
      const parentRect = anchor.parentElement!.getBoundingClientRect();
      const x = rect.left - origin.left - field.scrollLeft;
      const y = rect.top - origin.top - field.scrollTop;
      anchor.style.left = `${fieldRect.left - parentRect.left + x}px`;
      anchor.style.top = `${fieldRect.top - parentRect.top + y}px`;
      anchor.style.height = `${rect.height || parseFloat(style.fontSize)}px`;
      anchor.style.visibility =
        x >= field.clientLeft &&
        x < field.clientWidth &&
        y >= field.clientTop &&
        y < field.clientHeight
          ? "visible"
          : "hidden";
    };
    update();
    const observer = new ResizeObserver(update);
    observer.observe(field);
    field.addEventListener("scroll", update);
    field.addEventListener("input", update);
    field.addEventListener("select", update);
    return () => {
      observer.disconnect();
      mirror.remove();
      field.removeEventListener("scroll", update);
      field.removeEventListener("input", update);
      field.removeEventListener("select", update);
    };
  });
  return (
    <span ref={overlay} className="k-dictation-field-anchor" aria-hidden="true">
      <KDictationAnchor state={state} />
    </span>
  );
}
