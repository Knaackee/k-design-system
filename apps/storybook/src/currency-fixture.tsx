import { useState } from "react";
import {
  KContainer,
  KStack,
  KText,
  KField,
  KCurrencyInput,
} from "@k-design-system/ui";
const examples = [
  {
    label: "Amount",
    value: 123456,
    currency: "EUR",
    locale: "de-DE",
    digits: 2,
  },
  { label: "Zero", value: 0, currency: "EUR", locale: "de-DE", digits: 2 },
  {
    label: "Negative",
    value: -12345,
    currency: "USD",
    locale: "en-US",
    digits: 2,
  },
  { label: "Yen", value: 1234, currency: "JPY", locale: "ja-JP", digits: 0 },
  {
    label: "Dinar",
    value: 123456,
    currency: "KWD",
    locale: "en-US",
    digits: 3,
  },
  {
    label: "Read only",
    value: 123456,
    currency: "EUR",
    locale: "de-DE",
    digits: 2,
    readOnly: true,
  },
  {
    label: "Unavailable",
    value: 123456,
    currency: "EUR",
    locale: "de-DE",
    digits: 2,
    disabled: true,
  },
];
export function CurrencyFixture() {
  const [values, setValues] = useState<(number | null)[]>(
    examples.map((e) => e.value),
  );
  const [invalid, setInvalid] = useState<Record<number, boolean>>({});
  return (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="stretch" gap="section">
          <KText variant="heading4">Currency amounts</KText>
          {examples.map((example, index) => (
            <KField
              key={example.label}
              label={example.label}
              errorText={
                invalid[index]
                  ? "Enter a valid amount without extra decimal places."
                  : undefined
              }
            >
              <KCurrencyInput
                value={values[index] ?? null}
                currency={example.currency}
                locale={example.locale}
                fractionDigits={example.digits}
                readOnly={example.readOnly}
                disabled={example.disabled}
                clearable
                onInvalidDraft={() =>
                  setInvalid((previous) => ({ ...previous, [index]: true }))
                }
                onCommit={(value) => {
                  setValues((previous) =>
                    previous.map((old, i) => (i === index ? value : old)),
                  );
                  setInvalid((previous) => ({ ...previous, [index]: false }));
                }}
              />
            </KField>
          ))}
        </KStack>
      </KContainer>
    </div>
  );
}
