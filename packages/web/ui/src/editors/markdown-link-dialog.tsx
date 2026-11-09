import { useId, useRef, useState } from "react";
import { KField } from "../forms/field.js";
import { KInput } from "../forms/input.js";
import { KDialog } from "../overlays/overlay.js";
import { KButton } from "../primitives/button.js";

export interface KMarkdownLinkLabels {
  title: string;
  url: string;
  cancel: string;
  submit: string;
  invalidUrl: string;
  close: string;
}

export const defaultMarkdownLinkLabels: KMarkdownLinkLabels = {
  title: "Insert link",
  url: "Link URL",
  cancel: "Cancel",
  submit: "Insert link",
  invalidUrl: "Enter a valid link URL.",
  close: "Close",
};

export function markdownLinkUrl(value: string): string | undefined {
  const url = value.trim();
  if (!url || /[\s\u0000-\u001f\u007f<>\\]/.test(url)) return;
  const scheme = /^([a-z][a-z\d+.-]*):/i.exec(url)?.[1]?.toLowerCase();
  if (!scheme) return url;
  if (scheme === "mailto") return url.length > 7 ? url : undefined;
  if (scheme === "http" || scheme === "https") {
    if (!/^https?:\/\/[^/]/i.test(url)) return;
    try {
      if (new URL(url).hostname) return url;
    } catch {
      return;
    }
  }
}

export function MarkdownLinkDialog({
  labels,
  onCancel,
  onInsert,
}: {
  labels: KMarkdownLinkLabels;
  onCancel: () => void;
  onInsert: (url: string) => void;
}) {
  const inputRef = useRef<HTMLInputElement>(null);
  const form = useId();
  const [value, setValue] = useState("");
  const [invalid, setInvalid] = useState(false);

  return (
    <KDialog
      open
      title={labels.title}
      closeLabel={labels.close}
      initialFocusRef={inputRef}
      onOpenChange={(open) => {
        if (!open) onCancel();
      }}
      actions={
        <>
          <KButton variant="ghost" onClick={onCancel}>
            {labels.cancel}
          </KButton>
          <KButton type="submit" form={form}>
            {labels.submit}
          </KButton>
        </>
      }
    >
      <form
        id={form}
        onSubmit={(event) => {
          event.preventDefault();
          const url = markdownLinkUrl(value);
          if (url) onInsert(url);
          else {
            setInvalid(true);
            inputRef.current?.focus();
          }
        }}
      >
        <KField
          label={labels.url}
          errorText={invalid ? labels.invalidUrl : undefined}
        >
          <KInput
            ref={inputRef}
            value={value}
            inputMode="url"
            autoComplete="url"
            onChange={(event) => {
              setValue(event.target.value);
              setInvalid(false);
            }}
          />
        </KField>
      </form>
    </KDialog>
  );
}
