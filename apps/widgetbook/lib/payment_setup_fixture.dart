import 'dart:async';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:url_launcher/url_launcher.dart';

const paymentSetupFixtureIds = [
  'payment-setup-needs-correction',
  'payment-setup-connected',
  'payment-setup-action-required',
  'payment-setup-pending',
  'payment-setup-ready',
  'payment-setup-long-content',
];

const _copy = {
  KPaymentSetupState.connected: (
    label: 'Verbindung hergestellt',
    title: 'Mach dein Zahlungskonto startklar',
    description:
        'Dein Stripe-Konto ist mit Onzeit verbunden. Ergänze jetzt die Angaben, damit Kunden bei der Buchung bezahlen können.',
    action: 'Einrichtung starten',
    note: 'Halte deine Geschäfts-, Identitäts- und Bankdaten bereit.',
  ),
  KPaymentSetupState.actionRequired: (
    label: 'Einrichtung offen',
    title: 'Es fehlen noch ein paar Angaben',
    description:
        'Stripe benötigt noch Informationen zu deinem Unternehmen oder deinem Auszahlungskonto. Deine bisherigen Angaben bleiben erhalten.',
    action: 'Einrichtung fortsetzen',
    note: 'Stripe kann für die sichere Anmeldung ein eigenes Fenster öffnen.',
  ),
  KPaymentSetupState.pending: (
    label: 'In Prüfung',
    title: 'Deine Angaben werden geprüft',
    description:
        'Alles wurde übermittelt. Stripe prüft dein Zahlungskonto; du musst derzeit nichts ergänzen.',
    action: null,
    note:
        'Zahlungen sind nach der Freigabe möglich. Prüfe den Status später erneut.',
  ),
  KPaymentSetupState.needsCorrection: (
    label: 'Angaben prüfen',
    title: 'Stripe braucht eine Korrektur',
    description:
        'Deine Einrichtung wurde übermittelt. Stripe konnte einige Identitätsangaben nicht bestätigen und benötigt deine Prüfung.',
    action: 'Angaben prüfen',
    note: 'Dein Konto bleibt verbunden. Du beginnst nicht wieder von vorn.',
  ),
  KPaymentSetupState.ready: (
    label: 'Zahlungsbereit',
    title: 'Dein Zahlungskonto ist bereit',
    description:
        'Kunden können ihre Buchung jetzt online bezahlen. Zahlungen und Auszahlungen findest du in deiner Übersicht.',
    action: 'Zahlungen ansehen',
    note:
        'Auszahlungen erst nach erbrachter Leistung. Banklaufzeiten werden separat berücksichtigt.',
  ),
};

List<KPaymentSetupStep> paymentSetupSteps(KPaymentSetupState state) {
  final reviewing =
      state == KPaymentSetupState.pending || state == KPaymentSetupState.ready;
  return [
    const KPaymentSetupStep(
      id: 'connection',
      label: 'Verbindung',
      description: 'Hergestellt',
      state: KPaymentSetupStepState.complete,
    ),
    KPaymentSetupStep(
      id: 'setup',
      label: 'Einrichtung',
      description: state == KPaymentSetupState.needsCorrection
          ? 'Korrektur nötig'
          : reviewing
          ? 'Übermittelt'
          : 'Angaben ergänzen',
      state: state == KPaymentSetupState.needsCorrection
          ? KPaymentSetupStepState.attention
          : reviewing
          ? KPaymentSetupStepState.complete
          : KPaymentSetupStepState.current,
    ),
    KPaymentSetupStep(
      id: 'verification',
      label: 'Prüfung',
      description: state == KPaymentSetupState.ready
          ? 'Freigegeben'
          : state == KPaymentSetupState.pending
          ? 'Bei Stripe'
          : 'Noch ausstehend',
      state: state == KPaymentSetupState.ready
          ? KPaymentSetupStepState.complete
          : state == KPaymentSetupState.pending
          ? KPaymentSetupStepState.current
          : KPaymentSetupStepState.waiting,
    ),
  ];
}

class PaymentSetupFixture extends StatefulWidget {
  const PaymentSetupFixture({
    this.state = KPaymentSetupState.needsCorrection,
    this.longContent = false,
    super.key,
  });
  final KPaymentSetupState state;
  final bool longContent;
  @override
  State<PaymentSetupFixture> createState() => _PaymentSetupFixtureState();
}

