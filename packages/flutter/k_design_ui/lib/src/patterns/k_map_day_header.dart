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
      tokens.spaceHairline * (sheet ? 20 : 24),
      tokens.spaceHairline * (sheet ? 0 : 24),
      tokens.spaceHairline * (sheet ? 20 : 24),
      tokens.spaceHairline * (sheet ? 12 : 16),
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
                  KText(
                    dayLabel,
                    variant: KTextVariant.bodySmall,
                    style: TextStyle(color: tokens.colorTextMuted),
                  ),
                  SizedBox(height: tokens.spaceHairline * 5),
                  KText(
                    title,
                    variant: KTextVariant.heading3,
                    style: TextStyle(
                      fontSize:
                          tokens.fontBodySize * (sheet ? 21 / 14 : 23 / 14),
                      letterSpacing: tokens.spaceHairline * -.6,
                    ),
                  ),
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
          SizedBox(height: tokens.spaceHairline * 8),
          DefaultTextStyle.merge(
            style: TextStyle(
              color: tokens.colorTextMuted,
              fontFamily: tokens.fontFamily,
              fontSize: tokens.fontCaptionSize,
            ),
            child: summary,
          ),
        ],
        if (showCurrentTime) ...[
          SizedBox(height: tokens.spaceHairline * 18),
          DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.colorStatusInfoBackground,
              borderRadius: BorderRadius.circular(tokens.radiusControl),
            ),
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceHairline * 12),
              child: Row(
                children: [
                  KIcon(
                    KIconName.clock,
                    size: 16,
                    color: tokens.colorStatusInfoForeground,
                  ),
                  SizedBox(width: tokens.spaceHairline * 12),
                  Expanded(
                    child: KText(
                      '${formatTime(currentTime)} · ${labels.now}\n'
                      '${current?.title ?? labels.outside}',
                      variant: KTextVariant.caption,
                      style: TextStyle(
                        color: tokens.colorStatusInfoForeground,
                        height: tokens.spaceHairline * 1.6,
                      ),
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
