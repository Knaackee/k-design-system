import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class IconCatalogFixture extends StatefulWidget {
  const IconCatalogFixture({required this.size, super.key});
  final double size;
  @override
  State<IconCatalogFixture> createState() => _IconCatalogFixtureState();
}

class _IconCatalogFixtureState extends State<IconCatalogFixture> {
  String _query = '';
  int _page = 1;
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final matches = KIconName.values
        .where(
          (icon) => kIconLabels[icon]!.contains(_query.trim().toLowerCase()),
        )
        .toList();
    final pageCount = (matches.length / 96).ceil().clamp(1, 10000);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceLayoutGutter),
      child: KContainer(
        child: KStack(
          align: KLayoutAlign.stretch,
          gap: KLayoutGap.section,
          children: [
            const KText('Shared Lucide icons', variant: KTextVariant.heading4),
            KInline(
              wrap: true,
              gap: KLayoutGap.section,
              align: KLayoutAlign.center,
              children: [
                for (final icon in [
                  KIconName.check,
                  KIconName.x,
                  KIconName.arrowRight,
                  KIconName.info,
                ])
                  KIcon(icon, size: widget.size, label: kIconLabels[icon]),
              ],
            ),
            KInline(
              gap: KLayoutGap.section,
              align: KLayoutAlign.center,
              children: [
                for (final size in [12.0, 16.0, 20.0])
                  KIcon(
                    KIconName.check,
                    size: size,
                    label: 'Check ${size.toInt()}',
                  ),
              ],
            ),
            KSearchField(
              label: 'Search icons',
              placeholder: 'Search all Lucide icons',
              onChanged: (value) => setState(() {
                _query = value;
                _page = 1;
              }),
            ),
            KText(
              '${matches.length} / ${KIconName.values.length} Lucide icons',
              variant: KTextVariant.bodySmall,
            ),
            KGrid(
              minColumnWidth: 48,
              gap: KLayoutGap.control,
              children: [
                for (final icon in matches.skip((_page - 1) * 96).take(96))
                  SizedBox(
                    height: 32,
                    child: Center(
                      child: Tooltip(
                        message: kIconLabels[icon]!,
                        child: KIcon(
                          icon,
                          size: widget.size,
                          label: kIconLabels[icon],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (matches.isEmpty) const KText('No icons found'),
            if (pageCount > 1)
              KPagination(
                page: _page,
                pageCount: pageCount,
                siblingCount: 0,
                onPageChanged: (value) => setState(() => _page = value),
              ),
          ],
        ),
      ),
    );
  }
}
