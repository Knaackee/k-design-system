import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

const _brandLight = Color(0xFF6D28D9);
const _brandLightHover = Color(0xFF5B21B6);
const _brandLightPressed = Color(0xFF4C1D95);
const _brandDark = Color(0xFFC4B5FD);
const _brandDarkHover = Color(0xFFDDD6FE);
const _brandDarkPressed = Color(0xFFA78BFA);

ThemeData consumerTheme(Brightness brightness) => kDesignTheme(
  brightness: brightness,
  configuration: KDesignConfiguration.mobileApp,
  tokenTransform: (tokens) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? _brandDark : _brandLight;

    return tokens.copyWith(
      colorBrandPrimaryAccent: primary,
      colorBrandPrimaryForeground: primary,
      colorActionPrimaryBackground: primary,
      colorActionPrimaryHover: isDark ? _brandDarkHover : _brandLightHover,
      colorActionPrimaryPressed: isDark
          ? _brandDarkPressed
          : _brandLightPressed,
      colorActionPrimaryForeground: isDark
          ? const Color(0xFF1F1633)
          : Colors.white,
      colorBorderFocus: primary,
    );
  },
);
