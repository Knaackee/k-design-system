import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'settings_grouped_parts.dart';

// Gallery composition: KButton, KBreadcrumb and KAdaptiveDialog own interactions.
// SettingsGrouped tokens provide the reviewed surfaces, typography and spacing.
// This fixture does not replace app routes or persist any business data.
typedef _Item = ({
  String id,
  String title,
  KIconName icon,
  Color color,
  String description,
  String? value,
});
const _items = <_Item>[
  (
    id: 'customers',
    title: 'Kund:innen',
    icon: KIconName.users,
    color: Color(0xff0c679f),
    description: 'Kontakte, Adressen und Notizen',
    value: '10',
  ),
  (
    id: 'services',
    title: 'Leistungen',
    icon: KIconName.list,
    color: Color(0xff7c3aed),
    description: 'Buchbar mit Preis und Dauer',
    value: '8 aktiv',
  ),
  (
    id: 'categories',
    title: 'Kategorien',
    icon: KIconName.folders,
    color: Color(0xffdb2777),
    description: 'Gruppen und Reihenfolge',
    value: '3',
  ),
  (
    id: 'products',
    title: 'Produkte',
    icon: KIconName.package,
    color: Color(0xffea580c),
    description: 'Waren, Extras und Bestände',
    value: '5',
  ),
  (
    id: 'booking-page',
    title: 'Buchungsseite & QR',
    icon: KIconName.qrCode,
    color: Color(0xff0891b2),
    description: 'Link, Vorschau und QR-Code',
    value: 'Online',
  ),
  (
    id: 'business-profile',
    title: 'Betriebsprofil',
    icon: KIconName.store,
    color: Color(0xff0d9488),
    description: 'Name, Beschreibung und Kontakt',
    value: null,
  ),
  (
    id: 'locations',
    title: 'Standorte & Zeiten',
    icon: KIconName.mapPin,
    color: Color(0xff16a34a),
    description: 'Tagesstart, Tagesende, Ausnahmen',
    value: 'Mo–Fr',
  ),
  (
    id: 'booking-rules',
    title: 'Zonen & Buchungsregeln',
    icon: KIconName.hexagon,
    color: Color(0xffca8a04),
    description: 'Wo und wann man dich buchen kann',
    value: null,
  ),
  (
    id: 'history',
    title: 'Änderungsverlauf',
    icon: KIconName.rotateCcw,
    color: Color(0xff52525b),
    description: 'Änderungen und Veröffentlichungen',
    value: null,
  ),
];
const _groups = <(String, List<String>)>[
  ('Kund:innen & Angebot', ['customers', 'services', 'categories', 'products']),
  ('Auftritt', ['booking-page', 'business-profile']),
  ('Einsatz', ['locations', 'booking-rules']),
  ('Verlauf', ['history']),
];

class ManagementOverviewFixture extends StatefulWidget {
  const ManagementOverviewFixture({
    this.published = true,
    this.empty = false,
    this.longLabels = false,
    this.forceDark = false,
    super.key,
  });
  final bool published, empty, longLabels, forceDark;
  @override
  State<ManagementOverviewFixture> createState() =>
      _ManagementOverviewFixtureState();
}

