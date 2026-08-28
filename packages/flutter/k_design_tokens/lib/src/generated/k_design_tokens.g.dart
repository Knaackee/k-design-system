// GENERATED FILE. DO NOT EDIT.
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

abstract final class KDesignTokenVariants {
  static const presentationProductiveSpaceLayoutSectionGap = 32.0;
  static const presentationExpressiveSpaceLayoutSectionGap = 64.0;
  static const typeScaleCompactFontSize = 14.0;
  static const typeScaleStandardFontSize = 16.0;
  static const densityDenseSpaceControlGap = 4.0;
  static const densityDenseSpaceControlInsetInline = 8.0;
  static const densityDenseSizeControl = 32.0;
  static const densityStandardSpaceControlGap = 8.0;
  static const densityStandardSpaceControlInsetInline = 12.0;
  static const densityStandardSizeControl = 36.0;
  static const densitySpaciousSpaceControlGap = 12.0;
  static const densitySpaciousSpaceControlInsetInline = 16.0;
  static const densitySpaciousSizeControl = 44.0;
  static const inputModePointerSizeHitTarget = 24.0;
  static const inputModeTouchSizeHitTarget = 48.0;
  static const windowCompactSpaceLayoutGutter = 16.0;
  static const windowMediumSpaceLayoutGutter = 24.0;
  static const windowExpandedSpaceLayoutGutter = 32.0;
  static const windowLargeSpaceLayoutGutter = 48.0;
  static const windowExtraLargeSpaceLayoutGutter = 64.0;
}

@immutable
class KDesignTokens extends ThemeExtension<KDesignTokens> {
  const KDesignTokens({
    required this.colorSurfaceCanvas,
    required this.colorSurfaceRaised,
    required this.colorTextPrimary,
    required this.colorTextMuted,
    required this.colorBorderDefault,
    required this.colorBorderFocus,
    required this.colorActionPrimaryBackground,
    required this.colorActionPrimaryHover,
    required this.colorActionPrimaryPressed,
    required this.colorActionPrimaryForeground,
    required this.spaceControlGap,
    required this.spaceControlInsetInline,
    required this.spaceLayoutGutter,
    required this.spaceLayoutSectionGap,
    required this.sizeControl,
    required this.sizeHitTarget,
    required this.radiusControl,
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.motionFast,
  });

  final Color colorSurfaceCanvas;
  final Color colorSurfaceRaised;
  final Color colorTextPrimary;
  final Color colorTextMuted;
  final Color colorBorderDefault;
  final Color colorBorderFocus;
  final Color colorActionPrimaryBackground;
  final Color colorActionPrimaryHover;
  final Color colorActionPrimaryPressed;
  final Color colorActionPrimaryForeground;
  final double spaceControlGap;
  final double spaceControlInsetInline;
  final double spaceLayoutGutter;
  final double spaceLayoutSectionGap;
  final double sizeControl;
  final double sizeHitTarget;
  final double radiusControl;
  final String fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final Duration motionFast;

  static const orbitLight = KDesignTokens(
    colorSurfaceCanvas: Color(0xFFF7F8FA),
    colorSurfaceRaised: Color(0xFFFFFFFF),
    colorTextPrimary: Color(0xFF15171C),
    colorTextMuted: Color(0xFF5D6472),
    colorBorderDefault: Color(0xFFC9CDD6),
    colorBorderFocus: Color(0xFF8B8CF8),
    colorActionPrimaryBackground: Color(0xFF5556D9),
    colorActionPrimaryHover: Color(0xFF4546BD),
    colorActionPrimaryPressed: Color(0xFF4546BD),
    colorActionPrimaryForeground: Color(0xFFFFFFFF),
    spaceControlGap: 8.0,
    spaceControlInsetInline: 12.0,
    spaceLayoutGutter: 16.0,
    spaceLayoutSectionGap: 32.0,
    sizeControl: 36.0,
    sizeHitTarget: 24.0,
    radiusControl: 6.0,
    fontFamily: "Inter",
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    motionFast: Duration(milliseconds: 80),
  );

