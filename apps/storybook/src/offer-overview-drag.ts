import { useRef, type Dispatch, type SetStateAction } from "react";
import { useKLongPressDrag, type KLongPressPoint } from "@k-design-system/ui";
import type { OfferCategory, OfferItem } from "./offer-overview-data.js";
export function useOfferDrag(
  setItems: Dispatch<SetStateAction<OfferItem[]>>,
  setCategories: Dispatch<SetStateAction<OfferCategory[]>>,
  changed: () => void,
) {
  const source = useRef<HTMLElement | null>(null),
    target = useRef<HTMLElement | null>(null);
  const clean = () => {
    source.current?.removeAttribute("data-dragging");
    target.current?.removeAttribute("data-drop");
    source.current = null;
    target.current = null;
  };
  const hit = (p: KLongPressPoint) => {
    target.current?.removeAttribute("data-drop");
    const selector = source.current?.dataset.offerItem
      ? "[data-offer-item], [data-offer-category]"
      : "[data-offer-category]";
    target.current =
      document.elementFromPoint(p.x, p.y)?.closest<HTMLElement>(selector) ??
      null;
    if (target.current !== source.current)
      target.current?.setAttribute("data-drop", "");
  };
  return useKLongPressDrag({
    canStart: (el) => !!el.closest(".of-item-button,.of-category-toggle"),
    onStart: (p) => {
      source.current = p.target.closest<HTMLElement>(
        "[data-offer-item], [data-offer-category]",
      );
      source.current?.setAttribute("data-dragging", "");
    },
    onMove: hit,
    onCancel: clean,
    onEnd: (p) => {
      hit(p);
      const from = source.current,
        to = target.current;
      if (from && to && from !== to) {
        const after =
          p.y >
          to.getBoundingClientRect().top +
            to.getBoundingClientRect().height / 2;
        if (from.dataset.offerItem) {
          const id = from.dataset.offerItem,
            other = to.dataset.offerItem,
            category = to.dataset.offerCategoryId ?? to.dataset.offerCategory;
          setItems((old) => {
            const item = old.find((i) => i.id === id);
            if (!item || !category) return old;
            const next = old.filter((i) => i.id !== id);
            const index = other
              ? next.findIndex((i) => i.id === other)
              : next.length;
            next.splice(index + (other && after ? 1 : 0), 0, {
              ...item,
              category,
            });
            return next;
          });
        } else {
          setCategories((old) => {
            const item = old.find((i) => i.id === from.dataset.offerCategory);
            if (!item) return old;
            const next = old.filter((i) => i !== item);
            const index = next.findIndex(
              (i) => i.id === to.dataset.offerCategory,
            );
            next.splice(index + (after ? 1 : 0), 0, item);
            return next;
          });
        }
        changed();
      }
      clean();
    },
  });
}