class _PaymentSetupFixtureState extends State<PaymentSetupFixture> {
  late KPaymentSetupState _state = widget.state;
  bool _busy = false;
  String _notice = '';
  Timer? _timer;

  @override
  void didUpdateWidget(PaymentSetupFixture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      _timer?.cancel();
      _state = widget.state;
      _busy = false;
      _notice = '';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _simulate(KPaymentSetupState state) {
    setState(() => _busy = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          _state = state;
          _busy = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final value = _copy[_state]!;
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: t.spaceLayoutSectionGap + t.spaceLayoutGutter,
            horizontal: t.spaceLayoutGutter,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: t.layoutContentWidth),
            child: KStack(
              gap: KLayoutGap.section,
              align: KLayoutAlign.stretch,
              children: [
                KStack(
                  gap: KLayoutGap.control,
                  align: KLayoutAlign.stretch,
                  children: [
                    const KText('Zahlungen', variant: KTextVariant.heading2),
                    KText(
                      'Online bezahlt. Nach der Leistung ausgezahlt.',
                      style: TextStyle(color: t.colorTextMuted),
                    ),
                  ],
                ),
                KPaymentSetup(
                  state: _state,
                  providerName: 'Stripe',
                  connectionLabel: 'Mit Onzeit verbunden',
                  environmentLabel: 'Testmodus',
                  statusLabel: value.label,
                  title: widget.longContent
                      ? 'Stripe benötigt eine erneute Prüfung deiner übermittelten Unternehmens- und Identitätsangaben'
                      : value.title,
                  description: value.description,
                  note: value.note,
                  steps: paymentSetupSteps(_state),
                  stepsLabel: 'Einrichtung deines Zahlungskontos',
                  primaryAction: value.action == null
                      ? null
                      : KPaymentSetupAction(
                          label: value.action!,
                          loading: _busy,
                          icon: KIconName.arrowRight,
                          onAction: () {
                            if (_state == KPaymentSetupState.ready) {
                              setState(
                                () => _notice =
                                    'In der Anwendung öffnet sich jetzt die Zahlungsübersicht.',
                              );
                              return;
                            }
                            _simulate(
                              _state == KPaymentSetupState.connected
                                  ? KPaymentSetupState.actionRequired
                                  : KPaymentSetupState.pending,
                            );
                          },
                        ),
                  secondaryAction: _state == KPaymentSetupState.connected
                      ? null
                      : KPaymentSetupAction(
                          label: 'Status aktualisieren',
                          icon: KIconName.refreshCw,
                          loading:
                              _state == KPaymentSetupState.pending && _busy,
                          disabled:
                              _state != KPaymentSetupState.pending && _busy,
                          onAction: () => _state == KPaymentSetupState.pending
                              ? _simulate(KPaymentSetupState.ready)
                              : setState(
                                  () => _notice =
                                      'Der angezeigte Status ist aktuell.',
                                ),
                        ),
                  help: KPaymentSetupHelp(
                    title: 'Testmodus: So funktioniert die Prüfung',
                    child: KStack(
                      gap: KLayoutGap.control,
                      align: KLayoutAlign.stretch,
                      children: [
                        const KText(
                          'Hier fließt kein echtes Geld. Stripe verwendet besondere Testdaten; normale Angaben können im Test bewusst als nicht bestätigt erscheinen.',
                          variant: KTextVariant.bodySmall,
                        ),
                        const KText(
                          'Für eine erfolgreiche simulierte Prüfung nennt Stripe zum Beispiel das Geburtsdatum 01.01.1901. Verwende Testdaten bewusst und nur in der Sandbox.',
                          variant: KTextVariant.bodySmall,
                        ),
                        KLink(
                          label: 'Offizielle Stripe-Testdaten ansehen',
                          onPressed: () => unawaited(
                            launchUrl(
                              Uri.parse(
                                'https://docs.stripe.com/connect/testing#test-dates-of-birth',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Semantics(
                  liveRegion: true,
                  child: KText(
                    _notice.isNotEmpty
                        ? _notice
                        : 'Interaktive Widgetbook-Vorschau. Keine Verbindung zu Stripe; Zustandswechsel sind simuliert.',
                    variant: KTextVariant.caption,
                    style: TextStyle(color: t.colorTextMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
