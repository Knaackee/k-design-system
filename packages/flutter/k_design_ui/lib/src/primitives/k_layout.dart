import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

enum KLayoutGap { control, action, section }

enum KLayoutAlign { start, center, end, stretch }

double _gap(BuildContext context, KLayoutGap gap) {
  final tokens =
      Theme.of(context).extension<KDesignTokens>() ?? KDesignTokens.orbitLight;
  return switch (gap) {
    KLayoutGap.control => tokens.spaceControlGap,
    KLayoutGap.action => tokens.spaceContentActionGap,
    KLayoutGap.section => tokens.spaceLayoutSectionGap,
  };
}

CrossAxisAlignment _alignment(KLayoutAlign align) => switch (align) {
  KLayoutAlign.start => CrossAxisAlignment.start,
  KLayoutAlign.center => CrossAxisAlignment.center,
  KLayoutAlign.end => CrossAxisAlignment.end,
  KLayoutAlign.stretch => CrossAxisAlignment.stretch,
};

class KStack extends StatelessWidget {
  const KStack({
    required this.children,
    this.gap = KLayoutGap.control,
    this.align = KLayoutAlign.start,
    super.key,
  });

  final List<Widget> children;
  final KLayoutGap gap;
  final KLayoutAlign align;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: _alignment(align),
    spacing: _gap(context, gap),
    children: children,
  );
}

class KInline extends StatelessWidget {
  const KInline({
    required this.children,
    this.gap = KLayoutGap.control,
    this.align = KLayoutAlign.start,
    this.wrap = false,
    super.key,
  });

  final List<Widget> children;
  final KLayoutGap gap;
  final KLayoutAlign align;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    if (wrap && align == KLayoutAlign.stretch) {
      throw ArgumentError(
        'KInline does not support wrap with stretch alignment',
      );
    }
    final spacing = _gap(context, gap);
    if (wrap) {
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        crossAxisAlignment: switch (align) {
          KLayoutAlign.start => WrapCrossAlignment.start,
          KLayoutAlign.center => WrapCrossAlignment.center,
          KLayoutAlign.end => WrapCrossAlignment.end,
          KLayoutAlign.stretch => throw StateError(
            'Unsupported wrap alignment',
          ),
        },
        children: children,
      );
    }
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _alignment(align),
      spacing: spacing,
      children: children,
    );
    return align == KLayoutAlign.stretch ? IntrinsicHeight(child: row) : row;
  }
}
