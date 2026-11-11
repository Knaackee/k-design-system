import { createContext, useContext } from "react";

/** Internal: inherit the owner layer through React portals, without global ordering. */
export const OverlayLayerContext = createContext<number | undefined>(undefined);

export function resolveOverlayLayer(parent?: number, explicit?: number) {
  return explicit ?? (parent === undefined ? 3010 : parent + 30);
}

export function useOverlayLayer(explicit?: number) {
  return resolveOverlayLayer(useContext(OverlayLayerContext), explicit);
}
