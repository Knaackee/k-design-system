import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../primitives/k_text.dart';
import 'k_back_button.dart';

/// Header of a screen: back control, title, one line of context and up to
/// three actions (Decision 0012, Apple HIG Toolbars).
///
/// - Below 600 the back chevron and the actions share a top row and the
///   title sits underneath as a large title (iOS large title). From 600 the
///   title sits between back and actions.
/// - From 1.3× text the actions move under the title and wrap.
/// - [breadcrumb] shows above the title from 600 (deep desktop
///   hierarchies); below 600 only the back chevron is shown.
///
/// Give at most one prominent action (a primary [KButton]); the others are
/// ghost or icon buttons.
class KPageHeader extends StatelessWidget {
  const KPageHeader({
    required this.title,
    this.subtitle,
    this.backLabel,
    this.onBack,
    this.actions = const [],
    this.breadcrumb,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Shows a [KBackButton]; the label names the destination
  /// ("Back to Portfolios").
  final String? backLabel;

  /// Defaults to `Navigator.maybePop`.
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? breadcrumb;

  @override
  Widget build(BuildContext context) {
    assert(actions.length <= 3, 'KPageHeader takes at most 3 actions.');
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    final back = backLabel == null
        ? null
        : KBackButton(label: backLabel!, onPressed: onBack);
    final actionBar = actions.isEmpty
        ? null
        : Wrap(
            spacing: t.spaceControlGap,
            runSpacing: t.spaceControlGap,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (breadcrumb case final crumb? when !compact) ...[
              crumb,
              SizedBox(height: t.spaceTight),
            ],
            Semantics(
              header: true,
              child: KText(
                title,
                variant: compact
                    ? KTextVariant.heading1
                    : KTextVariant.heading2,
              ),
            ),
            if (subtitle case final text?) ...[
              SizedBox(height: t.spaceTight),
              KText(
                text,
                variant: KTextVariant.bodySmall,
                style: TextStyle(color: t.colorTextMuted),
              ),
            ],
          ],
        );
        final children = <Widget>[];
        if (compact) {
          final inlineActions = !largeText ? actionBar : null;
          if (back != null || inlineActions != null) {
            children.add(
              Row(
                children: [
                  ?back,
                  const Spacer(),
                  if (inlineActions != null) Flexible(child: inlineActions),
                ],
              ),
            );
            children.add(SizedBox(height: t.spaceTight));
          }
          children.add(copy);
          if (largeText && actionBar != null) {
            children
              ..add(SizedBox(height: t.spaceControlGap))
              ..add(
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: actionBar,
                ),
              );
          }
        } else {
          children.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (back != null) ...[back, SizedBox(width: t.spaceTight)],
                Expanded(child: copy),
                if (actionBar != null && !largeText) ...[
                  SizedBox(width: t.spaceContentActionGap),
                  Flexible(child: actionBar),
                ],
              ],
            ),
          );
          if (actionBar != null && largeText) {
            children
              ..add(SizedBox(height: t.spaceControlGap))
              ..add(
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: actionBar,
                ),
              );
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        );
      },
    );
  }
}
