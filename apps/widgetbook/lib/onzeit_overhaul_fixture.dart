import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/k_map.dart';
import 'package:k_design_ui/k_map_style.dart';

import 'avatar_editor_fixture.dart';
import 'onzeit_overhaul_data.dart';
import 'onzeit_overhaul_day.dart';
import 'settings_grouped_parts.dart';
import 'settings_overhaul_dialogs.dart';

const _pages = [
  ('home', 'Heute', KIconName.house),
  ('day', 'Mein Tag', KIconName.route),
  ('calendar', 'Kalender', KIconName.calendar),
  ('bookings', 'Buchungen', KIconName.list),
  ('inbox', 'Posteingang', KIconName.inbox),
  ('customers', 'Kund:innen', KIconName.users),
  ('assistant', 'Assistent', KIconName.sparkles),
];
final overhaulToday = DateTime.utc(2026, 11, 3, 12);
const _todayKey = '2026-11-03';

class OnzeitOverhaulFixture extends StatefulWidget {
  const OnzeitOverhaulFixture({
    this.initialPage = 'home',
    this.initialOverlay,
    this.empty = false,
    super.key,
  });

  final String initialPage;
  final String? initialOverlay;
  final bool empty;

  @override
  State<OnzeitOverhaulFixture> createState() => _OnzeitOverhaulFixtureState();
}

class _OnzeitOverhaulFixtureState extends State<OnzeitOverhaulFixture> {
  late String page = widget.initialPage;
  late final bookings = widget.empty
      ? <OverhaulBooking>[]
      : [...overhaulBookings];
  late final customers = widget.empty
      ? <OverhaulCustomer>[]
      : [...overhaulCustomers];
  DateTime calendarDate = overhaulToday;
  final calendarSelections = {monthKey(overhaulToday): overhaulToday};
  static int monthKey(DateTime date) => date.year * 12 + date.month;

  DateTime get selectedCalendarDay =>
      calendarSelections[monthKey(calendarDate)] ??
      DateTime(calendarDate.year, calendarDate.month);

  void selectCalendarDay(DateTime day) => setState(() {
    if (monthKey(day) != monthKey(calendarDate)) calendarDate = day;
    calendarSelections[monthKey(day)] = day;
  });
  String? calendarChoice;
  String filter = 'Alle', query = '', notice = '', chat = '';
  final chatController = TextEditingController();
  bool inboxRead = false;
  OverhaulBooking? selectedBooking;
  OverhaulCustomer? selectedCustomer;
  final avatarEditor = AvatarEditorFixtureData()..images.clear();
  OverhaulDayDraft dayDraft = const OverhaulDayDraft();