  static const orbitDark = KDesignTokens(
    colorSurfaceCanvas: Color(0xFF0D0F12),
    colorSurfaceRaised: Color(0xFF15171C),
    colorTextPrimary: Color(0xFFF7F8FA),
    colorTextMuted: Color(0xFFA9AFBB),
    colorBorderDefault: Color(0xFF343842),
    colorBorderFocus: Color(0xFF8B8CF8),
    colorActionPrimaryBackground: Color(0xFF696AF0),
    colorActionPrimaryHover: Color(0xFF7B7CF5),
    colorActionPrimaryPressed: Color(0xFF5556D9),
    colorActionPrimaryForeground: Color(0xFFFFFFFF),
    spaceControlGap: 8.0,
    spaceControlInsetInline: 12.0,
    spaceLayoutGutter: 16.0,
    spaceLayoutSectionGap: 32.0,
    sizeControl: 36.0,
    sizeHitTarget: 24.0,
    radiusControl: 6.0,
    fontFamily: "Inter",
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    motionFast: Duration(milliseconds: 80),
  );

  static const referenceLight = KDesignTokens(
    colorSurfaceCanvas: Color(0xFFF0FDFA),
    colorSurfaceRaised: Color(0xFFFFFFFF),
    colorTextPrimary: Color(0xFF134E4A),
    colorTextMuted: Color(0xFF52706D),
    colorBorderDefault: Color(0xFF99D5CD),
    colorBorderFocus: Color(0xFF2DD4BF),
    colorActionPrimaryBackground: Color(0xFF0D9488),
    colorActionPrimaryHover: Color(0xFF0F766E),
    colorActionPrimaryPressed: Color(0xFF115E59),
    colorActionPrimaryForeground: Color(0xFFFFFFFF),
    spaceControlGap: 8.0,
    spaceControlInsetInline: 12.0,
    spaceLayoutGutter: 16.0,
    spaceLayoutSectionGap: 32.0,
    sizeControl: 36.0,
    sizeHitTarget: 24.0,
    radiusControl: 6.0,
    fontFamily: "Inter",
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    motionFast: Duration(milliseconds: 80),
  );

  static const referenceDark = KDesignTokens(
    colorSurfaceCanvas: Color(0xFF071B19),
    colorSurfaceRaised: Color(0xFF0B2925),
    colorTextPrimary: Color(0xFFECFDF5),
    colorTextMuted: Color(0xFF91B8B2),
    colorBorderDefault: Color(0xFF23544E),
    colorBorderFocus: Color(0xFF5EEAD4),
    colorActionPrimaryBackground: Color(0xFF14B8A6),
    colorActionPrimaryHover: Color(0xFF2DD4BF),
    colorActionPrimaryPressed: Color(0xFF0D9488),
    colorActionPrimaryForeground: Color(0xFF042F2E),
    spaceControlGap: 8.0,
    spaceControlInsetInline: 12.0,
    spaceLayoutGutter: 16.0,
    spaceLayoutSectionGap: 32.0,
    sizeControl: 36.0,
    sizeHitTarget: 24.0,
    radiusControl: 6.0,
    fontFamily: "Inter",
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    motionFast: Duration(milliseconds: 80),
  );

