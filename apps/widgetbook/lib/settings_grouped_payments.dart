import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'settings_grouped_parts.dart';

class SgPayments extends StatefulWidget {
  const SgPayments({this.empty = false, this.overhaul = false, super.key});
  final bool empty, overhaul;
  @override
  State<SgPayments> createState() => _SgPaymentsState();
}

class _Payment {
  _Payment(
    this.name,
    this.service,
    this.day,
    this.time,
    this.amount,
    this.state,
  );
  final String name, service, day, time;
  final double amount;
  String state;
}

class _SgPaymentsState extends State<SgPayments> {
  late final payments = widget.empty
      ? <_Payment>[]
      : widget.overhaul
      ? [
          _Payment(
            'Beatrice Romano',
            'Einzeltraining',
            'Heute · Di, 3. Nov',
            '08:20',
            85,
            'Zu bestätigen',
          ),
          _Payment(
            'Riccardo Costa',
            'Mobilitäts-Session',
            'Heute · Di, 3. Nov',
            '11:20',
            65,
            'Zu bestätigen',
          ),
          _Payment(
            'Elisa Ferrari',
            'Einzeltraining',
            'Heute · Di, 3. Nov',
            '11:50',
            85,
            'Bezahlt',
          ),
          _Payment(
            'Luca Moretti',
            'Personal Training',
            'Gestern · Mo, 2. Nov',
            '14:10',
            95,
            'Erstattet',
          ),
          _Payment(
            'Anna Weber',
            'Mobilitäts-Session',
            'Gestern · Mo, 2. Nov',
            '16:00',
            65,
            'Abgelaufen',
          ),
        ]
      : [
          _Payment(
            'Beatrice Romano',
            'Einzeltraining',
            'Heute · Di, 3. Nov',
            '08:20',
            85,
            'Zu bestätigen',
          ),
          _Payment(
            'Riccardo Costa',
            'Mobilitäts-Session',
            'Heute · Di, 3. Nov',
            '11:20',
            65,
            'Zu bestätigen',
          ),
          _Payment(
            'Elisa Ferrari',
            'Outdoor-Training',
            'Gestern · Mo, 2. Nov',
            '14:20',
            75,
            'Zu bestätigen',
          ),
          _Payment(
            'Sara Villa',
            'Erstgespräch & erste Session',
            'Gestern · Mo, 2. Nov',
            '15:05',
            62.43,
            'Bezahlt',
          ),
          _Payment(
            'Anna Riva',
            'Mobilitäts-Session',
            'Gestern · Mo, 2. Nov',
            '16:05',
            36.69,
            'Erstattet',
          ),
          _Payment(
            'Leonardo Marino',
            'Erstgespräch',
            'Fr, 30. Okt',
            '10:00',
            36.69,
            'Bezahlt',
          ),
          _Payment(
            'Francesco Rossi',
            'Outdoor-Training',
            'Fr, 30. Okt',
            '13:20',
            85,
            'Bezahlt',
          ),
          _Payment(
            'Giulia Bianchi',
            'Mobilitäts-Session',
            'Do, 29. Okt',
            '09:45',
            36.69,
            'Abgelaufen',
          ),
        ];
  String filter = 'Alle';
  bool checks = false;
  String euro(double amount) =>
      '${amount.toStringAsFixed(2).replaceAll('.', ',')} €';
  @override
  Widget build(BuildContext context) {
    final todo = payments.where((p) => p.state == 'Zu bestätigen').toList();
    final history = payments
        .where(
          (p) =>
              p.state != 'Zu bestätigen' &&
              (filter == 'Alle' ||
                  filter == p.state ||
                  filter == 'Andere' && p.state == 'Abgelaufen'),
        )
        .toList();
    return KStack(
      gap: KLayoutGap.section,
      align: KLayoutAlign.stretch,
      children: [
        const SgStatus('Testmodus · Beispieldaten', warning: true),
        SgGroup(
          children: [
            SgInset(
              child: KStack(
                gap: KLayoutGap.action,
                align: KLayoutAlign.stretch,
                children: [
                  KInline(
                    gap: KLayoutGap.control,
                    children: [
                      const KAvatar(alt: 'Stripe', fallback: KText('S')),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KText('Stripe'),
                            SgMuted('✓ Verbunden'),
                            SgMuted('Auszahlungen aktiv'),
                          ],
                        ),
                      ),
                      KButton(
                        label: 'Öffnen',
                        variant: KButtonVariant.secondary,
                        leading: const KIcon(KIconName.externalLink, size: 16),
                        onPressed: () => sgDialog(
                          context,
                          'Stripe',
                          const KText(
                            'In der Anwendung öffnet diese Aktion dein Stripe-Dashboard. Diese Story verwendet ausschließlich Beispieldaten.',
                          ),
                        ),
                      ),
                    ],
                  ),
                  KButton(
                    label: 'Einrichtung abgeschlossen · 3 von 3',
                    variant: KButtonVariant.ghost,
                    trailing: KIcon(
                      checks ? KIconName.chevronDown : KIconName.chevronRight,
                    ),
                    onPressed: () => setState(() => checks = !checks),
                  ),
                  if (checks)
                    for (final s in [
                      'Konto verbunden',
                      'Angaben zum Business geprüft',
                      'Auszahlungskonto hinterlegt',
                    ])
                      KText('✓ $s'),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            for (final pair in [
              (
                euro(
                  payments
                      .where((p) => p.state == 'Bezahlt')
                      .fold<double>(0, (n, p) => n + p.amount),
                ),
                'November',
              ),
              ('${todo.length}', 'zu bestätigen'),
              (
                '${payments.where((p) => p.state == 'Erstattet').length}',
                'erstattet',
              ),
            ])
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KText(pair.$1, variant: KTextVariant.heading3),
                    SgMuted(pair.$2),
                  ],
                ),
              ),
          ],
        ),
        if (todo.isNotEmpty)
          SgGroup(
            title: 'Zu bestätigen',
            footer:
                'Bestätige, dass der Termin stattgefunden hat. Danach wird die Zahlung abgeschlossen.',
            children: [
              for (final p in todo)
                SgInset(
                  child: KInline(
                    gap: KLayoutGap.control,
                    children: [
                      KAvatar(alt: p.name),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KText(p.name),
                            SgMuted(
                              '${p.service} · ${p.time} · ${euro(p.amount)}',
                            ),
                          ],
                        ),
                      ),
                      KButton(
                        label: 'Bestätigen',
                        onPressed: () => setState(() => p.state = 'Bezahlt'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        KStack(
          gap: KLayoutGap.control,
          align: KLayoutAlign.stretch,
          children: [
            const SgMuted('Buchungszahlungen'),
            SgChoices(
              items: const ['Alle', 'Bezahlt', 'Erstattet', 'Andere'],
              value: filter,
              onChanged: (v) => setState(() => filter = v),
            ),
            if (history.isEmpty)
              SgGroup(
                children: [
                  SgInset(
                    child: SgMuted(
                      payments.isEmpty
                          ? 'Noch keine Buchungszahlungen. Sobald jemand online bezahlt, siehst du es hier.'
                          : 'Keine Buchungszahlungen in diesem Status.',
                    ),
                  ),
                ],
              ),
            for (final day in history.map((p) => p.day).toSet())
              SgGroup(
                title: day,
                children: [
                  for (final p in history.where((p) => p.day == day))
                    KButton(
                      label: 'Zahlung ${p.name}',
                      fullWidth: true,
                      variant: KButtonVariant.ghost,
                      onPressed: () => _details(context, p),
                      content: SgInset(
                        child: KInline(
                          gap: KLayoutGap.control,
                          children: [
                            KAvatar(alt: p.name),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  KText(p.name),
                                  SgMuted('${p.service} · ${p.time}'),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                KText(euro(p.amount)),
                                SgStatus(
                                  p.state,
                                  success: p.state == 'Bezahlt',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  void _details(BuildContext context, _Payment p) => sgDialog(
    context,
    'Zahlung',
    KStack(
      gap: KLayoutGap.section,
      align: KLayoutAlign.stretch,
      children: [
        KStack(
          gap: KLayoutGap.control,
          align: KLayoutAlign.center,
          children: [
            const SgMuted('Buchungsbetrag'),
            KText(euro(p.amount), variant: KTextVariant.heading2),
            SgStatus(p.state, success: p.state == 'Bezahlt'),
          ],
        ),
        KStack(
          gap: KLayoutGap.control,
          align: KLayoutAlign.center,
          children: [
            KAvatar(alt: p.name),
            KText(p.name),
          ],
        ),
        for (final group in [
          ('Termin', [('Datum', p.day), ('Uhrzeit', '${p.time} Uhr')]),
          ('Leistungen', [('Leistung', p.service)]),
          ('Abrechnung', [('Gesamtbetrag', euro(p.amount))]),
        ])
          SgGroup(
            title: group.$1,
            children: [
              for (final item in group.$2)
                SgInset(
                  child: Row(
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
  );
}
