part of 'user_dashboard_review.dart';

extension _DashboardSections on _UserDashboardReviewState {
  List<double> series(int length, double base, double amp, int seed) =>
      List.generate(
        length,
        (i) => math.max(
          0,
          (base +
                  amp * math.sin(i / 1.7 + seed) +
                  i * base / length * .35 +
                  ((i * 7 + seed * 3) % 4) -
                  1.5)
              .roundToDouble(),
        ),
      );
  List<double> get values => series(
    period == 7
        ? 7
        : period == 30
        ? 15
        : 13,
    period == 7
        ? 120
        : period == 30
        ? 210
        : 900,
    period == 7 ? 70 : 90,
    1,
  );
  String money(double value) =>
      '${value.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} €';
  Widget metrics() {
    final v = values;
    final bookings = series(v.length, 3, 2, 2);
    final items = [
      ('Umsatz', money(v.reduce((a, b) => a + b)), '+12 %', v),
      (
        'Buchungen',
        '${bookings.reduce((a, b) => a + b).round()}',
        '+8 %',
        bookings,
      ),
      (
        'Neue Kund:innen',
        '${math.max(2, (9 * period / 30).round())}',
        period == 7 ? '+1' : '+3',
        series(v.length, 1, 1, 4),
      ),
      ('Auslastung', '74 %', '−4 %', series(v.length, 70, 8, 5)),
    ];
    final tabs = SizedBox(
      width: wide ? 260 : null,
      child: KTabs(
        label: 'Auswertungszeitraum',
        expanded: true,
        value: '$period',
        onChanged: (v) => updateState(() => period = int.parse(v)),
        items: [
          for (final day in [7, 30, 90])
            KTabItem(
              id: '$day',
              label: KText('$day Tage'),
              content: const SizedBox.shrink(),
            ),
        ],
      ),
    );
    return KStack(
      gap: KLayoutGap.action,
      align: KLayoutAlign.stretch,
      children: [
        if (wide)
          Row(
            children: [
              const Expanded(
                child: KText('Dein Geschäft', variant: KTextVariant.heading3),
              ),
              tabs,
            ],
          )
        else ...[
          const KText('Dein Geschäft', variant: KTextVariant.heading3),
          tabs,
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = wide ? 4 : 2;
            final width = (constraints.maxWidth - 10 * (cols - 1)) / cols;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (i, item) in items.indexed)
                  SizedBox(
                    width: width,
                    child: box(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          muted(item.$1),
                          const SizedBox(height: 4),
                          KText(
                            item.$2,
                            variant: KTextVariant.heading2,
                            style: const TextStyle(
                              fontSize: 24,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            children: [
                              KText(
                                item.$3,
                                variant: KTextVariant.bodySmall,
                                style: TextStyle(
                                  color: i == 3
                                      ? t.colorStatusErrorAccent
                                      : success,
                                ),
                              ),
                              muted(' vs. davor'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 30,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _Spark(
                                item.$4,
                                i == 3 ? t.colorStatusErrorAccent : brand,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget revenue() {
    final v = values,
        before = series(
          values.length,
          period == 7
              ? 100
              : period == 30
              ? 180
              : 800,
          60,
          3,
        );
    return box(
      title: 'Umsatz',
      child: Column(
        children: [
          KBarChart(
            label: 'Umsatz im Vergleich zur Vorperiode',
            height: 150,
            series: [
              for (final (i, row) in [v, before].indexed)
                KChartSeries(
                  id: '$i',
                  label: i == 0 ? 'Aktuell' : 'Davor',
                  colorIndex: i,
                  points: [
                    for (final (x, y) in row.indexed)
                      KChartPoint(id: '$x', x: x.toDouble(), y: y),
                  ],
                ),
            ],
            xAxis: KChartAxis(
              min: -.5,
              max: v.length - .5,
              ticks: [],
              format: (v) => '${v.round()}',
            ),
            yAxis: KChartAxis(
              min: 0,
              max: ([...v, ...before].reduce(math.max) / 100).ceil() * 100,
              ticks: [],
              format: money,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in axisLabels(
                period == 7
                    ? ['Do', 'Fr', 'Sa', 'So', 'Mo', 'Di', 'Mi']
                    : period == 30
                    ? ['6. Okt', '20. Okt', '4. Nov']
                    : ['Aug', 'Sep', 'Okt', 'Nov'],
              ))
                muted(label),
            ],
          ),
        ],
      ),
    );
  }

  Widget week({bool ready = false}) => box(
    title: ready ? 'Diese Woche buchbar' : 'Nächste 7 Tage',
    end: ready ? null : muted('● gebucht  ○ frei'),
    child: KStack(
      gap: KLayoutGap.control,
      align: KLayoutAlign.stretch,
      children: [
        if (ready)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              const KText('31', variant: KTextVariant.heading1),
              muted('Std. frei · Mo–Fr 09–18'),
            ],
          ),
        bars(
          ready
              ? [100, 100, 100, 0, 0, 100, 100]
              : [free ? 0 : 88, 62, 75, 40, 0, 25, 50],
          ['Heute', 'Do', 'Fr', 'Sa', 'So', 'Mo', 'Di'],
          height: ready ? 70 : 110,
          green: ready,
        ),
        muted(
          ready
              ? 'Grün = buchbar. Sa und So bist du nicht buchbar.'
              : 'Am meisten frei: Mo, 9. Nov · 6 Std.',
        ),
        if (ready)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: link('Zeiten ändern'),
          ),
      ],
    ),
  );
  Widget bars(
    List<num> values,
    List<String> labels, {
    double height = 90,
    bool green = false,
    int todayIndex = 0,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      for (final (i, value) in values.indexed)
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: t.spaceControlGap * .375),
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 34),
                  child: Container(
                    height: math.max(12, height - 22),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: t.colorSurfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: value / 100,
                      widthFactor: 1,
                      child: ColoredBox(
                        color: green ? success.withValues(alpha: .25) : brand,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                KText(
                  labels[i],
                  variant: KTextVariant.bodySmall,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: i == todayIndex ? brand : t.colorTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
  Widget customers() => box(
    title: 'Neue Kund:innen',
    end: link('Alle'),
    child: Column(
      children: [
        for (final (i, entry) in const [
          ('Lena Hoffmann', 'Balayage · über Buchungsseite', 'heute'),
          ('Familie Öztürk', 'Kinderschnitt · über QR-Code', 'gestern'),
          ('Paul Neumann', 'Herrenschnitt · Empfehlung von Ingrid K.', 'Mo'),
          ('Clara Vogt', 'Waschen & Föhnen · Instagram', 'So'),
        ].indexed)
          row(
            divider: i > 0,
            leading: avatar(entry.$1, i),
            child: copy(entry.$1, entry.$2),
            trailing: muted(entry.$3),
          ),
      ],
    ),
  );
  Widget services() => box(
    title: 'Top-Leistungen',
    child: KStack(
      gap: KLayoutGap.control,
      align: KLayoutAlign.stretch,
      children: [
        for (final entry in const [
          ('Balayage', 1240.0),
          ('Herrenschnitt', 862.0),
          ('Waschen & Schneiden', 610.0),
          ('Kinderschnitt', 288.0),
        ])
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: KText(entry.$1)),
                  KText(money(entry.$2), variant: KTextVariant.label),
                ],
              ),
              const SizedBox(height: 6),
              Semantics(
                label: '${entry.$1}: ${money(entry.$2)}',
                child: KProgress(value: entry.$2 / 1240 * 100),
              ),
            ],
          ),
      ],
    ),
  );
  Widget share({bool draft = false, bool first = false}) {
    final content = box(
      title: first ? 'Bereit für deine erste Buchung' : 'Deine Buchungsseite',
      end: KBadge(
        variant: draft ? KBadgeVariant.secondary : KBadgeVariant.success,
        child: KText(draft ? 'Entwurf' : 'Online'),
      ),
      child: KStack(
        gap: KLayoutGap.action,
        align: KLayoutAlign.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: KQrCode(
                    data: 'https://example.invalid/denis',
                    label:
                        'Demo-QR-Code: example.invalid/denis – keine veröffentlichte Buchungsseite',
                    variant: KQrCodeVariant.soft,
                    eyeShape: KQrCodeEyeShape.rounded,
                    size: 64,
                  ),
                ),
              ),
              SizedBox(width: t.spaceContentActionGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KText(
                      'example.invalid/denis',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: first ? 18 : 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    muted(
                      draft
                          ? 'Schließe die Einrichtung ab, bevor du deine Seite veröffentlichst und teilst.'
                          : first
                          ? 'Jetzt geht es darum, dass Leute deine Seite finden.'
                          : 'Teile den Link in deiner Insta-Bio oder zeig den QR-Code vor Ort.',
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!draft && !first)
            stats(const [
              ('186', 'Aufrufe'),
              ('14', 'Buchungen'),
              ('7,5 %', 'Conversion'),
            ]),
          actions(
            button(
              'Kopieren',
              icon: KIconName.copy,
              secondary: true,
              disabled: draft,
            ),
            button('Teilen', icon: KIconName.share, disabled: draft),
          ),
        ],
      ),
    );
    if (!first) return content;
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where((e) => e is! KDesignTokens),
          t.copyWith(
            colorSurfaceRaised: theme.brightness == Brightness.dark
                ? const Color(0xff13334a)
                : const Color(0xffe8f3fa),
            colorBorderDefault: Colors.transparent,
          ),
        ],
      ),
      child: content,
    );
  }

