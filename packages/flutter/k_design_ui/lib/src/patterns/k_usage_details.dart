import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../basic_components.dart';
import '../extended_components.dart';
import '../primitives/k_text.dart';
import '../primitives/k_icon.dart';

@immutable
class KUsageWindow {
  const KUsageWindow({
    required this.id,
    required this.label,
    required this.valueLabel,
    this.progress,
    this.extraResetCount,
    this.renewalLabel,
    this.renewalExact,
  });

  final String id;
  final String label;
  final String valueLabel;
  final double? progress;
  final int? extraResetCount;
  final String? renewalLabel;
  final String? renewalExact;
}

@immutable
class KUsageValue {
  const KUsageValue({
    required this.id,
    required this.label,
    required this.valueLabel,
    this.detail,
  });

  final String id;
  final String label;
  final String valueLabel;
  final String? detail;
}

/// Read-only usage presentation. Providers, timestamps and freshness belong to
/// the consumer.
class KUsageDetails extends StatelessWidget {
  const KUsageDetails({
    required this.title,
    required this.statusLabel,
    this.sourceLabel,
    this.observedLabel,
    this.windows = const [],
    this.balances = const [],
    this.extraResets = const [],
    this.extraResetsLabel,
    this.emptyMessage,
    this.notice,
    super.key,
  });

  final String title;
  final String statusLabel;
  final String? sourceLabel;
  final String? observedLabel;
  final List<KUsageWindow> windows;
  final List<KUsageValue> balances;
  final List<KUsageValue> extraResets;
  final String? extraResetsLabel;
  final String? emptyMessage;
  final Widget? notice;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final muted = TextStyle(color: tokens.colorTextMuted);
    return Semantics(
      container: true,
      label: title,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 440;
          final windowColumns = constraints.maxWidth >= 700 ? 2 : 1;
          final windowWidth = windowColumns == 2
              ? (constraints.maxWidth - tokens.spaceControlInsetInline) / 2
              : constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: _spaced(tokens.spaceContentActionGap, [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: tokens.spaceControlGap,
                runSpacing: tokens.spaceControlGap,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KText(
                        title,
                        variant: KTextVariant.body,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (sourceLabel case final source?)
                        KText(
                          source,
                          variant: KTextVariant.caption,
                          style: muted,
                        ),
                    ],
                  ),
                  KBadge(
                    variant: KBadgeVariant.outline,
                    child: Text(statusLabel),
                  ),
                ],
              ),
              if (windows.isNotEmpty)
                Wrap(
                  spacing: tokens.spaceControlInsetInline,
                  runSpacing: tokens.spaceControlInsetInline,
                  children: [
                    for (final window in windows)
                      SizedBox(
                        width: windowWidth,
                        child: _UsageWindow(window: window),
                      ),
                  ],
                ),
              if (balances.isNotEmpty)
                _UsageValues(values: balances, stacked: narrow),
              if (extraResets.isNotEmpty)
                _ResetDetails(
                  label: extraResetsLabel ?? 'Additional resets',
                  values: extraResets,
                ),
              if (windows.isEmpty &&
                  balances.isEmpty &&
                  extraResets.isEmpty &&
                  emptyMessage != null)
                KText(
                  emptyMessage!,
                  variant: KTextVariant.bodySmall,
                  style: muted,
                ),
              if (observedLabel != null || notice != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _spaced(tokens.spaceTight, [
                    if (observedLabel case final observed?)
                      KText(
                        observed,
                        variant: KTextVariant.caption,
                        style: muted,
                      ),
                    if (notice case final value?)
                      DefaultTextStyle.merge(
                        style: TextStyle(
                          color: tokens.colorTextMuted,
                          fontSize: tokens.fontCaptionSize,
                        ),
                        child: value,
                      ),
                  ]),
                ),
            ]),
          );
        },
      ),
    );
  }
}

