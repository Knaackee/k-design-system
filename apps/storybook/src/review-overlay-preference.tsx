import { useEffect, useState, type ComponentProps } from "react";
import { KAdaptiveDialog, KPageSheet } from "@k-design-system/ui";
export type ReviewOverlayPreference = "bottom-sheet" | "page-sheet";
const storageKey = "onzeit-storybook-review-overlay";
const eventName = "onzeit-review-overlay-change";
function readPreference(): ReviewOverlayPreference {
  try {
    return window.localStorage.getItem(storageKey) === "page-sheet"
      ? "page-sheet"
      : "bottom-sheet";
  } catch {
    return "bottom-sheet";
  }
}
export function useReviewOverlayPreference() {
  const [preference, setPreference] =
    useState<ReviewOverlayPreference>(readPreference);
  useEffect(() => {
    const refresh = () => setPreference(readPreference());
    window.addEventListener(eventName, refresh);
    window.addEventListener("storage", refresh);
    return () => {
      window.removeEventListener(eventName, refresh);
      window.removeEventListener("storage", refresh);
    };
  }, []);
  const change = (value: ReviewOverlayPreference) => {
    setPreference(value);
    try {
      window.localStorage.setItem(storageKey, value);
    } catch {
      /* Session state remains usable. */
    }
    window.dispatchEvent(new Event(eventName));
  };
  return [preference, change] as const;
}
/** Temporary gallery-only experiment; no production preference or package contract. */
export function ReviewAdaptiveDialog(
  props: ComponentProps<typeof KAdaptiveDialog> & {
    presentationRootId?: string;
    preferPageSheet?: boolean;
  },
) {
  const [preference] = useReviewOverlayPreference();
  const {
    presentationRootId = "storybook-root",
    preferPageSheet = true,
    ...overlayProps
  } = props;
  return preference === "page-sheet" && preferPageSheet ? (
    <KPageSheet {...overlayProps} presentationRootId={presentationRootId} />
  ) : (
    <KAdaptiveDialog {...overlayProps} />
  );
}