  @override
  void initState() {
    super.initState();
    if (widget.initialOverlay case final overlay?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        switch (overlay) {
          case 'day':
            openDay();
          case 'customer':
            openCustomer(overhaulCustomers[1]);
          case 'editCustomer':
            editCustomer(overhaulCustomers[1]);
          case 'deleteCustomer':
            deleteCustomer(overhaulCustomers[1]);
          case 'photo':
            showAvatarEditorFixture(
              context,
              data: avatarEditor,
              onAvatarChange: (_) {},
            );
          default:
            openBooking(overhaulBookings[1], overlay: overlay);
        }
      });
    }
  }

  @override
  void dispose() {
    chatController.dispose();
    super.dispose();
  }

  void go(String next) => setState(() {
    page = next;
    filter = 'Alle';
    query = '';
    selectedBooking = null;
    selectedCustomer = null;
    notice = '';
  });

  List<OverhaulBooking> get active =>
      bookings.where((b) => b.pending || b.status == 'confirmed').toList();
  List<OverhaulBooking> get today =>
      active.where((b) => b.date == _todayKey && !b.pending).toList();

  String dateLabel(DateTime value) => overhaulDateLabel(value);
  String bookingDay(String day) => dateLabel(DateTime.parse(day));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = settingsGroupedTokens(
      theme.extension<KDesignTokens>()!,
      theme.brightness == Brightness.dark,
    );
    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where((e) => e is! KDesignTokens),
          tokens,
        ],
      ),
      child: Builder(
        builder: (context) => LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            final current = _pages.firstWhere((p) => p.$1 == page);
            final navigation = [
              for (final item in _pages)
                KButton(
                  label: item.$2,
                  fullWidth: true,
                  leading: KIcon(item.$3),
                  variant: item == current
                      ? KButtonVariant.secondary
                      : KButtonVariant.ghost,
                  onPressed: () => go(item.$1),
                ),
            ];
            final detail = switch (page) {
              'bookings' when selectedBooking != null => bookingDetails(
                context,
                selectedBooking!,
              ),
              'customers' when selectedCustomer != null => customerDetails(
                context,
                selectedCustomer!,
              ),
              'bookings' => emptyState(
                KIconName.calendar,
                'Buchung auswählen',
                'Wähle links eine Buchung aus.',
              ),
              'customers' => emptyState(
                KIconName.users,
                'Kund:in auswählen',
                'Wähle links einen Kontakt aus.',
              ),
              _ => null,
            };
            final content = KeyedSubtree(
              key: ValueKey(page),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(tokens.spaceLayoutGutter),
                child: KStack(
                  gap: KLayoutGap.action,
                  align: KLayoutAlign.stretch,
                  children: [
                    if (page != 'customers')
                      KText(
                        page == 'home' ? 'Guten Tag, Mara.' : current.$2,
                        variant: KTextVariant.heading2,
                      ),
                    if (notice.isNotEmpty) SgMuted(notice),
                    switch (page) {
                      'home' => home(context),
                      'day' => day(context),
                      'calendar' => calendar(
                        context,
                        constraints.maxWidth > 700,
                      ),
                      'bookings' => bookingList(),
                      'inbox' => inbox(),
                      'customers' => customerList(),
                      _ => assistant(),
                    },
                  ],
                ),
              ),
            );
            return Material(
              color: tokens.colorSurfaceCanvas,
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: tokens.layoutPanelWidth * .8,
                          child: Padding(
                            padding: EdgeInsets.all(tokens.spaceLayoutGutter),
                            child: KStack(
                              align: KLayoutAlign.stretch,
                              children: [
                                const KText(
                                  'onzeit.',
                                  variant: KTextVariant.heading3,
                                ),
                                ...navigation,
                                const Spacer(),
                                const Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: KAvatar(alt: 'Mara Krüger'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(child: content),
                        if (detail != null)
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(tokens.spaceLayoutGutter),
                              child: detail,
                            ),
                          ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.spaceLayoutGutter,
                          ),
                          child: KInline(
                            children: [
                              const Expanded(
                                child: KText(
                                  'onzeit.',
                                  variant: KTextVariant.heading3,
                                ),
                              ),
                              KButton(
                                label: 'Mehr',
                                leading: const KIcon(KIconName.menu),
                                variant: KButtonVariant.ghost,
                                onPressed: () => showNavigation(context),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: content),
                        KMobileAppBar(
                          variant: KMobileAppBarVariant.fixed,
                          labelVisibility: constraints.maxWidth <= 700
                              ? KMobileAppBarLabelVisibility.never
                              : KMobileAppBarLabelVisibility.always,
                          visibility: KMobileAppBarVisibility.always,
                          items: [
                            for (final item in _pages.where(
                              (item) => [
                                'home',
                                'calendar',
                                'bookings',
                                'inbox',
                              ].contains(item.$1),
                            ))
                              KMobileAppBarItem(
                                id: item.$1,
                                label: item.$2,
                                icon: KIcon(item.$3),
                              ),
                            const KMobileAppBarItem(
                              id: 'more',
                              label: 'Mehr',
                              icon: KIcon(KIconName.grid2x2),
                            ),
                          ],
                          selectedId:
                              ['day', 'customers', 'assistant'].contains(page)
                              ? 'more'
                              : page,
                          onSelectionChanged: (value) => value == 'more'
                              ? showNavigation(context)
                              : go(value),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Future<void> showNavigation(BuildContext context) async {
    final next = await KResponsiveDrawer.show<String>(
      context: context,
      breakpoint: 0,
      left: true,
      title: const KText('Navigation', variant: KTextVariant.heading3),
      closeLabel: 'Schließen',
      child: Builder(
        builder: (c) => KStack(
          align: KLayoutAlign.stretch,
          children: [
            for (final item in _pages)
              KButton(
                label: item.$2,
                leading: KIcon(item.$3),
                variant: KButtonVariant.ghost,
                onPressed: () => Navigator.of(c).pop(item.$1),
              ),
          ],
        ),
      ),
    );
    if (mounted && next != null) go(next);
  }

  Widget emptyState(KIconName icon, String title, String body) => KCard(
    child: KStack(
      gap: KLayoutGap.control,
      align: KLayoutAlign.center,
      children: [
        KIcon(icon, size: 30),
        KText(title, variant: KTextVariant.heading3),
        SgMuted(body),
      ],
    ),
  );

  Widget home(BuildContext context) {
    if (today.isEmpty) {
      return emptyState(
        KIconName.calendarCheck,
        'Bereit für die ersten Buchungen.',
        'Teile deine Seite, damit Kund:innen bei dir buchen können.',
      );
    }
    final next = today.length > 1 ? today[1] : today.first;
    final schedule = KStack(
      gap: KLayoutGap.action,
      align: KLayoutAlign.stretch,
      children: [
        KMediaCard(
          media: const OverhaulRouteMap(),
          child: KStack(
            align: KLayoutAlign.stretch,
            children: [
              const SgMuted('Nächster Termin'),
              KText(
                '${next.start} bis ${next.end}',
                variant: KTextVariant.heading2,
              ),
              const SgStatus('Losfahren um 10:26 · in 11 Min'),
              person(next.customer, next.service),
              KInline(
                wrap: true,
                gap: KLayoutGap.action,
                children: [
                  KButton(
                    label: 'Route starten',
                    leading: const KIcon(KIconName.navigation),
                    onPressed: () => setState(
                      () => notice = 'Route in der Vorschau geöffnet.',
                    ),
                  ),
                  KButton(
                    label: 'Termin öffnen',
                    variant: KButtonVariant.secondary,
                    onPressed: () => openBooking(next),
                  ),
                ],
              ),
            ],
          ),
        ),
        SgGroup(title: 'Heute', children: today.map(bookingRow).toList()),
      ],
    );
    final aside = KStack(
      gap: KLayoutGap.section,
      align: KLayoutAlign.stretch,
      children: [
        SgGroup(
          title: 'Anfragen',
          children: active.where((b) => b.pending).map(bookingRow).toList(),
        ),
        const SgGroup(
          title: 'Letzte 7 Tage',
          children: [
            SgInset(child: KText('12 Termine · 642 € Einnahmen · 2 Anfragen')),
          ],
        ),
      ],
    );
    return KStack(
      gap: KLayoutGap.action,
      align: KLayoutAlign.stretch,
      children: [
        const SgMuted('Dienstag, 3. November · 3 Termine noch heute'),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 740
              ? KInline(
                  gap: KLayoutGap.section,
                  children: [
                    Expanded(flex: 3, child: schedule),
                    Expanded(flex: 2, child: aside),
                  ],
                )
              : KStack(
                  gap: KLayoutGap.section,
                  align: KLayoutAlign.stretch,
                  children: [schedule, aside],
                ),
        ),
      ],
    );
  }

  Widget day(BuildContext context) => KStack(
    align: KLayoutAlign.stretch,
    gap: KLayoutGap.action,
    children: [
      SgMuted(dateLabel(dayDraft.day)),
      if (today.isNotEmpty && !dayDraft.off)
        const SizedBox(height: 220, child: OverhaulRouteMap()),
      SgGroup(
        children: [
          SgRow(
            dayDraft.off ? 'Freier Tag' : 'Tag anpassen',
            icon: KIconName.slidersHorizontal,
            onTap: openDay,
          ),
        ],
      ),
      if (today.isEmpty || dayDraft.off)
        emptyState(
          KIconName.route,
          'Keine Termine',
          'An diesem Tag ist nichts geplant.',
        )
      else
        KAgenda(
          label: 'Heutige Route',
          items: [
            const KAgendaItem(
              id: 'start',
              time: '08:18',
              title: 'Start · Zuhause',
            ),
            for (final b in today)
              KAgendaItem(
                id: b.id,
                time: b.start,
                title: b.customer.name,
                description: '${b.service} · bis ${b.end} · ${b.customer.area}',
                transition: SgMuted('${b.drive} Min · ${b.km} km'),
                state: b == today.first
                    ? KAgendaState.completed
                    : today.indexOf(b) == 1
                    ? KAgendaState.current
                    : KAgendaState.upcoming,
              ),
            const KAgendaItem(
              id: 'end',
              time: '16:00',
              title: 'Zurück · Zuhause',
            ),
          ],
        ),
    ],
  );

  Future<void> openDay() async {
    final result = await showOverhaulDay(
      context,
      dayDraft,
      presentation: reviewPageSheetPreference.value
          ? OverhaulPresentation.page
          : OverhaulPresentation.adaptive,
    );
    if (mounted && result != null) setState(() => dayDraft = result);
  }

  Widget calendar(BuildContext context, bool wide) {
    final modes = wide
        ? ['Woche', 'Monat', 'Liste']
        : ['Liste', '3 Tage', 'Monat'];
    final mode = modes.contains(calendarChoice) ? calendarChoice! : modes.first;
    final view = switch (mode) {
      'Monat' => KCalendarView.month,
      '3 Tage' => KCalendarView.threeDay,
      _ => KCalendarView.week,
    };
    void navigate(int direction) => setState(() {
      calendarDate = view == KCalendarView.month
          ? DateTime.utc(
              calendarDate.year,
              calendarDate.month + direction,
              1,
              12,
            )
          : calendarDate.add(
              Duration(days: direction * (view == KCalendarView.week ? 7 : 3)),
            );
    });
    final upcoming =
        active
            .where(
              (b) =>
                  b.date.compareTo(_todayKey) > 0 ||
                  b.date == _todayKey && b.end.compareTo('10:15') > 0,
            )
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final selectedDayBookings = active.where((booking) {
      final selected = selectedCalendarDay;
      return booking.date ==
          '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
    }).toList()..sort((a, b) => a.start.compareTo(b.start));
    return KStack(
      gap: KLayoutGap.action,
      align: KLayoutAlign.stretch,
      children: [
        KInline(
          align: KLayoutAlign.center,
          children: [
            Expanded(
              child: KText(
                mode == 'Liste'
                    ? 'Anstehend'
                    : overhaulMonthLabel(calendarDate),
                variant: KTextVariant.label,
              ),
            ),
            if (mode != 'Liste') ...[
              KIconButton(
                icon: KIconName.chevronLeft,
                label: 'Vorheriger Zeitraum',
                onPressed: () => navigate(-1),
              ),
              KButton(
                label: 'Heute',
                variant: KButtonVariant.secondary,
                onPressed: () => setState(() {
                  calendarDate = overhaulToday;
                  calendarSelections[monthKey(overhaulToday)] = overhaulToday;
                }),
              ),
              KIconButton(
                icon: KIconName.chevronRight,
                label: 'Nächster Zeitraum',
                onPressed: () => navigate(1),
              ),
            ],
          ],
        ),
        choices(modes, mode, (value) => setState(() => calendarChoice = value)),
        if (mode == 'Liste')
          if (upcoming.isEmpty)
            emptyState(
              KIconName.calendar,
              'Nichts geplant',
              'Hier erscheinen deine kommenden Termine.',
            )
          else
            groupedBookings(upcoming)
        else
          KCalendar<OverhaulBooking>(
            date: calendarDate,
            view: view,
            events: active,
            eventId: (b) => b.id,
            eventStart: (b) => b.startsAt,
            eventEnd: (b) => b.endsAt,
            eventAllDay: (_) => false,
            timeZone: 'Europe/Berlin',
            locale: 'de-DE',
            semanticLabel: 'Kalender',
            labels: const KCalendarLabels(
              allDay: 'Ganztägig',
              create: 'Termin erstellen',
              resizeStart: 'Beginn ändern',
              resizeEnd: 'Ende ändern',
            ),
            minimumDayWidth: wide ? 84 : 78,
            monthEventDisplay: wide
                ? KCalendarMonthEventDisplay.appointments
                : KCalendarMonthEventDisplay.indicators,
            selectedMonthDay: selectedCalendarDay,
            onMonthDayOpen: (date, _) => selectCalendarDay(date),
            startHour: 8,
            endHour: 19,
            height: view == KCalendarView.month ? (wide ? 600 : 360) : 580,
            onNavigate: navigate,
            onEventOpen: openBooking,
            eventBuilder: (context, value) => KText(
              value.event.customer.name,
              variant: KTextVariant.caption,
              maxLines: 1,
            ),
          ),
        if (mode == 'Monat')
          if (selectedDayBookings.isEmpty)
            SgGroup(
              title: overhaulDateLabel(selectedCalendarDay),
              children: const [SgInset(child: SgMuted('Keine Termine.'))],
            )
          else
            groupedBookings(selectedDayBookings),
      ],
    );
  }

  Widget choices(
    List<String> labels,
    String selected,
    ValueChanged<String> change,
  ) => KInline(
    gap: KLayoutGap.control,
    wrap: true,
    children: [
      for (final label in labels)
        KButton(
          label: label,
          variant: label == selected
              ? KButtonVariant.primary
              : KButtonVariant.ghost,
          onPressed: () => change(label),
        ),
    ],
  );

  Widget groupedBookings(List<OverhaulBooking> items) => KStack(
    gap: KLayoutGap.action,
    align: KLayoutAlign.stretch,
    children: [
      for (final date in items.map((b) => b.date).toSet())
        SgGroup(
          title: bookingDay(date),
          children: items.where((b) => b.date == date).map(bookingRow).toList(),
        ),
    ],
  );

  Widget bookingRow(OverhaulBooking booking) {
    final amount = booking.status == 'quote'
        ? 'Auf Anfrage'
        : overhaulMoney(booking.price + booking.travel);
    final tone = switch (booking.status) {
      'confirmed' => KBadgeVariant.success,
      'request' => KBadgeVariant.warning,
      'quote' => KBadgeVariant.info,
      'cancelled' => KBadgeVariant.destructive,
      _ => KBadgeVariant.secondary,
    };
    final description = '${booking.start} · ${booking.service}';
    return KButton(
      label:
          '${booking.customer.name}, $description, $amount, ${booking.statusLabel}',
      fullWidth: true,
      variant: KButtonVariant.ghost,
      onPressed: () => openBooking(booking),
      paddingInline: 0,
      content: SgInset(
        child: KInline(
          gap: KLayoutGap.control,
          align: KLayoutAlign.center,
          children: [
            KAvatar(alt: booking.customer.name),
            Expanded(
              child: KStack(
                children: [
                  KText(booking.customer.name, variant: KTextVariant.label),
                  SgMuted(description),
                ],
              ),
            ),
            Expanded(
              child: KStack(
                align: KLayoutAlign.end,
                children: [
                  KText(
                    amount,
                    variant: KTextVariant.label,
                    align: TextAlign.end,
                  ),
                  KBadge(
                    variant: tone,
                    child: Text(booking.statusLabel, textAlign: TextAlign.end),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bookingList() {
    final items = bookings
        .where((b) => filter == 'Alle' || b.statusLabel == filter)
        .toList();
    return KStack(
      gap: KLayoutGap.action,
      align: KLayoutAlign.stretch,
      children: [
        choices(
          ['Alle', 'Bestätigt', 'Anfrage', 'Preis auf Anfrage', 'Abgesagt'],
          filter,
          (value) => setState(() => filter = value),
        ),
        if (items.isEmpty)
          emptyState(
            KIconName.list,
            'Keine passenden Buchungen',
            'Neue Buchungen und Anfragen erscheinen hier.',
          )
        else
          groupedBookings(items),
      ],
    );
  }

  Widget inbox() => KStack(
    gap: KLayoutGap.action,
    align: KLayoutAlign.stretch,
    children: [
      KInline(
        wrap: true,
        children: [
          SgMuted(inboxRead || widget.empty ? 'Alles gelesen' : '3 ungelesen'),
          if (!inboxRead && !widget.empty)
            KButton(
              label: 'Alle gelesen',
              variant: KButtonVariant.secondary,
              onPressed: () => setState(() => inboxRead = true),
            ),
        ],
      ),
      choices(
        ['Alle', 'Ungelesen', 'Anfragen'],
        filter,
        (value) => setState(() => filter = value),
      ),
      if (widget.empty || inboxRead && filter == 'Ungelesen')
        emptyState(
          KIconName.inbox,
          'Alles ruhig hier',
          'Neue Anfragen, Zahlungen und Absagen erscheinen hier.',
        )
      else
        SgGroup(
          title: 'Heute',
          children: [
            for (final b in active.where((b) => b.pending)) bookingRow(b),
            if (filter != 'Anfragen' && today.isNotEmpty)
              SgRow(
                'Zahlung eingegangen',
                description: today.first.customer.name,
                onTap: () => openBooking(today.first, overlay: 'payment'),
              ),
          ],
        ),
    ],
  );

  Widget customerList() {
    final items = customers
        .where(
          (c) => '${c.name} ${c.area} ${c.address}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return KStack(
      align: KLayoutAlign.stretch,
      gap: KLayoutGap.action,
      children: [
        KInline(
          align: KLayoutAlign.center,
          children: [
            Expanded(
              child: KStack(
                children: [
                  const KText('Kund:innen', variant: KTextVariant.heading2),
                  SgMuted('${customers.length} Kontakte'),
                ],
              ),
            ),
            KButton(
              label: 'Neu',
              leading: const KIcon(KIconName.plus),
              onPressed: () => editCustomer(null),
            ),
          ],
        ),
        if (customers.isNotEmpty)
          KSearchField(
            label: 'Kund:innen suchen',
            placeholder: 'Name, Straße oder Stadtteil',
            onChanged: (value) => setState(() => query = value),
          ),
        if (customers.isEmpty) ...[
          emptyState(
            KIconName.users,
            'Noch keine Kund:innen',
            'Wer bei dir bucht, landet automatisch hier. Du kannst Kund:innen auch selbst anlegen.',
          ),
          Align(
            alignment: Alignment.center,
            child: KButton(
              label: 'Kund:in anlegen',
              onPressed: () => editCustomer(null),
            ),
          ),
        ] else if (items.isEmpty)
          emptyState(
            KIconName.search,
            'Niemand gefunden',
            'Versuche einen anderen Namen oder Stadtteil.',
          )
        else
          SgGroup(
            children: [
              for (final c in items)
                KButton(
                  label: '${c.name}, ${c.area}',
                  fullWidth: true,
                  paddingInline: 0,
                  variant: KButtonVariant.ghost,
                  onPressed: () => openCustomer(c),
                  content: SgInset(
                    child: KInline(
                      align: KLayoutAlign.center,
                      children: [
                        KAvatar(alt: c.name),
                        Expanded(
                          child: KStack(
                            children: [
                              KText(c.name, variant: KTextVariant.label),
                              SgMuted(c.area),
                            ],
                          ),
                        ),
                        if (c.id == 'c2') const SgMuted('Heute · 10:40'),
                        const KIcon(KIconName.chevronRight, size: 17),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget assistant() => KStack(
    align: KLayoutAlign.stretch,
    gap: KLayoutGap.action,
    children: [
      emptyState(
        KIconName.sparkles,
        'Wie kann ich dir helfen?',
        widget.empty
            ? 'Galerievorschau ohne Beispieldaten. Neue Buchungen erscheinen im Arbeitsalltag, sobald Termine vorhanden sind.'
            : 'Galerievorschau mit Beispieldaten. Probiere eine Frage aus und sieh dir eine Beispielantwort an.',
      ),
      for (final question in [
        'Was steht heute an?',
        'Welche Anfragen sind offen?',
      ])
        KButton(
          label: question,
          variant: KButtonVariant.secondary,
          onPressed: () => setState(() => chat = question),
        ),
      if (chat.isNotEmpty)
        KCard(
          child: KStack(
            children: [
              KText(chat, variant: KTextVariant.label),
              SgMuted(
                widget.empty
                    ? 'Sobald jemand bucht, kann ich dir Fragen zu deinen Terminen beantworten.'
                    : 'Heute hast du ${today.length} bestätigte Termine. Deine nächste Fahrt führt zu Jonas Becker.',
              ),
            ],
          ),
        ),
      KInput(label: 'Nachricht schreiben', controller: chatController),
      KButton(
        label: 'Senden',
        leading: const KIcon(KIconName.send),
        onPressed: () {
          if (chatController.text.trim().isEmpty) return;
          setState(() => chat = chatController.text.trim());
          chatController.clear();
        },
      ),
    ],
  );

  Widget person(OverhaulCustomer customer, String subtitle) => KInline(
    gap: KLayoutGap.control,
    children: [
      KAvatar(alt: customer.name),
      Expanded(
        child: KStack(
          align: KLayoutAlign.stretch,
          children: [
            KText(customer.name, variant: KTextVariant.label),
            SgMuted(subtitle),
          ],
        ),
      ),
    ],
  );

  void openBooking(OverhaulBooking booking, {String overlay = 'booking'}) {
    if (overlay == 'booking' &&
        page == 'bookings' &&
        MediaQuery.sizeOf(context).width >= 1100) {
      setState(() => selectedBooking = booking);
      return;
    }
    if (overlay == 'booking') {
      showPanel(
        'Buchungsdetails',
        (c) => bookingDetails(c, booking, modal: true),
      );
    } else if (overlay == 'payment') {
      showPanel(
        'Buchungszahlung',
        (_) => KStack(
          gap: KLayoutGap.action,
          align: KLayoutAlign.stretch,
          children: [
            KStack(
              align: KLayoutAlign.center,
              children: [
                const SgStatus('Beispielzahlung', success: true),
                KText(
                  overhaulMoney(booking.price + booking.travel),
                  variant: KTextVariant.heading2,
                ),
                SgMuted(booking.customer.name),
              ],
            ),
            SgGroup(
              children: [
                for (final item in [
                  ('Leistungen', overhaulMoney(booking.price)),
                  ('Anfahrt', overhaulMoney(booking.travel)),
                  ('Gesamt', overhaulMoney(booking.price + booking.travel)),
                ])
                  SgInset(
                    child: KInline(
                      children: [
                        Expanded(child: SgMuted(item.$1)),
                        KText(item.$2, variant: KTextVariant.label),
                      ],
                    ),
                  ),
              ],
            ),
            SgGroup(
              children: [
                for (final item in [
                  ('Kund:in', booking.customer.name),
                  ('Termin', '${bookingDay(booking.date)}, ${booking.start}'),
                  ('Buchungsnummer', 'DEMO-${booking.id}'),
                ])
                  SgInset(
                    child: KInline(
                      children: [
                        Expanded(child: SgMuted(item.$1)),
                        Flexible(child: KText(item.$2, align: TextAlign.end)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        compact: true,
      );
    } else {
      final cancel = overlay == 'cancel';
      final decline = overlay == 'decline';
      final needsPrice = overlay == 'accept' && booking.status == 'quote';
      num? price = needsPrice ? null : booking.price;
      showPanel(
        cancel
            ? 'Buchung absagen'
            : decline
            ? 'Anfrage ablehnen'
            : 'Anfrage annehmen',
        (c) => StatefulBuilder(
          builder: (c, update) => KStack(
            align: KLayoutAlign.stretch,
            gap: KLayoutGap.action,
            children: [
              SgMuted(
                '${booking.customer.name} · ${bookingDay(booking.date)} · ${booking.start}',
              ),
              if (cancel || decline)
                const KField(label: 'Grund (optional)', child: KInput()),
              if (needsPrice)
                KField(
                  label: 'Preis in Euro',
                  child: KInput(
                    keyboardType: TextInputType.number,
                    onChanged: (value) => update(
                      () => price = num.tryParse(value.replaceAll(',', '.')),
                    ),
                  ),
                ),
              KButton(
                label: cancel
                    ? 'Buchung absagen'
                    : decline
                    ? 'Ablehnen'
                    : 'Annehmen',
                onPressed: price == null || !price!.isFinite || price! < 0
                    ? null
                    : () {
                        final revised = booking.withStatus(
                          cancel || decline ? 'cancelled' : 'confirmed',
                          revisedPrice: price,
                        );
                        final index = bookings.indexWhere(
                          (item) => item.id == booking.id,
                        );
                        setState(() {
                          if (index >= 0) bookings[index] = revised;
                          if (selectedBooking?.id == booking.id) {
                            selectedBooking = revised;
                          }
                          notice = 'Buchung in der Vorschau aktualisiert.';
                        });
                        Navigator.of(c).pop();
                      },
              ),
              KButton(
                label: 'Zurück',
                variant: KButtonVariant.secondary,
                onPressed: () => Navigator.of(c).pop(),
              ),
            ],
          ),
        ),
        compact: true,
      );
    }
  }

  Widget bookingDetails(
    BuildContext context,
    OverhaulBooking b, {
    bool modal = false,
  }) => KStack(
    gap: KLayoutGap.action,
    align: KLayoutAlign.stretch,
    children: [
      KStack(
        gap: KLayoutGap.control,
        align: KLayoutAlign.center,
        children: [
          SgStatus(b.statusLabel, success: !b.pending),
          KText('${b.start} bis ${b.end}', variant: KTextVariant.heading2),
          SgMuted(bookingDay(b.date)),
        ],
      ),
      SgGroup(
        title: 'Kund:in & Einsatzort',
        children: [
          SgInset(child: person(b.customer, b.customer.area)),
          const SizedBox(height: 140, child: OverhaulRouteMap()),
          SgInset(
            child: KStack(
              align: KLayoutAlign.stretch,
              children: [KText(b.customer.address), SgMuted(b.customer.note)],
            ),
          ),
          SgRow(
            'Kund:in öffnen',
            onTap: () {
              if (modal) Navigator.of(context).pop();
              openCustomer(b.customer);
            },
          ),
        ],
      ),
      SgGroup(
        title: 'Leistungen & Preis',
        children: [
          SgRow(
            b.service,
            value: b.status == 'quote' ? 'Auf Anfrage' : overhaulMoney(b.price),
          ),
          SgRow('Anfahrt', value: overhaulMoney(b.travel)),
          SgRow(
            'Gesamt',
            value: b.status == 'quote'
                ? 'Offen'
                : overhaulMoney(b.price + b.travel),
          ),
          if (!b.pending)
            SgRow(
              'Zahlung',
              description: 'Online bezahlt',
              onTap: () => openBookingAction(context, b, 'payment', modal),
            ),
        ],
      ),
      KInline(
        wrap: true,
        gap: KLayoutGap.action,
        children: [
          if (b.pending) ...[
            KButton(
              label: 'Ablehnen',
              variant: KButtonVariant.secondary,
              onPressed: () => openBookingAction(context, b, 'decline', modal),
            ),
            KButton(
              label: b.status == 'quote' ? 'Preis nennen' : 'Annehmen',
              onPressed: () => openBookingAction(context, b, 'accept', modal),
            ),
          ] else ...[
            KButton(
              label: 'Absagen',
              variant: KButtonVariant.ghost,
              onPressed: () => openBookingAction(context, b, 'cancel', modal),
            ),
            KButton(
              label: 'Route starten',
              leading: const KIcon(KIconName.navigation),
              onPressed: () =>
                  setState(() => notice = 'Route in der Vorschau geöffnet.'),
            ),
          ],
        ],
      ),
    ],
  );

  void openBookingAction(
    BuildContext routeContext,
    OverhaulBooking booking,
    String overlay,
    bool modal,
  ) {
    if (modal) Navigator.of(routeContext).pop();
    openBooking(booking, overlay: overlay);
  }

  void openCustomer(OverhaulCustomer customer) {
    if (page == 'customers' && MediaQuery.sizeOf(context).width >= 1100) {
      setState(() => selectedCustomer = customer);
      return;
    }
    showPanel('Kund:in', (c) => customerDetails(c, customer));
  }

  Widget customerDetails(BuildContext context, OverhaulCustomer c) => KStack(
    gap: KLayoutGap.action,
    align: KLayoutAlign.stretch,
    children: [
      KStack(
        align: KLayoutAlign.center,
        children: [
          KAvatar(alt: c.name, size: KAvatarSize.large),
          KText(c.name, variant: KTextVariant.heading2),
          SgMuted('${c.area} · seit August 2025'),
        ],
      ),
      SgGroup(
        title: 'Nächster Termin',
        children: [
          for (final b in active.where((b) => b.customerId == c.id))
            bookingRow(b),
        ],
      ),
      SgGroup(
        title: 'Einsatzort',
        children: [
          const SizedBox(height: 140, child: OverhaulRouteMap()),
          SgInset(
            child: KStack(
              align: KLayoutAlign.stretch,
              children: [KText(c.address), SgMuted(c.note)],
            ),
          ),
        ],
      ),
      const SgGroup(
        title: 'Auf einen Blick',
        children: [
          SgInset(child: KText('8 Besuche · 384 € Umsatz · 1 kommend')),
        ],
      ),
      KInline(
        wrap: true,
        children: [
          KButton(
            label: 'Kund:in bearbeiten',
            variant: KButtonVariant.secondary,
            onPressed: () => editCustomer(c),
          ),
          KButton(
            label: 'Kund:in löschen',
            variant: KButtonVariant.ghost,
            onPressed: () => deleteCustomer(c),
          ),
        ],
      ),
    ],
  );

  Future<void> editCustomer(OverhaulCustomer? customer) async {
    final name = TextEditingController(text: customer?.name);
    final address = TextEditingController(text: customer?.address);
    final note = TextEditingController(text: customer?.note);
    Uint8List? draftPhoto;
    await showPanel(
      customer == null ? 'Kund:in hinzufügen' : 'Kund:in bearbeiten',
      (c) => StatefulBuilder(
        builder: (c, update) => KStack(
          gap: KLayoutGap.action,
          align: KLayoutAlign.stretch,
          children: [
            Align(
              alignment: Alignment.center,
              child: KButton(
                label: 'Foto auswählen',
                variant: KButtonVariant.ghost,
                onPressed: () => showAvatarEditorFixture(
                  c,
                  data: avatarEditor,
                  onAvatarChange: (bytes) {
                    if (c.mounted) update(() => draftPhoto = bytes);
                  },
                ),
                content: KAvatar(
                  alt: name.text.isEmpty ? 'Neues Bild' : name.text,
                  size: KAvatarSize.large,
                  image: draftPhoto == null ? null : MemoryImage(draftPhoto!),
                ),
              ),
            ),
            KInput(
              label: 'Name',
              controller: name,
              onChanged: (_) => update(() {}),
            ),
            const KInput(label: 'E-Mail'),
            KInput(label: 'Adresse', controller: address),
            KInput(label: 'Notiz', controller: note),
            KButton(
              label: 'Speichern',
              onPressed: name.text.trim().isEmpty
                  ? null
                  : () {
                      final revised = OverhaulCustomer(
                        customer?.id ?? 'local-${customers.length}',
                        name.text.trim(),
                        customer?.area ?? 'Leipzig',
                        address.text,
                        note.text,
                      );
                      setState(() {
                        if (customer == null) {
                          customers.add(revised);
                        } else {
                          customers[customers.indexWhere(
                                (c) => c.id == customer.id,
                              )] =
                              revised;
                          if (selectedCustomer?.id == customer.id) {
                            selectedCustomer = revised;
                          }
                        }
                      });
                      Navigator.of(c).pop();
                    },
            ),
          ],
        ),
      ),
    );
    name.dispose();
    address.dispose();
    note.dispose();
  }

  void deleteCustomer(OverhaulCustomer customer) => showPanel(
    'Kund:in löschen?',
    (c) => KStack(
      gap: KLayoutGap.action,
      align: KLayoutAlign.stretch,
      children: [
        const SgMuted(
          'Kontakt, Adresse und Notizen werden gelöscht. Vergangene Buchungen bleiben für deine Abrechnung erhalten.',
        ),
        KButton(
          label: 'Löschen',
          onPressed: () {
            setState(() {
              customers.removeWhere((item) => item.id == customer.id);
              selectedCustomer = null;
              notice = 'Kontakt in der Vorschau gelöscht.';
            });
            Navigator.of(c).pop();
          },
        ),
        KButton(
          label: 'Abbrechen',
          variant: KButtonVariant.secondary,
          onPressed: () => Navigator.of(c).pop(),
        ),
      ],
    ),
    compact: true,
  );

  Future<void> showPanel(
    String title,
    WidgetBuilder builder, {
    bool compact = false,
  }) {
    final heading = KText(title, variant: KTextVariant.heading3);
    if (!compact && reviewPageSheetPreference.value) {
      return KPageSheet.show<void>(
        context: context,
        builder: (c) => KPageSheet(
          title: heading,
          onClose: () => Navigator.of(c).pop(),
          closeLabel: 'Schließen',
          child: builder(c),
        ),
      );
    }
    return KAdaptiveDialog.show<void>(
      context: context,
      builder: (c) => KAdaptiveDialog(
        title: heading,
        onClose: () => Navigator.of(c).pop(),
        closeLabel: 'Schließen',
        expandBody: !compact,
        child: builder(c),
      ),
    );
  }
}

class OverhaulRouteMap extends StatelessWidget {
  const OverhaulRouteMap({super.key});
  static const points = [
    KMapCenter(longitude: 12.3748, latitude: 51.3405),
    KMapCenter(longitude: 12.3749, latitude: 51.3394),
    KMapCenter(longitude: 12.3754, latitude: 51.3386),
    KMapCenter(longitude: 12.3763, latitude: 51.3377),
    KMapCenter(longitude: 12.3771, latitude: 51.3368),
    KMapCenter(longitude: 12.3774, latitude: 51.3356),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return KMap(
      mapStyle: jsonEncode(createKMapStyle(tokens: t)),
      label: 'Beispielroute in Leipzig',
      center: points.first,
      interactive: false,
      showZoomControls: false,
      fitContent: true,
      fitPadding: 42,
      routes: const [KMapRoute(id: 'gallery-journey', coordinates: points)],
      pins: [
        KMapPin(
          id: 'previous',
          label: 'Vorheriger Termin',
          position: points.first,
          icon: KIconName.check,
        ),
        KMapPin(
          id: 'next',
          label: 'Nächster Termin',
          position: points.last,
          icon: KIconName.mapPin,
        ),
      ],
    );
  }
}
