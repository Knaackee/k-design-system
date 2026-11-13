import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_button.dart';
import '../primitives/k_text.dart';

class KBookingThemeChoice {
  const KBookingThemeChoice({
    required this.id,
    required this.label,
    required this.image,
  });
  final String id, label;
  final Widget image;
}

class KBookingThemePicker extends StatefulWidget {
  const KBookingThemePicker({
    required this.options,
    required this.value,
    required this.onChanged,
    this.carousel = false,
    this.footer,
    super.key,
  });
  final List<KBookingThemeChoice> options;
  final String value;
  final ValueChanged<String>? onChanged;
  final bool carousel;
  final Widget? footer;
  @override
  State<KBookingThemePicker> createState() => _KBookingThemePickerState();
}

class _KBookingThemePickerState extends State<KBookingThemePicker> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    Widget tile(KBookingThemeChoice option, double width) => SizedBox(
      width: width,
      child: Semantics(
        button: true,
        selected: option.id == widget.value,
        label: option.label,
        child: InkWell(
          onTap: widget.onChanged == null
              ? null
              : () => widget.onChanged!(option.id),
          borderRadius: BorderRadius.circular(t.radiusCard),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(t.radiusCard),
                  border: Border.all(
                    color: option.id == widget.value
                        ? t.colorActionPrimaryBackground
                        : t.colorBorderDefault,
                    width: option.id == widget.value
                        ? t.borderWidthStrong
                        : t.borderWidthDefault,
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ExcludeSemantics(child: option.image),
                ),
              ),
              SizedBox(height: t.spaceControlGap),
              KText(
                option.label,
                variant: KTextVariant.caption,
                align: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    final selected = widget.options
        .where((o) => o.id == widget.value)
        .firstOrNull;
    final first = widget.options.take(4).toList();
    if (selected != null &&
        !first.any((o) => o.id == widget.value) &&
        first.isNotEmpty) {
      first[first.length - 1] = selected;
    }
    final visible = expanded || widget.carousel ? widget.options : first;
    final expand = KButton(
      label: expanded
          ? 'Weniger anzeigen'
          : 'Alle ${widget.options.length} ansehen',
      variant: KButtonVariant.ghost,
      onPressed: () => setState(() => expanded = !expanded),
    );
    final thumbnails = LayoutBuilder(
      builder: (context, c) {
        final width = widget.carousel
            ? t.componentAvatarPickerTileWidth + t.sizeAvatarLarge
            : (c.maxWidth - 3 * t.spaceControlGap) / 4;
        final tiles = [for (final option in visible) tile(option, width)];
        if (widget.carousel && !expanded) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: t.spaceControlGap,
              children: tiles,
            ),
          );
        }
        return Wrap(
          spacing: t.spaceControlGap,
          runSpacing: t.spaceControlInsetInline,
          children: tiles,
        );
      },
    );
    if (!widget.carousel) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          thumbnails,
          if (widget.options.length > 4)
            Align(alignment: Alignment.centerLeft, child: expand),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: t.componentListSectionHeaderInset,
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: t.spaceControlGap,
            children: [
              const KText('Design', variant: KTextVariant.label),
              if (widget.options.length > 4) expand,
            ],
          ),
        ),
        SizedBox(height: t.componentListSectionHeaderGap),
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.colorSurfaceRaised,
            borderRadius: BorderRadius.circular(t.componentListGroupRadius),
          ),
          child: Padding(
            padding: EdgeInsets.all(t.componentListRowPaddingInline),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                thumbnails,
                if (widget.footer != null) ...[
                  SizedBox(height: t.spaceContentActionGap),
                  widget.footer!,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
