import { useLayoutEffect, useRef, useState, type ReactNode } from "react";
import { KIconButton } from "../actions/icon-button.js";
import { KListItem, KList } from "../data-display/list.js";
import { useKLocalization } from "../localization/provider.js";
import {
  KSidebar,
  KSidebarBody,
  KSidebarGroup,
  KSidebarItem,
} from "../navigation/sidebar.js";
import { KAdaptiveDialog } from "../overlays/overlay.js";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";
import type { KIconName } from "../generated/icons.js";
import { KText } from "../primitives/text.js";

/** One area of a KSettingsDialog (Decision 0017). */
export interface KSettingsDialogSection {
  id: string;
  title: string;
  /** Sections with the same group are listed under one label, in order. */
  group?: string;
  /** Icon in the navigation on tablets and desktops. */
  icon?: KIconName;
  description?: ReactNode;
  /** Short state on the phone list ("2 of 3 active"). */
  summary?: string;
  /** Marks the section; the section explains it with a KAlert. */
  status?: "info" | "success" | "warning" | "error";
  /** Unsaved changes in this section. */
  dirty?: boolean;
  content: ReactNode;
}

export interface KSettingsDialogPanelProps {
  title: string;
  subtitle?: string;
  /** Avatar or icon before the title. */
  leading?: ReactNode;
  /** A status in the header, e.g. a button that selects a section. */
  headerAction?: ReactNode;
  /** Usually KSaveBar: one save for all sections. */
  footer?: ReactNode;
  sections: readonly KSettingsDialogSection[];
  /** The open section. On phones `null` shows the section list. */
  selectedId?: string | null;
  onSelectedIdChange?: (id: string | null) => void;
  onClose?: () => void;
  closeLabel?: string;
  navigationLabel?: string;
  /** `auto` follows the panel width (600 px), like Flutter. */
  layout?: "auto" | "split" | "stack";
  /** Draws the sheet grip in the stack layout. */
  grip?: boolean;
  className?: string;
}

const breakpoint = 600;

function groupsOf(sections: readonly KSettingsDialogSection[]) {
  const groups: { label?: string; sections: KSettingsDialogSection[] }[] = [];
  for (const section of sections) {
    const last = groups.at(-1);
    if (!last || last.label !== section.group)
      groups.push({ label: section.group, sections: [section] });
    else last.sections.push(section);
  }
  return groups;
}

function Marker({ section }: { section: KSettingsDialogSection }) {
  const tone = section.dirty ? "dirty" : section.status;
  return tone ? (
    <span className="k-settings-dialog__marker" data-tone={tone} aria-hidden />
  ) : null;
}

/**
 * Settings of one object: a section navigation beside the content on
 * tablets and desktops, a section list with detail pages on phones
 * (Decision 0017). Same layout as Flutter `KSettingsDialog`.
 */
