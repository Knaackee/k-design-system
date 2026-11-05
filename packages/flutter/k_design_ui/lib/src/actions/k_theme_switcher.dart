import 'dart:async';
import '../feedback/k_haptics.dart';
import '../feedback/k_sound.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_animated_icon.dart';
import '../primitives/k_icon.dart';
import 'k_icon_button.dart';

/// Consumer owns applying and persisting this preference, including system mode.
class KThemeSwitcher extends StatelessWidget {
  const KThemeSwitcher({
    required this.value,
    required this.onChanged,
    this.label = 'Appearance',
    this.labels = const {},
    this.icons = const {},
    this.disabled = false,
    this.spring = KAnimatedIconSpring.snappy,
    this.reducedMotion = KAnimatedIconReducedMotion.user,
    super.key,
  });
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;
  final String label;
  final Map<ThemeMode, String> labels;
  final Map<ThemeMode, KIconName> icons;
  final bool disabled;
  final KAnimatedIconSpring spring;
  final KAnimatedIconReducedMotion reducedMotion;
  static const _labels = {
    ThemeMode.light: 'Light',
    ThemeMode.dark: 'Dark',
    ThemeMode.system: 'System',
  };
  static const _icons = {
    ThemeMode.light: KIconName.sun,
    ThemeMode.dark: KIconName.moon,
    ThemeMode.system: KIconName.monitor,
  };

  @override
  Widget build(BuildContext context) {
    final sound = KSoundProvider.maybeOf(context);
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final names = {..._labels, ...labels};
    final symbols = {..._icons, ...icons};
    const modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
    return KIconButton(
      label: '$label: ${names[value]}',
      icon: symbols[value]!,
      onPressed: disabled
          ? null
          : () {
              if (sound != null) unawaited(sound.play(KSoundCue.switchCue));
              kHaptic(context, KHapticCue.selection);
              onChanged(modes[(modes.indexOf(value) + 1) % modes.length]);
            },
      iconContent: KAnimatedIcon(
        symbols[value]!,
        spring: spring,
        reducedMotion: reducedMotion,
        color: t.colorActionGhostForeground,
      ),
    );
  }
}
