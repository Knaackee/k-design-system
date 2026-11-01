# UI sound parity — 2026-10-31

Scope approved: shared Web/Flutter language/theme sounds, no onboarding callback duplication.
KLanguageSwitcher emits tap only for changed language; KThemeSwitcher emits switch. Both use existing optional KSoundProvider/controller; no provider stays silent. Flutter K action/menu/button controls suppress OS feedback inside sound scope to avoid OEM-specific double clicks. App preference, gain and system mute remain respected.
Checks: Web build + Web/Storybook typecheck passed; Flutter scoped analysis passed; Flutter sound tests 7 passed including switchers/mute; Web sound tests 6 passed. Both device hot reload sessions updated. Browser live interaction blocked by browser.user unavailable; no acoustic listening verification claimed. Existing QR changes preserved; no commit/push.
Next: user listening comparison on OnePlus, tablet and Web with sounds enabled.
