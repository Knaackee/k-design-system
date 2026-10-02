part of 'k_activity.dart';

extension _ActivityGrid on _KActivityHeatmapState {
  Widget cell(
    DateTime day,
    double size,
    bool mobile,
    Map<DateTime, List<KActivityItem>> byDay,
  ) {
    final dayStatus = status(day, byDay[day]);
    final count = dayStatus.count;
    final outside = widget.mode == KActivityMode.completed
        ? day.isAfter(today)
        : day.isBefore(today);
    final disabled = outside && count == 0;
    final label = '${dateLabel(day)} ${day.year}: ${dayStatus.summary}';
    return Semantics(
      label: label,
      button: true,
      selected: selected == day,
      enabled: !disabled,
      child: Tooltip(
        message: label,
        child: Opacity(
          opacity: disabled ? t.opacityDisabled : 1,
          child: SizedBox(
            width: size,
            height: size,
            child: Material(
              color: level(count, dayStatus.open),
              borderRadius: BorderRadius.circular(t.radiusSmall),
              child: InkWell(
                borderRadius: BorderRadius.circular(t.radiusSmall),
                onTap: disabled ? null : () => chooseDay(day, mobile),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(t.radiusSmall),
                          border: Border.all(
                            color: selected == day || day == today
                                ? t.colorTextPrimary
                                : t.colorBorderDefault,
                            width: selected == day || day == today
                                ? t.borderWidthStrong
                                : t.borderWidthDefault,
                          ),
                        ),
                      ),
                    ),
                    if (count > 0)
                      PositionedDirectional(
                        end: t.spaceMicro,
                        bottom: t.spaceMicro,
                        child: Container(
                          width: t.spaceCompact,
                          height: t.spaceCompact,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dayStatus.open > 0
                                ? Colors.transparent
                                : t.colorTextPrimary,
                            border: Border.all(
                              color: dayStatus.open > 0
                                  ? t.colorTextPrimary
                                  : t.colorSurfaceCanvas,
                              width: dayStatus.open > 0
                                  ? t.borderWidthStrong
                                  : t.borderWidthDefault,
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
      ),
    );
  }

  Widget monthBlock(int offset, Map<DateTime, List<KActivityItem>> byDay) {
    final start = DateTime.utc(today.year, today.month + offset);
    final leading = start.weekday - 1;
    final length = DateTime.utc(start.year, start.month + 1, 0).day;
    const weeks = 6;
    return Container(
      key: monthKeys.putIfAbsent(offset, GlobalKey.new),
      margin: EdgeInsets.only(
        bottom: t.spaceLayoutSectionGap - t.spaceControlGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_KActivityHeatmapState.months[start.month - 1]} ${start.year}',
                  style: TextStyle(
                    fontSize: t.fontHeading5Size,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (offset == 0) small('Aktueller Monat'),
            ],
          ),
          SizedBox(height: t.spaceControlInsetInline),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.spaceControlGap),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    for (final day in [
                      'Mo',
                      'Di',
                      'Mi',
                      'Do',
                      'Fr',
                      'Sa',
                      'So',
                    ])
                      SizedBox(
                        height: touchSize + t.spaceSmallInset,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: small(day),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: t.spaceContentActionGap),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: box.maxWidth.clamp(
                          weeks * touchSize + (weeks - 1) * t.spaceControlGap,
                          weeks * touchSize +
                              (weeks - 1) * t.spaceControlInsetInline,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var week = 0; week < weeks; week++)
                              Column(
                                children: [
                                  for (var row = 0; row < 7; row++)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom: row < 6 ? t.spaceSmallInset : 0,
                                      ),
                                      child:
                                          week * 7 + row < leading ||
                                              week * 7 + row >= leading + length
                                          ? SizedBox(
                                              width: touchSize,
                                              height: touchSize,
                                            )
                                          : cell(
                                              DateTime.utc(
                                                start.year,
                                                start.month,
                                                week * 7 + row - leading + 1,
                                              ),
                                              touchSize,
                                              true,
                                              byDay,
                                            ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget desktop(double width, Map<DateTime, List<KActivityItem>> byDay) {
    final first = today.subtract(Duration(days: today.weekday - 1 + 91));
    final size = ((width - 25 * t.spaceTight) / 26).clamp(
      t.sizeSmallControl,
      touchSize,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var week = 0; week < 26; week++)
                SizedBox(
                  width: size + (week < 25 ? t.spaceTight : 0),
                  height: t.sizeCompact,
                  child: Builder(
                    builder: (_) {
                      final day = first.add(Duration(days: week * 7));
                      final last = day.add(const Duration(days: 6));
                      return day.month != last.month || week == 0
                          ? small(
                              _KActivityHeatmapState.months[last.month - 1]
                                  .substring(0, 3),
                            )
                          : SizedBox();
                    },
                  ),
                ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var week = 0; week < 26; week++)
                Padding(
                  padding: EdgeInsets.only(right: week < 25 ? t.spaceTight : 0),
                  child: Column(
                    children: [
                      for (var row = 0; row < 7; row++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: row < 6 ? t.spaceTight : 0,
                          ),
                          child: cell(
                            first.add(Duration(days: week * 7 + row)),
                            size,
                            false,
                            byDay,
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
}
