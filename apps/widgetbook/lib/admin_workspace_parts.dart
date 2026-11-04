import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

// Composition: grouped reference cards -> public KButton/Badge/Text/Chart.
// The whole rich KButton content includes the trailing status. Inline actions
// stay siblings, never nested buttons; no fake production actions in this gallery.
class AwBadge extends StatelessWidget {
  const AwBadge(this.value, {super.key});
  final String value;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final variant =
        [
          'Aktiv',
          'Bezahlt',
          'Freigegeben',
          'Eingelöst',
          'Angenommen',
          'Erfolgreich',
          'Stabil',
          'Zugestellt',
        ].contains(value)
        ? KBadgeVariant.success
        : [
            'Gesperrt',
            'Fehlgeschlagen',
            'Abgelehnt',
            'Widerrufen',
            'Gestört',
          ].contains(value)
        ? KBadgeVariant.destructive
        : ['Abgelaufen', 'Verzögert', 'Pausiert', 'Gekündigt'].contains(value)
        ? KBadgeVariant.warning
        : KBadgeVariant.secondary;
    final foreground = switch (variant) {
      KBadgeVariant.success => t.componentBadgeSuccessForeground,
      KBadgeVariant.destructive => t.componentBadgeDestructiveForeground,
      KBadgeVariant.warning => t.componentBadgeWarningForeground,
      _ => t.componentBadgeSecondaryForeground,
    };
    return KBadge(
      variant: variant,
      child: KText(
        value,
        variant: KTextVariant.caption,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class AwCard extends StatelessWidget {
  const AwCard({required this.children, this.inset = false, super.key});
  final List<Widget> children;
  final bool inset;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.colorSurfaceRaised,
        border: Border.all(color: t.colorBorderDefault),
        borderRadius: BorderRadius.circular(t.radiusCard),
      ),
      child: Padding(
        padding: EdgeInsets.all(inset ? t.spaceCardPadding : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0 && !inset)
                Padding(
                  padding: EdgeInsets.only(left: t.spaceCardPadding),
                  child: const KSeparator(),
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class AwGroup extends StatelessWidget {
  const AwGroup(this.title, {required this.child, this.action, super.key});
  final String title;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return KStack(
      gap: KLayoutGap.control,
      align: KLayoutAlign.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: KText(
                title,
                variant: KTextVariant.caption,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: t.colorTextMuted,
                ),
              ),
            ),
            ?action,
          ],
        ),
        child,
      ],
    );
  }
}

class AwRow extends StatelessWidget {
  const AwRow(
    this.title, {
    this.subtitle = '',
    this.avatar,
    this.end,
    this.action,
    this.onTap,
    super.key,
  });
  final String title, subtitle;
  final String? avatar;
  final Widget? end, action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final body = LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: EdgeInsets.symmetric(vertical: t.spaceControlGap),
        child: Row(
          children: [
            if (avatar != null) ...[
              KAvatar(alt: avatar!),
              SizedBox(width: t.spaceContentActionGap),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KText(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle.isNotEmpty)
                    KText(
                      subtitle,
                      variant: KTextVariant.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.colorTextMuted),
                    ),
                ],
              ),
            ),
            if (end != null) ...[
              SizedBox(width: t.spaceControlGap),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * .45,
                ),
                child: end!,
              ),
            ],
          ],
        ),
      ),
    );
    final trigger = onTap == null
        ? Padding(
            padding: EdgeInsets.symmetric(horizontal: t.spaceCardPadding),
            child: body,
          )
        : KButton(
            label: title,
            onPressed: onTap,
            variant: KButtonVariant.ghost,
            fullWidth: true,
            paddingInline: t.spaceCardPadding,
            content: body,
          );
    return action == null
        ? trigger
        : Row(
            children: [
              Expanded(child: trigger),
              Padding(
                padding: EdgeInsets.only(right: t.spaceCardPadding),
                child: action!,
              ),
            ],
          );
  }
}

