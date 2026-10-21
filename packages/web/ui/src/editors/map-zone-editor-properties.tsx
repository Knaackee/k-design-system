import { useId, useRef, useState } from "react";
import { KSwitch } from "../extended-components.js";
import { KInput } from "../forms/input.js";
import { KSelect } from "../forms/selection.js";
import { useKLocalization } from "../localization/provider.js";
import type { KMapZoneTravelCost } from "../maps/map-zone-geometry.js";
import { mapZoneForeground, mapZonePalette } from "../maps/map-zone-colors.js";
import { KButton } from "../primitives/button.js";
import { KAnimatedIcon } from "../primitives/animated-icon.js";
import { KIcon } from "../primitives/icon.js";
import {
  defaultZoneWorkingHoursLabels,
  ZoneWorkingHoursFields,
} from "./map-zone-editor-working-hours.js";
import { ZoneAvailabilityFields } from "./map-zone-editor-availability.js";
import type { KMapZoneEditorLabels } from "./map-zone-editor-labels.js";
import type {
  ZoneEditorPropertyController,
  ZoneSettingsValidationCode,
} from "./map-zone-editor-properties-state.js";
import type { KMapZonePropertyOptions } from "./map-zone-editor-types.js";

export function formatMapZoneTravelCost(
  cost: KMapZoneTravelCost,
  freeLabel: string,
  locale: Intl.LocalesArgument,
): string {
  if (cost.kind === "free") return freeLabel;
  const amount = new Intl.NumberFormat(locale, {
    style: "currency",
    currency: cost.currency,
  }).format(cost.amount);
  return `${amount}${cost.kind === "per-kilometer" ? "/km" : ""}`;
}

