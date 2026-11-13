import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../data_display/k_list.dart';
import '../navigation/k_sidebar.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_page.dart';
import '../primitives/k_text.dart';

/// Responsive settings shell shared by settings galleries and applications.
///
/// At widths below [breakpoint], [detailVisible] selects the navigation or
/// content view. At and above the breakpoint both panes remain visible.
class KSettingsPage extends StatelessWidget {
  const KSettingsPage({
    required this.navigation,
    required this.content,
    this.navigationMode,
    this.compactBreakpoint = breakpoint,
    this.detailVisible = false,
    this.onBack,
    this.backLabel = 'Settings',
    this.title,
    this.description,
    this.breadcrumb,
    this.eyebrow,
    this.wide = false,
    this.contentPadding,
    super.key,
  });

  static const double breakpoint = 700;

  /// Width below which navigation and detail are separate views.
  final double compactBreakpoint;

  final Widget navigation;

  /// Uses the panel token and standard rail width for controlled navigation.
  /// Null preserves the settings panel width. Compact navigation stays full width.
  final KSidebarMode? navigationMode;
  final Widget content;
  final bool detailVisible;
  final VoidCallback? onBack;
  final String backLabel;
  final String? title;
  final String? description;

  /// Public navigation slot before the page heading, matching Web.
  final Widget? breadcrumb;
  final String? eyebrow;
  final bool wide;

  /// Optional consumer spacing, equivalent to styling the Web content pane.
  /// Null preserves the standard responsive settings spacing.
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) => _buildPage(context);

  Widget _buildPage(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Material(
      color: tokens.colorSurfaceCanvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < compactBreakpoint;
          final navigationPane = ColoredBox(
            color: tokens.colorSurfaceRaised,
            child: SafeArea(child: navigation),
          );
          final contentPane = SafeArea(
            child: _contentPane(context, compact: compact),
          );
          if (!compact) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: switch (navigationMode) {
                    KSidebarMode.expanded => tokens.layoutPanelWidth,
                    KSidebarMode.rail => KSidebar.defaultRailWidth,
                    KSidebarMode.hidden => 0,
                    null => tokens.layoutPanelWidth,
                  },
                  child: navigationMode == KSidebarMode.hidden
                      ? const SizedBox.shrink()
                      : navigationPane,
                ),
                Expanded(child: contentPane),
              ],
            );
          }
          return detailVisible
              ? contentPane
              : SizedBox(width: constraints.maxWidth, child: navigationPane);
        },
      ),
    );
  }

  Widget _contentPane(BuildContext context, {required bool compact}) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final horizontal = compact
        ? tokens.spaceControlInsetInline + tokens.spaceSmallInset
        : tokens.spaceLayoutSectionGap + tokens.spaceContentActionGap;
    final vertical = compact
        ? tokens.spaceControlInsetInline
        : tokens.spaceLayoutSectionGap + tokens.spaceContentActionGap;
    final maxWidth = wide
        ? tokens.layoutContentWidth + (tokens.layoutMenuWidth * 2)
        : tokens.layoutContentWidth + tokens.layoutTableColumnWidth;
    return Material(
      key: const ValueKey('k-settings-content'),
      color: tokens.colorSurfaceCanvas,
      child: SingleChildScrollView(
        primary: false,
        padding:
            contentPadding ??
            EdgeInsets.fromLTRB(
              horizontal,
              compact ? tokens.spaceControlInsetInline : tokens.spaceControlGap,
              horizontal,
              vertical,
            ),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact && onBack != null) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: KButton(
                      label: backLabel,
                      leading: const KIcon(KIconName.arrowLeft),
                      variant: KButtonVariant.ghost,
                      onPressed: onBack,
                    ),
                  ),
                  SizedBox(
                    height: breadcrumb != null
                        ? tokens.spaceControlGap
                        : tokens.spaceControlInsetInline,
                  ),
                ],
                if (breadcrumb != null) ...[
                  breadcrumb!,
                  SizedBox(height: tokens.spaceControlGap),
                ],
                if (eyebrow case final value?) ...[
                  KText(
                    value,
                    variant: KTextVariant.caption,
                    style: TextStyle(color: tokens.colorTextMuted),
                  ),
                  SizedBox(height: tokens.spaceSmallInset),
                ],
                if (title case final value?) ...[
                  KText(value, variant: KTextVariant.heading2),
                  if (description != null)
                    SizedBox(height: tokens.spaceControlGap),
                ],
                if (description case final value?) ...[
                  KText(
                    value,
                    variant: KTextVariant.bodySmall,
                    style: TextStyle(color: tokens.colorTextMuted),
                  ),
                ],
                if (title != null || description != null || eyebrow != null)
                  SizedBox(
                    height:
                        tokens.spaceContentActionGap +
                        tokens.spaceControlInsetInline,
                  ),
                // The pane already owns the safe area and page-start inset.
                compact ? content : KPageTopGap(gap: 0, child: content),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A titled settings group with optional supporting copy.
