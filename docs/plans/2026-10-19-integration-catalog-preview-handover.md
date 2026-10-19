# Integration catalog preview handover

## Approved scope

Storybook and reusable Web pattern only. The user will review before Flutter
integration or application persistence. No commit, push or deployment requested.
Existing branch: `codex/integration-marketplace-preview`, based on
`a1c802ac7765e49b50cac3c64a659cd41d238f42` (equal to origin/main when fetched).

## Changes

- Removed the Account Selection story, fixture, unused pattern and styles.
  The marketplace now simulates OAuth returning from the service directly.
- Admin catalog exposes consumer callbacks for adding and editing entries.
- Added KIntegrationEditor using existing KDialog, KField, KInput, KTextarea,
  KSelect and KButton. Desktop dialog becomes a mobile Web bottom sheet.
- Fields: name, description, category, local icon preview, HTTPS MCP endpoint,
  authentication method, optional OAuth client ID and scopes. No secrets.
- Story state supports create/edit, failed/successful test simulation and
  publication. Saving always resets the entry to draft. Only tested entries
  can be published. Reload intentionally clears all preview changes.
- Upload accepts PNG/JPEG/WebP up to 2 MB, aborts reads on unmount, and disables
  save while reading. HTTPS validation rejects credentials and URL fragments.

## Evidence

Browser checks: required fields, HTTP rejection, create, edit, test failure,
test success, publish gating, local icon upload/preview, OAuth simulation
without account selection, mobile Web sheet at 390 x 844, cancel.
Web build/typechecks and focused formatting passed. Full `pnpm verify` was
started; see `.local-integration-verify.log` for the final result.
No Flutter source or host application was changed.

## Next action

Human visual review in Patterns / Integrations / Admin Catalog. After acceptance,
implement real administration persistence and tests in Assist Web; Flutter comes
only after the user authorizes that next step. Simulation is not live MCP/OAuth.