export function ZoneEditorPropertiesFields({
  controller,
  labels,
  propertyOptions,
}: {
  controller: ZoneEditorPropertyController;
  labels: KMapZoneEditorLabels;
  propertyOptions?: KMapZonePropertyOptions;
}) {
  const [colorsOpen, setColorsOpen] = useState(false);
  const { calendarLocale } = useKLocalization();
  const values = controller.values;
  const nameInput = useRef<HTMLInputElement>(null);
  const nameId = useId();
  if (!values) return null;
  const validationLabels: Record<ZoneSettingsValidationCode, string> = {
    "working-hours":
      propertyOptions?.workingHoursLabels?.invalid ??
      defaultZoneWorkingHoursLabels.invalid,
    "travel-cost": labels.invalidTravelCost,
    surcharge: labels.invalidSurcharge,
    weekdays: labels.chooseWeekday,
    recurrence: labels.invalidRecurrence,
    "start-weekday": labels.startWeekdayMismatch,
    "date-range": labels.invalidDateRange,
  };
  const options = propertyOptions;
  const travelCost = controller.travelCost;
  const money = (kind: "per-kilometer" | "flat-rate") =>
    new Intl.NumberFormat(options?.locale ?? calendarLocale, {
      style: "currency",
      currency: options?.currency ?? "EUR",
    }).format(Number(values.travelAmounts[kind]) || 0);
  const formatTravelCost = (cost: KMapZoneTravelCost) =>
    formatMapZoneTravelCost(
      cost,
      labels.freeTravelCost,
      options?.locale ?? calendarLocale,
    );
  const travelCostSources =
    options?.travelCostSources?.filter(
      (source) => source.id !== controller.zone?.id,
    ) ?? [];
  const paletteSelection = mapZonePalette.find(
    (color) => color.light === values.color.toLowerCase(),
  );
  const colors = paletteSelection
    ? [...mapZonePalette]
    : [
        {
          name: "custom",
          label: "Bisherige Farbe",
          light: values.color,
          dark: values.color,
        },
        ...mapZonePalette,
      ];
  return (
    <div className="k-map-zone-editor__properties-fields">
      <div className="k-map-zone-editor__properties-basics">
        <label className="k-map-zone-editor__identity-label" htmlFor={nameId}>
          {labels.zoneName}
        </label>
        <fieldset
          className="k-map-zone-editor__color-field"
          onKeyDown={(event) => {
            if (event.key === "Escape" && colorsOpen) {
              event.preventDefault();
              event.stopPropagation();
              setColorsOpen(false);
              event.currentTarget
                .querySelector<HTMLButtonElement>("button")
                ?.focus();
            }
          }}
        >
          <legend>{labels.zoneColor}</legend>
          <div
            className="k-map-zone-editor__identity-group"
            role="group"
            aria-label={labels.zoneName}
          >
            <KButton
              variant="ghost"
              className="k-map-zone-editor__color-summary"
              aria-label={labels.zoneColor}
              title={paletteSelection?.label ?? labels.zoneColor}
              aria-expanded={colorsOpen}
              onClick={() => setColorsOpen(!colorsOpen)}
            >
              <span
                className="k-map-zone-editor__color-preview"
                style={{
                  background: `light-dark(${paletteSelection?.light ?? values.color}, ${paletteSelection?.dark ?? values.color})`,
                }}
              />
              <KAnimatedIcon
                name={colorsOpen ? "chevron-up" : "chevron-down"}
              />
            </KButton>
            <KInput
              id={nameId}
              ref={nameInput}
              value={values.name}
              onChange={(event) => controller.setName(event.target.value)}
            />
          </div>
          <div
            className="k-map-zone-editor__color-disclosure"
            data-open={colorsOpen || undefined}
            inert={!colorsOpen}
            aria-hidden={!colorsOpen}
          >
            <div
              className="k-map-zone-editor__color-options"
              role="radiogroup"
              aria-label={labels.zoneColor}
            >
              {colors.map((color, index) => {
                const checked = values.color.toLowerCase() === color.light;
                return (
                  <button
                    key={color.name}
                    type="button"
                    role="radio"
                    aria-checked={checked}
                    aria-label={color.label}
                    title={color.label}
                    tabIndex={checked ? 0 : -1}
                    onClick={() => controller.setColor(color.light)}
                    onKeyDown={(event) => {
                      const direction = ["ArrowRight", "ArrowDown"].includes(
                        event.key,
                      )
                        ? 1
                        : ["ArrowLeft", "ArrowUp"].includes(event.key)
                          ? -1
                          : 0;
                      if (
                        !direction &&
                        event.key !== "Home" &&
                        event.key !== "End"
                      )
                        return;
                      event.preventDefault();
                      const next =
                        event.key === "Home"
                          ? 0
                          : event.key === "End"
                            ? colors.length - 1
                            : (index + direction + colors.length) %
                              colors.length;
                      const option = colors[next];
                      if (!option) return;
                      controller.setColor(option.light);
                      (
                        event.currentTarget.parentElement?.children[next] as
                          HTMLElement | undefined
                      )?.focus();
                    }}
                  >
                    <span
                      style={{
                        background: `light-dark(${color.light}, ${color.dark})`,
                        color: mapZoneForeground(color.light),
                      }}
                    >
                      {checked ? <KIcon name="check" /> : null}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>
        </fieldset>
      </div>
      {options ? (
        <KSwitch
          label={labels.requestRequired}
          checked={values.settings.requestRequired ?? false}
          onCheckedChange={(requestRequired) =>
            controller.updateSettings({ requestRequired })
          }
        />
      ) : null}
      {options ? (
        <div className="k-map-zone-editor__properties-section">
          <label className="k-map-zone-editor__field">
            <span>{labels.travelCost}</span>
            <KSelect
              options={[
                {
                  value: "per-kilometer",
                  label: `${labels.perKilometerTravelCost} · ${money("per-kilometer")}/km`,
                  leading: <KIcon name="car-front" strokeWidth={1.5} />,
                },
                {
                  value: "flat-rate",
                  label: `${labels.flatRateTravelCost} · ${money("flat-rate")}`,
                  leading: <KIcon name="banknote" strokeWidth={1.5} />,
                },
                {
                  value: "free",
                  label: labels.freeTravelCost,
                  leading: <KIcon name="gift" strokeWidth={1.5} />,
                },
              ]}
              value={travelCost.kind}
              onValueChange={(value) =>
                controller.setTravelKind(value as KMapZoneTravelCost["kind"])
              }
              label={labels.travelCost}
            />
          </label>
          {travelCost.kind !== "free" ? (
            <label className="k-map-zone-editor__field">
              <span>
                {labels.travelCostAmount} ({options.currency})
              </span>
              <KInput
                type="number"
                min="0"
                step="0.01"
                value={values.travelAmounts[travelCost.kind]}
                onChange={(event) => {
                  const raw = event.target.value;
                  controller.setTravelAmount(
                    travelCost.kind,
                    raw === "" ? "" : Number(raw),
                  );
                }}
              />
            </label>
          ) : null}
          {travelCostSources.length ? (
            <label className="k-map-zone-editor__field">
              <span>{labels.copyTravelCost}</span>
              <KSelect
                value=""
                placeholder={labels.chooseTravelCostSource}
                label={labels.copyTravelCost}
                options={travelCostSources.map((source) => ({
                  value: source.id,
                  label: `${source.label} · ${formatTravelCost(source.travelCost)}`,
                  leading: (
                    <KIcon
                      name={
                        source.travelCost.kind === "per-kilometer"
                          ? "car-front"
                          : source.travelCost.kind === "flat-rate"
                            ? "banknote"
                            : "gift"
                      }
                      strokeWidth={1.5}
                    />
                  ),
                }))}
                onValueChange={(id) => {
                  const source = travelCostSources.find(
                    (candidate) => candidate.id === id,
                  );
                  if (source) controller.copyTravelCost(source.travelCost);
                }}
              />
            </label>
          ) : null}
        </div>
      ) : null}
      {options ? (
        <div className="k-map-zone-editor__properties-section">
          <label className="k-map-zone-editor__field">
            <span>
              {labels.surcharge} ({options.currency})
            </span>
            <KInput
              type="number"
              min="0"
              step="0.01"
              value={values.settings.surcharge?.amount ?? 0}
              onChange={(event) => {
                const amount = Number(event.target.value);
                controller.setSurchargeEnabled(amount !== 0);
                controller.updateSettings({
                  surcharge: { amount, currency: options.currency },
                });
              }}
            />
          </label>
        </div>
      ) : null}
      {options ? (
        <ZoneWorkingHoursFields
          availability={values.settings.availability}
          hours={values.settings.workingHours}
          options={options}
          zoneId={controller.zone?.id}
          onChange={(workingHours) =>
            controller.updateSettings({ workingHours })
          }
        />
      ) : null}
      {options ? (
        <ZoneAvailabilityFields
          workingHours={values.settings.workingHours}
          availability={values.settings.availability}
          labels={labels}
          options={options}
          onChange={(availability) =>
            controller.updateSettings({ availability })
          }
        />
      ) : null}

      {controller.normalized.error ? (
        <p className="k-map-zone-editor__error" role="alert">
          {validationLabels[controller.normalized.error]}
        </p>
      ) : null}
    </div>
  );
}

export function ZoneEditorPropertiesActions({
  controller,
  labels,
  onDelete,
  onCancel,
}: {
  controller: ZoneEditorPropertyController;
  labels: KMapZoneEditorLabels;
  onDelete: () => void;
  onCancel: () => void;
}) {
  return (
    <div className="k-map-zone-editor__properties-actions">
      <KButton
        className="k-map-zone-editor__properties-delete"
        variant="ghost"
        onClick={onDelete}
      >
        <KIcon name="trash" />
        {labels.deleteZone}
      </KButton>

      <KButton variant="secondary" onClick={onCancel}>
        {labels.cancel}
      </KButton>
      {controller.dirty && (
        <KButton
          disabled={!controller.canApply}
          onClick={() => {
            if (controller.apply()) controller.setOpen(false);
          }}
        >
          {labels.done}
        </KButton>
      )}
    </div>
  );
}
