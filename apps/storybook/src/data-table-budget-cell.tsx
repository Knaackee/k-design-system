import { useState } from "react";
import {
  KCurrencyInput,
  KEditableCell,
  formatCurrencyMinorUnits,
} from "@k-design-system/ui";

export function BudgetCell({
  id,
  value,
  disabled,
  onCommit,
}: {
  id: string;
  value: number;
  disabled?: boolean;
  onCommit: (value: number) => void;
}) {
  const [editing, setEditing] = useState(false);
  const label = `Edit budget for ${id}`;
  return (
    <KEditableCell
      label={label}
      editing={editing}
      paddingInline={4}
      onEdit={disabled ? undefined : () => setEditing(true)}
      display={formatCurrencyMinorUnits(value, {
        currency: "EUR",
        locale: "de-DE",
        fractionDigits: 0,
      })}
      editor={
        <KCurrencyInput
          aria-label={label}
          value={value}
          currency="EUR"
          locale="de-DE"
          fractionDigits={0}
          disabled={disabled}
          autoFocus
          onCommit={(next) => {
            if (next !== null) onCommit(next);
          }}
          onBlur={() => setEditing(false)}
          onKeyDown={(event) => {
            if (event.key === "Escape" || event.key === "Enter")
              setEditing(false);
          }}
        />
      }
    />
  );
}
