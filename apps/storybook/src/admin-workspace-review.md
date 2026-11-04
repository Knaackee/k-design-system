# Admin workspace — Storybook review

Reference: `C:/Users/dknaa/Downloads/onzeit-admin.html`.

## Delivered

Gallery-only composition using public K controls: adaptive dialog, avatar, badges, buttons, fields, inputs, search, select, switch, textarea, charts and stack. No production backend or app integration. Twelve sections plus mobile navigation; responsive light/dark layouts, local search/status filters, period selection, mock detail dialogs and actions.

Stories at `http://localhost:6006/?path=/story/review-adminworkspace--` followed by:
`overview`, `navigation`, `customers`, `access`, `growth`, `subscriptions`, `waitlist`, `invitations`, `applications`, `partners`, `operations`, `assistant`, `audit`.

All actions are explicitly demonstrated with synthetic data; email addresses use example.invalid. No real emails, payments, permission changes, account blocking or service retries occur. API-key input is not persisted and clears when the dialog closes.

## Integration findings / contracts to confirm

- Existing invitation lifetime is 14 days; the HTML's 7-day promise must not override that contract. The gallery does not advertise a fixed lifetime.
- Ambassador referral links do not currently prove entitlement to registration. They are shown as example links, not a registration bypass.
- Full admin roles/permission enforcement, MFA and owner protections need backend authorization contracts; owner is immutable in the gallery.
- Customer lock/unlock and password-link actions must use existing authentication/mail-worker paths and audit outcomes.
- Analytics require explicit definitions for active businesses, comparison periods, conversion denominators, attribution/source/campaign, country/language/platform and privacy-safe collection. Values here are fixtures.
- Subscription/payment retry and invoices need actual payment-provider contracts and duplicate-request protection.
- Service retry must only expose known retryable jobs, with permissions and an audit trail. Reference-specific Postmark was replaced by neutral SMTP.
- AI provider/model/fallback/key settings must reflect supported runtime configurations. Speculative model names from the HTML were replaced with explicit demo model names.
- Public K charts replace the hand-drawn HTML SVGs; chart rendering is therefore not an identical SVG. This preserves the shared components and accessibility.
- Production brand logo and real profile images should be supplied by the host application; the gallery uses an icon/wordmark and initial avatars.

## Verification

- Storybook TypeScript check: passed.
- Production Storybook build: passed.
- Desktop/mobile overview visually inspected; removed inherited gallery padding, corrected responsive tabs, chart colors and row line-height.
- All 13 stories at 390/1440 widths in light/dark passed scripted browser verification: no JavaScript errors and no document/main horizontal overflow (52 combinations). Customer search empty state and detail dialog also passed.
- Widgetbook endpoint is available; no Flutter/Widgetbook implementation is claimed in this Storybook-first review phase.

No commit or publication performed by this worker. Human visual acceptance remains outstanding.

- Additional interaction checks passed: period selection, attention navigation, customer lock dialog, inline waitlist approval, registration switch.

### Polishing pass, 4 November 2026

- Rechecked the original HTML detail-sheet markup and row/action metrics. The main detail defect was lost review-theme inheritance across the dialog portal; the portal now explicitly receives the same tokens as the page.
- Application, partner, customer, invitation and waitlist details use full-width grouped key/value cards, 46px minimum rows, readable normal-weight values, compact 22px headings and a separate motivation card. Desktop dialog width is 520px; mobile remains the public adaptive sheet. Inter remains the deliberate project-standard difference from the reference's Geist.
- Public `headerless`, `showClose=false`, `bodyClassName` and KIconButton compose the reference header without targeting private overlay styles. Removing the hidden default close control prevents its clipped-icon popover appearing as a dark blob over the title.
- The primary row button now covers the complete row including padding and decorative status badges. Inline copy/approve/reject buttons remain separate higher-layer controls; no nested buttons or competing row click handlers were introduced.
- Referral links, email addresses and social handles are one line with ellipsis. The full string remains in accessible content/title and clipboard actions. Narrative motivation remains multiline.
- Repeated the 52-case page sweep (13 stories, 390/1440 widths, light/dark): no page errors or horizontal overflow. Search-empty recovery and customer dialog opening passed. Root separately checks right-edge hit areas, keyboard/Escape/focus return and short 320px screens.
- Existing all-in-one story file length is a documented structural debt, not a new abstraction. This pass preserves the existing state/render architecture while the host and Flutter compositions are integrated; no arbitrary file partitions were introduced.

Human visual acceptance remains outstanding. Gallery callbacks still only mutate synthetic in-memory fixtures; they must not be mistaken for backend functionality.

### KPI alignment follow-up

- Measured all KPI scenes (overview, growth, subscriptions, partnerships) at 320, 390, 768 and 1440px. Adjacent card heights were already equal, but wrapped labels shifted values by 24px at 320/390px. Shared three-row CSS subgrid tracks now align labels, values and comparison rows without truncating labels or imposing fixed card heights. Re-measurement confirms equal value baselines and no card overflow in all sixteen combinations.
- The production host has a separate metric-card composition; this gallery adjustment still needs deliberate transfer after review. No host application or navigation changed in this follow-up.
