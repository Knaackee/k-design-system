import { useMemo, useState } from "react";
import { KAttachment, KBadge } from "../basic-components.js";
import { KCheckbox } from "../forms/checkbox.js";
import { KField } from "../forms/field.js";
import { KInput } from "../forms/input.js";
import { KSelect } from "../forms/selection.js";
import type { KCardBorder } from "../primitives/card.js";
import { KButton } from "../primitives/button.js";
import { KIcon, type KIconName } from "../primitives/icon.js";
import { KAgentQuestion } from "./agent-parts.js";
import type {
  KAgentAttachmentRequestPart,
  KAgentAttachmentRequestResponse,
  KAgentExternalActionPart,
  KAgentExternalActionResponse,
  KAgentFormField,
  KAgentFormPart,
  KAgentFormResponse,
  KAgentQuestionPart,
  KAgentQuestionResponse,
} from "./types.js";

export type KAgentQuestionToolProps = {
  border?: KCardBorder;
  part: KAgentQuestionPart;
  onResponse?: (response: KAgentQuestionResponse) => void;
};

export const KAgentTextQuestion = (props: KAgentQuestionToolProps) => (
  <KAgentQuestion {...props} />
);
export const KAgentSingleChoice = (props: KAgentQuestionToolProps) => (
  <KAgentQuestion {...props} />
);
export const KAgentMultipleChoice = (props: KAgentQuestionToolProps) => (
  <KAgentQuestion {...props} />
);
export const KAgentConfirmation = (props: KAgentQuestionToolProps) => (
  <KAgentQuestion {...props} />
);

export function KAgentForm({
  part,
  onResponse,
  requiredLabel = "Required",
}: {
  part: KAgentFormPart;
  onResponse?: (response: KAgentFormResponse) => void;
  requiredLabel?: string;
}) {
  const initial = useMemo(
    () =>
      Object.fromEntries(
        part.fields.map((field) => [
          field.id,
          field.defaultValue ?? defaultFieldValue(field),
        ]),
      ),
    [part.fields],
  );
  const [values, setValues] = useState<Record<string, unknown>>(initial);
  const pending = part.state === "pending";
  const valid = part.fields.every((field) =>
    validateField(field, values[field.id]),
  );
  const update = (id: string, value: unknown) =>
    setValues((current) => ({ ...current, [id]: value }));

  if (!pending) {
    return (
      <ResolvedCard
        title={part.title}
        summary={part.responseSummary}
        state={part.state}
      />
    );
  }

  return (
    <section
      className="k-agent-card k-agent-form"
      aria-labelledby={`${part.id}-title`}
    >
      <AskHeading
        id={`${part.id}-title`}
        icon="info"
        title={part.title}
        description={part.description}
      />
      <div className="k-agent-form__fields">
        {part.fields.map((field) => (
          <FormField
            key={field.id}
            field={field}
            value={values[field.id]}
            onChange={(value) => update(field.id, value)}
            requiredLabel={requiredLabel}
          />
        ))}
      </div>
      <div className="k-agent-actions">
        {part.cancelLabel ? (
          <KButton
            variant="secondary"
            onClick={() =>
              onResponse?.({ formId: part.id, action: "cancel", values })
            }
          >
            {part.cancelLabel}
          </KButton>
        ) : null}
        <KButton
          disabled={!valid}
          onClick={() =>
            onResponse?.({ formId: part.id, action: "submit", values })
          }
        >
          {part.submitLabel ?? "Continue"}
        </KButton>
      </div>
    </section>
  );
}

export function KAgentExternalAction({
  part,
  onResponse,
}: {
  part: KAgentExternalActionPart;
  onResponse?: (response: KAgentExternalActionResponse) => void;
}) {
  if (part.state !== "pending") {
    return (
      <ResolvedCard
        title={part.title}
        summary={part.responseSummary}
        state={part.state}
      />
    );
  }
  return (
    <section className="k-agent-card k-agent-external-action">
      <AskHeading
        icon="external-link"
        title={part.title}
        description={part.description}
      />
      <div className="k-agent-actions">
        {part.cancelLabel ? (
          <KButton
            variant="secondary"
            onClick={() =>
              onResponse?.({
                actionId: part.id,
                action: "cancel",
                url: part.url,
              })
            }
          >
            {part.cancelLabel}
          </KButton>
        ) : null}
        <KButton
          onClick={() =>
            onResponse?.({ actionId: part.id, action: "open", url: part.url })
          }
        >
          {part.actionLabel}
        </KButton>
      </div>
    </section>
  );
}

