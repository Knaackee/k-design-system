import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:k_design_tokens/k_design_tokens.dart';

import '../primitives/k_icon.dart';
import '../primitives/k_leading.dart';
import '../primitives/k_text.dart';
import 'k_title_value_layout.dart';

/// Text roles of list parts per style preset (Decision 0014).
class _KListRoles {
  const _KListRoles(this.title, this.value, this.header, this.uppercaseHeader);
  final KTextVariant title;
  final KTextVariant value;
  final KTextVariant header;
  final bool uppercaseHeader;

  static _KListRoles of(BuildContext context) =>
      switch (KAdaptive.maybeOf(context)?.style ?? KStyle.linear) {
        // iOS: body-size titles and values.
        // iOS 26: sentence-case section headers in the subheadline size.
        KStyle.apple => const _KListRoles(
          KTextVariant.body,
          KTextVariant.body,
          KTextVariant.label,
          false,
        ),
        // Material 3: body-large titles, body-medium values.
        KStyle.material => const _KListRoles(
          KTextVariant.body,
          KTextVariant.bodySmall,
          KTextVariant.label,
          false,
        ),
        // Productivity: medium labels, quieter small values.
        KStyle.linear => const _KListRoles(
          KTextVariant.label,
          KTextVariant.bodySmall,
          KTextVariant.label,
          false,
        ),
      };
}

/// One group of [KListItem]s on its own surface, with an optional section
/// [title] above and [footer] below (inset grouped list).
///
/// The list draws its surface: place it on the page, never inside a card.
/// Stack several lists with `KStack(gap: KLayoutGap.section)` for sections.
/// Separators start at the text of the row above, as in iOS.
class KList extends StatelessWidget {
  const KList({
    required this.children,
    this.title,
    this.footer,
    this.separated = true,
    super.key,
  });

  final List<Widget> children;
  final String? title;
  final String? footer;

  /// Draws a hairline between rows.
  final bool separated;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final roles = _KListRoles.of(context);
    final style = KAdaptive.maybeOf(context)?.style ?? KStyle.linear;
    final apple = style == KStyle.apple;
    // Apple and Material groups are tonal surfaces without an outline.
    final outlined = style == KStyle.linear;
    final radius = BorderRadius.circular(t.componentListGroupRadius);
    Widget aside(String text, {required bool header}) => Padding(
      padding: EdgeInsetsDirectional.only(
        start: t.componentListSectionHeaderInset,
        end: t.componentListSectionHeaderInset,
        bottom: header ? t.componentListSectionHeaderGap : 0,
        top: header ? 0 : t.componentListSectionHeaderGap,
      ),
      child: KText(
        header && roles.uppercaseHeader ? text.toUpperCase() : text,
        variant: header ? roles.header : KTextVariant.caption,
        style: TextStyle(color: t.colorTextMuted),
      ),
    );
    final rows = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      final child = children[index];
      rows.add(child);
      if (separated && index < children.length - 1) {
        final leading =
            child is KListItem &&
            (child.leading != null ||
                child.leadingIcon != null ||
                child.mediaIcon != null);
        rows.add(
          Padding(
            padding: EdgeInsetsDirectional.only(
              start:
                  t.componentListRowPaddingInline +
                  (leading
                      ? (child.mediaIcon != null
                                    ? t.componentListMediaSize
                                    : t.sizeIconDefault) *
                                kIconScale(context) +
                            t.componentListLeadingGap
                      : 0),
            ),
            child: Divider(
              height: t.spaceHairline,
              thickness: t.spaceHairline,
              color: t.colorBorderDefault,
            ),
          ),
        );
      }
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title case final text?) aside(text, header: true),
          _GroupClip(
            radius: radius,
            continuous: apple,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.colorSurfaceRaised,
                borderRadius: radius,
                // iOS groups have no outline; the productivity look does.
                border: !outlined
                    ? null
                    : Border.all(
                        color: t.colorBorderDefault,
                        width: t.spaceHairline,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: rows,
              ),
            ),
          ),
          if (footer case final text?) aside(text, header: false),
        ],
      ),
    );
  }
}

/// Clips a list group; Apple uses continuous (squircle) corners.
class _GroupClip extends StatelessWidget {
  const _GroupClip({
    required this.radius,
    required this.continuous,
    required this.child,
  });
  final BorderRadius radius;
  final bool continuous;
  final Widget child;

  @override
  Widget build(BuildContext context) => continuous
      ? ClipRSuperellipse(borderRadius: radius, child: child)
      : ClipRRect(borderRadius: radius, child: child);
}

