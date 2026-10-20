import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../primitives/k_text.dart';
import 'k_map_day_types.dart';

KMapDayItem? currentKMapDayItem(List<KMapDayItem> items, int currentTime) {
  for (final item in items) {
    if (currentTime >= item.start && currentTime < item.end) return item;
  }
  return null;
}

Widget buildKMapDayForecast({
  required KDesignTokens tokens,
  required KMapDayItem item,
  required KMapDayLabels labels,
  required KMapDayTimeFormatter formatTime,
}) {
  final difference = item.expectedStart! - item.start;
  return Align(
    alignment: AlignmentDirectional.centerStart,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.colorStatusWarningBackground,
        borderRadius: BorderRadius.circular(tokens.radiusControl),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceHairline * 6,
          vertical: tokens.spaceHairline * 4,
        ),
        child: KText(
          '${labels.expected} ${formatTime(item.expectedStart!)} · '
          '${difference.abs()} ${labels.minutes} '
          '${difference > 0 ? labels.later : labels.earlier}',
          variant: KTextVariant.caption,
          style: TextStyle(color: tokens.colorStatusWarningForeground),
        ),
      ),
    ),
  );
}

Widget buildKMapDayNowLine({
  required KDesignTokens tokens,
  required int currentTime,
  required KMapDayLabels labels,
  required KMapDayTimeFormatter formatTime,
}) => Padding(
  padding: EdgeInsets.only(top: tokens.spaceHairline * 8),
  child: Row(
    children: [
      KText(
        formatTime(currentTime),
        variant: KTextVariant.caption,
        style: TextStyle(
          color: tokens.colorStatusInfoAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(width: tokens.spaceHairline * 6),
      Expanded(
        child: Container(
          height: tokens.spaceHairline * 2,
          color: tokens.colorStatusInfoAccent,
        ),
      ),
      SizedBox(width: tokens.spaceHairline * 6),
      KText(
        labels.now,
        variant: KTextVariant.caption,
        style: TextStyle(
          color: tokens.colorStatusInfoAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
);