export function KSettingsDialogPanel({
  title,
  subtitle,
  leading,
  headerAction,
  footer,
  sections,
  selectedId,
  onSelectedIdChange,
  onClose,
  closeLabel = "Close",
  navigationLabel = "Sections",
  layout = "auto",
  grip = true,
  className,
}: KSettingsDialogPanelProps) {
  const { messages } = useKLocalization();
  const ref = useRef<HTMLDivElement>(null);
  const scroll = useRef<HTMLDivElement>(null);
  const [internal, setInternal] = useState<string | null>(selectedId ?? null);
  const [narrow, setNarrow] = useState(false);
  useLayoutEffect(() => {
    const element = ref.current;
    if (layout !== "auto" || !element) return;
    const measure = () =>
      setNarrow(element.getBoundingClientRect().width < breakpoint);
    measure();
    if (typeof ResizeObserver === "undefined") return;
    const observer = new ResizeObserver(measure);
    observer.observe(element);
    return () => observer.disconnect();
  }, [layout]);
  const stack = layout === "stack" || (layout === "auto" && narrow);
  const currentId = onSelectedIdChange ? (selectedId ?? null) : internal;
  const select = (id: string | null) => {
    scroll.current?.scrollTo({ top: 0 });
    if (onSelectedIdChange) onSelectedIdChange(id);
    else setInternal(id);
  };
  const found = sections.find((section) => section.id === currentId);
  const current = stack ? found : (found ?? sections[0]);
  const groups = groupsOf(sections);
  const close = onClose ? (
    <KIconButton
      icon="x"
      label={closeLabel}
      variant="ghost"
      onClick={onClose}
    />
  ) : null;
  const detailHeader = stack && current;
  return (
    <div
      ref={ref}
      className={["k-settings-dialog", className].filter(Boolean).join(" ")}
      data-layout={stack ? "stack" : "split"}
    >
      {stack && grip ? (
        <div className="k-settings-dialog__grip" aria-hidden>
          <span className="k-bottom-sheet-grip" />
        </div>
      ) : null}
      <header
        className="k-settings-dialog__header"
        data-back={detailHeader ? true : undefined}
      >
        {detailHeader ? (
          <KButton variant="ghost" onClick={() => select(null)}>
            <KIcon name="chevron-left" size={16} />
            {messages.settingsBack}
          </KButton>
        ) : (
          leading
        )}
        <div className="k-settings-dialog__heading">
          <KText
            as="h2"
            variant="heading5"
            className="k-settings-dialog__title"
          >
            {detailHeader ? current.title : title}
          </KText>
          {!detailHeader && subtitle ? (
            <KText
              as="p"
              variant="caption"
              className="k-settings-dialog__subtitle"
            >
              {subtitle}
            </KText>
          ) : null}
        </div>
        {!detailHeader ? headerAction : null}
        {close}
      </header>
      <div className="k-settings-dialog__main">
        {stack ? null : (
          <KSidebar mode="expanded" label={navigationLabel}>
            <KSidebarBody>
              {groups.map((group, index) => (
                <KSidebarGroup key={group.label ?? index} label={group.label}>
                  {group.sections.map((section) => (
                    <KSidebarItem
                      key={section.id}
                      label={section.title}
                      textLabel={section.title}
                      leading={
                        section.icon ? (
                          <KIcon name={section.icon} size={20} />
                        ) : undefined
                      }
                      active={section.id === current?.id}
                      trailing={<Marker section={section} />}
                      onSelect={() => select(section.id)}
                    />
                  ))}
                </KSidebarGroup>
              ))}
            </KSidebarBody>
          </KSidebar>
        )}
        <div className="k-settings-dialog__content" ref={scroll}>
          {current ? (
            <section aria-label={current.title}>
              {stack ? null : (
                <KText as="h3" variant="heading4">
                  {current.title}
                </KText>
              )}
              {current.description ? (
                <KText
                  as="p"
                  variant="bodySmall"
                  className="k-settings-dialog__description"
                >
                  {current.description}
                </KText>
              ) : null}
              <div className="k-settings-dialog__body">{current.content}</div>
            </section>
          ) : (
            <div className="k-settings-dialog__list">
              {groups.map((group, index) => (
                <KList key={group.label ?? index} title={group.label}>
                  {group.sections.map((section) => (
                    <KListItem
                      key={section.id}
                      title={section.title}
                      description={section.summary}
                      trailing={<Marker section={section} />}
                      disclosure
                      onClick={() => select(section.id)}
                    />
                  ))}
                </KList>
              ))}
            </div>
          )}
        </div>
      </div>
      {footer ? (
        <div className="k-settings-dialog__footer">{footer}</div>
      ) : null}
    </div>
  );
}

export interface KSettingsDialogProps extends KSettingsDialogPanelProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  dismissible?: boolean;
}

/** KSettingsDialogPanel in a dialog on tablets and desktops, a bottom sheet on phones. */
export function KSettingsDialog({
  open,
  onOpenChange,
  dismissible,
  className,
  ...panel
}: KSettingsDialogProps) {
  return (
    <KAdaptiveDialog
      open={open}
      onOpenChange={onOpenChange}
      dismissible={dismissible}
      title={panel.title}
      headerless
      showClose={false}
      contentInset={false}
      className={["k-settings-dialog-surface", className]
        .filter(Boolean)
        .join(" ")}
    >
      <KSettingsDialogPanel
        {...panel}
        grip={false}
        onClose={panel.onClose ?? (() => onOpenChange(false))}
      />
    </KAdaptiveDialog>
  );
}

export interface KSaveBarProps {
  changes: number;
  onSave: () => void;
  onDiscard?: () => void;
  saving?: boolean;
  className?: string;
}

/** Saves a form or KSettingsDialog together (Decision 0017). */
export function KSaveBar({
  changes,
  onSave,
  onDiscard,
  saving = false,
  className,
}: KSaveBarProps) {
  const { messages } = useKLocalization();
  const dirty = changes > 0;
  const state = !dirty
    ? messages.allSaved
    : changes === 1
      ? messages.unsavedChange
      : messages.unsavedChanges.replace("{count}", String(changes));
  return (
    <div className="k-save-bar-container">
      <div
        className={["k-save-bar", className].filter(Boolean).join(" ")}
        data-dirty={dirty || undefined}
      >
        <KText
          as="p"
          variant="bodySmall"
          className="k-save-bar__state"
          aria-live="polite"
        >
          {state}
        </KText>
        {onDiscard ? (
          <KButton
            variant="ghost"
            disabled={!dirty || saving}
            onClick={onDiscard}
          >
            {messages.discard}
          </KButton>
        ) : null}
        <KButton disabled={!dirty || saving} onClick={onSave}>
          {messages.save}
        </KButton>
      </div>
    </div>
  );
}
