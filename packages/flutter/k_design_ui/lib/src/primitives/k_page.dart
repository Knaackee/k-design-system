import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'k_layout.dart';

/// Readable width of a [KPage].
enum KPageWidth {
  /// Lists, details and dashboards (`layout.pageWidth`, 960).
  content,

  /// Sign-in, onboarding steps and other single forms (`layout.formWidth`,
  /// 520). The form is centred vertically when it is shorter than the
  /// screen, as on iOS and Android sign-in screens.
  form,
}

/// The scrolling body of a screen (Decision 0015): page gutter, safe areas,
/// a readable maximum width on tablets and desktops, and section spacing
/// between [children]. Use it for every screen so no form or list runs
/// across a whole iPad or desktop window.
class KPage extends StatelessWidget {
  const KPage({
    required this.children,
    this.width = KPageWidth.content,
    this.controller,
    super.key,
  });

  final List<Widget> children;
  final KPageWidth width;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final padding = MediaQuery.paddingOf(context);
    final form = width == KPageWidth.form;
    final gutter = t.spaceLayoutGutter;
    final insets = EdgeInsets.fromLTRB(
      gutter + padding.left,
      gutter + padding.top,
      gutter + padding.right,
      gutter + padding.bottom,
    );
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        controller: controller,
        padding: insets,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: form && constraints.hasBoundedHeight
                ? math.max(0, constraints.maxHeight - insets.vertical)
                : 0,
          ),
          child: Align(
            alignment: form ? Alignment.center : Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: form ? t.layoutFormWidth : t.layoutPageWidth,
              ),
              child: KStack(
                gap: KLayoutGap.section,
                align: KLayoutAlign.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
