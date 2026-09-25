import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../generated/k_icons.g.dart';
export '../generated/k_icons.g.dart' show KIconName, kIconLabels;

class KIcon extends StatelessWidget {
  const KIcon(this.name, {this.size = 16, this.color, this.label, super.key});
  final KIconName name;
  final double size;
  final Color? color;

  /// Omit for decorative icons; label meaningful standalone icons.
  final String? label;
  @override
  Widget build(BuildContext context) {
    if (!size.isFinite || size <= 0) {
      throw ArgumentError.value(size, 'size', 'Must be positive and finite');
    }
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    return SvgPicture.string(
      kIconSvg[name]!,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? tokens.colorTextPrimary,
        BlendMode.srcIn,
      ),
      semanticsLabel: label,
      excludeFromSemantics: label == null || label!.isEmpty,
    );
  }
}
