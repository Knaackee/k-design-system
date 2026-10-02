import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'activity_fixture_data.dart';

Color activityLevelColor(KDesignTokens t, int count) => count == 0
    ? t.colorSurfaceSubtle
    : Color.lerp(
        t.colorSurfaceCanvas,
        t.colorTextPrimary,
        [0.0, .15, .30, .55, 1.0][count.clamp(0, 4)],
      )!;
Widget activitySmall(KDesignTokens t, String text) =>
    Text(text, style: TextStyle(fontSize: 11, color: t.colorTextMuted));
Widget activityDayCell(
  DateTime date,
  double size,
  bool completed,
  bool isSelected,
  int count,
  KDesignTokens t,
  VoidCallback onTap,
) {
  final disabled = completed
      ? date.isAfter(activityToday)
      : date.isBefore(activityToday);
  final label =
      '${activityDateLabel(date)} ${date.year}: $count ${completed ? 'abgeschlossene' : 'anstehende'} Issues';
  return Semantics(
    label: label,
    button: true,
    selected: isSelected,
    enabled: !disabled,
    child: Tooltip(
      message: label,
      child: Opacity(
        opacity: disabled ? .25 : 1,
        child: SizedBox(
          width: size,
          height: size,
          child: Material(
            color: activityLevelColor(t, count),
            borderRadius: BorderRadius.circular(3),
            child: InkWell(
              borderRadius: BorderRadius.circular(3),
              onTap: disabled ? null : onTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: isSelected || date == activityToday
                        ? t.colorTextPrimary
                        : t.colorBorderDefault,
                    width: date == activityToday || isSelected ? 2 : 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget activityIssueRow(
  KDesignTokens t,
  ActivityIssue issue,
  bool mobile,
  VoidCallback onTap,
) => InkWell(
  onTap: onTap,
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: t.colorBorderDefault)),
    ),
    child: Row(
      children: [
        KIcon(
          issue.project == 'Orbit' ? KIconName.rocket : KIconName.code,
          size: 18,
          color: issue.project == 'Orbit'
              ? const Color(0xffE76F51)
              : const Color(0xff2A9D8F),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                issue.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              activitySmall(
                t,
                '${issue.id} · ${issue.project} · ${issue.person}',
              ),
              if (mobile) activitySmall(t, activityDateLabel(issue.date!)),
            ],
          ),
        ),
        if (!mobile) activitySmall(t, activityDateLabel(issue.date!)),
        const SizedBox(width: 12),
        const KIcon(KIconName.chevronRight),
      ],
    ),
  ),
);

Widget activityDesktopRaster(
  double width,
  KDesignTokens t,
  Widget Function(DateTime, double, bool) dayCell,
) {
  final size = ((width - 8 - 25 * 4) / 26).clamp(20.0, 44.0);
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Column(
      children: [
        SizedBox(
          width: 26 * (size + 4) - 4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final month in ['Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'])
                activitySmall(t, month),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var week = 0; week < 26; week++)
              Padding(
                padding: EdgeInsets.only(right: week < 25 ? 4 : 0),
                child: Column(
                  children: [
                    for (var row = 0; row < 7; row++)
                      Padding(
                        padding: EdgeInsets.only(bottom: row < 6 ? 4 : 0),
                        child: dayCell(
                          activityDay(week * 7 + row),
                          size,
                          false,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
