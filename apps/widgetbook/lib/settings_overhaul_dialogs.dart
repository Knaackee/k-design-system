import 'dart:async';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'settings_grouped_parts.dart';

final reviewPageSheetPreference = ValueNotifier<bool>(false);

Future<String?> showSettingsReviewDialog(
  BuildContext context,
  String title, {
  String name = '',
  String email = '',
}) {
  final page =
      reviewPageSheetPreference.value &&
      title != 'Abmelden?' &&
      title != 'Konto löschen?';
  Widget builder(BuildContext c) =>
      _SettingsReviewDialog(title, page: page, name: name, email: email);
  return page
      ? KPageSheet.show(context: context, builder: builder)
      : KAdaptiveDialog.show(context: context, builder: builder);
}

class _SettingsReviewDialog extends StatefulWidget {
  const _SettingsReviewDialog(
    this.title, {
    required this.page,
    required this.name,
    required this.email,
  });
  final String title, name, email;
  final bool page;

  @override
  State<_SettingsReviewDialog> createState() => _SettingsReviewDialogState();
}

class _SettingsReviewDialogState extends State<_SettingsReviewDialog> {
  late final input = TextEditingController(
    text: switch (widget.title) {
      'Name bearbeiten' => widget.name,
      'E-Mail ändern' => widget.email,
      _ => '',
    },
  );
  final password = TextEditingController(), repeat = TextEditingController();
  int progress = 0;
  bool showPassword = false;
  Timer? download;

  @override
  void dispose() {
    input.dispose();
    password.dispose();
    repeat.dispose();
    download?.cancel();
    super.dispose();
  }

