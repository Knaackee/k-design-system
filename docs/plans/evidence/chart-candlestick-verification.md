# Candlestick reference — implementation evidence

## Accepted scope

On 2026-09-25 the user approved the proposed shared Candlestick reference with “Ja, das klingt doch gut. Mache das bitte.” This continues the chart adapter work: TanStack primitives on Web, native fl_chart CandlestickChart on Flutter, no added renderer dependency. The preceding chart-family work is accepted and remains uncommitted; preserve it. No commit or push is authorized in this request.

Implement KCandlestickChart with shared OHLC inputs, stable IDs, externally controlled selection and visible range, customizable labels/formatters/state content, existing design tokens, crosshair and OHLC tooltip. Include rising, falling and Doji samples. Optional demo data-table button composes KDialog and KTable.

## Verification before implementation

- Model checks: invalid/nonfinite OHLC rejection, positive/negative and Doji values, stable immutable data, visible range.
- Flutter layout and interaction tests across densities and narrow/wide widths; fixture tests for the shared data and modal.
- Web typecheck/build and model tests; browser keyboard/pointer selection and matching screenshots for both platforms.
- Integrated pnpm verify, including both gallery builds. Existing native Android limitation remains: Widgetbook has no Android host; do not scaffold one in this slice.

## Result

Implemented and exported KCandlestickChart on both platforms. Web composes bounded lineY wicks and rect bodies; Flutter uses native CandlestickChart with its painter extension for minimum visible Doji height. Public data stays unchanged. Range overrides the x domain; keyboard/pointer selection uses stable candle IDs. Styling uses existing tokens; no new dependencies.

Targeted checks passed: three Web model tests, shared fixture parity test, six Flutter component tests (including nine width/density combinations and a raster Doji assertion), Flutter gallery test, targeted analysis, Web typecheck/build and formatting.

Browser checks at compact width: matching candles and axes, Home/right-arrow selection, Doji Open=Close=103 with High=111 and Low=100, Flutter pointer selection with identical OHLC and volume, Web table with eight data rows, Flutter modal open/close and horizontal scrolling to Low/Close/Volume. Screenshots are in artifacts/chart-candlestick. No native Android test was performed.

User visually accepted the direction and requested removal of redundant colored tooltip dots. Removed on both platforms; final browser screenshots confirm text-only OHLC/volume rows. Web build and affected-source formatting were separately rerun after this adjustment; the ongoing integrated run covered the final sources in analysis, tests and gallery builds.

Final pnpm verify exited 0: formatting, generation, 70 tooling tests, style audit, Web build/typecheck, Flutter analysis, 423 Flutter tests and both gallery builds. Existing Wasm dry-run and Cupertino font warnings remain; the JavaScript release build succeeds. No commit or push performed.
