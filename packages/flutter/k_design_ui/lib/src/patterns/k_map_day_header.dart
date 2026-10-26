import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/k_icon_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_text.dart';
import 'k_map_day_annotations.dart';
import 'k_map_day_types.dart';

Widget buildKMapDayHeader({
  required KDesignTokens tokens,
  required List<KMapDayItem> items,
  required int currentTime,
  required String dayLabel,
  required String title,
  required bool sheet,
  required KMapDayPanelState state,
  required KMapDayLabels labels,
  required KMapDayTimeFormatter formatTime,
  required bool showCurrentTime,
  required ValueChanged<int> onStep,
  Widget? summary,
}) {
  final current = currentKMapDayItem(items, currentTime);
  return Padding(
    padding: EdgeInsets.fromLTRB(
      tokens.spaceLayoutGutter,
      sheet ? 0 : tokens.spaceLayoutGutter,
      tokens.spaceLayoutGutter,
      tokens.spaceControlGap,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dayLabel.isNotEmpty) ...[
                    KText(
                      dayLabel,
                      variant: KTextVariant.caption,
                      style: TextStyle(color: tokens.colorTextMuted),
                    ),
                    SizedBox(height: tokens.spaceTight),
                  ],
                  KText(title, variant: KTextVariant.heading6),
                ],
              ),
            ),
            if (sheet) ...[
              KIconButton(
                label: labels.smaller,
                icon: KIconName.chevronDown,
                onPressed: state == KMapDayPanelState.compact
                    ? null
                    : () => onStep(-1),
              ),
              KIconButton(
                label: labels.larger,
                icon: KIconName.chevronUp,
                onPressed: state == KMapDayPanelState.expanded
                    ? null
                    : () => onStep(1),
              ),
            ],
          ],
        ),
        if (summary != null) ...[
          SizedBox(height: tokens.spaceTight),
          DefaultTextStyle.merge(
            style: TextStyle(
              color: tokens.colorTextMuted,
              fontFamily: tokens.fontFamily,
              fontSize: tokens.fontBodySmallSize,
              height: tokens.fontBodySmallLineHeight / tokens.fontBodySmallSize,
            ),
            child: summary,
          ),
        ],
        if (showCurrentTime) ...[
          SizedBox(height: tokens.spaceContentActionGap),
          DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.colorStatusInfoBackground,
              borderRadius: BorderRadius.circular(tokens.radiusControl),
            ),
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceControlInsetInline),
              child: Row(
                children: [
                  KIcon(
                    KIconName.clock,
                    size: tokens.sizeContent,
                    color: tokens.colorStatusInfoForeground,
                  ),
                  SizedBox(width: tokens.spaceControlGap),
                  Expanded(
                    child: KText(
                      '${formatTime(currentTime)} · ${labels.now}\n'
                      '${current?.title ?? labels.outside}',
                      variant: KTextVariant.caption,
                      style: TextStyle(color: tokens.colorStatusInfoForeground),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
