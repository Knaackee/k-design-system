part of 'k_offer_overview.dart';

extension _OfferOverviewControls on _KOfferOverviewState {
  Widget _newButton(KDesignTokens t) => KMenuButton(
    label: _t('Neu'),
    disabled: !widget.enabled,
    actions: widget.newActions,
    triggerContent: Container(
      height: t.sizeControl,
      padding: EdgeInsets.symmetric(horizontal: t.spaceControlInsetInline),
      decoration: BoxDecoration(
        color: t.colorActionPrimaryBackground,
        borderRadius: BorderRadius.circular(t.radiusControl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KIcon(
            KIconName.plus,
            size: 18,
            color: t.colorActionPrimaryForeground,
          ),
          SizedBox(width: t.spaceControlGap),
          Text(
            _t('Neu'),
            style: TextStyle(
              color: t.colorActionPrimaryForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _filters(List<KOfferEntry> entries, KDesignTokens t) => Theme(
    data: Theme.of(context).copyWith(
      extensions: [
        ...Theme.of(
          context,
        ).extensions.values.where((e) => e is! KDesignTokens),
        t.copyWith(
          radiusControl: t.radiusFull,
          fontControlSize: t.fontControlSize,
          fontControlWeight: FontWeight.w600,
          colorActionPrimaryBackground: t.colorTextPrimary,
          colorActionPrimaryForeground: t.colorSurfaceCanvas,
        ),
      ],
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in const [
            ('all', 'Alle'),
            ('service', 'Leistungen'),
            ('product', 'Produkte'),
            ('archived', 'Archiviert'),
          ])
            Padding(
              padding: EdgeInsets.only(right: t.spaceControlGap),
              child: KButton(
                label: item.$1 == 'all'
                    ? _t(item.$2)
                    : '${_t(item.$2)} · ${entries.where((e) => item.$1 == 'archived' ? e.archived : !e.archived && e.kind == item.$1).length}',
                variant: _filter == item.$1
                    ? KButtonVariant.primary
                    : KButtonVariant.secondary,
                onPressed: () => _selectFilter(item.$1),
              ),
            ),
        ],
      ),
    ),
  );
  Widget _hint(KDesignTokens t) => Container(
    padding: EdgeInsets.all(t.spaceContentActionGap),
    decoration: BoxDecoration(
      color: t.colorBrandPrimaryBackground,
      borderRadius: BorderRadius.circular(t.radiusCard),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        KIcon(KIconName.hand, size: 22, color: t.colorBrandPrimaryForeground),
        SizedBox(width: t.spaceContentActionGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KText(
                _t('Halten und ziehen zum Sortieren'),
                style: TextStyle(
                  fontSize: t.fontBodySize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              KText(
                _t('Leistungen, Produkte und Kategorien frei anordnen.'),
                variant: KTextVariant.caption,
                style: TextStyle(
                  color: t.colorTextMuted,
                  fontSize: t.fontBodySize,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
