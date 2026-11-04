import type { ReactNode } from "react";
import { KTabs, KCatalogEditorRow } from "@k-design-system/ui";
export { KCatalogEditorSection as Section } from "@k-design-system/ui";
export function Row({
  title,
  help,
  children,
}: {
  title: string;
  help?: string;
  children: ReactNode;
}) {
  return (
    <KCatalogEditorRow title={title} help={help}>
      {children}
    </KCatalogEditorRow>
  );
}
export function Choice({
  value,
  onChange,
  items,
  label,
}: {
  value: string;
  onChange: (s: string) => void;
  items: [string, string][];
  label: string;
}) {
  return (
    <KTabs
      expanded
      label={label}
      value={value}
      onValueChange={onChange}
      items={items.map(([id, label]) => ({ id, label, content: null }))}
    />
  );
}