class AwKeyValues extends StatelessWidget {
  const AwKeyValues(this.values, {super.key});
  final List<(String, Widget)> values;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return AwCard(
      children: [
        for (final v in values)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.spaceCardPadding,
              vertical: t.spaceContentActionGap - t.borderWidthDefault * 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: KText(
                    v.$1,
                    variant: KTextVariant.body,
                    style: TextStyle(color: t.colorTextMuted),
                  ),
                ),
                SizedBox(width: t.spaceControlGap),
                Expanded(
                  flex: 6,
                  child: Align(alignment: Alignment.centerRight, child: v.$2),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class AwKpis extends StatelessWidget {
  const AwKpis(this.items, {super.key});
  final List<(String, String, String)> items;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 700 ? 4 : 2;
        return Column(
          children: [
            for (var start = 0; start < items.length; start += columns) ...[
              if (start > 0) SizedBox(height: t.spaceControlGap),
              _row(context, start, columns),
            ],
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, int start, int columns) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    // Shared natural table tracks align wrapped labels, values and trends.
    // Card surfaces stretch behind the table without fixed text/card heights.
    return Stack(
      children: [
        Positioned.fill(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < columns; i++) ...[
                if (i > 0) SizedBox(width: t.spaceControlGap),
                Expanded(
                  child: start + i < items.length
                      ? const AwCard(children: [])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
        Table(
          columnWidths: {
            for (var i = 0; i < columns * 2 - 1; i++)
              i: i.isOdd
                  ? FixedColumnWidth(t.spaceControlGap)
                  : const FlexColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: [
            for (var track = 0; track < 3; track++)
              TableRow(
                children: [
                  for (var i = 0; i < columns; i++) ...[
                    if (i > 0) const SizedBox.shrink(),
                    start + i < items.length
                        ? _cell(context, items[start + i], track)
                        : const SizedBox.shrink(),
                  ],
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _cell(
    BuildContext context,
    (String, String, String) value,
    int track,
  ) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        t.spaceCardPadding,
        track == 0
            ? t.spaceCardPadding
            : track == 1
            ? t.spaceControlGap
            : 0,
        t.spaceCardPadding,
        track == 2
            ? t.spaceCardPadding
            : track == 1
            ? t.spaceControlGap
            : 0,
      ),
      child: switch (track) {
        0 => KText(
          value.$1,
          variant: KTextVariant.caption,
          style: TextStyle(color: t.colorTextMuted),
        ),
        1 => KText(value.$2, variant: KTextVariant.heading3),
        _ =>
          value.$3.isEmpty
              ? const SizedBox.shrink()
              : KText(
                  '${value.$3}  vs. Vorperiode',
                  variant: KTextVariant.caption,
                  style: TextStyle(
                    color: value.$3.startsWith('-')
                        ? t.colorStatusErrorAccent
                        : t.colorStatusSuccessForeground,
                  ),
                ),
      },
    );
  }
}

class AwCharts extends StatelessWidget {
  const AwCharts({this.days = 30, this.revenue = true, super.key});
  final int days;
  final bool revenue;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final n = days == 7 ? 7 : 15;
    final series = [
      for (var s = 0; s < 2; s++)
        KChartSeries(
          id: '$s',
          label: s == 0 ? 'Aktuell' : 'Vorperiode',
          colorIndex: s,
          points: [
            for (var i = 0; i < n; i++)
              KChartPoint(
                id: '$i',
                x: i.toDouble(),
                y:
                    6 +
                    3 * math.sin(i / 2.3 + s * 2) +
                    i * 6 / n * .4 +
                    ((i * 7 + s * 13) % 5),
              ),
          ],
        ),
    ];
    final x = KChartAxis(
      min: 0,
      max: (n - 1).toDouble(),
      ticks: [0, (n / 2).floorToDouble(), (n - 1).toDouble()],
      format: (v) => '${v.toInt() + 1}',
    );
    final y = KChartAxis(
      min: 0,
      max: 20,
      ticks: [0, 10, 20],
      format: (v) => '${v.toInt()}',
    );
    final line = AwCard(
      inset: true,
      children: [
        KLineChart(
          label: 'Anmeldungen',
          series: series,
          xAxis: x,
          yAxis: y,
          height: 180,
        ),
      ],
    );
    final bars = AwCard(
      inset: true,
      children: [
        KBarChart(
          label: 'Umsatz pro Woche',
          series: [
            KChartSeries(
              id: 'revenue',
              label: 'Umsatz (€)',
              points: [
                for (var i = 0; i < 8; i++)
                  KChartPoint(
                    id: '$i',
                    x: i.toDouble(),
                    y: 700 + 120 * math.sin(i + 2) + i * 35,
                  ),
              ],
            ),
          ],
          xAxis: KChartAxis(
            min: 0,
            max: 7,
            ticks: [0, 3, 7],
            format: (v) => 'KW ${v.toInt() + 36}',
          ),
          yAxis: KChartAxis(
            min: 0,
            max: 1200,
            ticks: [0, 600, 1200],
            format: (v) => '${v.toInt()}',
          ),
          height: 180,
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) => !revenue
          ? line
          : box.maxWidth >= 650
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: line),
                SizedBox(width: t.spaceCardPadding),
                Expanded(child: bars),
              ],
            )
          : KStack(
              gap: KLayoutGap.action,
              align: KLayoutAlign.stretch,
              children: [line, bars],
            ),
    );
  }
}
