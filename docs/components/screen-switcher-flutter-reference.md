# ScreenSwitcher Flutter reference

The approved evaluation uses card_stack_widget 0.1.6 directly in Widgetbook, not a published KScreenSwitcher wrapper. Navigation / ScreenSwitcher / screen-switcher-reference contains 15 cards and a reset button. Card colors, radius and spacing use KDesignTokens. Upstream gesture and animation parameters are untouched; swipes reorder cards through the stack. Geometry parameters are normalized for 15 cards: the original scale formula produces negative scales with that count. Back-card scale is bounded to 72%, and the initial vertical spread to 70 logical pixels. Gesture and animation defaults remain unchanged. This is not yet an Apple Mail-style overview with selectable previews.

Target platforms: Windows, Android and iOS. Browser preview is supplemental, not proof of native behavior. Windows runner added for native review. Debug build encountered MSVC C1001 in the existing audioplayers_windows dependency; release attempt log: .dart_tool/widgetbook-native-release.log.

Verification: scoped Flutter analysis and screen_switcher_reference_test.dart passed, including upstream-default assertions, drag and reset. No iOS or Android runtime verification yet. Next: evaluate the original library behavior before designing a production wrapper.
