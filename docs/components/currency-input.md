# Currency Input

KCurrencyInput belongs to Forms and composes KInput on both platforms. It accepts
nullable signed integer minor units, currency, locale and fractionDigits
(default 2, supported 0 through 6). Values stay within the Web safe-integer range
on both platforms. Examples: EUR 123456 at two digits means 1,234.56 euros;
JPY 1234 at zero digits means 1,234 yen. Consumers explicitly select precision.

onCommit returns validated minor units on Enter or blur. onInvalidDraft reports
an incomplete/invalid draft; it is not a persisted value. Empty input commits null.
Escape restores the supplied value. Text parsing uses exact string/integer
operations and rejects excess decimals, malformed grouping and overflow without
rounding. Locale affects separators/digits, not stored values. Changing the
currency does not convert the amount or perform exchange-rate arithmetic.

The focused draft omits the currency marker; the resting input displays a
localized currency amount. Disabled/read-only, labels, inherited field validation
and optional clearing follow the existing Forms conventions. Application code owns
validation messages and persistence. Helpers formatCurrencyMinorUnits and
parseCurrencyMinorUnits are exported for compact cell display and consumer logic.

The currency-input-states gallery matches across platforms: EUR amount/zero,
negative USD, zero-decimal JPY, three-decimal KWD, read-only and disabled fields.
The data-table-cells fixture demonstrates a plain amount until activated.
Both platforms use the same explicit currency-symbol policy: EUR uses €;
USD and JPY use matching locale-specific symbols; KWD uses its Arabic symbol in
Arabic and the ISO code elsewhere. Other currencies use their ISO code. Locale
still controls placement, separators and spacing. This intentionally bounded
policy avoids differences between browser Intl and Dart intl symbol catalogs.
