import type { ReactNode } from "react";
import { KStack, KInline } from "../primitives/layout.js";

/** Shared editor geometry. Hosts own form state, validation and persistence. */
export function KCatalogEditorBody({
  preview,
  children,
}: {
  preview: ReactNode;
  children: ReactNode;
}) {
  return (
    <div className="k-catalog-editor-body">
      <div className="k-catalog-editor-columns">
        <aside className="k-catalog-editor-aside">{preview}</aside>
        <KStack
          className="k-catalog-editor-fields"
          gap="section"
          align="stretch"
        >
          {children}
        </KStack>
      </div>
    </div>
  );
}
export function KCatalogEditorSection({
  title,
  help,
  action,
  children,
}: {
  title: string;
  help?: string;
  action?: ReactNode;
  children: ReactNode;
}) {
  return (
    <section className="k-catalog-editor-section">
      {title && (
        <div className="k-catalog-editor-section-title">
          <h2>{title}</h2>
          {action}
        </div>
      )}
      {children}
      {help && <p className="k-catalog-editor-help">{help}</p>}
    </section>
  );
}
export function KCatalogEditorCard({
  children,
  inset = true,
  className = "",
}: {
  children: ReactNode;
  inset?: boolean;
  className?: string;
}) {
  return (
    <div
      className={`k-catalog-editor-card${inset ? " k-catalog-editor-inset" : ""} ${className}`}
    >
      {children}
    </div>
  );
}
export function KCatalogEditorRow({
  title,
  help,
  children,
  divider = false,
}: {
  title: string;
  help?: string;
  children: ReactNode;
  divider?: boolean;
}) {
  return (
    <div className="k-catalog-editor-row" data-divider={divider || undefined}>
      <div className="k-catalog-editor-row-label">
        {title}
        {help && <small>{help}</small>}
      </div>
      {children}
    </div>
  );
}
export function KCatalogEditorPreview({
  image,
  name,
  subtitle,
  tags,
  label = "So sehen es Kund:innen",
}: {
  image: ReactNode;
  name: string;
  subtitle: string;
  tags?: ReactNode;
  label?: string;
}) {
  return (
    <div className="k-catalog-editor-preview">
      <span className="k-catalog-editor-preview-label">{label}</span>
      <div className="k-catalog-editor-preview-image">{image}</div>
      <div className="k-catalog-editor-preview-copy">
        <strong>{name}</strong>
        <small>{subtitle}</small>
        {tags && (
          <KInline gap="control" wrap>
            {tags}
          </KInline>
        )}
      </div>
    </div>
  );
}
