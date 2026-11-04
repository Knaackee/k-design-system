part of 'admin_workspace_fixture.dart';

extension _AdminGrowth on _AdminWorkspaceState {
  Widget _growthBars(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    const values = [
      (
        'Quellen',
        [
          ('Ambassadors', 74),
          ('Instagram', 52),
          ('TikTok', 31),
          ('Google', 24),
          ('Direkt', 12),
        ],
      ),
      (
        'Länder',
        [
          ('Deutschland', 141),
          ('Österreich', 27),
          ('Schweiz', 14),
          ('Türkei', 6),
        ],
      ),
      ('Sprachen', [('Deutsch', 166), ('Englisch', 13), ('Türkisch', 9)]),
      ('Plattformen', [('iOS', 96), ('Android', 71), ('Web', 21)]),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 650 ? 2 : 1;
        return Wrap(
          spacing: t.spaceCardPadding,
          runSpacing: t.spaceCardPadding,
          children: [
            for (final group in values)
              SizedBox(
                width:
                    (box.maxWidth - t.spaceCardPadding * (columns - 1)) /
                    columns,
                child: AwCard(
                  inset: true,
                  children: [
                    KText(group.$1, variant: KTextVariant.label),
                    SizedBox(height: t.spaceContentActionGap),
                    for (final v in group.$2)
                      Padding(
                        padding: EdgeInsets.only(bottom: t.spaceControlGap),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: KText(v.$1, variant: KTextVariant.caption),
                            ),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, c) => Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width:
                                        c.maxWidth * v.$2 / group.$2.first.$2,
                                    height: t.spaceControlGap,
                                    decoration: BoxDecoration(
                                      color: t.colorActionPrimaryBackground,
                                      borderRadius: BorderRadius.circular(
                                        t.radiusControl,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: t.spaceControlGap),
                            SizedBox(
                              width: 30,
                              child: KText(
                                '${v.$2}',
                                variant: KTextVariant.caption,
                                align: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
