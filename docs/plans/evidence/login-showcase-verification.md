# Login showcase verification

## Scope and authorization

On 28 September 2026 the user approved password masking and the presented
Login-Showcase plan, requested repair of the reported integrity conflicts, and
authorized eventual commit/merge/push to master when finished. The subsequent
instruction “repariere” authorized repairing the reported Storybook typecheck
issues. Human visual acceptance remains pending; no commit or push yet.

Implementation branch: `codex/login-showcase`, based on
`a58611ca7589ec1a07cc7f4d90ad9771cf29cc13`. Assetry host work is preserved.

## Integrity repair

The three reported conflicts were checkout byte changes, not changed decisions.
The original files in `D:/Development/k-design-system` match the recorded approval
SHA-256 values exactly. Their contents equal the submodule copies after CRLF-to-LF
normalization. They were restored byte-for-byte after checking both conditions.
The CLI has no exact-byte restoration operation; native file copying restored
the approved originals without modifying receipts or inventing approval.

`.gitattributes` now exempts these three immutable files from text conversion.
All other text uses LF on checkout. This also prevents fresh Windows checkouts
from failing Prettier, generated-output checks and the Lucide source digest.
Generators regenerated their own outputs; no generated source was hand-edited.
Git reports no semantic generator/icon changes. `skillset plan check` reports
zero errors and four pre-existing legacy/unindexed notices. No historical
approval was fabricated to silence these notices.

## Implementation and checks

- Flutter KInput adds optional `obscureText = false`; masked mode disables
  autocorrection and suggestions while retaining the controller value.
- Storybook and Widgetbook contain Showcase → Login → Assetry, with matching
  fixture identity `showcase-login-assetry`. Consumer branding is local to the
  gallery composition. Both use a text wordmark; no new shared visual tokens.
- Login and password recovery only demonstrate local feedback. No credential
  transmission, persistence or authentication implementation.
- Storybook uses ESNext/Bundler resolution like the existing Web consumer.
  Its typecheck is now included in `typecheck:web` and therefore `pnpm verify`.
  Context-menu fixture now uses the existing `control` gap instead of `content`.
- `flutter test test/input_password_test.dart`: one test passed.
- `flutter test --no-pub test/login_showcase_test.dart`: two tests passed,
  including validation and recovery feedback at 375 and 1024 logical pixels.
- `pnpm --filter @k-design-system/storybook typecheck`: passed.
- Browser: both login demos submit with synthetic input and show local success.
  Web password recovery shows its demo message. Flutter password is concealed.
  Web at exactly 375px has no horizontal overflow; the two-column desktop and
  compact layouts were displayed. Flutter gallery was displayed at 375 and 1024.
  This is not a claim of pixel-identical geometry or native-device acceptance.
- Storybook restarted after changing its configuration and normalizing source
  files; stale development indexing errors cleared after restart.

## Review links and remaining gates

- Assetry: http://127.0.0.1:4310/app/login
- Storybook: http://localhost:6006/?path=/story/showcase-login--assetry
- Widgetbook: http://localhost:6007/#/?path=showcase/login/assetry

The integrated `pnpm verify` run is in progress; its final result must be appended.
Observed upstream notices include experimental Node MockTimers, Vite chunk size,
and Storybook's future v11 ariaLabel requirement. None was suppressed or fixed by
editing installed dependencies. Earlier Assetry Worker-test/Sourcemap findings
remain outside this library slice. Visual acceptance and the final verification
result are required before the authorized master delivery.
