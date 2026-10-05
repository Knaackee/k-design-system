import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_text.dart';

/// Responsive settings shell shared by settings galleries and applications.
///
/// At widths below [breakpoint], [detailVisible] selects the navigation or
/// content view. At and above the breakpoint both panes remain visible.
class KSettingsPage extends StatelessWidget {
  const KSettingsPage({
    required this.navigation,
    required this.content,
    this.detailVisible = false,
    this.onBack,
    this.backLabel = 'Settings',
    this.title,
    this.description,
    this.eyebrow,
    this.wide = false,
    super.key,
  });

  static const double breakpoint = 700;

  final Widget navigation;
  final Widget content;
  final bool detailVisible;
  final VoidCallback? onBack;
  final String backLabel;
  final String? title;
  final String? description;
  final String? eyebrow;
  final bool wide;

  @override
  Widget build(BuildContext context) => _buildPage(context);

  Widget _buildPage(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Material(
      color: tokens.colorSurfaceCanvas,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < breakpoint;
            if (!compact) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 280, child: navigation),
                  Expanded(child: _contentPane(context, compact: false)),
                ],
              );
            }
            return detailVisible
                ? _contentPane(context, compact: true)
                : SizedBox(width: constraints.maxWidth, child: navigation);
          },
        ),
      ),
    );
  }

  Widget _contentPane(BuildContext context, {required bool compact}) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final horizontal = compact ? 18.0 : 48.0;
    final vertical = compact ? 12.0 : 48.0;
    final maxWidth = wide ? 1120.0 : 800.0;
    return Material(
      key: const ValueKey('k-settings-content'),
      color: tokens.colorSurfaceCanvas,
      child: SingleChildScrollView(
        primary: false,
        padding: EdgeInsets.fromLTRB(
          horizontal,
          compact ? 12 : 24,
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
                  const SizedBox(height: 12),
                ],
                if (eyebrow case final value?) ...[
                  KText(
                    value,
                    variant: KTextVariant.caption,
                    style: TextStyle(color: tokens.colorTextMuted),
                  ),
                  const SizedBox(height: 6),
                ],
                if (title case final value?) ...[
                  KText(value, variant: KTextVariant.heading2),
                  if (description != null) const SizedBox(height: 8),
                ],
                if (description case final value?) ...[
                  KText(
                    value,
                    variant: KTextVariant.bodySmall,
                    style: TextStyle(color: tokens.colorTextMuted),
                  ),
                ],
                if (title != null || description != null || eyebrow != null)
                  const SizedBox(height: 28),
                content,
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
            const SizedBox(height: 6),
            KText(
              value,
              variant: KTextVariant.bodySmall,
              style: TextStyle(color: tokens.colorTextMuted),
            ),
          ],
          const SizedBox(height: 20),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = switch (layout) {
          KSettingsRowLayout.auto => constraints.maxWidth < 480,
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
              const SizedBox(height: 4),
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      copy,
                      const SizedBox(height: 12),
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
                      const SizedBox(width: 24),
                      boundedControl,
                    ],
                  ),
          ),
        );
      },
    );
  }
}
