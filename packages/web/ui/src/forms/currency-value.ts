export interface KCurrencyFormat {
  currency: string;
  locale: string;
  fractionDigits?: number;
}
export type KCurrencyParseResult =
  { valid: true; value: number | null } | { valid: false };
const spaces = (text: string) => text.replace(/[\u00a0\u202f]/g, " ");
// Shared currency-symbol policy; other currencies intentionally use their ISO code.
function currencySymbol(currency: string, locale: string): string {
  const language = locale.replaceAll("_", "-").split("-")[0];
  switch (currency.toUpperCase()) {
    case "EUR":
      return "€";
    case "USD":
      return language === "fr" ? "$US" : language === "ar" ? "US$" : "$";
    case "JPY":
      return language === "ja"
        ? "￥"
        : language === "fr"
          ? "JPY"
          : ["ar", "hi"].includes(language!)
            ? "JP¥"
            : "¥";
    case "KWD":
      return language === "ar" ? "د.ك.\u200f" : "KWD";
    default:
      return currency.toUpperCase();
  }
}
function context({ currency, locale, fractionDigits = 2 }: KCurrencyFormat) {
  if (
    !Number.isInteger(fractionDigits) ||
    fractionDigits < 0 ||
    fractionDigits > 6
  )
    throw new RangeError("fractionDigits must be an integer from 0 to 6");
  const number = new Intl.NumberFormat(locale);
  const parts = number.formatToParts(-12345.6);
  const decimal = parts.find((p) => p.type === "decimal")?.value ?? ".";
  const group = parts.find((p) => p.type === "group")?.value ?? ",";
  const minus = parts.find((p) => p.type === "minusSign")?.value ?? "-";
  const digits = Array.from({ length: 10 }, (_, n) =>
    new Intl.NumberFormat(locale, { useGrouping: false }).format(n),
  );
  const money = new Intl.NumberFormat(locale, {
    style: "currency",
    currencyDisplay: "code",
    currency,
    minimumFractionDigits: fractionDigits,
    maximumFractionDigits: fractionDigits,
  });
  return {
    number,
    money,
    decimal,
    group,
    minus,
    digits,
    fractionDigits,
    symbol: currencySymbol(currency, locale),
  };
}
export function formatCurrencyMinorUnits(
  value: number | null,
  options: KCurrencyFormat,
  currencyDisplay = true,
): string {
  const c = context(options);
  if (value === null) return "";
  if (!Number.isSafeInteger(value))
    throw new RangeError("Expected safe integer minor units");
  const amount = BigInt(value);
  const magnitude = amount < 0n ? -amount : amount;
  const divisor = 10n ** BigInt(c.fractionDigits);
  const integer = c.number.format(magnitude / divisor);
  const fraction = (magnitude % divisor)
    .toString()
    .padStart(c.fractionDigits, "0")
    .replace(/\d/g, (digit) => c.digits[Number(digit)]!);
  const numeric = integer + (c.fractionDigits ? c.decimal + fraction : "");
  if (!currencyDisplay) return (amount < 0n ? c.minus : "") + numeric;
  let inserted = false;
  return c.money
    .formatToParts(amount < 0n ? -1n : 1n)
    .map((part, index, parts) => {
      if (part.type === "currency") return c.symbol;
      if (
        part.type === "literal" &&
        /^\s+$/.test(part.value) &&
        parts[index - 1]?.type === "currency" &&
        !/[A-Za-z]$/.test(c.symbol)
      )
        return "";
      if (["integer", "group", "decimal", "fraction"].includes(part.type)) {
        if (inserted) return "";
        inserted = true;
        return numeric;
      }
      return part.value;
    })
    .join("");
}
export function parseCurrencyMinorUnits(
  text: string,
  options: KCurrencyFormat,
): KCurrencyParseResult {
  const c = context(options);
  let input = spaces(text.replace(/[\u061c\u200e\u200f]/g, "")).trim();
  if (!input) return { valid: true, value: null };
  input = input.replace(c.minus, "-");
  const negative = input.startsWith("-");
  if (negative || input.startsWith("+")) input = input.slice(1);
  const symbols = [
    options.currency.toUpperCase(),
    c.symbol.replace(/[\u061c\u200e\u200f]/g, ""),
  ];
  for (const symbol of symbols) {
    if (input.startsWith(symbol)) input = input.slice(symbol.length).trim();
    else if (input.endsWith(symbol))
      input = input.slice(0, -symbol.length).trim();
  }
  c.digits.forEach((digit, index) => {
    input = input.split(digit).join(String(index));
  });
  const pieces = input.split(c.decimal);
  if (pieces.length > 2) return { valid: false };
  const rawInteger = pieces[0]!;
  const integer = rawInteger.split(spaces(c.group)).join("");
  const fraction = pieces[1];
  if (
    !/^\d+$/.test(integer) ||
    (fraction !== undefined &&
      (!/^\d+$/.test(fraction) || fraction.length > c.fractionDigits))
  )
    return { valid: false };
  if (rawInteger !== integer) {
    let expected = spaces(c.number.format(BigInt(integer)));
    c.digits.forEach((digit, index) => {
      expected = expected.split(digit).join(String(index));
    });
    if (rawInteger !== expected) return { valid: false };
  }
  const amount =
    BigInt(integer) * 10n ** BigInt(c.fractionDigits) +
    BigInt((fraction ?? "").padEnd(c.fractionDigits, "0") || "0");
  if (amount > BigInt(Number.MAX_SAFE_INTEGER)) return { valid: false };
  return { valid: true, value: Number(negative ? -amount : amount) };
}
