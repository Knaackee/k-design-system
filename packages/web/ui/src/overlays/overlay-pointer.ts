/** A stable editor portal can be inside the dialog DOM but outside its React tree. */
export function handleOverlayPointerOutside(
  event: {
    detail: { originalEvent: { target: EventTarget | null } };
    preventDefault: () => void;
  },
  content: HTMLElement | null,
  dismissible: boolean,
) {
  const target = event.detail.originalEvent.target;
  if (!dismissible || (target instanceof Node && content?.contains(target)))
    event.preventDefault();
}