  void close([String? result]) => Navigator.of(context).pop(result);
  void startDownload() {
    setState(() => progress = 1);
    download = Timer.periodic(const Duration(milliseconds: 180), (timer) {
      setState(() => progress = (progress + 10).clamp(0, 100));
      if (progress == 100) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final title = KText(widget.title, variant: KTextVariant.heading3);
    Widget field(
      String label,
      TextEditingController c, {
      bool secret = false,
    }) => KField(
      label: label,
      child: KInput(
        controller: c,
        obscureText: secret && !showPassword,
        onChanged: (_) => setState(() {}),
      ),
    );
    final contents = switch (widget.title) {
      'Abmelden?' => <Widget>[
        const SgMuted(
          'Du wirst auf diesem Gerät abgemeldet. Deine Daten bleiben erhalten.',
        ),
        destructive(
          t,
          'Abmelden',
          () => close('Abmelden in der Vorschau bestätigt.'),
        ),
        cancel(),
      ],
      'Konto löschen?' => <Widget>[
        const SgMuted(
          'Das Löschen deines Kontos betrifft auch deine Buchungsseite und die zugehörigen Daten.',
        ),
        field('Zum Bestätigen „LÖSCHEN“ eingeben', input),
        destructive(
          t,
          'Konto löschen',
          input.text == 'LÖSCHEN'
              ? () => close('Bestätigung in der Vorschau geprüft.')
              : null,
        ),
        cancel(),
      ],
      'Passwort ändern' => <Widget>[
        field('Aktuelles Passwort', input, secret: true),
        field('Neues Passwort', password, secret: true),
        field('Neues Passwort wiederholen', repeat, secret: true),
        KCheckbox(
          label: 'Passwörter anzeigen',
          value: showPassword,
          onChanged: (value) => setState(() => showPassword = value ?? false),
        ),
        for (final rule in [
          ('Mindestens 12 Zeichen', password.text.length >= 12),
          (
            'Buchstaben und Zahlen',
            RegExp('[A-Za-z]').hasMatch(password.text) &&
                RegExp(r'\d').hasMatch(password.text),
          ),
          (
            'Passwörter stimmen überein',
            password.text.isNotEmpty && repeat.text == password.text,
          ),
        ])
          KInline(
            align: KLayoutAlign.center,
            children: [
              KIcon(rule.$2 ? KIconName.check : KIconName.circle, size: 16),
              Expanded(child: SgMuted(rule.$1)),
            ],
          ),
        KButton(
          label: 'Passwort ändern',
          onPressed:
              input.text.isNotEmpty &&
                  password.text.length >= 12 &&
                  RegExp('[A-Za-z]').hasMatch(password.text) &&
                  RegExp(r'\d').hasMatch(password.text) &&
                  repeat.text == password.text
              ? () => close('Passwort in der Vorschau geprüft.')
              : null,
        ),
        cancel(),
      ],
      'Update verfügbar' => <Widget>[
        const KCard(
          child: KInline(
            gap: KLayoutGap.action,
            children: [
              KIcon(KIconName.download, size: 32),
              Expanded(
                child: KStack(
                  align: KLayoutAlign.stretch,
                  children: [
                    KText('Onzeit 0.1.1', variant: KTextVariant.label),
                    SgMuted('Installiert: 0.1.0+1 · 18 MB'),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (progress == 0) ...[
          const KText('Neu in dieser Version', variant: KTextVariant.label),
          const KStack(
            align: KLayoutAlign.stretch,
            children: [
              KText('• Fahrzeiten zwischen deinen Terminen auf „Heute“'),
              KText('• Feiertage nach Bundesland übernehmen'),
              KText('• Zonen: Zeiten aus einer anderen Zone übernehmen'),
              KText('• Fehlerbehebungen'),
            ],
          ),
          const SgMuted('Das Android-Update wird in der Galerie simuliert.'),
          KButton(
            label: 'Herunterladen & installieren',
            leading: const KIcon(KIconName.download),
            onPressed: startDownload,
          ),
          cancel('Später'),
        ] else if (progress < 100) ...[
          KProgress(
            value: progress.toDouble(),
            label: const Text('Wird heruntergeladen …'),
            valueLabel: SgMuted('${(18 * progress / 100).round()} von 18 MB'),
          ),
          const SgMuted('Du kannst Onzeit währenddessen weiter benutzen.'),
          KButton(
            label: 'Abbrechen',
            variant: KButtonVariant.secondary,
            onPressed: () {
              download?.cancel();
              setState(() => progress = 0);
            },
          ),
        ] else ...[
          const SgStatus('Download abgeschlossen · Simulation', success: true),
          const SgMuted(
            'Auf Android würde anschließend die Installation angeboten. Offene Eingaben vorher speichern.',
          ),
          KButton(
            label: 'Jetzt installieren',
            onPressed: () =>
                close('Installationsschritt in der Vorschau geprüft.'),
          ),
          cancel('Beim nächsten Start'),
        ],
      ],
      _ => <Widget>[
        SgMuted(
          widget.title == 'Name bearbeiten'
              ? 'Dein Profil, wie du es möchtest.'
              : 'Halte deine Kontaktdaten aktuell.',
        ),
        field(
          widget.title == 'Name bearbeiten'
              ? 'Vollständiger Name'
              : 'Neue E-Mail-Adresse',
          input,
        ),
        SgMuted(
          widget.title == 'Name bearbeiten'
              ? 'So wird dein Name in deinem Konto angezeigt.'
              : 'In der Anwendung bestätigst du die neue Adresse per E-Mail, bevor sie übernommen wird.',
        ),
        KInline(
          gap: KLayoutGap.action,
          children: [
            Expanded(child: cancel()),
            Expanded(
              child: KButton(
                label: 'Änderung speichern',
                onPressed:
                    input.text.trim().isEmpty ||
                        widget.title == 'E-Mail ändern' &&
                            !input.text.contains('@')
                    ? null
                    : () => close(input.text.trim()),
              ),
            ),
          ],
        ),
        const SgMuted('Designvorschau · Änderungen gelten nur hier.'),
      ],
    };
    final body = Padding(
      padding: EdgeInsets.only(bottom: t.spaceContentActionGap),
      child: KStack(
        gap: KLayoutGap.action,
        align: KLayoutAlign.stretch,
        children: contents,
      ),
    );
    return widget.page
        ? KPageSheet(
            title: title,
            closeLabel: 'Schließen',
            onClose: close,
            child: body,
          )
        : KAdaptiveDialog(
            title: title,
            closeLabel: 'Schließen',
            onClose: close,
            expandBody: false,
            child: body,
          );
  }

  Widget cancel([String label = 'Abbrechen']) => KButton(
    label: label,
    variant: KButtonVariant.secondary,
    onPressed: close,
  );

  Widget destructive(KDesignTokens t, String label, VoidCallback? onPressed) =>
      Theme(
        data: Theme.of(context).copyWith(
          extensions: [
            t.copyWith(
              colorActionPrimaryBackground: t.colorStatusErrorForeground,
              colorActionPrimaryForeground: t.colorSurfaceCanvas,
            ),
          ],
        ),
        child: KButton(label: label, onPressed: onPressed),
      );
}
