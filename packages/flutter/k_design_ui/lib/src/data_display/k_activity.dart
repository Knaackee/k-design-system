import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../overlays/k_overlays.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';

part 'k_activity_grid.dart';

enum KActivityMode { completed, upcoming }

class KActivityItem {
  const KActivityItem({
    required this.id,
    required this.title,
    this.date,
    this.metadata,
    this.leading,
    this.completed,
  });
  final String id, title;
  final DateTime? date;
  final String? metadata;
  final Widget? leading;
  final bool? completed;
}

/// The consumer supplies filtered items and their activity dates/navigation.
class KActivityHeatmap extends StatefulWidget {
  const KActivityHeatmap({
    required this.items,
    required this.mode,
    required this.today,
    required this.onOpenItem,
    this.onAddDate,
    this.addLabel = 'Issue hinzufügen',
    this.phone = false,
    super.key,
  });
  final List<KActivityItem> items;
  final KActivityMode mode;
  final DateTime today;
  final ValueChanged<String> onOpenItem;
  final ValueChanged<DateTime>? onAddDate;
  final String addLabel;
  final bool phone;
  @override
  State<KActivityHeatmap> createState() => _KActivityHeatmapState();
}

class _KActivityHeatmapState extends State<KActivityHeatmap> {
  DateTime? selected;
  int firstMonth = 0, lastMonth = 2;
  final monthKeys = <int, GlobalKey>{};
  KDesignTokens get t => Theme.of(context).extension<KDesignTokens>()!;
  // Matches the Web Activity cell's spacious control size.
  double get touchSize => KDesignTokenVariants.densitySpaciousSizeControl;
  DateTime dateOnly(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
  DateTime get today => dateOnly(widget.today);
  static const months = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];
  String dateLabel(DateTime date) => '${date.day}. ${months[date.month - 1]}';
  List<KActivityItem> rows(DateTime day) => widget.items
      .where((item) => item.date != null && dateOnly(item.date!) == day)
      .toList();
  ({int count, int completed, int open, int level, String summary}) status(
    DateTime day, [
    List<KActivityItem>? dayItems,
  ]) {
    final items = dayItems ?? rows(day);
    final completed = items
        .where(
          (item) => item.completed ?? widget.mode == KActivityMode.completed,
        )
        .length;
    final count = items.length;
    final open = count - completed;
    final level = count == 0
        ? 0
        : count == 1
        ? 1
        : count <= 3
        ? 2
        : count <= 7
        ? 3
        : 4;
    return (
      count: count,
      completed: completed,
      open: open,
      level: level,
      summary: '$count Issues, $open offen, $completed erledigt',
    );
  }

  Color level(int count, int open) {
    if (count == 0) return t.colorSurfaceSubtle;
    final intensity = count == 1
        ? 0.22
        : count <= 3
        ? 0.42
        : count <= 7
        ? 0.68
        : 1.0;
    return Color.lerp(
      t.colorSurfaceCanvas,
      open > 0 ? t.colorStatusWarningAccent : t.colorStatusSuccessAccent,
      intensity,
    )!;
  }

  Widget small(String text) => Text(
    text,
    style: TextStyle(fontSize: t.fontCaptionSize, color: t.colorTextMuted),
  );

