# Date, time and date-time pickers

Rapid scope accepted on 2026-09-16: `KDatePicker`, `KTimePicker` and
`KDateTimePicker` on React/Web and Flutter, with configurable time zone and
formats. This follows backup commit `d21153e`. No further commit is authorized.

## Contract

| Parameter                    | Shared behavior                                                                                        |
| ---------------------------- | ------------------------------------------------------------------------------------------------------ |
| `value`                      | Controlled nullable canonical string; callbacks use `onValueChange` on Web and `onChanged` on Flutter. |
| `timeZone`                   | IANA identifier, default `UTC`; examples include `Europe/Berlin` and `America/New_York`.               |
| `dateFormat`                 | `iso` (`YYYY-MM-DD`), `dayMonthYear` (`DD.MM.YYYY`), or `monthDayYear` (`MM/DD/YYYY`).                 |
| `timeFormat`                 | `h24` (`HH:mm`) or `h12` (`hh:mm AM/PM`).                                                              |
| `locale`                     | `en` or `de` in this first slice; changes calendar labels and week start, independently of format.     |
| `labels`                     | Consumer overrides for dialog, action, field and validation text.                                      |
| `min`, `max`                 | Inclusive boundaries in the component's canonical value format.                                        |
| `disambiguation`             | `reject` (default), `earlier`, or `later` for duplicated local date-times.                             |
| `clearable`                  | Optional dialog Clear action, default false. Manual empty input can emit null.                         |
| `readOnly`, disabled/enabled | Prevent changes and opening the dialog.                                                                |
| `now`                        | Optional reference instant for deterministic empty-calendar initialization.                            |

DatePicker values are calendar dates (`2026-09-16`), independent of UTC offsets.
TimePicker values are wall-clock times (`14:30`); without a date they are not
converted to instants. Their time zone provides context and determines the
current local reference date/time.

DateTimePicker values are UTC ISO strings with minute precision. It accepts
`2026-09-16T12:30:00Z` and `2026-09-16T12:30:00.000Z`; callbacks use the latter
canonical form. Seconds and fractional milliseconds must be zero in this slice.
Display and edits use `timeZone`; changing that parameter preserves the instant.
Date and time formats affect presentation and parsing, not the stored value.

Dates are parsed strictly: invalid dates never normalize into another month.
Spring-forward gaps are rejected under every disambiguation policy. Fall-back
overlaps require an explicit earlier/later policy or remain a validation error.
Web uses the runtime's Intl zone data; Flutter bundles the Dart timezone package.
Time-zone database versions can differ, especially for newly changed political
rules; keep runtime and package data current when such dates matter.

The accepted selection-first extension adds `allowTextInput` (default false)
and `minuteStep` (default 1). Minute steps must be positive integer divisors of
60 no greater than 30. They control the offered minute choices, not storage
precision: an existing off-step minute remains as an extra sorted choice and
optional manual input may still enter any valid minute. Values are never silently
rounded. Labels also cover hours, minutes, AM/PM period, month/year navigation.

The configured time-zone identifier is not rendered beneath picker fields or
inside picker dialogs. It remains available through component/provider parameters
and gallery configuration controls; conversion, validation and canonical values
continue to use it.

## Interaction and parity

The default field is read-only text with a calendar/clock opener. Clicking the
field or opener, or pressing Enter/Space on the focused field, opens the picker.
`allowTextInput: true` enables direct typing instead: clicking the field edits it,
while the icon opens the picker with additional formatted draft fields. Enter or
blur commits valid manual input; invalid drafts retain the application value.

DatePicker opens a Gregorian calendar. Separate month and year buttons open
three-column, four-row selection grids. Month choices use abbreviated visible
names and full accessible names. Year pages contain twelve years, with previous
and next navigation. Choosing a month/year changes the displayed calendar;
choosing a day changes the draft. The day grid supports arrow keys, Home/End,
PageUp/PageDown and Shift+PageUp/PageDown. English weeks start Sunday, German
weeks Monday. Disabled dates remain unavailable.

