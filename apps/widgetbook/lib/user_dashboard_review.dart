import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/k_map.dart';
import 'package:k_design_ui/k_map_style.dart';

part 'user_dashboard_review_sections.dart';

/// Synthetic gallery composition matching Review/UserDashboard in Storybook.
/// No account, booking or notification is changed by any gallery action.
class UserDashboardReview extends StatefulWidget {
  const UserDashboardReview({this.scenario = 'full', super.key});
  final String scenario;
  @override
  State<UserDashboardReview> createState() => _UserDashboardReviewState();
}

class _UserDashboardReviewState extends State<UserDashboardReview> {
  int period = 30;
  String notice = '';
  bool lastMinute = false;
  final requests = <int>[0, 1];
  final steps = <bool>[true, true, true, false, false, false];
  final tips = <bool>[true, false, false, false];
  late KDesignTokens t;
  bool wide = false;
  bool get free => widget.scenario == 'free';
  Color get brand => t.colorActionPrimaryBackground;
  Color get success => t.colorStatusSuccessForeground;
  void updateState(VoidCallback change) => setState(change);
  void feedback(String value) =>
      setState(() => notice = 'Designvorschau: $value');

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final dark = base.brightness == Brightness.dark;
    final source = base.extension<KDesignTokens>()!;
    final tokens = source.copyWith(
      radiusCard: 20,
      spaceCardPadding: 16,
      spaceContentActionGap: 14,
      spaceControlGap: 8,
      spaceLayoutSectionGap: 22,
      fontBodySize: 15,
      fontBodyLineHeight: 22.5,
      fontBodySmallSize: 13,
      fontBodySmallLineHeight: 18.85,
      fontHeading4Size: 16,
      fontHeading4LineHeight: 22.4,
      fontHeadingWeight: FontWeight.w600,
      fontLabelWeight: FontWeight.w600,
      colorSurfaceCanvas: Color(dark ? 0xff09090b : 0xfff4f4f5),
      colorSurfaceRaised: Color(dark ? 0xff18181b : 0xffffffff),
      colorSurfaceSubtle: const Color(
        0xff27272a,
      ).withValues(alpha: dark ? 1 : .04),
      colorTextPrimary: Color(dark ? 0xfffafafa : 0xff18181b),
      colorTextMuted: Color(dark ? 0xffa1a1aa : 0xff52525b),
      colorBorderDefault: Color(dark ? 0xff27272a : 0xffe4e4e7),
      colorActionPrimaryBackground: Color(dark ? 0xff7ac1f2 : 0xff0c679f),
      colorActionPrimaryForeground: Color(dark ? 0xff082f49 : 0xffffffff),
      colorActionSecondaryBackground: Color(dark ? 0xff27272a : 0xfff4f4f5),
      colorActionSecondaryForeground: Color(dark ? 0xfffafafa : 0xff18181b),
      colorActionGhostForeground: Color(dark ? 0xfffafafa : 0xff18181b),
      colorStatusSuccessForeground: Color(dark ? 0xff34d399 : 0xff047857),
    );
    return Theme(
      data: base.copyWith(
        extensions: [
          ...base.extensions.values.where((e) => e is! KDesignTokens),
          tokens,
        ],
      ),
      child: Builder(
        builder: (context) {
          t = Theme.of(context).extension<KDesignTokens>()!;
          return ColoredBox(
            color: t.colorSurfaceCanvas,
            child: LayoutBuilder(
              builder: (context, outer) {
                final mobile = outer.maxWidth < 600;
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1128),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: mobile
                              ? t.spaceCardPadding
                              : t.spaceLayoutGutter,
                          vertical: mobile ? t.spaceLayoutGutter : 32,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            wide = constraints.maxWidth >= 900;
                            return KStack(
                              gap: KLayoutGap.section,
                              align: KLayoutAlign.stretch,
                              children: [
                                header(),
                                if (widget.scenario == 'fresh')
                                  setup()
                                else if (widget.scenario == 'ready')
                                  ready()
                                else ...[
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: KInline(
                                      gap: KLayoutGap.control,
                                      children: [
                                        button('Termin', icon: KIconName.plus),
                                        button(
                                          'Seite teilen',
                                          icon: KIconName.share,
                                          secondary: true,
                                        ),
                                        button(
                                          'QR-Code',
                                          icon: KIconName.qrCode,
                                          secondary: true,
                                        ),
                                        button(
                                          'Kund:in',
                                          icon: KIconName.users,
                                          secondary: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (wide)
                                    columns(
                                      stack([
                                        if (free) ...quiet() else today(),
                                        requestList(),
                                      ]),
                                      next(),
                                    )
                                  else ...[
                                    next(),
                                    if (free) ...quiet() else today(),
                                    requestList(),
                                  ],
                                  metrics(),
                                  columns(
                                    stack([revenue(), week()]),
                                    stack([
                                      customers(),
                                      if (!free) services(),
                                      share(),
                                    ]),
                                  ),
                                ],
                                Center(
                                  child: muted(
                                    'Interaktive Designvorschau · synthetische Daten · keine echten Aktionen',
                                  ),
                                ),
                                if (notice.isNotEmpty)
                                  box(
                                    child: Row(
                                      children: [
                                        KIcon(
                                          KIconName.check,
                                          color: success,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: muted(notice)),
                                        KIconButton(
                                          label: 'Hinweis schließen',
                                          icon: KIconName.x,
                                          onPressed: () =>
                                              setState(() => notice = ''),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget header() {
    final fresh = widget.scenario == 'fresh';
    final remaining = steps.indexed.where((e) => e.$1 != 4 && !e.$2).length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: KStack(
            gap: KLayoutGap.control,
            align: KLayoutAlign.stretch,
            children: [
              KText(
                fresh ? 'Willkommen, Denis.' : 'Guten Abend, Denis.',
                variant: KTextVariant.heading1,
                style: TextStyle(
                  fontSize: wide ? 36 : 30,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),
              KText(
                fresh
                    ? (remaining == 0
                          ? 'Alles erledigt – bereit für deine erste Buchung.'
                          : 'Noch $remaining ${remaining == 1 ? 'Schritt' : 'Schritte'} bis zur ersten Buchung.')
                    : 'Mittwoch, 4. November${widget.scenario == 'full'
                          ? ' · 4 Termine heute'
                          : widget.scenario == 'ready'
                          ? ' · Deine Seite ist seit 6 Tagen online'
                          : ''}',
                style: TextStyle(color: t.colorTextMuted),
              ),
            ],
          ),
        ),
        if (!fresh)
          KIconButton(
            label: 'Assistent',
            icon: KIconName.sparkles,
            onPressed: () => feedback('Assistent öffnen'),
          ),
      ],
    );
  }

  Widget stack(List<Widget> children) => KStack(
    gap: KLayoutGap.section,
    align: KLayoutAlign.stretch,
    children: children,
  );
  Widget columns(Widget left, Widget right) => wide
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 8, child: left),
            SizedBox(width: t.spaceLayoutSectionGap),
            Expanded(flex: 5, child: right),
          ],
        )
      : stack([left, right]);
  Widget muted(String value) => KText(
    value,
    variant: KTextVariant.bodySmall,
    style: TextStyle(color: t.colorTextMuted),
  );
  Widget copy(String title, String subtitle, {bool wrap = false}) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      KText(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      KText(
        subtitle,
        variant: KTextVariant.bodySmall,
        maxLines: wrap ? null : 1,
        overflow: wrap ? null : TextOverflow.ellipsis,
        style: TextStyle(color: t.colorTextMuted),
      ),
    ],
  );
  Widget button(
    String label, {
    KIconName? icon,
    bool secondary = false,
    bool disabled = false,
    VoidCallback? onPressed,
  }) => KButton(
    label: label,
    leading: icon == null ? null : KIcon(icon, size: 16),
    variant: secondary ? KButtonVariant.secondary : KButtonVariant.primary,
    onPressed: disabled
        ? null
        : onPressed ?? () => feedback('$label – nur Vorschau'),
  );
  Widget link(String label) => KButton(
    label: label,
    variant: KButtonVariant.ghost,
    paddingInline: 0,
    onPressed: () => feedback('$label öffnen'),
  );
  Widget box({String? title, Widget? end, required Widget child}) => KCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Row(
            children: [
              Expanded(child: KText(title, variant: KTextVariant.heading4)),
              ?end,
            ],
          ),
          SizedBox(height: t.spaceContentActionGap),
        ],
        child,
      ],
    ),
  );
  Widget avatar(String name, [int index = 0]) {
    const colors = [
      Color(0xff0c679f),
      Color(0xff7c3aed),
      Color(0xffdb2777),
      Color(0xffea580c),
      Color(0xff0d9488),
    ];
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where((e) => e is! KDesignTokens),
          t.copyWith(
            colorSurfaceSubtle: colors[index % colors.length],
            colorTextPrimary: Colors.white,
            componentAvatarSizeMedium: 38,
          ),
        ],
      ),
      child: KAvatar(alt: name),
    );
  }

