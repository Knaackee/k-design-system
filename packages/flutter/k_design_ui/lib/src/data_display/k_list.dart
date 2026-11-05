import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../primitives/k_icon.dart';
import '../primitives/k_leading.dart';
import '../primitives/k_text.dart';

/// A grouped list of [KListItem]s with separators (Apple inset-grouped
/// list without its own card: place it inside one [KCard] or directly on a
/// surface, never a card per row).
class KList extends StatelessWidget {
  const KList({required this.children, this.separated = true, super.key});

  final List<Widget> children;

  /// Draws a hairline between rows.
  final bool separated;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (separated && index > 0)
              Divider(
                height: t.spaceHairline,
                thickness: t.spaceHairline,
                color: t.colorBorderDefault,
                indent: t.spaceControlInsetInline,
              ),
            children[index],
          ],
        ],
      ),
    );
  }
}

/// One row of a list: optional leading icon, title, optional description,
/// optional trailing value or control, and a disclosure chevron when it
/// navigates.
///
/// - The leading visual aligns to the first title line (Decision 0010).
/// - Title and description wrap; set [titleMaxLines] to truncate with "…".
/// - The trailing part takes at most half the row and moves under the copy
///   from 1.3× text, so values never squeeze the title.
/// - With [onPressed] the whole row is one button; a trailing control
///   (switch, checkbox) should then be omitted to avoid nested targets.
class KListItem extends StatefulWidget {
  const KListItem({
    required this.title,
    this.description,
    this.leading,
    this.leadingIcon,
    this.trailing,
    this.onPressed,
    this.disclosure,
    this.selected = false,
    this.enabled = true,
    this.titleMaxLines,
    super.key,
  });

  final String title;
  final String? description;

  /// A custom leading visual; it is placed on the first title line.
  final Widget? leading;

  /// Shortcut for a 20 px leading icon.
  final KIconName? leadingIcon;

  /// Value, badge or control at the end of the row.
  final Widget? trailing;
  final VoidCallback? onPressed;

  /// Shows the chevron. Defaults to true when [onPressed] is set.
  final bool? disclosure;
  final bool selected;
  final bool enabled;
  final int? titleMaxLines;

  @override
  State<KListItem> createState() => _KListItemState();
}

class _KListItemState extends State<KListItem> {
  bool _highlighted = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final interactive = widget.onPressed != null && widget.enabled;
    final disclosure = widget.disclosure ?? widget.onPressed != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final muted = !widget.enabled;
    final leadingSize = t.sizeIconDefault;
    final leading =
        widget.leading ??
        (widget.leadingIcon == null
            ? null
            : KIcon(
                widget.leadingIcon!,
                size: leadingSize,
                color: t.colorTextMuted,
              ));
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        KText(
          widget.title,
          variant: KTextVariant.label,
          maxLines: widget.titleMaxLines,
          overflow: widget.titleMaxLines == null ? null : TextOverflow.ellipsis,
          style: muted ? TextStyle(color: t.colorTextMuted) : null,
        ),
        if (widget.description case final description?) ...[
          SizedBox(height: t.spaceTight),
          KText(
            description,
            variant: KTextVariant.bodySmall,
            style: TextStyle(color: t.colorTextMuted),
          ),
        ],
      ],
    );
    final chevron = disclosure
        ? KLeading.icon(
            rtl ? KIconName.chevronLeft : KIconName.chevronRight,
            size: 16,
            textVariant: KTextVariant.label,
            color: t.colorTextMuted,
          )
        : null;
    final row = LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            widget.trailing != null &&
            MediaQuery.textScalerOf(context).scale(1) >= 1.3;
        final gap = t.spaceControlGap;
        final body = stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  copy,
                  SizedBox(height: t.spaceTight),
                  widget.trailing!,
                ],
              )
            : Row(
                children: [
                  Expanded(child: copy),
                  if (widget.trailing case final trailing?) ...[
                    SizedBox(width: gap),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: math.max(0, constraints.maxWidth / 2),
                      ),
                      child: trailing,
                    ),
                  ],
                ],
              );
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: t.sizeHitTarget),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.spaceControlInsetInline,
              vertical: t.spaceControlGap,
            ),
            // Short rows centre in the hit target as a whole; the leading
            // visual and the chevron stay on the first title line.
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    KLeading(
                      size: leadingSize,
                      textVariant: KTextVariant.label,
                      child: leading,
                    ),
                    SizedBox(width: gap),
                  ],
                  Expanded(child: body),
                  if (chevron != null) ...[SizedBox(width: gap), chevron],
                ],
              ),
            ),
          ),
        );
      },
    );
    final background = widget.selected
        ? t.colorActionSecondaryBackground
        : _highlighted
        ? t.colorActionGhostHover
        : Colors.transparent;
    return Semantics(
      button: widget.onPressed != null,
      enabled: widget.enabled,
      selected: widget.selected,
      container: true,
      child: Material(
        color: background,
        child: InkWell(
          onTap: interactive ? widget.onPressed : null,
          onHighlightChanged: (value) => setState(() => _highlighted = value),
          onHover: interactive
              ? (value) => setState(() => _highlighted = value)
              : null,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: t.colorActionGhostHover,
          child: row,
        ),
      ),
    );
  }
}