  @override
  KDesignTokens copyWith({
    Color? colorSurfaceCanvas,
    Color? colorSurfaceRaised,
    Color? colorTextPrimary,
    Color? colorTextMuted,
    Color? colorBorderDefault,
    Color? colorBorderFocus,
    Color? colorActionPrimaryBackground,
    Color? colorActionPrimaryHover,
    Color? colorActionPrimaryPressed,
    Color? colorActionPrimaryForeground,
    double? spaceControlGap,
    double? spaceControlInsetInline,
    double? spaceLayoutGutter,
    double? spaceLayoutSectionGap,
    double? sizeControl,
    double? sizeHitTarget,
    double? radiusControl,
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    Duration? motionFast,
  }) {
    return KDesignTokens(
      colorSurfaceCanvas: colorSurfaceCanvas ?? this.colorSurfaceCanvas,
      colorSurfaceRaised: colorSurfaceRaised ?? this.colorSurfaceRaised,
      colorTextPrimary: colorTextPrimary ?? this.colorTextPrimary,
      colorTextMuted: colorTextMuted ?? this.colorTextMuted,
      colorBorderDefault: colorBorderDefault ?? this.colorBorderDefault,
      colorBorderFocus: colorBorderFocus ?? this.colorBorderFocus,
      colorActionPrimaryBackground: colorActionPrimaryBackground ?? this.colorActionPrimaryBackground,
      colorActionPrimaryHover: colorActionPrimaryHover ?? this.colorActionPrimaryHover,
      colorActionPrimaryPressed: colorActionPrimaryPressed ?? this.colorActionPrimaryPressed,
      colorActionPrimaryForeground: colorActionPrimaryForeground ?? this.colorActionPrimaryForeground,
      spaceControlGap: spaceControlGap ?? this.spaceControlGap,
      spaceControlInsetInline: spaceControlInsetInline ?? this.spaceControlInsetInline,
      spaceLayoutGutter: spaceLayoutGutter ?? this.spaceLayoutGutter,
      spaceLayoutSectionGap: spaceLayoutSectionGap ?? this.spaceLayoutSectionGap,
      sizeControl: sizeControl ?? this.sizeControl,
      sizeHitTarget: sizeHitTarget ?? this.sizeHitTarget,
      radiusControl: radiusControl ?? this.radiusControl,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      motionFast: motionFast ?? this.motionFast,
    );
  }

  @override
  KDesignTokens lerp(covariant KDesignTokens? other, double t) {
    if (other == null) return this;
    return KDesignTokens(
      colorSurfaceCanvas: Color.lerp(colorSurfaceCanvas, other.colorSurfaceCanvas, t)!,
      colorSurfaceRaised: Color.lerp(colorSurfaceRaised, other.colorSurfaceRaised, t)!,
      colorTextPrimary: Color.lerp(colorTextPrimary, other.colorTextPrimary, t)!,
      colorTextMuted: Color.lerp(colorTextMuted, other.colorTextMuted, t)!,
      colorBorderDefault: Color.lerp(colorBorderDefault, other.colorBorderDefault, t)!,
      colorBorderFocus: Color.lerp(colorBorderFocus, other.colorBorderFocus, t)!,
      colorActionPrimaryBackground: Color.lerp(colorActionPrimaryBackground, other.colorActionPrimaryBackground, t)!,
      colorActionPrimaryHover: Color.lerp(colorActionPrimaryHover, other.colorActionPrimaryHover, t)!,
      colorActionPrimaryPressed: Color.lerp(colorActionPrimaryPressed, other.colorActionPrimaryPressed, t)!,
      colorActionPrimaryForeground: Color.lerp(colorActionPrimaryForeground, other.colorActionPrimaryForeground, t)!,
      spaceControlGap: lerpDouble(spaceControlGap, other.spaceControlGap, t)!,
      spaceControlInsetInline: lerpDouble(spaceControlInsetInline, other.spaceControlInsetInline, t)!,
      spaceLayoutGutter: lerpDouble(spaceLayoutGutter, other.spaceLayoutGutter, t)!,
      spaceLayoutSectionGap: lerpDouble(spaceLayoutSectionGap, other.spaceLayoutSectionGap, t)!,
      sizeControl: lerpDouble(sizeControl, other.sizeControl, t)!,
      sizeHitTarget: lerpDouble(sizeHitTarget, other.sizeHitTarget, t)!,
      radiusControl: lerpDouble(radiusControl, other.radiusControl, t)!,
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
      fontSize: lerpDouble(fontSize, other.fontSize, t)!,
      fontWeight: FontWeight.lerp(fontWeight, other.fontWeight, t)!,
      motionFast: t < 0.5 ? motionFast : other.motionFast,
    );
  }
}
