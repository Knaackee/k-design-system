import { KBottomSheet, type KBottomSheetProps } from "./overlay.js";

export type KPageSheetProps = KBottomSheetProps & {
  presentationRootId: string;
};

/** Tall page presentation with a gesture-linked receding application surface. */
export function KPageSheet(props: KPageSheetProps) {
  return <KBottomSheet {...props} />;
}
