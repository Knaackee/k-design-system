import {
  useId,
  useEffect,
  useRef,
  useState,
  type ChangeEvent,
  type FormEvent,
  type ReactNode,
} from "react";

import { KBadge } from "../basic-components.js";
import type { KIntegrationCatalogState } from "./integrations-admin.js";
import { KField } from "../forms/field.js";
import { KInput } from "../forms/input.js";
import { KSelect } from "../forms/selection.js";
import { KTextarea } from "../forms/textarea.js";
import { KDialog } from "../overlays/overlay.js";
import { KButton } from "../primitives/button.js";

export type KIntegrationAuthType = "oauth" | "none" | "bearer";

export interface KIntegrationDraft {
  name: string;
  description: string;
  category: string;
  endpoint: string;
  authType: KIntegrationAuthType;
  clientId: string;
  scopes: string;
  iconDataUrl: string;
}

export interface KIntegrationEditorProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  value?: KIntegrationDraft;
  icon?: ReactNode;
  catalogState?: KIntegrationCatalogState;
  testControls?: ReactNode;
  /** Explicit development origins only. The server must independently authorize endpoints. */
  allowedHttpOrigins?: readonly string[];
  testSuccessMessage?: string;
  testFailureMessage?: string;
  testErrorMessage?: string;
  onTest?: (draft: KIntegrationDraft) => boolean | Promise<boolean>;
  onPublish?: (draft: KIntegrationDraft) => void | Promise<void>;
  onSave: (
    draft: KIntegrationDraft,
    state: KIntegrationCatalogState,
  ) => void | Promise<void>;
}

type RequiredField = "name" | "description" | "category" | "endpoint";
type ValidationErrors = Partial<Record<RequiredField, string>>;

const emptyDraft: KIntegrationDraft = {
  name: "",
  description: "",
  category: "",
  endpoint: "",
  authType: "oauth",
  clientId: "",
  scopes: "",
  iconDataUrl: "",
};

const authOptions = [
  { value: "oauth", label: "OAuth 2.0" },
  { value: "none", label: "Keine Authentifizierung" },
  { value: "bearer", label: "Bearer-Token" },
] as const;

const supportedIconTypes = new Set(["image/png", "image/jpeg", "image/webp"]);
const maximumIconBytes = 2 * 1024 * 1024;

