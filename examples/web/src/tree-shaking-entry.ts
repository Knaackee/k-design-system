// Deliberately use the root barrel here: this proves that a standard ESM
// bundler can remove unrelated root exports as well as support direct subpaths.
import { KButton } from "@k-design-system/ui";

export const ConsumerButton = KButton;
