import {
  useEffect,
  useRef,
  useState,
  type CSSProperties,
  type PointerEvent as ReactPointerEvent,
} from "react";
import { createPortal } from "react-dom";
import { Marker, type Map } from "maplibre-gl";
import { KIcon } from "../primitives/icon.js";
import type { KMapOverlayProps, KMapPin, KMapPinMove } from "./map-overlays.js";
import { edgePanVelocity, type resolvePinDrag } from "./map-pin-drag.js";

type Position = [number, number];
type Gesture = {
  id: number;
  target: HTMLButtonElement;
  x: number;
  y: number;
  start: Position;
  grabX: number;
  grabY: number;
  active: boolean;
  timer?: ReturnType<typeof setTimeout>;
};

export function Pin({
  map,
  pin,
  selected,
  onClick,
  onMove,
  renderPin,
  dragOptions,
  onDragStart,
  onDrag,
  onDragEnd,
  onDragCancel,
}: {
  map: Map;
  pin: KMapPin;
  selected: boolean;
  onClick: () => void;
  onMove?: KMapOverlayProps["onPinMove"];
  renderPin?: KMapOverlayProps["renderPin"];
  dragOptions: ReturnType<typeof resolvePinDrag>;
  onDragStart?: KMapOverlayProps["onPinDragStart"];
  onDrag?: KMapOverlayProps["onPinDrag"];
  onDragEnd?: KMapOverlayProps["onPinDragEnd"];
  onDragCancel?: KMapOverlayProps["onPinDragCancel"];
}) {
  const [element] = useState(() => document.createElement("div"));
  const marker = useRef<Marker | null>(null);
  const gesture = useRef<Gesture | null>(null);
  const animation = useRef(0);
  const edgeAnimation = useRef(0);
  const edgeFrameTime = useRef(0);
  const revision = useRef(0);
  const suppressClick = useRef(false);
  const [dragging, setDragging] = useState(false);
  const latest = useRef({
    pin,
    onMove,
    dragOptions,
    onDragStart,
    onDrag,
    onDragEnd,
    onDragCancel,
  });
  latest.current = {
    pin,
    onMove,
    dragOptions,
    onDragStart,
    onDrag,
    onDragEnd,
    onDragCancel,
  };
  const [lng, lat] = pin.position;
  const eventFor = (position: Position): KMapPinMove => ({
    id: pin.id,
    position,
    source: "drag",
  });
  const currentPosition = (): Position => {
    const current = marker.current!.getLngLat().wrap();
    return [current.lng, current.lat];
  };
  const cancelGesture = () => {
    clearTimeout(gesture.current?.timer);
    cancelAnimationFrame(edgeAnimation.current);
    edgeFrameTime.current = 0;
    gesture.current = null;
    setDragging(false);
  };
  const positionAtPointer = (value: Gesture): Position => {
    const rect = map.getContainer().getBoundingClientRect();
    const next = map
      .unproject([
        value.x - rect.left + value.grabX,
        value.y - rect.top + value.grabY,
      ])
      .wrap();
    return [next.lng, Math.max(-85.051129, Math.min(85.051129, next.lat))];
  };
  const previewAtPointer = () => {
    const value = gesture.current;
    if (!value?.active) return;
    const position = positionAtPointer(value);
    marker.current?.setLngLat(position);
    latest.current.onDrag?.(eventFor(position));
  };
  const edgeFrame = (time: number) => {
    const value = gesture.current;
    const options = latest.current.dragOptions.edgePan;
    if (!value?.active || !options) return;
    const rect = map.getContainer().getBoundingClientRect();
    const velocity = edgePanVelocity(
      { x: value.x - rect.left, y: value.y - rect.top },
      { width: rect.width, height: rect.height },
      options.padding,
      options.maxSpeed,
    );
    const elapsed = edgeFrameTime.current
      ? Math.min(32, time - edgeFrameTime.current)
      : 16;
    edgeFrameTime.current = time;
    if (velocity.x || velocity.y) {
      map.panBy(
        [(velocity.x * elapsed) / 1000, (velocity.y * elapsed) / 1000],
        { duration: 0 },
      );
      if (options.zoomOutPerSecond && map.getZoom() > options.minZoom)
        map.setZoom(
          Math.max(
            options.minZoom,
            map.getZoom() - (options.zoomOutPerSecond * elapsed) / 1000,
          ),
        );
      previewAtPointer();
    }
    edgeAnimation.current = requestAnimationFrame(edgeFrame);
  };
  const returnToHost = () => {
    const instance = marker.current;
    if (!instance) return;
    cancelAnimationFrame(animation.current);
    const from = currentPosition();
    const to = latest.current.pin.position;
    const duration = window.matchMedia("(prefers-reduced-motion: reduce)")
      .matches
      ? 0
      : latest.current.dragOptions.durationMs;
    const start = performance.now();
    const frame = (time: number) => {
      const progress = duration ? Math.min(1, (time - start) / duration) : 1;
      const eased = 1 - (1 - progress) ** 3;
      instance.setLngLat([
        from[0] + (to[0] - from[0]) * eased,
        from[1] + (to[1] - from[1]) * eased,
      ]);
      if (progress < 1) animation.current = requestAnimationFrame(frame);
    };
    animation.current = requestAnimationFrame(frame);
  };
  const commit = (position: Position, source: KMapPinMove["source"]) => {
    const request = ++revision.current;
    // Keep the dropped position while a host processes/accepts it; never snap back first.
    Promise.resolve()
      .then(() => latest.current.onMove?.({ id: pin.id, position, source }))
      .then((accepted) => {
        if (accepted === false && request === revision.current) returnToHost();
      })
      .catch(() => {
        if (request === revision.current) returnToHost();
      });
  };

  useEffect(() => {
    marker.current = new Marker({ element, anchor: pin.anchor ?? "bottom" })
      .setLngLat([lng, lat])
      .addTo(map);
    return () => {
      ++revision.current;
      clearTimeout(gesture.current?.timer);
      cancelAnimationFrame(animation.current);
      cancelAnimationFrame(edgeAnimation.current);
      marker.current?.remove();
      marker.current = null;
    };
  }, [map, element, pin.anchor]);
  useEffect(() => {
    // Controlled previews echo the marker position while the pointer is still
    // down. Keep that render from cancelling the gesture after its first frame.
    if (gesture.current?.active) return;
    ++revision.current;
    cancelAnimationFrame(animation.current);
    if (gesture.current) cancelGesture();
    marker.current?.setLngLat([lng, lat]);
  }, [lng, lat]);
  useEffect(() => {
    const reanchor = () => previewAtPointer();
    map.on("move", reanchor);
    return () => {
      map.off("move", reanchor);
    };
  }, [map]);
  useEffect(() => {
    const size = pin.size ?? 40;
    const tipOffset =
      !renderPin && (pin.shape ?? "pin") === "pin"
        ? size / Math.SQRT2 - Math.max(44, size) / 2
        : 0;
    marker.current?.setOffset([0, -tipOffset]);
  }, [pin.size, pin.shape, renderPin]);
  useEffect(() => {
    if (!pin.draggable && gesture.current) {
      cancelGesture();
      returnToHost();
    }
  }, [pin.draggable]);

  const activate = (value: Gesture) => {
    if (gesture.current !== value) return;
    value.active = true;
    const rect = map.getContainer().getBoundingClientRect();
    const projected = map.project(value.start);
    value.grabX = projected.x - (value.x - rect.left);
    value.grabY = projected.y - (value.y - rect.top);
    suppressClick.current = true;
    setDragging(true);
    latest.current.onDragStart?.(eventFor(value.start));
    if (latest.current.dragOptions.edgePan)
      edgeAnimation.current = requestAnimationFrame(edgeFrame);
  };
  const down = (event: ReactPointerEvent<HTMLButtonElement>) => {
    if (
      !pin.draggable ||
      event.button !== 0 ||
      !event.isPrimary ||
      gesture.current
    )
      return;
    event.preventDefault();
    event.stopPropagation();
    event.currentTarget.focus({ preventScroll: true });
    event.currentTarget.setPointerCapture(event.pointerId);
    ++revision.current;
    cancelAnimationFrame(animation.current);
    suppressClick.current = false;
    const value: Gesture = {
      id: event.pointerId,
      target: event.currentTarget,
      x: event.clientX,
      y: event.clientY,
      start: currentPosition(),
      grabX: 0,
      grabY: 0,
      active: false,
    };
    gesture.current = value;
    if (dragOptions.activation === "longPress")
      value.timer = setTimeout(() => activate(value), dragOptions.longPressMs);
  };
  const move = (event: ReactPointerEvent<HTMLButtonElement>) => {
    const value = gesture.current;
    if (!value || event.pointerId !== value.id) return;
    const dx = event.clientX - value.x,
      dy = event.clientY - value.y;
    if (!value.active) {
      if (dragOptions.activation === "longPress") {
        if (Math.hypot(dx, dy) > 8) cancelGesture();
        return;
      }
      if (Math.hypot(dx, dy) < 3) return;
      activate(value);
    }
    value.x = event.clientX;
    value.y = event.clientY;
    previewAtPointer();
  };
  const finish = (
    event: ReactPointerEvent<HTMLButtonElement>,
    cancelled = false,
  ) => {
    const value = gesture.current;
    if (!value || event.pointerId !== value.id) return;
    const position = currentPosition();
    cancelGesture();
    if (event.currentTarget.hasPointerCapture(event.pointerId))
      event.currentTarget.releasePointerCapture(event.pointerId);
    if (!value.active) return;
    if (cancelled) {
      latest.current.onDragCancel?.(eventFor(position));
      returnToHost();
      return;
    }
    latest.current.onDragEnd?.(eventFor(position));
    commit(position, "drag");
  };
  useEffect(() => {
    const cancelForAdditionalPointer = (event: globalThis.PointerEvent) => {
      const value = gesture.current;
      if (!value || event.pointerId === value.id) return;
      const position = currentPosition();
      const active = value.active;
      cancelGesture();
      if (value.target.hasPointerCapture(value.id))
        value.target.releasePointerCapture(value.id);
      // A cancelled midpoint gesture must not fall through to its click action.
      suppressClick.current = true;
      if (active) latest.current.onDragCancel?.(eventFor(position));
      returnToHost();
    };
    window.addEventListener("pointerdown", cancelForAdditionalPointer, true);
    return () =>
      window.removeEventListener(
        "pointerdown",
        cancelForAdditionalPointer,
        true,
      );
  }, []);
  return createPortal(
    <button
      type="button"
      className="k-map__pin"
      data-shape={renderPin ? "custom" : (pin.shape ?? "pin")}
      data-dragging={dragging}
      data-draggable={pin.draggable || undefined}
      aria-label={pin.label}
      aria-pressed={selected}
      title={pin.label}
      onClick={() => {
        if (suppressClick.current) {
          suppressClick.current = false;
          return;
        }
        onClick();
      }}
      onMouseDown={(event) => {
        if (pin.draggable) event.stopPropagation();
      }}
      onTouchStart={(event) => {
        // The second touchstart contains both touches and must reach MapLibre so
        // its native pinch recognizer can take over after the pin drag cancels.
        if (pin.draggable && event.touches.length < 2) event.stopPropagation();
      }}
      onPointerDown={down}
      onPointerMove={move}
      onPointerUp={(event) => finish(event)}
      onPointerCancel={(event) => finish(event, true)}
      onLostPointerCapture={(event) => finish(event, true)}
      onContextMenu={(event) => {
        if (pin.draggable) event.preventDefault();
      }}
      aria-keyshortcuts={
        pin.draggable
          ? "ArrowUp ArrowDown ArrowLeft ArrowRight Escape"
          : undefined
      }
      onKeyDown={(event) => {
        if (event.key === "Escape" && gesture.current) {
          event.stopPropagation();
          const value = gesture.current;
          cancelGesture();
          if (value.active)
            latest.current.onDragCancel?.(eventFor(currentPosition()));
          returnToHost();
          return;
        }
        if (
          !pin.draggable ||
          !["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"].includes(
            event.key,
          )
        )
          return;
        event.preventDefault();
        event.stopPropagation();
        const [currentLng, currentLat] = currentPosition();
        const delta = event.shiftKey ? 0.001 : 0.0001;
        const nextLng =
          currentLng +
          (event.key === "ArrowRight"
            ? delta
            : event.key === "ArrowLeft"
              ? -delta
              : 0);
        const position: Position = [
          ((nextLng + 540) % 360) - 180,
          Math.max(
            -85.051129,
            Math.min(
              85.051129,
              currentLat +
                (event.key === "ArrowUp"
                  ? delta
                  : event.key === "ArrowDown"
                    ? -delta
                    : 0),
            ),
          ),
        ];
        marker.current?.setLngLat(position);
        commit(position, "keyboard");
      }}
      style={
        {
          "--k-map-pin-size":
            pin.size === undefined ? undefined : `${pin.size}px`,
          "--k-map-pin-color": pin.color,
          "--k-map-pin-drag-scale": dragOptions.scale,
          "--k-map-pin-drag-duration": `${dragOptions.durationMs}ms`,
        } as CSSProperties
      }
    >
      <span className="k-map__pin-motion">
        <span className={renderPin ? "k-map__pin-content" : "k-map__pin-face"}>
          {renderPin ? (
            renderPin(pin, {
              selected,
              draggable: pin.draggable ?? false,
              dragging,
            })
          ) : pin.imageUrl ? (
            <img src={pin.imageUrl} alt="" draggable={false} />
          ) : (
            <KIcon name={pin.icon ?? "map-pin"} size={20} />
          )}
        </span>
      </span>
    </button>,
    element,
  );
}
