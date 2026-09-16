import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget _frame(BuildContext context, List<Widget> children) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  return SingleChildScrollView(
    padding: EdgeInsets.symmetric(vertical: tokens.spaceLayoutGutter),
    child: KContainer(
      child: KStack(
        align: KLayoutAlign.stretch,
        gap: KLayoutGap.section,
        children: children,
      ),
    ),
  );
}

Widget buildContainerBounds(BuildContext context) => _frame(context, [
  const KText('Contained content', variant: KTextVariant.heading4),
  const KCard(child: KText('Centered content with shared gutters.')),
]);
Widget buildGridResponsive(BuildContext context) {
  final columns = context.knobs.object.dropdown<int>(
    label: 'Columns',
    options: [0, 1, 2, 3, 4, 6],
    initialOption: 0,
    labelBuilder: (n) => n == 0 ? 'Auto' : '$n',
  );
  final minWidth = context.knobs.double.slider(
    label: 'Minimum column width',
    initialValue: 240,
    min: 80,
    max: 400,
    divisions: 16,
  );
  final gap = context.knobs.object.dropdown<KLayoutGap>(
    label: 'Gap',
    options: KLayoutGap.values,
    initialOption: KLayoutGap.section,
    labelBuilder: (gap) => gap.name,
  );
  return _frame(context, [
    const KText('Responsive grid', variant: KTextVariant.heading4),
    KGrid(
      columns: columns == 0 ? null : columns,
      minColumnWidth: minWidth,
      gap: gap,
      children: [
        for (final n in [1, 2, 3, 4]) KCard(child: KText('Item $n')),
      ],
    ),
  ]);
}

Widget buildIconLucide(BuildContext context) {
  final size = context.knobs.object.dropdown<double>(
    label: 'Size',
    options: [12, 16, 20, 24],
    initialOption: 16,
    labelBuilder: (n) => '${n.toInt()}',
  );
  String iconLabel(KIconName name) => name.name.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '-${match[0]!.toLowerCase()}',
  );
  return _frame(context, [
    const KText('Shared Lucide icons', variant: KTextVariant.heading4),
    KInline(
      wrap: true,
      gap: KLayoutGap.section,
      align: KLayoutAlign.center,
      children: [
        KIcon(KIconName.check, label: 'Check', size: size),
        KIcon(KIconName.x, label: 'Close', size: size),
        KIcon(KIconName.arrowRight, label: 'Next', size: size),
        KIcon(KIconName.info, label: 'Information', size: size),
      ],
    ),
    KInline(
      gap: KLayoutGap.section,
      align: KLayoutAlign.center,
      children: [
        for (final n in [12.0, 16.0, 20.0])
          KIcon(KIconName.check, size: n, label: 'Check ${n.toInt()}'),
      ],
    ),
    KText(
      '${KIconName.values.length} Lucide icons',
      variant: KTextVariant.bodySmall,
    ),
    KGrid(
      minColumnWidth: 48,
      gap: KLayoutGap.control,
      children: [
        for (final name in KIconName.values)
          SizedBox(
            height: 32,
            child: Center(
              child: Tooltip(
                message: iconLabel(name),
                child: KIcon(name, size: size, label: iconLabel(name)),
              ),
            ),
          ),
      ],
    ),
  ]);
}

Widget buildSeparatorOrientations(BuildContext context) => _frame(context, [
  const KText('Separators', variant: KTextVariant.heading4),
  const KText('Above the line'),
  const KSeparator(),
  const KInline(
    gap: KLayoutGap.section,
    align: KLayoutAlign.center,
    children: [
      KText('First'),
      KSeparator(orientation: KSeparatorOrientation.vertical, length: 48),
      KText('Second'),
    ],
  ),
  const Align(
    alignment: AlignmentDirectional.centerStart,
    child: KSeparator(length: 120),
  ),
  const KText('Below the line'),
]);
