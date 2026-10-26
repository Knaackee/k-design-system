# KMap — Storybook integration

KMap is available through separate map entry points for React and Flutter. The approved scope is the configurable base map in Storybook and Widgetbook; routes, traffic overlays and Onzeit integration remain separate slices.

- React renderer: `@k-design-system/ui/patterns/map`; renderer-free style factory: `@k-design-system/ui/maps`.
- Flutter renderer: `package:k_design_ui/k_map.dart`; renderer-free style factory: `package:k_design_ui/k_map_style.dart`.
- Source tokens live in KDS semantic/theme inputs. Web CSS and Dart ThemeExtension projections are generated from the same inputs. Per-map overrides do not change global theme defaults.
- React hosts import MapLibre CSS and `@k-design-system/ui/maps.css` only where a map is used, and configure the worker through their bundler. Flutter Web hosts also load the MapLibre JS/CSS required by the Flutter plugin; Widgetbook provides that bootstrap.
- Both galleries use the same initial center `[13.388, 52.517]`, zoom `14`, map layers, settings and token defaults. Theme changes preserve the current camera and explicit token overrides. Reset restores current-theme defaults.
- Gallery controls expose map settings and token overrides; a table shows token names, CSS variable equivalents, defaults and effective values.
- Map labels use Noto Sans glyph stacks from OpenFreeMap. Inter remains the surrounding KDS UI font; Inter map labels require compatible hosted glyph PBF files and matching font tokens.
- Tiles and glyphs require network access. Sources are replaceable, but vector data must retain the OpenMapTiles schema. Attribution remains visible. No device location permission is requested.
- MapLibre style parity is tested against Web-generated fixtures. Native Android/iOS rendering still requires device verification before host adoption; Widgetbook browser verification is not a native-device claim.

No commit, push or deployment is part of this slice. Integrated verification and screenshots are recorded with the delivery evidence.