/// One row of a [KList]: optional leading icon, title, optional description,
/// optional trailing value, and a chevron when it navigates.
///
/// - Leading icon, chevron and a non-text trailing (badge, dot) sit on the
///   first title line (Decision 0010); text trailing shares the title line.
///   Every row of the same content therefore has the same height.
/// - Title and description wrap; set [titleMaxLines] to truncate with "…".
/// - The trailing part takes at most half the row and moves under the title
///   from 1.3× text.
/// - With [onPressed] the whole row is one button; it then takes no
///   interactive trailing control.
class KListItem extends StatefulWidget {
  const KListItem({
    required this.title,
    this.description,
    this.leading,
    this.leadingIcon,
    this.mediaIcon,
    this.trailing,
    this.value,
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

  /// Shortcut for a leading icon in the default icon size.
  final KIconName? leadingIcon;

  /// An icon on a tonal media tile (an object such as a building or a
  /// folder). The row then centres leading, value and chevron on the copy
  /// block, as iOS and Material do for two-line rows with media.
  final KIconName? mediaIcon;

  /// Non-text trailing content (badge, status dot), centred on the title line.
  final Widget? trailing;

  /// Trailing value text ("12.4 GB"), set in the style's value role.
  final String? value;
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
    final roles = _KListRoles.of(context);
    final interactive = widget.onPressed != null && widget.enabled;
    // Material list rows navigate without a chevron (Android settings).
    final disclosure =
        widget.disclosure ??
        (widget.onPressed != null &&
            KAdaptive.maybeOf(context)?.style != KStyle.material);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    // Leading icons and media tiles grow with the text (Decision 0015).
    final iconScale = kIconScale(context);
    final iconSize = t.sizeIconDefault * iconScale;
    // Height of the first title line, the band everything aligns to.
    final band = math.max(
      0.0,
      KLeading.offsetFor(context, size: 0, textVariant: roles.title) * 2,
    );
    // Media rows centre everything on the copy block; others use the band.
    final media = widget.mediaIcon != null;
    Widget onBand(Widget child) => media
        ? child
        : SizedBox(
            height: band,
            // A badge taller than the line overflows the band evenly instead of
            // pushing the row taller, so rows keep one height.
            child: OverflowBox(
              minHeight: 0,
              maxHeight: double.infinity,
              fit: OverflowBoxFit.deferToChild,
              child: child,
            ),
          );
    final muted = TextStyle(color: t.colorTextMuted);
    final leading =
        widget.leading ??
        (media
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: t.componentListMediaBackground,
                  borderRadius: BorderRadius.circular(
                    t.componentListMediaRadius,
                  ),
                ),
                child: Center(
                  child: KIcon(
                    widget.mediaIcon!,
                    size: t.sizeIconDefault,
                    color: t.componentListMediaForeground,
                  ),
                ),
              )
            : null) ??
        (widget.leadingIcon == null
            ? null
            : KIcon(
                widget.leadingIcon!,
                size: t.sizeIconDefault,
                color: t.colorTextMuted,
              ));
    final value = widget.value == null
        ? null
        : KText(
            widget.value!,
            variant: largeText ? KTextVariant.bodySmall : roles.value,
            style: muted,
          );
    // Material rows show the value as supporting text (Android Settings).
    final stackValue =
        largeText || KAdaptive.maybeOf(context)?.style == KStyle.material;
    final title = KText(
      widget.title,
      variant: roles.title,
      maxLines: widget.titleMaxLines,
      overflow: widget.titleMaxLines == null ? null : TextOverflow.ellipsis,
      style: widget.enabled ? null : muted,
    );
    final description = widget.description == null
        ? null
        : KText(
            widget.description!,
            variant: KTextVariant.bodySmall,
            style: muted,
          );
    final chevron = disclosure
        ? onBand(
            KIcon(
              rtl ? KIconName.chevronLeft : KIconName.chevronRight,
              size: 16,
              color: t.colorTextMuted,
            ),
          )
        : null;
    final row = Row(
      crossAxisAlignment: media
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          onBand(
            SizedBox.square(
              dimension: media
                  ? t.componentListMediaSize * iconScale
                  : iconSize,
              child: leading,
            ),
          ),
          SizedBox(width: t.componentListLeadingGap),
        ],
        Expanded(
          child: Builder(
            builder: (context) {
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  title,
                  if (description != null) ...[
                    SizedBox(height: t.spaceMicro),
                    description,
                  ],
                  // From 1.3× text the badge moves under the title.
                  if (largeText && widget.trailing != null) ...[
                    SizedBox(height: t.spaceMicro),
                    widget.trailing!,
                  ],
                ],
              );
              if (value == null) return copy;
              // Side by side when both fit on one line, else the value
              // moves under the copy; words are never broken (0015).
              return KTitleValueLayout(
                copy: copy,
                value: value,
                gap: t.spaceControlGap,
                stackGap: t.spaceMicro,
                band: band,
                stacked: stackValue,
              );
            },
          ),
        ),
        if (!largeText && widget.trailing != null) ...[
          SizedBox(width: t.spaceControlGap),
          onBand(widget.trailing!),
        ],
        if (chevron != null) ...[SizedBox(width: t.spaceControlGap), chevron],
      ],
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(t.componentListRowMinHeight, t.sizeHitTarget),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: t.componentListRowPaddingInline,
                vertical: t.componentListRowPaddingBlock,
              ),
              // A one-line row centres in the minimum height as a whole.
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: row,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