class _ManagementOverviewFixtureState extends State<ManagementOverviewFixture> {
  String? page;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = settingsGroupedTokens(
      theme.extension<KDesignTokens>()!,
      widget.forceDark || theme.brightness == Brightness.dark,
    );
    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where((e) => e is! KDesignTokens),
          t,
        ],
      ),
      child: Builder(
        builder: (context) => LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 900;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  SizedBox(
                    width: t.layoutPanelWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: t.colorBorderDefault),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: t.spaceControlInsetInline,
                          vertical: t.spaceLayoutSectionGap,
                        ),
                        child: KStack(
                          gap: KLayoutGap.section,
                          align: KLayoutAlign.stretch,
                          children: [
                            const KText(
                              'Verwaltung',
                              variant: KTextVariant.heading3,
                            ),
                            KButton(
                              label: 'Übersicht',
                              fullWidth: true,
                              variant: KButtonVariant.ghost,
                              leading: const KIcon(
                                KIconName.briefcase,
                                size: 19,
                              ),
                              onPressed: () => setState(() => page = null),
                            ),
                            ..._groupWidgets(context, navigation: true),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: t.spaceControlInsetInline * (wide ? 2 : 1),
                      vertical: t.spaceLayoutSectionGap,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: LayoutBuilder(
                          builder: (context, content) => _content(
                            context,
                            wide: wide,
                            tiles: wide && content.maxWidth >= 580,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context, {
    required bool wide,
    required bool tiles,
  }) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final selected = page == null
        ? null
        : _items.firstWhere((i) => i.id == page);
    return KStack(
      gap: KLayoutGap.section,
      align: KLayoutAlign.stretch,
      children: [
        KBreadcrumb(
          label: 'Brotkrümelnavigation',
          items: [
            KBreadcrumbItem(
              id: 'management',
              label: 'Verwaltung',
              onSelect: () => setState(() => page = null),
            ),
            if (selected != null)
              KBreadcrumbItem(id: selected.id, label: selected.title),
          ],
        ),
        if (selected != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: KButton(
              label: 'Zurück zur Verwaltung',
              variant: KButtonVariant.ghost,
              leading: const KIcon(KIconName.arrowLeft),
              onPressed: () => setState(() => page = null),
            ),
          ),
          KText(selected.title, variant: KTextVariant.heading2),
          SgMuted(selected.description),
          const KText(
            'Dieses Navigationsziel ist Teil der Vorschau. In der Anwendung öffnet sich hier der vorhandene Fachbereich.',
          ),
          const KBadge(child: KText('Widgetbook-Vorschau')),
        ] else ...[
          KStack(
            gap: KLayoutGap.control,
            align: KLayoutAlign.stretch,
            children: [
              const KText('Verwaltung', variant: KTextVariant.heading2),
              KText(
                'Alles für deinen Betrieb und deine Buchungen.',
                style: TextStyle(color: t.colorTextMuted),
              ),
            ],
          ),
          _share(context),
          ..._groupWidgets(context, tiles: tiles, desktop: wide),
        ],
      ],
    );
  }

  List<Widget> _groupWidgets(
    BuildContext context, {
    bool navigation = false,
    bool tiles = false,
    bool desktop = false,
  }) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return _groups.map((group) {
      final entries = group.$2
          .map((id) => _items.firstWhere((i) => i.id == id))
          .toList();
      final content = desktop
          ? LayoutBuilder(
              builder: (context, c) => Wrap(
                spacing: t.spaceContentActionGap,
                runSpacing: t.spaceContentActionGap,
                children: [
                  for (var i = 0; i < entries.length; i++)
                    SizedBox(
                      width:
                          tiles &&
                              !(entries.length.isOdd && i == entries.length - 1)
                          ? (c.maxWidth - t.spaceContentActionGap) / 2
                          : c.maxWidth,
                      child: _card(
                        context,
                        _item(context, entries[i], tile: true),
                      ),
                    ),
                ],
              ),
            )
          : _card(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0)
                      Container(
                        height: t.borderWidthDefault,
                        color: t.colorBorderDefault,
                      ),
                    _item(context, entries[i], navigation: navigation),
                  ],
                ],
              ),
            );
      return KStack(
        gap: KLayoutGap.control,
        align: KLayoutAlign.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.spaceControlGap),
            child: KText(
              group.$1,
              variant: KTextVariant.caption,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: t.colorTextMuted,
              ),
            ),
          ),
          content,
        ],
      );
    }).toList();
  }

  Widget _card(BuildContext context, Widget child) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.colorSurfaceRaised,
        borderRadius: BorderRadius.circular(t.radiusCard),
        border: Border.all(color: t.colorBorderDefault),
      ),
      child: child,
    );
  }

  Widget _item(
    BuildContext context,
    _Item item, {
    bool navigation = false,
    bool tile = false,
  }) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final title = widget.longLabels && item.id == 'booking-rules'
        ? 'Buchungsgebiete und individuelle Buchungsbedingungen'
        : item.title;
    final value = item.id == 'booking-page'
        ? (widget.published ? 'Online' : 'Entwurf')
        : widget.empty && item.value != null
        ? '0'
        : item.value;
    final status = value == null
        ? null
        : item.id == 'booking-page'
        ? SgStatus(value, success: widget.published)
        : KText(
            value,
            variant: KTextVariant.caption,
            maxLines: 1,
            style: TextStyle(
              fontSize: navigation ? 11.5 : 13,
              color: t.colorTextMuted,
            ),
          );
    final titleWidget = KText(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: !navigation,
      style: TextStyle(
        fontSize: navigation
            ? 14
            : tile
            ? 16
            : 15.5,
        height: 1.4,
        fontWeight: tile ? FontWeight.w600 : FontWeight.w500,
      ),
    );
    final icon = Container(
      width: 36,
      height: navigation ? 26 : 36,
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(navigation ? 8 : 11),
      ),
      child: Center(
        child: KIcon(
          item.icon,
          size: navigation ? 15 : 19,
          color: Colors.white,
        ),
      ),
    );
    final gap = navigation ? t.spaceControlGap : t.spaceContentActionGap;
    return ColoredBox(
      color: page == item.id
          ? t.colorBrandPrimaryBackground
          : Colors.transparent,
      child: KButton(
        label: '$title${value == null ? '' : ' $value'}',
        fullWidth: true,
        variant: KButtonVariant.ghost,
        paddingInline: navigation
            ? t.spaceControlGap
            : t.spaceControlInsetInline + (tile ? 2 : 0),
        onPressed: () => setState(() => page = item.id),
        content: Padding(
          padding: EdgeInsets.symmetric(
            vertical: navigation
                ? t.spaceControlGap
                : tile
                ? t.spaceControlInsetInline + 2
                : t.spaceContentActionGap,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tile)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: titleWidget),
                          if (status != null) ...[SizedBox(width: gap), status],
                        ],
                      )
                    else
                      titleWidget,
                    if (!navigation) ...[
                      const SizedBox(height: 4),
                      SgMuted(item.description),
                    ],
                  ],
                ),
              ),
              if (!tile && status != null) ...[SizedBox(width: gap), status],
              if (!tile) ...[
                SizedBox(width: gap),
                KIcon(
                  KIconName.chevronRight,
                  size: navigation ? 15 : 18,
                  color: t.colorTextMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _share(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final action = KButton(
      label: widget.published ? 'Teilen' : 'Einrichten',
      leading: KIcon(
        widget.published ? KIconName.share : KIconName.arrowRight,
        size: 17,
      ),
      onPressed: () => widget.published
          ? sgDialog(
              context,
              'Buchungsseite teilen',
              KStack(
                gap: KLayoutGap.action,
                children: [
                  const KText(
                    'In der Anwendung öffnet sich hier der vorhandene Dialog für QR-Code und Teilen.',
                  ),
                  KButton(
                    label: 'Schließen',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            )
          : setState(() => page = 'booking-page'),
    );
    return Container(
      padding: EdgeInsets.all(t.spaceControlInsetInline),
      decoration: BoxDecoration(
        color: t.colorBrandPrimaryBackground,
        borderRadius: BorderRadius.circular(t.radiusCard),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final copy = Row(
            children: [
              Container(
                width: 9,
                height: 9,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.published
                      ? t.colorStatusSuccessForeground
                      : t.colorTextMuted,
                ),
              ),
              SizedBox(width: t.spaceContentActionGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KText(
                      widget.published
                          ? 'Deine Buchungsseite ist online'
                          : 'Deine Buchungsseite ist noch im Entwurf',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SgMuted(
                      widget.published
                          ? '${widget.empty ? '0' : '8'} Leistungen buchbar · Mo–Fr'
                          : 'Schließe die Einrichtung ab, um Buchungen zu erhalten.',
                    ),
                  ],
                ),
              ),
            ],
          );
          if (c.maxWidth < 320) {
            return KStack(
              gap: KLayoutGap.action,
              align: KLayoutAlign.stretch,
              children: [
                copy,
                Align(alignment: Alignment.centerRight, child: action),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              SizedBox(width: t.spaceContentActionGap),
              action,
            ],
          );
        },
      ),
    );
  }
}
