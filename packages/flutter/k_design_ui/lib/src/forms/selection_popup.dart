import '../localization/k_localization.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../primitives/k_icon.dart';
import 'form_style.dart';
import 'k_select.dart';
import 'option_media.dart';

class KSelectionPopup extends StatelessWidget {
  const KSelectionPopup({
    required this.options,
    required this.active,
    required this.value,
    this.truncateLabels = false,
    this.multiple = false,
    this.values = const [],
    required this.maxHeight,
    required this.onActive,
    required this.onSelected,
    required this.optionKeys,
    this.optionsLabel,
    this.noResultsLabel,
    super.key,
  });
  final String? optionsLabel, noResultsLabel;
  final List<KSelectOption> options;
  final int active;
  final String? value;
  final bool multiple;
  final bool truncateLabels;
  final List<String> values;
  bool _selected(String candidate) =>
      multiple ? values.contains(candidate) : value == candidate;
  final double maxHeight;
  final ValueChanged<int> onActive;
  final ValueChanged<KSelectOption> onSelected;
  final Map<String, GlobalKey> optionKeys;
  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    final target = math.max(t.sizeControl, t.sizeHitTarget);
    return Semantics(
      container: true,
      label: optionsLabel ?? KLocalization.of(context).text('options'),
      child: TextFieldTapRegion(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: EdgeInsets.all(t.spaceControlGap),
            decoration: BoxDecoration(
              color: t.colorSurfaceRaised,
              border: Border.all(color: t.colorBorderDefault),
              borderRadius: BorderRadius.circular(t.radiusOverlay),
              boxShadow: t.elevationOverlay,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (options.isEmpty)
                    Container(
                      constraints: BoxConstraints(minHeight: target),
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(
                        horizontal: t.spaceControlInsetInline,
                        vertical: t.spaceControlGap,
                      ),
                      child: Text(
                        noResultsLabel ??
                            KLocalization.of(context).text('noResults'),
                        style: formTextStyle(context, color: t.colorTextMuted),
                      ),
                    ),
                  for (var i = 0; i < options.length; i++)
                    Semantics(
                      key: optionKeys.putIfAbsent(
                        options[i].value,
                        GlobalKey.new,
                      ),
                      selected: _selected(options[i].value),
                      enabled: !options[i].disabled,
                      onTap: options[i].disabled
                          ? null
                          : () => onSelected(options[i]),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: options[i].disabled
                            ? null
                            : () => onSelected(options[i]),
                        child: MouseRegion(
                          cursor: options[i].disabled
                              ? SystemMouseCursors.basic
                              : SystemMouseCursors.click,
                          onEnter: options[i].disabled
                              ? null
                              : (_) => onActive(i),
                          child: Opacity(
                            opacity: options[i].disabled ? .48 : 1,
                            child: Container(
                              constraints: BoxConstraints(minHeight: target),
                              padding: EdgeInsets.symmetric(
                                horizontal: t.spaceControlInsetInline,
                                vertical: t.spaceControlGap,
                              ),
                              decoration: BoxDecoration(
                                color: i == active
                                    ? t.colorActionGhostHover
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  t.radiusControl,
                                ),
                              ),
                              foregroundDecoration: i == active
                                  ? BoxDecoration(
                                      border: Border.all(
                                        color: t.colorBorderFocus,
                                        width: t.borderWidthStrong,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        t.radiusControl,
                                      ),
                                    )
                                  : null,
                              child: Row(
                                children: [
                                  if (options[i].hasMedia) ...[
                                    KOptionMedia(options[i]),
                                    SizedBox(width: t.spaceControlGap),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          options[i].label,
                                          maxLines: truncateLabels ? 1 : null,
                                          overflow: truncateLabels
                                              ? TextOverflow.ellipsis
                                              : null,
                                          style: formTextStyle(context),
                                        ),
                                        if (options[i].description != null)
                                          Text(
                                            options[i].description!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                formTextStyle(
                                                  context,
                                                  color: t.colorTextMuted,
                                                ).copyWith(
                                                  fontSize: t.fontCaptionSize,
                                                  height:
                                                      t.fontCaptionLineHeight /
                                                      t.fontCaptionSize,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (multiple ||
                                      _selected(options[i].value)) ...[
                                    SizedBox(width: t.spaceControlGap),
                                    KIcon(
                                      multiple
                                          ? (_selected(options[i].value)
                                                ? KIconName.squareCheck
                                                : KIconName.square)
                                          : KIconName.check,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