export function KIntegrationEditor({
  open,
  onOpenChange,
  value,
  icon,
  onSave,
  catalogState = "draft",
  onTest,
  onPublish,
  testControls,
  allowedHttpOrigins = [],
  testSuccessMessage = "Test erfolgreich. Freigabe möglich.",
  testFailureMessage = "Test fehlgeschlagen. Bitte prüfe die Konfiguration.",
  testErrorMessage = "Die Aktion konnte nicht abgeschlossen werden. Bitte versuche es erneut.",
}: KIntegrationEditorProps) {
  const [status, setStatus] = useState(catalogState);
  const [testMessage, setTestMessage] = useState("");
  const formId = useId();
  const iconInput = useRef<HTMLInputElement>(null);
  const readerRef = useRef<FileReader | null>(null);
  const [draft, setDraft] = useState<KIntegrationDraft>(() => ({
    ...emptyDraft,
    ...value,
  }));
  const [errors, setErrors] = useState<ValidationErrors>({});
  const [iconError, setIconError] = useState("");
  const [isReadingIcon, setIsReadingIcon] = useState(false);
  const [operation, setOperation] = useState<
    "test" | "save" | "publish" | null
  >(null);
  const pending = useRef(false);
  const mounted = useRef(true);
  const busy = isReadingIcon || operation !== null;

  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
      readerRef.current?.abort();
    };
  }, []);

  function update<K extends keyof KIntegrationDraft>(
    field: K,
    nextValue: KIntegrationDraft[K],
  ) {
    setDraft((current) => ({ ...current, [field]: nextValue }));
    setStatus("draft");
    setTestMessage("");
    if (field in errors) {
      setErrors((current) => ({ ...current, [field]: undefined }));
    }
  }

  async function perform(
    kind: "test" | "save" | "publish",
    action: () => Promise<void>,
  ) {
    if (pending.current || isReadingIcon) return;
    pending.current = true;
    setOperation(kind);
    setTestMessage("");
    try {
      await action();
    } catch {
      if (mounted.current) {
        if (kind === "test") setStatus("draft");
        setTestMessage(
          kind === "test"
            ? testErrorMessage
            : "Die Aktion konnte nicht abgeschlossen werden. Bitte versuche es erneut.",
        );
      }
    } finally {
      pending.current = false;
      if (mounted.current) setOperation(null);
    }
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const normalizedDraft = normalizeDraft(draft);
    const nextErrors = validateDraft(normalizedDraft, allowedHttpOrigins);
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length === 0 && !busy) {
      void perform("save", async () => {
        await onSave(normalizedDraft, status);
      });
    }
  }

  function runTest() {
    const normalized = normalizeDraft(draft);
    const nextErrors = validateDraft(normalized, allowedHttpOrigins);
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length || busy || !onTest) return;
    void perform("test", async () => {
      const success = await onTest(normalized);
      if (!mounted.current) return;
      setStatus(success ? "tested" : "draft");
      setTestMessage(success ? testSuccessMessage : testFailureMessage);
    });
  }

  function selectIcon(event: ChangeEvent<HTMLInputElement>) {
    const input = event.currentTarget;
    const file = input.files?.[0];
    input.value = "";
    if (!file) return;

    readerRef.current?.abort();
    readerRef.current = null;
    setIsReadingIcon(false);
    if (!supportedIconTypes.has(file.type)) {
      setIconError("Bitte wähle eine PNG-, JPEG- oder WebP-Datei aus.");
      return;
    }
    if (file.size > maximumIconBytes) {
      setIconError("Das Icon darf höchstens 2 MB groß sein.");
      return;
    }

    const reader = new FileReader();
    readerRef.current = reader;
    setIsReadingIcon(true);
    reader.addEventListener("load", () => {
      if (typeof reader.result === "string") {
        update("iconDataUrl", reader.result);
        setIconError("");
      }
      if (readerRef.current === reader) readerRef.current = null;
      setIsReadingIcon(false);
    });
    reader.addEventListener("error", () => {
      setIconError("Das Icon konnte nicht gelesen werden.");
      if (readerRef.current === reader) readerRef.current = null;
      setIsReadingIcon(false);
    });
    reader.readAsDataURL(file);
  }

  const hasIconPreview = draft.iconDataUrl.startsWith("data:image/");

  return (
    <KDialog
      open={open}
      onOpenChange={(nextOpen) => {
        if (!pending.current) onOpenChange(nextOpen);
      }}
      title={value ? "Integration bearbeiten" : "Integration hinzufügen"}
      description="Lege die Katalogangaben und die technische Verbindung fest."
      closeLabel="Dialog schließen"
      className="k-integration-editor"
      actions={
        <>
          <KButton
            variant="ghost"
            disabled={busy}
            onClick={() => onOpenChange(false)}
          >
            Abbrechen
          </KButton>
          <KButton
            type="submit"
            form={formId}
            loading={isReadingIcon || operation === "save"}
            disabled={busy}
          >
            Integration speichern
          </KButton>
        </>
      }
    >
      <form
        id={formId}
        className="k-integration-editor__form"
        noValidate
        onSubmit={submit}
      >
        <fieldset
          disabled={busy}
          style={{
            border: 0,
            padding: 0,
            margin: 0,
            minWidth: 0,
            display: "contents",
          }}
        >
          <div className="k-integration-editor__review">
            <KBadge
              variant={
                status === "published"
                  ? "success"
                  : status === "tested"
                    ? "info"
                    : "outline"
              }
            >
              {status === "published"
                ? "Veröffentlicht"
                : status === "tested"
                  ? "Getestet"
                  : "Entwurf"}
            </KBadge>
            {onTest ? (
              <KButton
                type="button"
                variant="secondary"
                disabled={busy}
                loading={operation === "test"}
                onClick={runTest}
              >
                Verbindung testen
              </KButton>
            ) : null}
            {onPublish ? (
              <KButton
                type="button"
                disabled={status !== "tested" || busy}
                loading={operation === "publish"}
                onClick={() => {
                  void perform("publish", async () => {
                    await onPublish(normalizeDraft(draft));
                    if (mounted.current) setStatus("published");
                  });
                }}
              >
                Veröffentlichen
              </KButton>
            ) : null}
          </div>
          {testMessage ? (
            <p role="status" className="k-integration-editor__security-note">
              {testMessage}
            </p>
          ) : null}
          {testControls}
          <div className="k-integration-editor__icon">
            {hasIconPreview || icon ? (
              <span className="k-integration-editor__icon-preview">
                {hasIconPreview ? (
                  <img src={draft.iconDataUrl} alt="Icon-Vorschau" />
                ) : (
                  icon
                )}
              </span>
            ) : null}
            <KField
              label="Icon"
              helperText="PNG, JPEG oder WebP, maximal 2 MB"
              errorText={iconError || undefined}
            >
              <input
                ref={iconInput}
                hidden
                type="file"
                accept="image/png,image/jpeg,image/webp"
                onChange={selectIcon}
              />
              <KButton
                variant="secondary"
                onClick={() => iconInput.current?.click()}
              >
                {hasIconPreview || icon ? "Icon ersetzen" : "Icon hochladen"}
              </KButton>
            </KField>
          </div>

          <KField label="Name" required errorText={errors.name}>
            <KInput
              value={draft.name}
              onChange={(event) => update("name", event.currentTarget.value)}
            />
          </KField>

          <KField label="Beschreibung" required errorText={errors.description}>
            <KTextarea
              rows={2}
              value={draft.description}
              onChange={(event) =>
                update("description", event.currentTarget.value)
              }
            />
          </KField>

          <div className="k-integration-editor__row">
            <KField label="Kategorie" required errorText={errors.category}>
              <KInput
                value={draft.category}
                onChange={(event) =>
                  update("category", event.currentTarget.value)
                }
              />
            </KField>
            <KField label="Authentifizierung" required>
              <KSelect
                value={draft.authType}
                options={authOptions}
                onValueChange={(nextValue) =>
                  update("authType", nextValue as KIntegrationAuthType)
                }
              />
            </KField>
          </div>

          <KField
            label="HTTPS-Endpoint"
            required
            errorText={errors.endpoint}
            helperText="Beispiel: https://api.example.com"
          >
            <KInput
              type="url"
              inputMode="url"
              value={draft.endpoint}
              onChange={(event) =>
                update("endpoint", event.currentTarget.value)
              }
            />
          </KField>

          {draft.authType === "oauth" ? (
            <div className="k-integration-editor__row">
              <KField label="OAuth Client-ID" helperText="Optional">
                <KInput
                  value={draft.clientId}
                  autoComplete="off"
                  onChange={(event) =>
                    update("clientId", event.currentTarget.value)
                  }
                />
              </KField>
              <KField
                label="OAuth Scopes"
                helperText="Optional, durch Leerzeichen getrennt"
              >
                <KInput
                  value={draft.scopes}
                  onChange={(event) =>
                    update("scopes", event.currentTarget.value)
                  }
                />
              </KField>
            </div>
          ) : null}

          <p className="k-integration-editor__security-note">
            Zugangsdaten werden nicht im Katalog gespeichert. Die Anmeldung
            erfolgt beim Verbinden.
          </p>
        </fieldset>
      </form>
    </KDialog>
  );
}

