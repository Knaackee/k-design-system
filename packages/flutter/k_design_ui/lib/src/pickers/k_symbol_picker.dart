import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent, MatrixUtils;
import 'dart:convert';

import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../forms/k_input.dart';
import '../actions/action_control.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_surface.dart';
import '../primitives/k_text.dart';
import '../generated/k_emoji.g.dart' as data;
import '../generated/k_emoji_rasters.g.dart' as rasters;
part 'symbol_picker_vector.dart';
part 'symbol_picker_panel.dart';
part 'symbol_picker_anchor.dart';

class KSymbolItem {
  const KSymbolItem({
    required this.id,
    required this.label,
    required this.category,
    this.keywords = const [],
    this.disabled = false,
    this.icon,
    this.value,
    this.svg,
    this.tones = const [],
  });
  final String id, label, category;
  final List<String> keywords;
  final bool disabled;
  final KIconName? icon;
  final String? value, svg;
  final List<KEmojiTone> tones;
  KSymbolItem withTone(int tone) {
    if (tone < 1 || tone > tones.length) return this;
    return KSymbolItem(
      id: id,
      label: label,
      category: category,
      keywords: keywords,
      disabled: disabled,
      icon: icon,
      value: tones[tone - 1].value,
      svg: tones[tone - 1].svg,
      tones: tones,
    );
  }
}

class KEmojiTone {
  const KEmojiTone(this.value, this.svg);
  final String value, svg;
}

final kDefaultIconItems = List<KSymbolItem>.unmodifiable(
  KIconName.values.map((name) {
    final id = name.name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '-${m[0]!.toLowerCase()}',
    );
    return KSymbolItem(
      id: id,
      label: id.replaceAll('-', ' '),
      category: 'Lucide',
      icon: name,
    );
  }),
);
final kEmojiCatalog = List<KSymbolItem>.unmodifiable(
  data.kEmojiCatalog.map(
    (item) => KSymbolItem(
      id: item['id'] as String,
      label: item['label'] as String,
      category: item['category'] as String,
      value: item['value'] as String,
      svg: item['svg'] as String,
      keywords: (item['keywords'] as List).cast<String>(),
      tones: (item['tones'] as List)
          .map((t) => KEmojiTone(t['value'] as String, t['svg'] as String))
          .toList(),
    ),
  ),
);

class KSymbolPickerLabels {
  const KSymbolPickerLabels({
    this.search = 'Search',
    this.searchPlaceholder,
    this.clearSearch,
    this.all = 'All',
    this.recent = 'Recent',
    this.empty = 'No matches',
    this.hint = 'Choose a symbol',
    this.skinTone = 'Skin tone',
    this.tones = const [
      'Default',
      'Light',
      'Medium light',
      'Medium',
      'Medium dark',
      'Dark',
    ],
  });
  final String search, all, recent, empty, hint, skinTone;
  final String? searchPlaceholder, clearSearch;
  final List<String> tones;
}

typedef KSymbolItemBuilder =
    Widget Function(BuildContext context, KSymbolItem item);

/// Button with an anchored picker. Consumers own selection and persistence.
class KIconPicker extends StatelessWidget {
  const KIconPicker({
    required this.onSelect,
    this.items,
    this.value,
    this.recentIds = const [],
    this.labels = const KSymbolPickerLabels(),
    this.categoryLabels = const {},
    this.itemBuilder,
    this.enabled = true,
    this.onDismiss,
    this.width = 352,
    this.height = 420,
    this.triggerLabel,
    this.triggerContent,
    this.open,
    this.onOpenChange,
    super.key,
  });
  final ValueChanged<KSymbolItem> onSelect;
  final List<KSymbolItem>? items;
  final String? value;
  final List<String> recentIds;
  final KSymbolPickerLabels labels;
  final Map<String, String> categoryLabels;
  final KSymbolItemBuilder? itemBuilder;
  final bool enabled;
  final VoidCallback? onDismiss;
  final double width, height;
  final String? triggerLabel;
  final Widget? triggerContent;
  final bool? open;
  final ValueChanged<bool>? onOpenChange;
  @override
  Widget build(BuildContext context) => _SymbolPickerAnchor(
    label: triggerLabel ?? 'Choose icon',
    icon: KIconName.star,
    width: width,
    height: height,
    enabled: enabled,
    open: open,
    onOpenChange: onOpenChange,
    triggerContent: triggerContent,
    builder: (close, searchFocus) => _SymbolPicker(
      searchFocus: searchFocus,
      items: items ?? kDefaultIconItems,
      onSelect: (item) {
        onSelect(item);
        close();
      },
      value: value,
      recentIds: recentIds,
      labels: labels,
      categoryLabels: categoryLabels,
      itemBuilder: itemBuilder ?? (_, item) => KIcon(item.icon!, size: 20),
      enabled: enabled,
      onDismiss: () {
        close();
        onDismiss?.call();
      },
      width: width.clamp(0, MediaQuery.sizeOf(context).width - 16),
      height: height.clamp(160, MediaQuery.sizeOf(context).height - 16),
    ),
  );
}

