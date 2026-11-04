import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:widgetbook/widgetbook.dart';

import 'deployment_overhaul_fixture.dart';
import 'onzeit_overhaul_day.dart';
import 'onzeit_overhaul_fixture.dart';
import 'settings_grouped_fixture.dart';

Widget _review(Widget child, {bool dark = false, double? previewWidth}) {
  final content = dark
      ? Theme(
          data: kDesignTheme(brightness: Brightness.dark),
          child: child,
        )
      : child;
  if (previewWidth == null) return content;
  return Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: previewWidth),
      child: LayoutBuilder(
        builder: (context, constraints) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(size: Size(constraints.maxWidth, constraints.maxHeight)),
          child: content,
        ),
      ),
    ),
  );
}

WidgetbookCategory onzeitOverhaulGallery() => WidgetbookCategory(
  name: 'Review',
  children: [
    WidgetbookFolder(
      name: 'AppOverhaul',
      children: [
        WidgetbookFolder(
          name: 'Arbeitsalltag',
          children: [
            for (final item in const <(String, String, String?, bool, bool)>[
              ('heute', 'home', null, false, false),
              ('heute-leer', 'home', null, true, false),
              ('heute-dark', 'home', null, false, true),
              ('mein-tag', 'day', null, false, false),
              ('mein-tag-leer', 'day', null, true, false),
              ('tag-anpassen', 'day', 'day', false, false),
              ('kalender', 'calendar', null, false, false),
              ('kalender-leer', 'calendar', null, true, false),
              ('buchungen', 'bookings', null, false, false),
              ('buchungen-leer', 'bookings', null, true, false),
              ('buchungsdetails', 'bookings', 'booking', false, false),
              ('buchungszahlung', 'bookings', 'payment', false, false),
              ('buchung-absagen', 'bookings', 'cancel', false, false),
              ('posteingang', 'inbox', null, false, false),
              ('posteingang-leer', 'inbox', null, true, false),
              ('kunden', 'customers', null, false, false),
              ('kunden-leer', 'customers', null, true, false),
              ('kundendetails', 'customers', 'customer', false, false),
              ('kunde-bearbeiten', 'customers', 'editCustomer', false, false),
              ('kunde-loeschen', 'customers', 'deleteCustomer', false, false),
              ('fotoauswahl', 'customers', 'photo', false, false),
              ('assistent', 'assistant', null, false, false),
              ('assistent-leer', 'assistant', null, true, false),
            ])
              WidgetbookUseCase(
                name: item.$1,
                builder: (_) => _review(
                  OnzeitOverhaulFixture(
                    key: ValueKey(item.$1),
                    initialPage: item.$2,
                    initialOverlay: item.$3,
                    empty: item.$4,
                  ),
                  dark: item.$5,
                ),
              ),
          ],
        ),
      ],
    ),
    WidgetbookFolder(
      name: 'SettingsOverhaul',
      children: [
        for (final item in const <(String, String, String?)>[
          ('profile', 'profile', null),
          ('profile-desktop', 'profile', null),
          ('profile-mobile', 'profile', null),
          ('overview', 'profile', null),
          ('appearance', 'appearance', null),
          ('language', 'language', null),
          ('payments', 'payments', null),
          ('payments-empty', 'payments', null),
          ('integrations', 'integrations', null),
          ('about', 'about', null),
          ('access', 'access', null),
          ('access-empty', 'access', null),
          ('assistant', 'assistant', null),
          ('server', 'server', null),
          ('password', 'profile', 'Passwort ändern'),
          ('logout', 'profile', 'Abmelden?'),
          ('delete-account', 'profile', 'Konto löschen?'),
          ('update', 'about', 'Update verfügbar'),
          ('profile-dark', 'profile', null),
          ('member', 'profile', null),
          ('edit-name', 'profile', 'Name bearbeiten'),
          ('edit-email', 'profile', 'E-Mail ändern'),
        ])
          WidgetbookUseCase(
            name: item.$1,
            builder: (_) => _review(
              SettingsGroupedFixture(
                key: ValueKey(item.$1),
                initialPage: item.$2,
                initialDialog: item.$3,
                admin: item.$1 != 'member',
                overview: item.$1 == 'overview' || item.$1 == 'member',
                emptyAccess: item.$1 == 'access-empty',
                emptyPayments: item.$1 == 'payments-empty',
                overhaul: true,
              ),
              dark: item.$1 == 'profile-dark',
              previewWidth: switch (item.$1) {
                'profile-mobile' => 390,
                'profile-desktop' => 1280,
                _ => null,
              },
            ),
          ),
      ],
    ),
    WidgetbookFolder(
      name: 'DeploymentOverhaul',
      children: [
        for (final item in const <(String, String, String?, bool, bool)>[
          ('times', 'times', null, false, false),
          ('times-dark', 'times', null, false, true),
          ('times-empty', 'times', null, true, false),
          ('zones', 'zones', null, false, false),
          ('zones-dark', 'zones', null, false, true),
          ('zones-empty', 'zones', null, true, false),
          ('history', 'history', null, false, false),
          ('history-dark', 'history', null, false, true),
          ('history-empty', 'history', null, true, false),
          ('private-appointment', 'times', 'private', false, false),
          ('transport-change', 'times', 'transport', false, false),
          ('holiday-import', 'times', 'holidays', false, false),
          ('zone-editor', 'zones', 'zone', false, false),
          ('history-detail', 'history', 'history', false, false),
          ('historical-preview', 'history', 'historyPreview', false, false),
          ('undo-confirmation', 'history', 'undo', false, false),
        ])
          WidgetbookUseCase(
            name: item.$1,
            builder: (_) => _review(
              DeploymentOverhaulFixture(
                key: ValueKey(item.$1),
                initialPage: item.$2,
                initialSheet: item.$3,
                empty: item.$4,
              ),
              dark: item.$5,
            ),
          ),
      ],
    ),
    WidgetbookFolder(
      name: 'PageSheetComparison',
      children: [
        for (final item in const [
          ('page-sheet', OverhaulPresentation.page),
          ('adaptive-dialog', OverhaulPresentation.adaptive),
          ('side-panel', OverhaulPresentation.drawer),
          ('dark', OverhaulPresentation.page),
        ])
          WidgetbookUseCase(
            name: item.$1,
            builder: (_) => _review(
              OverhaulPageSheetFixture(
                key: ValueKey(item.$1),
                initial: item.$2,
              ),
              dark: item.$1 == 'dark',
            ),
          ),
      ],
    ),
  ],
);
