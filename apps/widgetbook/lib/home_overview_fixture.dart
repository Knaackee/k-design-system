import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/k_map.dart';
import 'package:k_design_ui/k_map_style.dart';

class HomeOverviewFixture extends StatefulWidget {
  const HomeOverviewFixture({
    this.newAccount = false,
    this.maxWidth = 1120,
    super.key,
  });
  final bool newAccount;
  final double maxWidth;
  @override
  State<HomeOverviewFixture> createState() => _HomeOverviewFixtureState();
}

class _HomeOverviewFixtureState extends State<HomeOverviewFixture> {
  String notice = '';
  static const points = [
    KMapCenter(longitude: 12.3748, latitude: 51.3405),
    KMapCenter(longitude: 12.3749, latitude: 51.3394),
    KMapCenter(longitude: 12.3754, latitude: 51.3386),
    KMapCenter(longitude: 12.3763, latitude: 51.3377),
    KMapCenter(longitude: 12.3771, latitude: 51.3368),
    KMapCenter(longitude: 12.3774, latitude: 51.3356),
  ];
  Widget button(String label, {KIconName? icon, bool secondary = false}) =>
      KButton(
        label: label,
        leading: icon == null ? null : KIcon(icon),
        variant: secondary ? KButtonVariant.secondary : KButtonVariant.primary,
        onPressed: () => setState(() => notice = 'Demo: $label'),
      );
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.extension<KDesignTokens>()!;
    final tokens = base.copyWith(
      radiusCard: 24,
      spaceCardPadding: base.spaceContentActionGap,
      colorBrandPrimaryAccent: const Color(0xff2563eb),
      colorBrandPrimaryBackground: const Color(0xffdbeafe),
      colorBrandPrimaryForeground: const Color(0xff1d4ed8),
      colorActionPrimaryBackground: const Color(0xff2563eb),
      colorActionPrimaryForeground: const Color(0xffffffff),
      colorActionPrimaryHover: const Color(0xff1d4ed8),
      colorActionPrimaryPressed: const Color(0xff1e40af),
    );
    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where(
            (extension) => extension is! KDesignTokens,
          ),
          tokens,
        ],
      ),
      child: Builder(builder: _content),
    );
  }

  Widget _content(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    Widget muted(String text) => KText(
      text,
      variant: KTextVariant.bodySmall,
      style: TextStyle(color: t.colorTextMuted),
    );
    Widget heading(String text) => KText(text, variant: KTextVariant.heading4);
    Widget person(String name, String detail) => Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.colorBrandPrimaryBackground,
          ),
          child: KText(name[0]),
        ),
        SizedBox(width: t.spaceContentActionGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KText(name, variant: KTextVariant.label),
              muted(detail),
            ],
          ),
        ),
      ],
    );
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          child: Padding(
            padding: EdgeInsets.all(t.spaceLayoutSectionGap),
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 720;
                final time = KStack(
                  children: [
                    muted('Nächster Termin'),
                    KInline(
                      align: KLayoutAlign.center,
                      children: [
                        const KText('10:40', variant: KTextVariant.heading1),
                        muted('in 25 Min.'),
                      ],
                    ),
                  ],
                );
                final customer = KStack(
                  children: [
                    person('Jonas Becker', 'Herrenschnitt · 30 Min.'),
                    muted('Beispielstraße 18, Leipzig'),
                  ],
                );
                final actions = KInline(
                  wrap: true,
                  gap: KLayoutGap.action,
                  children: [
                    button('Route starten', icon: KIconName.navigation),
                    button('Anrufen', icon: KIconName.phone, secondary: true),
                  ],
                );
                final media = KMap(
                  mapStyle: jsonEncode(createKMapStyle(tokens: t)),
                  center: points.first,
                  interactive: false,
                  showZoomControls: false,
                  fitContent: true,
                  fitPadding: 48,
                  routes: const [
                    KMapRoute(id: 'previous-to-next', coordinates: points),
                  ],
                  pins: [
                    KMapPin(
                      id: 'previous',
                      label: 'Vorherige Station',
                      position: points.first,
                      icon: KIconName.check,
                    ),
                    KMapPin(
                      id: 'next',
                      label: 'Nächster Termin: Jonas Becker',
                      position: points.last,
                      icon: KIconName.user,
                    ),
                  ],
                  label:
                      'Beispielroute von der vorherigen zur nächsten Station',
                );
                final next = KMediaCard(
                  media: media,
                  mediaOverlay: KSurface(
                    radius: KSurfaceRadius.full,
                    child: Padding(
                      padding: EdgeInsets.all(t.spaceControlGap),
                      child: const KText(
                        '6 Min.',
                        variant: KTextVariant.caption,
                      ),
                    ),
                  ),
                  child: KStack(
                    align: KLayoutAlign.stretch,
                    gap: KLayoutGap.action,
                    children: [
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: time),
                            Expanded(flex: 6, child: customer),
                          ],
                        )
                      else ...[
                        time,
                        customer,
                      ],
                      actions,
                    ],
                  ),
                );
                final newCard = KMediaCard(
                  media: ColoredBox(
                    color: t.colorBrandPrimaryBackground,
                    child: Center(
                      // Illustration: scales down under large text.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: KStack(
                          align: KLayoutAlign.center,
                          children: [
                            const KIcon(KIconName.scissors, size: 48),
                            const KText(
                              'Alex’ Haarpflege',
                              variant: KTextVariant.heading3,
                            ),
                            const KText('Schöne Haare. Bei dir zu Hause.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  child: KStack(
                    children: [
                      const KText(
                        'Deine Seite ist bereit für die ersten Buchungen.',
                        variant: KTextVariant.heading3,
                      ),
                      muted('onzeit.com/u/alex-demo'),
                      KInline(
                        wrap: true,
                        children: [
                          button('Seite teilen', icon: KIconName.share),
                          button('Ansehen', secondary: true),
                        ],
                      ),
                    ],
                  ),
                );
                final left = KStack(
                  align: KLayoutAlign.stretch,
                  gap: KLayoutGap.section,
                  children: [
                    widget.newAccount ? newCard : next,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        heading('Heute'),
                        button('Mein Tag', secondary: true),
                      ],
                    ),
                    if (widget.newAccount)
                      muted(
                        'Noch keine Termine. Sobald jemand bucht, steht der Termin hier, mit Route und Uhrzeit.',
                      )
                    else
                      const KAgenda(
                        label: 'Heutige Termine',
                        items: [
                          KAgendaItem(
                            id: 'first',
                            time: '09:00',
                            title: 'Maria S.',
                            description: 'Waschen & Schneiden · 45 Min.',
                            state: KAgendaState.completed,
                          ),
                          KAgendaItem(
                            id: 'next',
                            time: '10:40',
                            title: 'Jonas Becker',
                            description: 'Herrenschnitt · 30 Min.',
                            state: KAgendaState.current,
                            transition: KText(
                              '14 Min. zum nächsten Termin',
                              variant: KTextVariant.caption,
                            ),
                          ),
                          KAgendaItem(
                            id: 'later',
                            time: '11:45',
                            title: 'Renate W.',
                            description: 'Farbe · 90 Min.',
                          ),
                          KAgendaItem(
                            id: 'last',
                            time: '14:00',
                            title: 'Seniorenheim Lindenhof',
                            description: '4 Termine am Stück',
                          ),
                        ],
                      ),
                  ],
                );
                final right = KStack(
                  align: KLayoutAlign.stretch,
                  gap: KLayoutGap.section,
                  children: [
                    heading(
                      widget.newAccount
                          ? 'Mehr Buchungen bekommen'
                          : 'Diese Woche',
                    ),
                    if (widget.newAccount)
                      ...[
                        'In deinen Status posten',
                        'QR-Code ausdrucken',
                        'Extras ergänzen',
                      ].map((s) => button(s, secondary: true))
                    else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final stat in [
                            ('23', 'Termine', '+4'),
                            ('1.240 €', 'Einnahmen', '+18 %'),
                            ('3,5 h', 'weniger Fahrt', 'dank Route'),
                          ])
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: t.spaceControlGap,
                                ),
                                child: KStack(
                                  children: [
                                    KText(
                                      stat.$1,
                                      variant: KTextVariant.heading3,
                                    ),
                                    muted(stat.$2),
                                    KText(
                                      stat.$3,
                                      variant: KTextVariant.caption,
                                      style: TextStyle(
                                        color: stat.$3.startsWith('+')
                                            ? t.colorStatusSuccessForeground
                                            : t.colorTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          heading('Anfragen'),
                          KButton(
                            label: 'Alle',
                            variant: KButtonVariant.ghost,
                            onPressed: () =>
                                setState(() => notice = 'Demo: Alle Anfragen'),
                          ),
                        ],
                      ),
                      for (final request in [
                        ('Sophie L.', 'Langhaarschnitt · Di 15:10'),
                        ('Thomas R.', 'Herrenschnitt · Mi 09:00'),
                      ])
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: t.colorBorderDefault),
                            ),
                          ),
                          child: KButton(
                            label: 'Anfrage von ${request.$1} öffnen',
                            variant: KButtonVariant.ghost,
                            fullWidth: true,
                            paddingInline: 0,
                            onPressed: () =>
                                setState(() => notice = 'Demo: ${request.$1}'),
                            content: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: t.spaceContentActionGap,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: person(request.$1, request.$2),
                                  ),
                                  const KIcon(KIconName.chevronRight),
                                ],
                              ),
                            ),
                          ),
                        ),
                      KCard(
                        child: Row(
                          children: [
                            const KIcon(KIconName.scissors),
                            SizedBox(width: t.spaceControlGap),
                            Expanded(
                              child: KStack(
                                children: [
                                  const KText(
                                    'Deine Buchungsseite',
                                    variant: KTextVariant.label,
                                  ),
                                  KLink(
                                    label: 'alex-demo.onzeit.com',
                                    onPressed: () => setState(
                                      () =>
                                          notice = 'Demo: Buchungsseite öffnen',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            KButton(
                              label: 'Buchungsseite teilen',
                              content: const KIcon(KIconName.share),
                              variant: KButtonVariant.ghost,
                              onPressed: () => setState(
                                () => notice = 'Demo: Buchungsseite teilen',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    muted(
                      'Gestaltungsvorschau · Alle Namen, Werte und die Karte sind Beispieldaten.',
                    ),
                  ],
                );
                return KStack(
                  align: KLayoutAlign.stretch,
                  gap: KLayoutGap.section,
                  children: [
                    KStack(
                      children: [
                        const KText(
                          'Guten Tag, Alex.',
                          variant: KTextVariant.heading2,
                        ),
                        muted(
                          widget.newAccount
                              ? 'Sonntag, 1. November'
                              : 'Sonntag, 1. November · noch 3 Termine heute',
                        ),
                      ],
                    ),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 17, child: left),
                          SizedBox(width: t.spaceLayoutSectionGap),
                          Expanded(flex: 10, child: right),
                        ],
                      )
                    else ...[
                      left,
                      right,
                    ],
                    KText(notice, variant: KTextVariant.bodySmall),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