class KEmojiPicker extends StatefulWidget {
  const KEmojiPicker({
    required this.onSelect,
    this.items,
    this.value,
    this.recentIds = const [],
    this.labels = const KSymbolPickerLabels(),
    this.categoryLabels = const {},
    this.itemBuilder,
    this.enabled = true,
    this.onDismiss,
    this.width = 352,
    this.height = 420,
    this.triggerLabel,
    this.triggerContent,
    this.open,
    this.onOpenChange,
    this.skinTone,
    this.onSkinToneChange,
    super.key,
  });
  final ValueChanged<KSymbolItem> onSelect;
  final List<KSymbolItem>? items;
  final String? value;
  final List<String> recentIds;
  final KSymbolPickerLabels labels;
  final Map<String, String> categoryLabels;
  final KSymbolItemBuilder? itemBuilder;
  final bool enabled;
  final VoidCallback? onDismiss;
  final double width, height;
  final String? triggerLabel;
  final Widget? triggerContent;
  final bool? open;
  final ValueChanged<bool>? onOpenChange;
  final int? skinTone;
  final ValueChanged<int>? onSkinToneChange;
  @override
  State<KEmojiPicker> createState() => _KEmojiPickerState();
}

class _KEmojiPickerState extends State<KEmojiPicker> {
  int _tone = 0;
  @override
  Widget build(BuildContext context) {
    final tone = (widget.skinTone ?? _tone).clamp(0, 5);
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return _SymbolPickerAnchor(
      label: widget.triggerLabel ?? 'Choose emoji',
      icon: KIconName.heart,
      width: widget.width,
      height: widget.height,
      enabled: widget.enabled,
      open: widget.open,
      onOpenChange: widget.onOpenChange,
      triggerContent: widget.triggerContent,
      builder: (close, searchFocus) => _SymbolPicker(
        searchFocus: searchFocus,
        items: widget.items ?? kEmojiCatalog,
        onSelect: (item) {
          widget.onSelect(item.withTone(tone));
          close();
        },
        value: widget.value,
        recentIds: widget.recentIds,
        labels: widget.labels,
        categoryLabels: widget.categoryLabels,
        enabled: widget.enabled,
        onDismiss: () {
          close();
          widget.onDismiss?.call();
        },
        width: widget.width.clamp(0, MediaQuery.sizeOf(context).width - 16),
        height: widget.height.clamp(
          160,
          MediaQuery.sizeOf(context).height - 16,
        ),
        itemBuilder: (context, item) =>
            widget.itemBuilder?.call(context, item.withTone(tone)) ??
            _emojiPicture(item.withTone(tone)),
        accessory: Container(
          width: 112,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: tokens.colorSurfaceSubtle,
            border: Border.all(color: tokens.colorBorderDefault),
            borderRadius: BorderRadius.circular(tokens.radiusSmall),
          ),
          child: Semantics(
            label: widget.labels.skinTone,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: tone,
                isExpanded: true,
                hint: Text(widget.labels.skinTone),
                items: List.generate(
                  6,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: KText(
                      widget.labels.tones[i],
                      variant: KTextVariant.bodySmall,
                      maxLines: 1,
                    ),
                  ),
                ),
                onChanged: widget.enabled
                    ? (next) {
                        if (next == null) return;
                        if (widget.skinTone == null) {
                          setState(() => _tone = next);
                        }
                        widget.onSkinToneChange?.call(next);
                      }
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
