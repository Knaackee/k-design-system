import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../navigation/k_scroll_top_bar.dart';
import 'k_layout.dart';

/// Readable width of a [KPage].
enum KPageWidth {
  /// Lists, details and dashboards (`layout.pageWidth`, 960).
  content,

  /// Uses the available width for calendars, tables and broad workspaces.
  fluid,

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
    this.onRefresh,
    super.key,
  });

  final List<Widget> children;
  final KPageWidth width;
  final ScrollController? controller;

  /// Pull to refresh, as on iOS (Apple style) and Android (other styles).
  /// Never add a refresh button to the page actions.
  final Future<void> Function()? onRefresh;

  /// Whether [context] is inside a [KPage]: the page's gutter already
  /// separates its content from the top, so a [KPageHeader] adds none.
  static bool isInside(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_KPageScope>() != null;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final padding = MediaQuery.paddingOf(context);
    final form = width == KPageWidth.form;
    final gutter = t.spaceLayoutGutter;
    // Below a top bar row with controls the row already separates the page
    // from the status bar: the title follows it closely, as on iOS.
    // Beside a sidebar the page starts on the line of the sidebar header.
    final topGap = KTopBarTitleScope.barControlsOf(context)
        ? t.spaceTight
        : KPageTopGap.maybeOf(context) ??
              (KTopBarTitleScope.maybeOf(context) != null &&
                      KAdaptive.maybeOf(context)?.style == KStyle.material
                  ? gutter + t.spaceLayoutSectionGap
                  : gutter);
    final insets = EdgeInsets.fromLTRB(
      gutter + padding.left,
      topGap + padding.top,
      gutter + padding.right,
      gutter + padding.bottom,
    );
    Widget body(BoxConstraints constraints) => ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: form && constraints.hasBoundedHeight
            ? math.max(0, constraints.maxHeight - insets.vertical)
            : 0,
      ),
      child: Align(
        alignment: form ? Alignment.center : Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: switch (width) {
              KPageWidth.form => t.layoutFormWidth,
              KPageWidth.content => t.layoutPageWidth,
              KPageWidth.fluid => double.infinity,
            },
          ),
          child: _KPageScope(
            child: KStack(
              gap: KLayoutGap.section,
              align: KLayoutAlign.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
    final refresh = onRefresh;
    if (refresh != null && KAdaptive.maybeOf(context)?.style == KStyle.apple) {
      // iOS: the spinner opens above the content as the page is pulled.
      return LayoutBuilder(
        builder: (context, constraints) => CustomScrollView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // The control must be the first sliver to receive the overscroll.
            CupertinoSliverRefreshControl(onRefresh: refresh),
            SliverPadding(
              padding: insets,
              sliver: SliverToBoxAdapter(child: body(constraints)),
            ),
          ],
        ),
      );
    }
    final scroll = LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        controller: controller,
        physics: refresh == null ? null : const AlwaysScrollableScrollPhysics(),
        padding: insets,
        child: body(constraints),
      ),
    );
    if (refresh == null) return scroll;
    return RefreshIndicator(
      onRefresh: refresh,
      edgeOffset: padding.top,
      color: t.colorActionPrimaryBackground,
      backgroundColor: t.colorSurfaceRaised,
      child: scroll,
    );
  }
}

class _KPageScope extends InheritedWidget {
  const _KPageScope({required super.child});

  @override
  bool updateShouldNotify(_KPageScope oldWidget) => false;
}

/// Overrides the top gap of the [KPage]s below it. [KAppShell] uses it so
/// a page beside the sidebar starts on the line of the sidebar header.
class KPageTopGap extends InheritedWidget {
  const KPageTopGap({required this.gap, required super.child, super.key});

  final double gap;

  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KPageTopGap>()?.gap;

  @override
  bool updateShouldNotify(KPageTopGap oldWidget) => gap != oldWidget.gap;
}
