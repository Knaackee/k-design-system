# Localization

Rapid scope accepted on 2026-09-16: central localization for existing components,
shared language packs, external overrides and matching gallery language controls.
Language, calendar conventions, date/time formats and time zone are independent.

## Configuration

React applications wrap their component tree in `KLocalizationProvider`.
Flutter applications use `KLocalization`; it integrates with the ambient Flutter
`Localizations` locale when no language is explicitly configured. React defaults
to English for deterministic server/client output. Configure the same explicit
locale on both platforms when comparing them.

```tsx
<KLocalizationProvider
  locale="de"
  calendarLocale="de"
  dateFormat="iso"
  timeFormat="h24"
  timeZone="Europe/Berlin"
  messages={{ apply: "Termin bestätigen" }}
>
  <KDateTimePicker value={value} onValueChange={setValue} />
</KLocalizationProvider>
```

```dart
KLocalization(
  locale: 'de',
  calendarLocale: 'de',
  dateFormat: KDateFormat.iso,
  timeFormat: KTimeFormat.h24,
  timeZone: 'Europe/Berlin',
  messages: const {'apply': 'Termin bestätigen'},
  child: KDateTimePicker(value: value, onChanged: setValue),
)
```

Nested providers inherit unspecified settings. Text precedence is component
label override, provider message override, selected language pack, then English.
Existing picker `labels`, input/select `clearLabel`, select `placeholder`, filter
`resetLabel`, and explicit picker language/format/zone parameters remain supported.
Select/Combobox also expose `optionsLabel` and `noResultsLabel`; FilterChip exposes
`removeLabel`. Consumer content such as field labels, option data and menu actions
is never translated automatically.

`locale` selects UI messages. `calendarLocale` selects month/weekday names and
first day of week; absent an explicit setting, it follows `locale`. An explicit
component picker locale selects that component's messages and calendar together.
Changing language alone does not change canonical values, time zone or formats.
Defaults remain ISO date, 24-hour time and UTC. Formatting remains the existing
explicit `iso`, `dayMonthYear`, `monthDayYear`, `h24` and `h12` contract; locale does
not silently infer one of these formats. Seconds, alternate calendars and localized
numeral systems are not added by this slice. AM/PM remain the existing time-format
markers.

## Language packs

Initial packs: English (`en`), German (`de`), French (`fr`), Spanish (`es`), Italian
(`it`), Portuguese (`pt`, European Portuguese), Dutch (`nl`), Polish (`pl`), Czech
(`cs`), Swedish (`sv`), Danish (`da`), Norwegian Bokmal (`nb`), Finnish (`fi`) and
Turkish (`tr`). These are initial translations, not a claim of professional
linguistic review in every language.

Lookup is case-insensitive: exact tag, base language, English. Underscores are
normalized to hyphens. Thus `de-CH` uses `de` unless a custom exact-tag pack exists.
A base-language fallback does not promise regional calendar conventions: supply
an exact regional pack or choose calendar settings explicitly when these matter.

`locales/*.json` is the shared source for messages, twelve month names, seven
weekday names (Sunday first), and `firstDay` (0=Sunday through 6=Saturday).
`pnpm generate` projects these files into both UI packages. `pnpm generate:check`
checks completeness, placeholders and generated-file drift. Do not edit generated
files. Calendar names were initially captured from Node Intl/ICU; the committed
snapshot makes both rendering platforms use the same data.

Applications can supply extra packs through the provider's `locales` map and
select them with a locale string. A pack contains `name`, `messages`, `months`,
`weekdays`, and `firstDay`. Use a complete calendar and inherit a built-in pack for
partial customization. The `remove` message must contain `{label}` exactly once.
React exports `kLocaleCatalog`, `kSupportedLocales`, and the typed `KLocaleData`
contract. Flutter exports `KLocalizationData` for resolving inherited settings.

Right-to-left layout, non-Latin typography and device screen-reader validation
remain separate verification work. Registering a custom pack does not certify
those behaviors. No app-wide translation service, remote loading, or pluralization
engine is imposed; applications retain their own localization solution.

## Galleries and checks

Storybook's global `language` control and Widgetbook's Language addon apply to
all component fixtures. Picker-specific language controls default to inheritance.
Gallery navigation, demo headings and example data remain consumer content.

- Storybook URL: `globals=language:de`.
- Widgetbook URL: `language={locale:de}`.
- `node --test tooling/localization.test.mjs` validates all packs, fallbacks,
  independent configuration and custom packs.
- `node apps/storybook/src/localization.test.mjs` checks provider/form overrides
  and actual Web picker interactions in every initial language.
- Native localization and gallery tests cover inheritance and overrides.
- Repository completion requires `pnpm verify` and paired browser checks.

Behavior follows the global/local override approach documented by
[MUI](https://mui.com/x/react-date-pickers/localization/) and the ambient locale
model described by [Flutter](https://docs.flutter.dev/ui/internationalization).

Verified on 2026-09-16:

- `pnpm verify` passed (`.localization-verify.log`): 21 tooling tests, 10 token
  tests, 178 Flutter UI tests, 23 Widgetbook tests, static analysis, generated
  drift checks, formatting and both gallery production builds.
- `localization.test.mjs` passed provider/form overrides and Web interactions
  in all 14 languages; existing `pickers.test.mjs` also passed.
- `localization-parity.test.mjs` passed 42 Web/Flutter Web combinations:
  all 14 languages at 375, 700 and 1024 logical pixels, Standard density,
  100% text, pointer mode, Orbit Dark. Month/year controls and action buttons
  agree within 0.5 logical pixels. Canonical date-time values remain unchanged.
- Native regressions verify that changing language in an open picker updates
  labels/calendar while preserving its draft, including removal of overrides.
- Approved density Plan and ADR hashes remain unchanged. No commit was created.

Change date/time formatting and time zone while a picker is closed; an open
Flutter picker preserves the model configuration with which editing began.
Language/message updates are supported during editing. Browser automation does
not replace physical-device, screen-reader or linguistic acceptance. Human
visual and native-language review remain open; RTL is not certified by this slice.