TimePicker offers independently scrollable hours and minutes, plus AM/PM in
12-hour format. Each column shows five rows, centers its selected value when
possible and supports ArrowUp/Down, Home/End and direct selection. Scrollbars
are hidden consistently; columns retain touch and wheel scrolling. Row height
is the maximum of control size, hit-target size and scaled control font plus
16 pixels. DateTimePicker combines this time selector with the same calendar.

Apply commits the draft. Cancel, Escape and outside dismissal discard it.
Clear commits null. Closing returns focus to the stable opener. The existing
inline Clear focus issue in older form controls remains a separate issue.

Both platforms use available logical viewport width, not platform identity:
DateTimePicker uses a 720-pixel panel at widths of at least 736 pixels, with
equal calendar/time columns separated by 16 pixels. Below that threshold it
stacks the sections in a 400-pixel panel constrained to viewport minus 16 pixels.
DatePicker and TimePicker use the same 400-pixel constraint. Panels scroll when
height is insufficient. Touch target sizing follows the shared input-mode tokens.
Phone, tablet and desktop therefore use identical rules on Web and Flutter.

Matching fixtures remain `date-picker-states`, `time-picker-states` and
`date-time-picker-states`, under Forms/DatePicker, Forms/TimePicker and
Forms/DateTimePicker. Both galleries expose time zone, formats, locale, DST
policy, optional text input and minute steps. Density, color, font and target
sizes come from shared tokens. Month names may wrap at enlarged text sizes.

Date ranges, multiple dates, seconds, alternate calendars and an embedded zone
selector remain outside this slice. Applications supply their selected zone.

Interaction follow-up: time columns support mouse dragging as well as touch
swiping, wheel scrolling and keyboard navigation. Dragging or swiping scrolls
without committing a time; selecting a row changes the draft. In DateTimePicker,
opening month/year selection or navigating months hides the entire time section.
Choosing a month or year alone does not restore it: explicitly choosing a day
restores the time section with its previous time draft. A nonempty initial value
already has a selected day; an empty value waits for day selection. With optional
text entry, a valid date draft also enables time entry. On wide layouts the
calendar keeps its original width and the time column remains empty while hidden.

## Verification and acceptance

Allowed paths: both UI packages, gallery fixtures/registrations/tests, native
dependency manifest and lockfile, picker model tests in tooling, this document
and the component catalog. Approved Plan and ADR bodies remain unchanged.

Checks: strict format/leap-date tests; Europe/Berlin gap and overlap tests;
UTC conversion and boundaries; native widget tests; browser interaction and
focus tests; paired phone/tablet/desktop layouts at all densities and enlarged
text; final `pnpm verify`. Native device and screen-reader validation remain
separate from browser and widget-test evidence. Human visual acceptance is
still required.

Verified on 2026-09-16 after the final touch-layout corrections:

- `pnpm verify` passed: formatting, generated sources, tooling tests, Web build
  and types, Flutter analysis, 10 token tests, 152 UI tests, 20 Widgetbook tests,
  and both production gallery builds. The UI suite includes 17 picker tests.
- `pnpm exec tsc -p apps/storybook/tsconfig.json --noEmit` passed.
- `node apps/storybook/src/pickers.test.mjs` passed Web format, DST, keyboard,
  cancel, clearing and focus checks.
- `node apps/storybook/src/pickers-flutter.test.mjs` passed Apply, Cancel, Clear
  and keyboard focus-return checks for all three actual Flutter Web fixtures.
- `node apps/storybook/src/pickers-parity.test.mjs` passed 54 paired cases:
  three picker types, 375/700/1024-pixel viewports, all densities and 100/200%
  text, Orbit Dark and pointer input. Repeating with `KDS_PARITY_MOBILE=1`
  passed nine German touch cases at 375 pixels and 200% text across all densities.
  Input targets, opener targets, footer buttons and selected calendar cells agree
  within the 0.5-pixel threshold; screenshots were also inspected.

