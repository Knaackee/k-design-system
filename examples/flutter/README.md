# Flutter consumer example

This is a small, runnable application that consumes the Flutter design-system
packages through local paths. It deliberately keeps product state and token
overrides in the consumer:

- `lib/theme/consumer_theme.dart` owns the example brand colors.
- `lib/app.dart` owns application state and event handling.
- `k_design_tokens` and `k_design_ui` provide tokens, themes and components.

## Run and verify

```bash
flutter pub get
flutter run -d chrome
flutter run -d <android-device-id> --release
flutter analyze
flutter test
```

## Use from a Git submodule

If an application checks this repository out at `design-system/`, reference both
Flutter packages from the application's `pubspec.yaml`:

```yaml
dependencies:
  k_design_tokens:
    path: design-system/packages/flutter/k_design_tokens
  k_design_ui:
    path: design-system/packages/flutter/k_design_ui
```

Both declarations are intentional. `k_design_ui` uses the token package, while
the application imports `k_design_tokens` to create its own theme. The consuming
application must keep its `KDesignTokenTransform`, theme-mode choice and product
configuration outside the submodule. It must not edit generated token files or
the shared Orbit defaults for application-specific branding.

Start with `kDesignTheme(tokenTransform: ...)` as shown in
`lib/theme/consumer_theme.dart`. The transform receives the resolved defaults and
returns a copied token set scoped to this application.
