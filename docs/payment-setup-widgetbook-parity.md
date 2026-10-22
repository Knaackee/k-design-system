# Payment setup: Flutter and Widgetbook parity

The Flutter `KPaymentSetup` is a presentation pattern. Consumers supply state, provider labels, steps, actions and help. It makes no Stripe calls and contains no Stripe SDK.

Five states mirror the accepted web pattern: connected, actionRequired, pending, needsCorrection and ready. Six Widgetbook cases use the same `payment-setup-*` fixture IDs, including long content. Setup and refresh actions in the gallery simulate state changes; help starts collapsed.

Preview route: `/#/?path=patterns/paymentsetup/payment-setup-needs-correction`. Use Patterns → PaymentSetup for all cases.

The pattern uses public KCard, KText, KIcon, KBadge, KButton, KDisclosure, KStack and KInline. Layout switches at 420 logical pixels of card content width. It follows shared status colors, token spacing, reduced motion and text scaling.

The port exposed two shared primitive geometry differences, corrected at their source: badge content-box minimum height/line height and normal disclosure border layout. Compact disclosures retain their borderless geometry. Widgetbook now explicitly bundles Cupertino icons required by its gallery shell.

Verification on 2026-10-22:

- Four fixture tests pass, including all six cases at 320/768/1280 widths in both themes, long content at 200% text/reduced motion, setup→pending→ready interaction, help disclosure and responsive step ordering.
- Four pattern/primitive/disclosure tests pass, including badge/disclosure Web token geometry across every density, pointer/touch input and 100%/200% text.
- Seventeen existing basic component, compact agent and workflow regressions pass.
- Scoped analysis and Widgetbook release build pass; Cupertino font packaging warning resolved.
- Font-correct captures at 375/768/1280 widths in both themes are generated with `flutter test --no-pub --dart-define=PAYMENT_SETUP_EVIDENCE=true test/payment_setup_fixture_test.dart` from apps/widgetbook; outputs stay in ignored build/payment-setup-evidence.
- Captures were visually compared with the accepted Storybook screenshots. Browser-native and Flutter text rasterization still differ; this is not a claim of binary pixel equality. Root separately verified the actual Widgetbook hash route displays the pattern.

Host application integration and human acceptance are separate from this component verification.
