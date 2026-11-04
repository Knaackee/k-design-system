import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

const _brandLight = Color(0xFF6D28D9);
const _brandLightHover = Color(0xFF5B21B6);
const _brandLightPressed = Color(0xFF4C1D95);
const _brandDark = Color(0xFFC4B5FD);
const _brandDarkHover = Color(0xFFDDD6FE);
const _brandDarkPressed = Color(0xFFA78BFA);

/// Base Material theme; [consumerAdaptive] resolves the K axes per window.
ThemeData consumerTheme(Brightness brightness) => kDesignTheme(
  brightness: brightness,
  tokenTransform: consumerTokens(brightness),
);

/// Host-owned brand overrides, applied on top of the resolved tokens.
KDesignTokenTransform consumerTokens(Brightness brightness) => (tokens) {
  final isDark = brightness == Brightness.dark;
  final primary = isDark ? _brandDark : _brandLight;

  return tokens.copyWith(
    colorBrandPrimaryAccent: primary,
    colorBrandPrimaryForeground: primary,
    colorActionPrimaryBackground: primary,
    colorActionPrimaryHover: isDark ? _brandDarkHover : _brandLightHover,
    colorActionPrimaryPressed: isDark ? _brandDarkPressed : _brandLightPressed,
    colorActionPrimaryForeground: isDark
        ? const Color(0xFF1F1633)
        : Colors.white,
    colorBorderFocus: primary,
  );
};

/// Decision 0010: resolve density, type ramp, input and window class from
/// the running window instead of a fixed preset.
Widget consumerAdaptive(BuildContext context, Widget? child) {
  final brightness = Theme.of(context).brightness;
  return KAdaptiveTheme(
    brightness: brightness,
    tokenTransform: consumerTokens(brightness),
    child: child!,
  );
}
