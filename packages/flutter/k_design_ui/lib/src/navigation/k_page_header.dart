import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../primitives/k_page.dart';

import '../primitives/k_text.dart';
import '../actions/k_menu_button.dart';
import 'k_back_button.dart';
import 'k_scroll_top_bar.dart';

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
    this.backHistory = const [],
    this.leading,
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

  /// Levels above this screen for the back button's long-press menu; give
  /// it whenever [breadcrumb] is set so phones keep the path (0015).
  final List<KMenuAction> backHistory;

  /// A navigation button at the start (menu, chat history) for screens
  /// without a back control: on phones it sits at the start of the top
  /// bar, as in Gmail or ChatGPT; wider, before the title. Never place
  /// such a button in the page content (Decision 0015).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    assert(actions.length <= 3, 'KPageHeader takes at most 3 actions.');
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    final style = KAdaptive.maybeOf(context)?.style ?? KStyle.linear;
    final back = backLabel == null
        ? leading
        : KBackButton(
            label: backLabel!,
            onPressed:
                onBack ??
                () {
                  if (context.mounted) Navigator.maybePop(context);
                },
            history: backHistory,
          );
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
            KTopBarTitleAnchor(
              title: title,
              back: backLabel == null ? null : back,
              leading: backLabel == null ? leading : null,
              actions: actions,
              child: Semantics(
                header: true,
                child: KText(
                  title,
                  variant: switch ((style, compact)) {
                    // iOS large title on every width.
                    (KStyle.apple, _) => KTextVariant.heading1,
                    // Material 3 large flexible app bar headline.
                    (KStyle.material, _) => KTextVariant.heading1,
                    (KStyle.linear, true) => KTextVariant.heading2,
                    (KStyle.linear, false) => KTextVariant.heading3,
                  },
                ),
              ),
            ),
            if (subtitle case final text?) ...[
              SizedBox(height: t.componentPageHeaderTitleGap),
              KText(
                text,
                variant: KTextVariant.bodySmall,
                style: TextStyle(color: t.colorTextMuted),
              ),
            ],
          ],
        );
        final children = <Widget>[];
        // Phones inside the shell: back and actions live in the top bar
        // (KScrollTopBar); the header shows only the large title (0015).
        final inBar = compact && KTopBarTitleScope.maybeOf(context) != null;
        if (inBar) {
          // Material top-level pages: the bar's actions sit at the end of
          // the title's line.
          final inset = KTopBarTitleScope.actionsInsetOf(context);
          children.add(
            inset > 0
                ? Padding(
                    padding: EdgeInsetsDirectional.only(end: inset),
                    child: copy,
                  )
                : copy,
          );
        } else if (compact) {
          final inlineActions = !largeText ? actionBar : null;
          if (back != null || inlineActions != null) {
            children.add(
              Row(
                children: [
                  ?back,
                  // Actions take all remaining width, like the Web grid, so
                  // a short action row never wraps early.
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: inlineActions ?? const SizedBox.shrink(),
                    ),
                  ),
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
        // In a KPage the page gutter, and below a bar row with controls
        // the row, already separate the title from the top.
        final barRow = inBar && KTopBarTitleScope.barControlsOf(context);
        final spaced = barRow || KPage.isInside(context);
        final pageGap = KPageTopGap.maybeOf(context);
        return Padding(
          padding: EdgeInsets.only(
            top: spaced
                ? 0
                : pageGap != null
                ? MediaQuery.paddingOf(context).top + pageGap
                : t.componentPageHeaderPaddingBlockStart,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        );
      },
    );
  }
}
