/** Move the portal container, never its React subtree or editor instance. */
export function moveMarkdownEditorMount(mount: HTMLElement, host: HTMLElement) {
  if (mount.parentElement === host) return;
  const moveBefore = (
    host as HTMLElement & {
      moveBefore?: (node: Node, before: Node | null) => void;
    }
  ).moveBefore;
  if (moveBefore && mount.isConnected && host.isConnected) {
    moveBefore.call(host, mount, null);
    return;
  }

  const active = mount.ownerDocument.activeElement;
  const focused =
    active instanceof HTMLElement && mount.contains(active) ? active : null;
  const selection = mount.ownerDocument.getSelection();
  const saved =
    selection?.anchorNode && mount.contains(selection.anchorNode)
      ? {
          anchor: selection.anchorNode,
          anchorOffset: selection.anchorOffset,
          focus: selection.focusNode,
          focusOffset: selection.focusOffset,
        }
      : null;
  const scroll = [mount, ...mount.querySelectorAll<HTMLElement>("*")]
    .filter((node) => node.scrollTop || node.scrollLeft)
    .map((node) => ({ node, top: node.scrollTop, left: node.scrollLeft }));
  host.append(mount);
  focused?.focus({ preventScroll: true });
  if (saved?.focus && selection) {
    selection.setBaseAndExtent(
      saved.anchor,
      saved.anchorOffset,
      saved.focus,
      saved.focusOffset,
    );
  }
  for (const { node, top, left } of scroll) {
    node.scrollTop = top;
    node.scrollLeft = left;
  }
}

/** The portal's React ancestry skips the dialog's normal Tab-loop handler. */
export function wrapMarkdownEditorTab(event: KeyboardEvent) {
  if (
    event.defaultPrevented ||
    event.key !== "Tab" ||
    event.shiftKey ||
    event.altKey ||
    event.ctrlKey ||
    event.metaKey
  )
    return;
  const mount = event.currentTarget as HTMLElement;
  const dialog = mount.closest<HTMLElement>('[role="dialog"]');
  if (!dialog) return;
  const controls = [
    ...dialog.querySelectorAll<HTMLElement>(
      'button, input, select, textarea, a[href], [tabindex], [contenteditable="true"]',
    ),
  ].filter(
    (node) =>
      node.tabIndex >= 0 &&
      !node.matches(":disabled") &&
      !node.closest("[inert]") &&
      node.getClientRects().length > 0,
  );
  if (
    controls.length &&
    mount.ownerDocument.activeElement === controls.at(-1)
  ) {
    event.preventDefault();
    controls[0].focus();
  }
}