  @override
  void didUpdateWidget(KActivityHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) selected = null;
  }

  Future<void> chooseDay(DateTime day, bool mobile) async {
    setState(() => selected = selected == day && !mobile ? null : day);
    if (!mobile) return;
    await KBottomSheet.show<void>(
      context: context,
      title: Text(dateLabel(day)),
      description: Text(
        widget.mode == KActivityMode.completed
            ? 'Abgeschlossene Issues'
            : 'Issues',
      ),
      closeLabel: 'Schließen',
      child: dayItems(day, mobile: true),
    );
    if (mounted) setState(() => selected = null);
  }

  Widget dayItems(DateTime day, {bool mobile = false}) {
    final items = rows(day);
    final dayStatus = status(day);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(alignment: Alignment.centerLeft, child: small(dayStatus.summary)),
        if (widget.onAddDate != null) ...[
          SizedBox(height: t.spaceControlGap),
          KButton(
            label: widget.addLabel,
            onPressed: () => widget.onAddDate!(day),
            fullWidth: mobile,
          ),
        ],
        if (items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: t.spaceLayoutSectionGap),
            child: Text(
              'Keine Issues an diesem Tag.',
              style: TextStyle(color: t.colorTextMuted),
            ),
          ),
        for (final item in items)
          InkWell(
            onTap: () {
              if (mobile) Navigator.of(context).pop();
              widget.onOpenItem(item.id);
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: t.spaceCardPadding),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.colorBorderDefault)),
              ),
              child: Row(
                children: [
                  if (item.leading != null) ...[
                    item.leading!,
                    SizedBox(width: t.spaceControlInsetInline),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: t.fontBodySmallSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: t.spaceCompact),
                        small(item.metadata ?? item.id),
                        if (mobile) small(dateLabel(day)),
                      ],
                    ),
                  ),
                  if (!mobile) small(dateLabel(day)),
                  SizedBox(width: t.spaceControlInsetInline),
                  const KIcon(KIconName.chevronRight),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void loadMonths(bool earlier) {
    final anchor = monthKeys[firstMonth]?.currentContext;
    final top = (anchor?.findRenderObject() as RenderBox?)
        ?.localToGlobal(Offset.zero)
        .dy;
    final position = anchor == null
        ? null
        : Scrollable.maybeOf(anchor)?.position;
    setState(() {
      if (earlier) {
        firstMonth -= 3;
      } else {
        lastMonth += 3;
      }
    });
    if (earlier && top != null && position != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !position.hasPixels) return;
        final next = (anchor?.findRenderObject() as RenderBox?)
            ?.localToGlobal(Offset.zero)
            .dy;
        if (next != null) {
          position.jumpTo(
            (position.pixels + next - top).clamp(
              position.minScrollExtent,
              position.maxScrollExtent,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final mobile = widget.phone || box.maxWidth <= 600;
      final byDay = <DateTime, List<KActivityItem>>{};
      for (final item in widget.items) {
        if (item.date != null) {
          (byDay[dateOnly(item.date!)] ??= []).add(item);
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.items.length} Issues',
            style: TextStyle(
              fontSize: t.fontBodySmallSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: t.sizeSmallControl),
          if (mobile) ...[
            KButton(
              label: 'Frühere Monate laden',
              onPressed: () => loadMonths(true),
              variant: KButtonVariant.ghost,
              fullWidth: true,
            ),
            SizedBox(height: t.spaceLayoutSectionGap - t.spaceControlGap),
            for (var month = firstMonth; month <= lastMonth; month++)
              monthBlock(month, byDay),
            KButton(
              label: 'Weitere Monate laden',
              onPressed: () => loadMonths(false),
              variant: KButtonVariant.ghost,
              fullWidth: true,
            ),
          ] else
            desktop(box.maxWidth, byDay),
          SizedBox(height: t.spaceControlGap),
          Wrap(
            spacing: t.spaceContentActionGap,
            runSpacing: t.spaceControlGap,
            children: [
              small(
                '${widget.mode == KActivityMode.completed ? 'Abschlüsse' : 'Issues'} pro Tag · Heute: ${dateLabel(today)} · Amber: offen · Grün: erledigt',
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  small('Weniger'),
                  for (var i = 0; i <= 4; i++)
                    Container(
                      width: t.spaceBarInline,
                      height: t.spaceBarInline,
                      margin: EdgeInsets.symmetric(horizontal: t.spaceMicro),
                      decoration: BoxDecoration(
                        color: level(i == 0 ? 0 : [1, 3, 7, 8][i - 1], 1),
                        border: Border.all(color: t.colorBorderDefault),
                        borderRadius: BorderRadius.circular(t.radiusSmall),
                      ),
                    ),
                  small('Mehr'),
                ],
              ),
            ],
          ),
          if (!mobile && selected != null) ...[
            SizedBox(height: t.spaceLayoutSectionGap),
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateLabel(selected!),
                    style: TextStyle(
                      fontSize: t.fontHeading5Size,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                KButton(
                  label: 'Schließen',
                  onPressed: () => setState(() => selected = null),
                  variant: KButtonVariant.ghost,
                ),
              ],
            ),
            dayItems(selected!),
          ],
        ],
      );
    },
  );
}