  Widget row({
    required Widget child,
    Widget? leading,
    Widget? trailing,
    bool divider = false,
    CrossAxisAlignment alignment = CrossAxisAlignment.center,
  }) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      border: divider
          ? Border(top: BorderSide(color: t.colorBorderDefault))
          : null,
    ),
    child: Row(
      crossAxisAlignment: alignment,
      children: [
        if (leading != null) ...[
          leading,
          SizedBox(width: t.spaceContentActionGap),
        ],
        Expanded(child: child),
        if (trailing != null) ...[SizedBox(width: t.spaceControlGap), trailing],
      ],
    ),
  );
  Widget actions(Widget left, Widget right) => Row(
    children: [
      Expanded(child: left),
      SizedBox(width: t.spaceControlGap),
      Expanded(child: right),
    ],
  );

  static const points = [
    KMapCenter(longitude: 12.3748, latitude: 51.3405),
    KMapCenter(longitude: 12.3749, latitude: 51.3394),
    KMapCenter(longitude: 12.3754, latitude: 51.3386),
    KMapCenter(longitude: 12.3763, latitude: 51.3377),
    KMapCenter(longitude: 12.3771, latitude: 51.3368),
    KMapCenter(longitude: 12.3774, latitude: 51.3356),
  ];
  Widget next() => ClipRRect(
    borderRadius: BorderRadius.circular(t.radiusCard),
    child: KSurface(
      tone: KSurfaceTone.raised,
      radius: KSurfaceRadius.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 96,
            child: KMap(
              mapStyle: jsonEncode(createKMapStyle(tokens: t)),
              center: points.first,
              label: 'Beispielroute zum nächsten Termin',
              interactive: false,
              showZoomControls: false,
              fitContent: true,
              fitContentPadding: const EdgeInsets.fromLTRB(24, 48, 24, 12),
              routes: [
                KMapRoute(id: 'next', coordinates: points, color: brand),
              ],
              pins: [
                KMapPin(
                  id: 'previous',
                  position: points.first,
                  label: 'Vorherige Station',
                  icon: KIconName.check,
                  shape: KMapPinShape.circle,
                  color: brand,
                ),
                KMapPin(
                  id: 'next',
                  position: points.last,
                  label: free ? 'Jonas Becker' : 'Lena Hoffmann',
                  icon: KIconName.mapPin,
                  color: brand,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(t.spaceCardPadding),
            child: KStack(
              gap: KLayoutGap.control,
              align: KLayoutAlign.stretch,
              children: [
                muted('Nächster Termin · ${free ? 'Morgen' : 'in 13 Min'}'),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    KText(
                      free ? '09:30' : '17:15',
                      variant: KTextVariant.heading1,
                      style: const TextStyle(
                        fontSize: 34,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    muted(
                      free
                          ? 'bis 10:30 · 14 Min Fahrt'
                          : 'bis 19:15 · 11 Min Fahrt',
                    ),
                  ],
                ),
                KInline(
                  gap: KLayoutGap.control,
                  children: [
                    KIcon(KIconName.car, size: 16, color: brand),
                    KText(
                      free ? 'Losfahren um 09:16' : 'Jetzt losfahren',
                      variant: KTextVariant.label,
                      style: TextStyle(color: brand),
                    ),
                  ],
                ),
                row(
                  leading: avatar(
                    free ? 'Jonas Becker' : 'Lena Hoffmann',
                    free ? 0 : 4,
                  ),
                  child: copy(
                    free ? 'Jonas Becker' : 'Lena Hoffmann',
                    free
                        ? 'Herrenschnitt · Bornaische Str. 18, Leipzig'
                        : 'Balayage · Karl-Heine-Str. 42, Leipzig',
                  ),
                ),
                actions(
                  button('Route', icon: KIconName.navigation),
                  button('Details', secondary: true),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget today() => box(
    title: 'Heute',
    end: link('Mein Tag'),
    child: Column(
      children: [
        for (final (i, entry) in const [
          ('08:30', 'Ingrid Kühn', 'Waschen & Schneiden · Zentrum-Süd'),
          ('10:40', 'Renate Weber', 'Farbe, Schneiden · Gohlis'),
          ('14:30', 'Familie Öztürk', '3× Kinderschnitt · Connewitz'),
          ('17:15', 'Lena Hoffmann', 'Balayage · Plagwitz'),
        ].indexed)
          Opacity(
            opacity: i < 3 ? .5 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 48,
                    child: KText(
                      entry.$1,
                      style: TextStyle(
                        color: t.colorTextMuted,
                        fontSize: 14.5,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 14,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < 3 ? t.colorBorderDefault : brand,
                            boxShadow: i < 3
                                ? null
                                : [
                                    BoxShadow(
                                      color: brand.withValues(alpha: .12),
                                      spreadRadius: 4,
                                    ),
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KText(
                          entry.$2,
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        muted(entry.$3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
  Widget requestList() => box(
    title: requests.isEmpty ? 'Anfragen' : 'Offene Anfragen',
    end: requests.isEmpty ? null : KBadge(child: KText('${requests.length}')),
    child: requests.isEmpty
        ? muted('Alles beantwortet.')
        : Column(
            children: [
              for (final i in requests)
                row(
                  divider: i != requests.first,
                  leading: avatar(
                    i == 0 ? 'Thomas Richter' : 'Sophie Lange',
                    i + 3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      copy(
                        i == 0 ? 'Thomas Richter' : 'Sophie Lange',
                        i == 0
                            ? 'Herrenschnitt · Do, 5. Nov, 11:00'
                            : 'Balayage · Mo, 9. Nov · Preis offen',
                      ),
                      muted(i == 0 ? '35,40 €' : 'Auf Anfrage'),
                    ],
                  ),
                  trailing: KInline(
                    gap: KLayoutGap.control,
                    children: [
                      for (final accept in [false, true])
                        KIconButton(
                          label:
                              '${i == 0 ? 'Thomas Richter' : 'Sophie Lange'}: Anfrage ${accept ? 'annehmen' : 'ablehnen'}',
                          icon: accept ? KIconName.check : KIconName.x,
                          iconContent: KIcon(
                            accept ? KIconName.check : KIconName.x,
                            color: accept ? success : t.colorStatusErrorAccent,
                            size: 16,
                          ),
                          onPressed: () {
                            setState(() => requests.remove(i));
                            feedback(
                              'Anfrage ${accept ? 'angenommen' : 'abgelehnt'} – nur Vorschau',
                            );
                          },
                        ),
                    ],
                  ),
                ),
            ],
          ),
  );
  List<Widget> quiet() => [
    Theme(
      data: Theme.of(context).copyWith(
        extensions: [
          ...Theme.of(
            context,
          ).extensions.values.where((e) => e is! KDesignTokens),
          t.copyWith(
            colorSurfaceRaised: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xff13334a)
                : const Color(0xffe8f3fa),
            colorBorderDefault: Colors.transparent,
          ),
        ],
      ),
      child: box(
        child: KInline(
          gap: KLayoutGap.action,
          align: KLayoutAlign.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: brand,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: KIcon(
                  KIconName.sun,
                  color: t.colorActionPrimaryForeground,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const KText(
                    'Heute ist frei.',
                    variant: KTextVariant.label,
                    style: TextStyle(fontSize: 17, height: 1.5),
                  ),
                  KText(
                    "Morgen um 09:30 geht’s weiter. Willst du kurzfristige Buchungen für heute erlauben?",
                    variant: KTextVariant.bodySmall,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: t.colorTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    box(
      title: 'Lücken füllen',
      child: Column(
        children: [
          row(
            child: copy(
              'Last-Minute heute freigeben',
              'Kund:innen können bis 1 Std. vorher buchen',
              wrap: true,
            ),
            trailing: KSwitch(
              value: lastMinute,
              onChanged: (v) {
                setState(() => lastMinute = v);
                feedback(
                  'Last-Minute ${v ? 'aktiv' : 'inaktiv'} – nur Vorschau',
                );
              },
              label: 'Last-Minute',
              showLabel: false,
            ),
          ),
          row(
            divider: true,
            child: copy(
              'Stammkund:innen erinnern',
              '3 waren seit über 6 Wochen nicht da',
              wrap: true,
            ),
            trailing: button('Ansehen', secondary: true),
          ),
        ],
      ),
    ),
  ];
}