export function KAgentAttachmentRequest({
  part,
  onResponse,
}: {
  part: KAgentAttachmentRequestPart;
  onResponse?: (response: KAgentAttachmentRequestResponse) => void;
}) {
  if (part.state !== "pending") {
    return (
      <ResolvedCard
        title={part.title}
        summary={part.responseSummary}
        state={part.state}
      />
    );
  }
  return (
    <section className="k-agent-card k-agent-attachment-request">
      <AskHeading
        icon="paperclip"
        title={part.title}
        description={part.description}
      />
      {part.attachments?.length ? (
        <div className="k-agent-attachment-request__files">
          {part.attachments.map((attachment) => (
            <KAttachment
              key={attachment.id}
              title={attachment.title}
              description={attachment.description}
              state={attachment.state}
              progress={attachment.progress}
            />
          ))}
        </div>
      ) : null}
      <KButton
        onClick={() =>
          onResponse?.({
            requestId: part.id,
            action: "select",
            accept: part.accept,
            multiple: part.multiple ?? false,
            maxFiles: part.maxFiles,
          })
        }
      >
        {part.actionLabel}
      </KButton>
    </section>
  );
}

function FormField({
  field,
  value,
  onChange,
  requiredLabel,
}: {
  field: KAgentFormField;
  value: unknown;
  onChange: (value: unknown) => void;
  requiredLabel: string;
}) {
  const helper = [field.description, field.required ? requiredLabel : null]
    .filter(Boolean)
    .join(" · ");
  if (field.kind === "boolean") {
    return (
      <KField
        label={field.label}
        helperText={helper || undefined}
        required={field.required}
      >
        <KCheckbox
          label={field.label}
          value={Boolean(value)}
          onValueChange={onChange}
        />
      </KField>
    );
  }
  if (field.kind === "single-choice") {
    return (
      <KField
        label={field.label}
        helperText={helper || undefined}
        required={field.required}
      >
        <KSelect
          options={(field.options ?? []).map(({ id, label }) => ({
            value: id,
            label,
          }))}
          value={typeof value === "string" ? value : null}
          placeholder={field.placeholder}
          onValueChange={onChange}
        />
      </KField>
    );
  }
  if (field.kind === "multiple-choice") {
    const selected = Array.isArray(value) ? value.map(String) : [];
    return (
      <fieldset className="k-agent-form__choice-group">
        <legend>
          {field.label}
          {field.required ? " *" : ""}
        </legend>
        {field.description ? <small>{field.description}</small> : null}
        {field.options?.map((option) => (
          <KCheckbox
            key={option.id}
            label={option.label}
            value={selected.includes(option.id)}
            onValueChange={(checked) =>
              onChange(
                checked
                  ? [...selected, option.id]
                  : selected.filter((id) => id !== option.id),
              )
            }
          />
        ))}
      </fieldset>
    );
  }
  return (
    <KField
      label={field.label}
      helperText={helper || undefined}
      required={field.required}
    >
      <KInput
        type={field.kind === "number" ? "number" : "text"}
        value={String(value ?? "")}
        placeholder={field.placeholder}
        min={field.minimum}
        max={field.maximum}
        onChange={(event) =>
          onChange(
            field.kind === "number"
              ? event.target.valueAsNumber
              : event.target.value,
          )
        }
      />
    </KField>
  );
}

function AskHeading({
  id,
  icon,
  title,
  description,
}: {
  id?: string;
  icon: KIconName;
  title: string;
  description?: string;
}) {
  return (
    <div className="k-agent-card__heading">
      <KIcon name={icon} />
      <div>
        <strong id={id}>{title}</strong>
        {description ? <p>{description}</p> : null}
      </div>
    </div>
  );
}

function ResolvedCard({
  title,
  summary,
  state,
}: {
  title: string;
  summary?: string;
  state: string;
}) {
  return (
    <section className="k-agent-card k-agent-request--resolved">
      <AskHeading icon="check" title={title} description={summary} />
      <KBadge variant="outline">{state}</KBadge>
    </section>
  );
}

function defaultFieldValue(field: KAgentFormField): unknown {
  if (field.kind === "boolean") return false;
  if (field.kind === "multiple-choice") return [];
  return "";
}

function validateField(field: KAgentFormField, value: unknown) {
  if (field.kind === "number" && typeof value === "number") {
    if (Number.isNaN(value)) return !field.required;
    return (
      (field.minimum === undefined || value >= field.minimum) &&
      (field.maximum === undefined || value <= field.maximum)
    );
  }
  if (field.kind === "multiple-choice") {
    const count = Array.isArray(value) ? value.length : 0;
    return (
      (!field.required || count > 0) &&
      (field.minItems === undefined || count >= field.minItems) &&
      (field.maxItems === undefined || count <= field.maxItems)
    );
  }
  if (!field.required) return true;
  return field.kind === "boolean"
    ? value === true
    : String(value ?? "").trim().length > 0;
}