  Widget stats(List<(String, String)> entries) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final e in entries)
        Expanded(
          child: Column(
            children: [
              KText(
                e.$1,
                variant: KTextVariant.heading3,
                style: const TextStyle(fontSize: 18, height: 1.5),
              ),
              KText(
                e.$2,
                variant: KTextVariant.bodySmall,
                align: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: t.colorTextMuted,
                ),
              ),
            ],
          ),
        ),
    ],
  );
  Widget ghost({bool small = false}) => box(
    title: 'Dein Geschäft',
    child: KStack(
      gap: KLayoutGap.action,
      align: KLayoutAlign.stretch,
      children: [
        Opacity(
          opacity: .35,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final labels = small
                  ? ['Umsatz', 'Buchungen']
                  : ['Umsatz', 'Buchungen', 'Neue Kund:innen', 'Auslastung'];
              final columns = small || !wide ? 2 : 4;
              final gap = t.spaceControlGap * 1.25;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              final theme = Theme.of(context);
              return Theme(
                data: theme.copyWith(
                  extensions: [
                    ...theme.extensions.values.where(
                      (e) => e is! KDesignTokens,
                    ),
                    t.copyWith(
                      spaceCardPadding: t.spaceContentActionGap,
                      radiusCard: 16,
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final label in labels)
                      SizedBox(
                        width: width,
                        child: KSurface(
                          tone: KSurfaceTone.subtle,
                          border: KSurfaceBorder.none,
                          radius: KSurfaceRadius.large,
                          // Decision 0010: tiles inside a card are surfaces, never nested cards.
                          child: Padding(
                            padding: EdgeInsets.all(t.spaceControlInsetInline),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                muted(label),
                                const KText(
                                  '–',
                                  variant: KTextVariant.heading2,
                                  style: TextStyle(fontSize: 24, height: 1.5),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: 30,
                                  child: CustomPaint(
                                    painter: _Spark(const [
                                      2,
                                      4,
                                      3,
                                      6,
                                      5,
                                      8,
                                      7,
                                    ], t.colorTextMuted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: t.spaceControlGap * 1.5,
            vertical: t.spaceControlGap * 1.25,
          ),
          decoration: BoxDecoration(
            color: t.colorSurfaceCanvas,
            borderRadius: BorderRadius.circular(12),
          ),
          child: KText(
            small
                ? 'Umsatz, Buchungen und neue Kund:innen erscheinen hier ab der ersten Buchung.'
                : 'Ab deiner ersten Buchung siehst du hier Umsatz, Buchungen und Auslastung.',
            variant: KTextVariant.bodySmall,
            align: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: t.colorTextMuted),
          ),
        ),
      ],
    ),
  );
  Widget check(bool done) => Container(
    width: 26,
    height: 26,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: done ? success : null,
      border: Border.all(
        color: done ? success : t.colorBorderDefault,
        width: 2,
      ),
    ),
    child: done
        ? Center(child: KIcon(KIconName.check, size: 16, color: Colors.white))
        : null,
  );
  Widget setup() {
    const labels = [
      ('Profil & Foto', 'Damit Kund:innen dich erkennen'),
      ('Erste Leistung', 'Mit Preis und Dauer'),
      ('Startadresse', 'Für Anfahrten'),
      ('Zone festlegen', 'Wo man dich buchen kann'),
      ('Zahlungen verbinden', 'Optional · Stripe'),
      ('Seite teilen', 'Nach der Veröffentlichung'),
    ];
    final count = steps.indexed.where((e) => e.$1 != 4 && e.$2).length;
    return columns(
      box(
        child: Column(
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: 64,
                  child: CustomPaint(
                    painter: _Ring(count / 5, success, t.colorSurfaceSubtle),
                    child: Center(
                      child: KText(
                        '$count/5',
                        variant: KTextVariant.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: t.spaceContentActionGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const KText(
                        'Einrichtung',
                        variant: KTextVariant.label,
                        style: TextStyle(fontSize: 17, height: 1.5),
                      ),
                      KText(
                        'Dauert etwa 5 Minuten.',
                        variant: KTextVariant.bodySmall,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: t.colorTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: t.spaceControlGap),
            for (final (i, e) in labels.indexed)
              Container(
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : Border(top: BorderSide(color: t.colorBorderDefault)),
                ),
                child: KButton(
                  label: '${e.$1} ${e.$2}',
                  fullWidth: true,
                  paddingInline: 0,
                  variant: KButtonVariant.ghost,
                  content: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        check(steps[i]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Opacity(
                            opacity: steps[i] ? .55 : 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                KText(
                                  e.$1,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    decoration: steps[i]
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                muted(e.$2),
                              ],
                            ),
                          ),
                        ),
                        if (!steps[i])
                          const KIcon(KIconName.chevronRight, size: 20),
                      ],
                    ),
                  ),
                  onPressed: () {
                    updateState(() => steps[i] = !steps[i]);
                    feedback('${e.$1} – Demostatus geändert');
                  },
                ),
              ),
          ],
        ),
      ),
      stack([share(draft: true), ghost(small: true)]),
    );
  }

  Widget ready() {
    const entries = [
      (
        'Link in deine Instagram-Bio',
        'Die meisten ersten Buchungen kommen von dort',
        'Erledigt',
      ),
      (
        'Bestandskund:innen einladen',
        'Kontakte auswählen und deinen Link teilen',
        'Einladen',
      ),
      (
        'QR-Code ausdrucken',
        'Für Visitenkarte, Auto oder Salon-Spiegel',
        'PDF',
      ),
      (
        'Testbuchung machen',
        'Erlebe deine Seite wie deine Kund:innen',
        'Starten',
      ),
    ];
    return stack([
      columns(
        stack([
          share(first: true),
          box(
            title: 'So kommen die ersten Buchungen',
            end: muted('${tips.where((v) => v).length} von 4'),
            child: Column(
              children: [
                for (final (i, e) in entries.indexed)
                  row(
                    alignment: CrossAxisAlignment.start,
                    divider: i > 0,
                    leading: check(tips[i]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KText(
                          e.$1,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: tips[i] ? t.colorTextMuted : null,
                            decoration: tips[i]
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        muted(e.$2),
                      ],
                    ),
                    trailing: tips[i]
                        ? null
                        : button(
                            e.$3,
                            secondary: true,
                            onPressed: () {
                              updateState(() => tips[i] = true);
                              feedback('${e.$1} – nur Vorschau');
                            },
                          ),
                  ),
              ],
            ),
          ),
        ]),
        stack([
          box(
            title: 'Besuche auf deiner Seite',
            end: link('Details'),
            child: KStack(
              gap: KLayoutGap.action,
              align: KLayoutAlign.stretch,
              children: [
                KInline(
                  gap: KLayoutGap.control,
                  children: [
                    const KText('38', variant: KTextVariant.heading1),
                    KText('+12 heute', style: TextStyle(color: success)),
                  ],
                ),
                bars(
                  [0, 25, 42, 17, 75, 58, 100],
                  ['Do', 'Fr', 'Sa', 'So', 'Mo', 'Di', 'Heute'],
                  todayIndex: 6,
                ),
                stats(const [
                  ('38', 'Besuche'),
                  ('9', 'Leistung gewählt'),
                  ('3', 'bis Terminwahl'),
                ]),
                muted(
                  '3 Personen waren kurz vor der Buchung. Kurze Vorlaufzeiten und mehr freie Termine helfen.',
                ),
              ],
            ),
          ),
          week(ready: true),
        ]),
      ),
      ghost(),
    ]);
  }
}

class _Spark extends CustomPainter {
  const _Spark(this.values, this.color);
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final max = values.reduce(math.max);
    final path = Path();
    for (final (i, value) in values.indexed) {
      final x = i / (values.length - 1) * size.width,
          y = size.height - 2 - value / math.max(1, max) * (size.height - 4);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_Spark old) => old.values != values || old.color != color;
}

class _Ring extends CustomPainter {
  const _Ring(this.value, this.color, this.track);
  final double value;
  final Color color, track;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawOval(rect.deflate(6), paint..color = track);
    canvas.drawArc(
      rect.deflate(6),
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_Ring old) =>
      old.value != value || old.color != color || old.track != track;
}
