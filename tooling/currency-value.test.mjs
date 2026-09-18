import test from "node:test";
import assert from "node:assert/strict";
import {
  formatCurrencyMinorUnits as format,
  parseCurrencyMinorUnits as parse,
} from "../packages/web/ui/src/forms/currency-value.ts";
const de = { currency: "EUR", locale: "de-DE" };
const en = { currency: "USD", locale: "en-US" };
test("exact localized integer money including safe integer boundary", () => {
  for (const options of [
    de,
    en,
    { currency: "INR", locale: "hi-IN" },
    { currency: "EGP", locale: "ar-EG" },
  ]) {
    for (const fractionDigits of [0, 2, 3]) {
      for (const value of [
        null,
        0,
        -1,
        1,
        123456789,
        Number.MAX_SAFE_INTEGER,
        -Number.MAX_SAFE_INTEGER,
      ]) {
        const config = { ...options, fractionDigits };
        assert.deepEqual(parse(format(value, config), config), {
          valid: true,
          value,
        });
      }
    }
  }
});
test("paste accepts matching currency, grouping and nonbreaking spaces", () => {
  assert.deepEqual(parse("1.234,50 €", de), { valid: true, value: 123450 });
  assert.deepEqual(parse("$1,234.50", en), { valid: true, value: 123450 });
  assert.deepEqual(parse("1\u202f234,50 €", { ...de, locale: "fr-FR" }), {
    valid: true,
    value: 123450,
  });
});
test("incomplete or excessive drafts never silently round", () => {
  for (const value of [
    "-",
    "+",
    "1,",
    "1,001",
    "12.34,00",
    "NaN",
    "Infinity",
    "90071992547409,92",
    "€",
    "1e3",
  ]) {
    assert.equal(parse(value, de).valid, false, value);
  }
  assert.deepEqual(parse("", de), { valid: true, value: null });
  assert.deepEqual(parse("-0,00", de), { valid: true, value: 0 });
  assert.throws(() => format(Number.MAX_SAFE_INTEGER + 1, de));
});
test("shared currency symbols, spacing and ISO fallback Unicode goldens", () => {
  const examples = [
    [123456, "EUR", "de-DE", 2, "1.234,56\u00a0€"],
    [0, "EUR", "de-DE", 2, "0,00\u00a0€"],
    [-12345, "USD", "en-US", 2, "-$123.45"],
    [1234, "JPY", "ja-JP", 0, "￥1,234"],
    [123456, "KWD", "en-US", 3, "KWD\u00a0123.456"],
    [123456, "EUR", "de-DE", 2, "1.234,56\u00a0€"],
    [123456, "EUR", "de-DE", 2, "1.234,56\u00a0€"],
    [123456, "CHF", "en-US", 2, "CHF\u00a01,234.56"],
    [123456, "USD", "fr-FR", 2, "1\u202f234,56\u00a0$US"],
    [123456, "JPY", "hi-IN", 2, "JP¥1,234.56"],
  ];
  for (const [value, currency, locale, fractionDigits, expected] of examples) {
    const options = { currency, locale, fractionDigits };
    assert.equal(format(value, options), expected);
    assert.deepEqual(parse(expected, options), { valid: true, value });
  }
});
