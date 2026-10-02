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
  });
  final String id, title;
  final DateTime? date;
  final String? metadata;
  final Widget? leading;
}

/// The consumer supplies filtered items and their activity dates/navigation.
class KActivityHeatmap extends StatefulWidget {
  const KActivityHeatmap({
    required this.items,
    required this.mode,
    required this.today,
    required this.onOpenItem,
    this.phone = false,
    super.key,
  });
  final List<KActivityItem> items;
  final KActivityMode mode;
  final DateTime today;
  final ValueChanged<String> onOpenItem;
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
  Color level(int count) => count == 0
      ? t.colorSurfaceSubtle
      : Color.lerp(
          t.colorSurfaceCanvas,
          t.colorTextPrimary,
          [
            0.0,
            t.opacityFaint,
            t.opacityMedium,
            t.opacityInteractiveHover,
            1.0,
          ][count.clamp(0, 4)],
        )!;
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
      final counts = <DateTime, int>{};
      for (final item in widget.items) {
        if (item.date != null) {
          final day = dateOnly(item.date!);
          counts[day] = (counts[day] ?? 0) + 1;
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
              monthBlock(month, counts),
            KButton(
              label: 'Weitere Monate laden',
              onPressed: () => loadMonths(false),
              variant: KButtonVariant.ghost,
              fullWidth: true,
            ),
          ] else
            desktop(box.maxWidth, counts),
          SizedBox(height: t.spaceControlGap),
          Wrap(
            spacing: t.spaceContentActionGap,
            runSpacing: t.spaceControlGap,
            children: [
              small(
                '${widget.mode == KActivityMode.completed ? 'Abschlüsse' : 'Issues'} pro Tag · Heute: ${dateLabel(today)}',
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
                        color: level(i),
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