Browser checks use headless Microsoft Edge through Playwright. Set
`KDS_PLAYWRIGHT_MODULE` to an available Playwright module and `KDS_PARITY_OUTPUT`
to an evidence directory for the geometry test. Local run logs are
`.pickers-verify-final.log`, `.pickers-parity.log` and `.pickers-mobile-de.log`.

Text editing remains platform-native: selection highlight and touch selection
handles can differ between HTML inputs and Flutter text fields. This is an
intentional platform behavior, not a claim of identical editor rasterization.
Native-device and screen-reader testing and human visual acceptance remain open.
The pre-existing inline Clear focus issue in older form controls remains separate;
the picker footer restores focus to its stable opener in both browser tests.

Storybook on port 6006 and Widgetbook on port 6007 run as background services
without visible server windows. New picker changes are uncommitted; the prior
backup remains `d21153e`. Approved density Plan and ADR bodies were hash-checked
unchanged.

Selection-first extension verified on 2026-09-16 (supersedes the counts above):

- Final `pnpm verify` passed, including 17 tooling tests, 10 token tests,
  162 Flutter UI tests (27 picker tests), 20 Widgetbook tests, static checks,
  formatting and both production gallery builds.
- Web browser interaction checks passed month/year navigation and focus,
  hour/minute/AM-PM selection, minute-step behavior and preservation of existing
  off-step values. Flutter browser checks passed all three picker types with
  manual input both enabled and disabled, including Apply, Cancel, Clear and
  keyboard focus return.
- Geometry checks passed 75 paired configurations: 54 pointer cases across
  375/700/1024 logical pixels, all densities and 100/200% text; nine German
  touch cases at 375 pixels and 200% text; nine equivalent 12-hour cases; and
  three desktop cases with optional manual input and 12-hour time. The unchanged
  tolerance is 0.5 logical pixels. Desktop and enlarged mobile screenshots were
  also visually inspected. This measures layout parity, not identical font
  rasterization across rendering engines.
- A separate simulated-viewport check confirmed that a 375-pixel Widgetbook
  preview inside a 1024-pixel browser uses a centered 359-pixel stacked dialog.
  Flutter now uses the nearest Navigator so the dialog respects that viewport.
- Final logs: `.picker-selection-verify-final.log`,
  `.picker-selection-parity-final.log`, `.picker-selection-mobile-final.log`,
  `.picker-selection-h12-final.log` and `.picker-selection-manual-final.log`.
  Screenshot and geometry evidence folders are `picker-selection-final`,
  `picker-selection-mobile-final`, `picker-selection-h12-final` and
  `picker-selection-manual-final` in the session visualization directory.

Physical-device performance and screen-reader validation were not performed.
Human visual acceptance remains open; this extension has not been committed.

Follow-up verification on 2026-09-16: `pnpm verify` passed on the integrated
mouse-drag and day-confirmation changes (`.picker-gesture-verify.log`). The native
picker suite now has 32 passing tests, including mouse/touch drag without value
changes, hidden time during calendar browsing, empty values and manual dates.
Web browser tests also passed actual mouse dragging and CDP touch swiping without
accidental selection. `pickers-navigation-parity.test.mjs` passed month/year
selection geometry and day-gated time visibility at 375, 700 and 1024 logical
pixels within the unchanged 0.5-pixel tolerance. Browser assertions await Flutter's
asynchronous semantics update before inspecting hidden controls.

## References

- [WAI-ARIA date picker dialog](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/examples/datepicker-dialog/)
- [Carbon date/time picker usage](https://carbondesignsystem.com/components/date-picker/usage/)
- [Dart timezone](https://pub.dev/packages/timezone)