function validateDraft(
  draft: KIntegrationDraft,
  allowedHttpOrigins: readonly string[],
): ValidationErrors {
  const errors: ValidationErrors = {};
  if (!draft.name.trim()) errors.name = "Bitte gib einen Namen ein.";
  if (!draft.description.trim()) {
    errors.description = "Bitte gib eine Beschreibung ein.";
  }
  if (!draft.category.trim()) {
    errors.category = "Bitte gib eine Kategorie ein.";
  }

  if (!draft.endpoint.trim()) {
    errors.endpoint = "Bitte gib einen HTTPS-Endpoint ein.";
  } else {
    try {
      const endpoint = new URL(draft.endpoint);
      if (
        endpoint.protocol !== "https:" &&
        !(
          endpoint.protocol === "http:" &&
          allowedHttpOrigins.includes(endpoint.origin)
        )
      ) {
        errors.endpoint = "Der Endpoint muss HTTPS verwenden.";
      } else if (endpoint.username || endpoint.password || endpoint.hash) {
        errors.endpoint =
          "Der Endpoint darf keine Zugangsdaten oder URL-Fragmente enthalten.";
      }
    } catch {
      errors.endpoint = "Bitte gib eine gültige HTTPS-URL ein.";
    }
  }
  return errors;
}

function normalizeDraft(draft: KIntegrationDraft): KIntegrationDraft {
  return {
    ...draft,
    name: draft.name.trim(),
    description: draft.description.trim(),
    category: draft.category.trim(),
    endpoint: draft.endpoint.trim(),
    clientId: draft.clientId.trim(),
    scopes: draft.scopes.trim(),
    iconDataUrl: draft.iconDataUrl.trim(),
  };
}