class _UsageWindow extends StatelessWidget {
  const _UsageWindow({required this.window});
  final KUsageWindow window;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final progress = window.progress;
    final validProgress =
        progress != null &&
        progress.isFinite &&
        progress >= 0 &&
        progress <= 100;
    final resetCount = window.extraResetCount;
    final resetSemantics = resetCount == 1
        ? '1 zusätzlicher Reset vorhanden'
        : '$resetCount zusätzliche Resets vorhanden';
    final value = Wrap(
      spacing: tokens.spaceControlGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          window.valueLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        if (resetCount != null && resetCount > 0)
          Semantics(
            label: resetSemantics,
            child: Tooltip(
              message: resetSemantics,
              child: ExcludeSemantics(
                child: KBadge(
                  variant: KBadgeVariant.secondary,
                  child: Text('+$resetCount'),
                ),
              ),
            ),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: _spaced(tokens.spaceControlGap, [
        if (validProgress)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: tokens.spaceControlGap,
                runSpacing: tokens.spaceTight,
                children: [Text(window.label), value],
              ),
              SizedBox(height: tokens.componentProgressMetaGap),
              KProgress(value: progress),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: KText(window.label, variant: KTextVariant.bodySmall),
              ),
              value,
            ],
          ),
        if (window.renewalLabel case final renewal?)
          KText(
            '$renewal${window.renewalExact == null ? '' : ' · ${window.renewalExact}'}',
            variant: KTextVariant.caption,
            style: TextStyle(color: tokens.colorTextMuted),
          ),
      ]),
    );
  }
}

class _UsageValues extends StatelessWidget {
  const _UsageValues({required this.values, required this.stacked});
  final List<KUsageValue> values;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _spaced(tokens.spaceControlInsetInline, [
        for (final value in values)
          stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _spaced(tokens.spaceTight, [
                    _label(value.label, tokens),
                    _value(value, tokens, TextAlign.start),
                  ]),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _label(value.label, tokens)),
                    SizedBox(width: tokens.spaceControlInsetInline),
                    Expanded(child: _value(value, tokens, TextAlign.end)),
                  ],
                ),
      ]),
    );
  }

  Widget _label(String label, KDesignTokens tokens) => KText(
    label,
    variant: KTextVariant.bodySmall,
    style: TextStyle(color: tokens.colorTextMuted),
  );

  Widget _value(KUsageValue value, KDesignTokens tokens, TextAlign align) =>
      Column(
        crossAxisAlignment: align == TextAlign.end
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          KText(
            value.valueLabel,
            variant: KTextVariant.bodySmall,
            align: align,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (value.detail case final detail?)
            KText(
              detail,
              variant: KTextVariant.caption,
              align: align,
              style: TextStyle(color: tokens.colorTextMuted),
            ),
        ],
      );
}

List<Widget> _spaced(double gap, List<Widget> children) => [
  for (final (index, child) in children.indexed) ...[
    if (index > 0) SizedBox(height: gap),
    child,
  ],
];

class _ResetDetails extends StatefulWidget {
  const _ResetDetails({required this.label, required this.values});
  final String label;
  final List<KUsageValue> values;
  @override
  State<_ResetDetails> createState() => _ResetDetailsState();
}

class _ResetDetailsState extends State<_ResetDetails> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: _open,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: t.spaceControlGap),
              foregroundColor: t.colorTextPrimary,
              backgroundColor: Colors.transparent,
              overlayColor: Colors.transparent,
              minimumSize: Size(0, t.sizeHitTarget),
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: () => setState(() => _open = !_open),
            child: Row(
              children: [
                Expanded(
                  child: KText(
                    widget.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                KIcon(
                  _open ? KIconName.chevronDown : KIconName.chevronRight,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          for (final value in widget.values)
            Padding(
              padding: EdgeInsets.symmetric(vertical: t.spaceControlGap),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KText(
                          value.label,
                          variant: KTextVariant.bodySmall,
                          style: TextStyle(color: t.colorTextMuted),
                        ),
                        if (value.detail case final detail?)
                          KText(
                            detail,
                            variant: KTextVariant.caption,
                            style: TextStyle(color: t.colorTextMuted),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: t.spaceControlGap),
                  KText(
                    value.valueLabel,
                    variant: KTextVariant.bodySmall,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
