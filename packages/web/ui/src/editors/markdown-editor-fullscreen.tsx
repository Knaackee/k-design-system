import {
  useCallback,
  useContext,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { createPortal } from "react-dom";
import { KIconButton } from "../actions/icon-button.js";
import { KDesktopDialog } from "../overlays/overlay.js";
import {
  OverlayLayerContext,
  resolveOverlayLayer,
} from "../overlays/overlay-layer.js";
import {
  moveMarkdownEditorMount,
  wrapMarkdownEditorTab,
} from "./markdown-editor-mount.js";

/** A stable portal target keeps the editor view, history and dictation mounted. */
export function MarkdownEditorFullscreen({
  enabled,
  title,
  expandLabel,
  collapseLabel,
  children,
}: {
  enabled: boolean;
  title: string;
  expandLabel: string;
  collapseLabel: string;
  children: (action: ReactNode, expanded: boolean) => ReactNode;
}) {
  const [expanded, setExpanded] = useState(false);
  const parentLayer = useContext(OverlayLayerContext);
  const fullscreenLayer = resolveOverlayLayer(parentLayer);
  const [mount] = useState(() => {
    if (typeof document === "undefined") return null;
    const element = document.createElement("div");
    element.className = "k-markdown-editor-mount";
    element.addEventListener("keydown", wrapMarkdownEditorTab);
    return element;
  });
  const inline = useRef<HTMLDivElement | null>(null);
  const focused = useRef<HTMLElement | null>(null);
  const attach = useCallback(
    (host: HTMLDivElement | null) => {
      const target = host ?? inline.current;
      if (mount && target) {
        const active = mount.ownerDocument.activeElement;
        if (active instanceof HTMLElement && mount.contains(active))
          focused.current = active;
        moveMarkdownEditorMount(mount, target);
        if (!host) {
          requestAnimationFrame(() => {
            if (
              mount.isConnected &&
              focused.current &&
              mount.contains(focused.current)
            )
              focused.current.focus({ preventScroll: true });
          });
        }
      }
    },
    [mount],
  );
  const attachInline = useCallback(
    (host: HTMLDivElement | null) => {
      inline.current = host;
      if (host) attach(host);
    },
    [attach],
  );

  if (!enabled || !mount) return children(null, false);

  const action = (
    <KIconButton
      icon={expanded ? "minimize-2" : "maximize-2"}
      label={expanded ? collapseLabel : expandLabel}
      variant="secondary"
      aria-expanded={expanded}
      onPointerDown={(event) => event.preventDefault()}
      onClick={() => setExpanded((current) => !current)}
    />
  );
  return (
    <>
      <div ref={attachInline} className="k-markdown-editor-inline" />
      {createPortal(
        <OverlayLayerContext.Provider
          value={expanded ? fullscreenLayer : parentLayer}
        >
          {children(action, expanded)}
        </OverlayLayerContext.Provider>,
        mount,
      )}
      <KDesktopDialog
        open={expanded}
        onOpenChange={setExpanded}
        zIndex={fullscreenLayer}
        title={title}
        className="k-dialog--fullscreen k-markdown-editor-fullscreen"
        bodyClassName="k-markdown-editor-fullscreen-body"
        contentInset={false}
        initialFocusRef={focused}
        closeLabel={collapseLabel}
        leading={
          <KIconButton
            icon="arrow-left"
            label={collapseLabel}
            variant="ghost"
            onPointerDown={(event) => event.preventDefault()}
            onClick={() => setExpanded(false)}
          />
        }
        showClose={false}
      >
        <div ref={attach} className="k-markdown-editor-fullscreen-host" />
      </KDesktopDialog>
    </>
  );
}