class KSettingsSection extends StatelessWidget {
  const KSettingsSection({
    required this.title,
    required this.child,
    this.description,
    super.key,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KText(title, variant: KTextVariant.heading4),
          if (description case final value?) ...[
            SizedBox(height: tokens.spaceSmallInset),
            KText(
              value,
              variant: KTextVariant.bodySmall,
              style: TextStyle(color: tokens.colorTextMuted),
            ),
          ],
          SizedBox(
            height: tokens.spaceControlInsetInline + tokens.spaceControlGap,
          ),
          child,
        ],
      ),
    );
  }
}

/// A responsive title/description and control row for one setting.
enum KSettingsRowLayout {
  /// Places controls beside text from 480px and stacks them below that width.
  auto,

  /// Keeps the control beside the text at every supported width.
  compact,

  /// Places the control below the text and gives it the full available width.
  fullWidth,
}

class KSettingsRow extends StatelessWidget {
  const KSettingsRow({
    required this.title,
    required this.control,
    this.description,
    this.layout = KSettingsRowLayout.auto,
    super.key,
  });

  final String title;
  final String? description;
  final Widget control;
  final KSettingsRowLayout layout;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final inList = KList.isRow(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = switch (layout) {
          // Decision 0010: stack on narrow rows and from 1.3x system text.
          KSettingsRowLayout.auto =>
            constraints.maxWidth < 480 ||
                MediaQuery.textScalerOf(context).scale(1) >= 1.3,
          KSettingsRowLayout.compact => false,
          KSettingsRowLayout.fullWidth => true,
        };
        final boundedControl = layout == KSettingsRowLayout.fullWidth
            ? SizedBox(width: double.infinity, child: control)
            : ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: math.min(360, constraints.maxWidth),
                ),
                child: control,
              );
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KText(title, variant: KTextVariant.label),
            if (description case final value?) ...[
              SizedBox(height: tokens.spaceTight),
              KText(
                value,
                variant: KTextVariant.bodySmall,
                style: TextStyle(color: tokens.colorTextMuted),
              ),
            ],
          ],
        );
        return Semantics(
          container: true,
          child: Padding(
            // In a KList the row takes the list's inline inset.
            padding: EdgeInsets.symmetric(
              horizontal: inList ? tokens.componentListRowPaddingInline : 0,
              vertical: tokens.spaceControlInsetInline,
            ),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      copy,
                      SizedBox(height: tokens.spaceControlInsetInline),
                      if (layout == KSettingsRowLayout.fullWidth)
                        boundedControl
                      else
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: boundedControl,
                        ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: copy),
                      SizedBox(
                        width:
                            tokens.spaceContentActionGap +
                            tokens.spaceControlGap,
                      ),
                      boundedControl,
                    ],
                  ),
          ),
        );
      },
    );
  }
}
