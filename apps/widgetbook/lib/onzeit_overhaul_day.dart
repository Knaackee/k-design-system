import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'settings_grouped_parts.dart';

final _germanCalendar = const KLocalizationData(locale: 'de-DE').calendar();

String overhaulMonthLabel(DateTime date) =>
    '${(_germanCalendar['months'] as List)[date.month - 1]} ${date.year}';

String overhaulDateLabel(DateTime date) =>
    '${(_germanCalendar['weekdays'] as List)[date.weekday % 7]}, ${date.day}. ${overhaulMonthLabel(date)}';

enum OverhaulPresentation { adaptive, drawer, page }

class OverhaulDayDraft {
  const OverhaulDayDraft({
    this.date,
    this.off = false,
    this.start = '08:00',
    this.end = '18:00',
    this.startPlace = 'Kochstraße 21, Leipzig',
    this.endPlace = 'Kochstraße 21, Leipzig',
    this.mode = 'Auto',
    this.firstIn = true,
    this.lastIn = true,
  });
  final DateTime? date;
  final bool off, firstIn, lastIn;
  final String start, end, startPlace, endPlace, mode;

  DateTime get day => date ?? DateTime(2026, 11, 3);
}

Future<OverhaulDayDraft?> showOverhaulDay(
  BuildContext context,
  OverhaulDayDraft saved, {
  OverhaulPresentation presentation = OverhaulPresentation.adaptive,
}) {
  Widget form(BuildContext c) =>
      _OverhaulDayForm(saved: saved, presentation: presentation);
  return switch (presentation) {
    OverhaulPresentation.adaptive => KAdaptiveDialog.show(
      context: context,
      builder: form,
      barrierDismissible: false,
    ),
    OverhaulPresentation.page => KPageSheet.show(
      context: context,
      builder: form,
      barrierDismissible: false,
    ),
    OverhaulPresentation.drawer => KResponsiveDrawer.show(
      context: context,
      title: const KText('Tag anpassen', variant: KTextVariant.heading3),
      closeLabel: 'Schließen',
      dismissible: false,
      child: Builder(builder: form),
    ),
  };
}

class _OverhaulDayForm extends StatefulWidget {
  const _OverhaulDayForm({required this.saved, required this.presentation});
  final OverhaulDayDraft saved;
  final OverhaulPresentation presentation;

  @override
  State<_OverhaulDayForm> createState() => _OverhaulDayFormState();
}

class _OverhaulDayFormState extends State<_OverhaulDayForm> {
  late final start = TextEditingController(text: widget.saved.start);
  late final end = TextEditingController(text: widget.saved.end);
  late final startPlace = TextEditingController(text: widget.saved.startPlace);
  late final endPlace = TextEditingController(text: widget.saved.endPlace);
  late DateTime date = widget.saved.day;
  late bool off = widget.saved.off,
      firstIn = widget.saved.firstIn,
      lastIn = widget.saved.lastIn;
  late String mode = widget.saved.mode;
  bool discard = false;

  @override
  void dispose() {
    for (final c in [start, end, startPlace, endPlace]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get dirty =>
      date != widget.saved.day ||
      off != widget.saved.off ||
      firstIn != widget.saved.firstIn ||
      lastIn != widget.saved.lastIn ||
      mode != widget.saved.mode ||
      start.text != widget.saved.start ||
      end.text != widget.saved.end ||
      startPlace.text != widget.saved.startPlace ||
      endPlace.text != widget.saved.endPlace;

  void reset() {
    const defaults = OverhaulDayDraft();
    setState(() {
      start.text = defaults.start;
      end.text = defaults.end;
      startPlace.text = defaults.startPlace;
      endPlace.text = defaults.endPlace;
      off = defaults.off;
      firstIn = defaults.firstIn;
      lastIn = defaults.lastIn;
      mode = defaults.mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final time = RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]$');
    final valid =
        off ||
        time.hasMatch(start.text) &&
            time.hasMatch(end.text) &&
            start.text.compareTo(end.text) < 0 &&
            startPlace.text.trim().isNotEmpty &&
            endPlace.text.trim().isNotEmpty;
    final t = Theme.of(context).extension<KDesignTokens>()!;
    const standard = OverhaulDayDraft();
    final changeCount = [
      off != standard.off,
      start.text != standard.start,
      end.text != standard.end,
      startPlace.text != standard.startPlace,
      endPlace.text != standard.endPlace,
      firstIn != standard.firstIn,
      lastIn != standard.lastIn,
      mode != standard.mode,
    ].where((changed) => changed).length;
    String status(bool changed) => changed ? 'Abweichung' : 'Standard';

    void close() {
      if (dirty) {
        setState(() => discard = true);
      } else {
        Navigator.of(context).pop();
      }
    }

    const title = KText('Tag anpassen', variant: KTextVariant.heading3);
    final actions = KInline(
      gap: KLayoutGap.control,
      wrap: true,
      children: [
        KButton(
          label: 'Alles zurücksetzen',
          variant: KButtonVariant.secondary,
          onPressed: reset,
        ),
        KButton(
          label: 'Übernehmen',
          onPressed: !valid
              ? null
              : () {
                  Navigator.of(context).pop(
                    OverhaulDayDraft(
                      date: date,
                      off: off,
                      start: start.text,
                      end: end.text,
                      startPlace: startPlace.text,
                      endPlace: endPlace.text,
                      mode: mode,
                      firstIn: firstIn,
                      lastIn: lastIn,
                    ),
                  );
                },
        ),
      ],
    );
    final body = Padding(
      padding: EdgeInsets.only(bottom: t.spaceContentActionGap),
      child: KStack(
        gap: KLayoutGap.action,
        align: KLayoutAlign.stretch,
        children: [
          KInline(
            wrap: true,
            children: [
              for (final item in const [
                (3, 'Heute'),
                (4, 'Morgen'),
                (5, 'Donnerstag'),
              ])
                KButton(
                  label: item.$2,
                  variant:
                      date.year == 2026 &&
                          date.month == 11 &&
                          date.day == item.$1
                      ? KButtonVariant.primary
                      : KButtonVariant.secondary,
                  onPressed: () =>
                      setState(() => date = DateTime(2026, 11, item.$1)),
                ),
            ],
          ),
          KInline(
            align: KLayoutAlign.center,
            children: [
              KIconButton(
                icon: KIconName.chevronLeft,
                label: 'Vorheriger Tag',
                onPressed: () => setState(
                  () => date = date.subtract(const Duration(days: 1)),
                ),
              ),
              Expanded(
                child: KText(
                  overhaulDateLabel(date),
                  variant: KTextVariant.label,
                ),
              ),
              KIconButton(
                icon: KIconName.chevronRight,
                label: 'Nächster Tag',
                onPressed: () =>
                    setState(() => date = date.add(const Duration(days: 1))),
              ),
            ],
          ),
          SgMuted(
            changeCount == 0
                ? 'Es gelten deine Standards.'
                : '$changeCount ${changeCount == 1 ? 'Abweichung' : 'Abweichungen'} für diesen Tag',
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 480 ? 2 : 4;
              final width =
                  (constraints.maxWidth - (columns - 1) * t.spaceControlGap) /
                  columns;
              return KInline(
                wrap: true,
                children: [
                  for (final item in <(String, KIconName, VoidCallback)>[
                    ('Freier Tag', KIconName.bed, () => off = true),
                    (
                      'Später Start',
                      KIconName.sunrise,
                      () {
                        off = false;
                        start.text = '10:00';
                      },
                    ),
                    (
                      'Früher Feierabend',
                      KIconName.moon,
                      () {
                        off = false;
                        end.text = '15:00';
                      },
                    ),
                    (
                      'Start im Studio',
                      KIconName.mapPin,
                      () {
                        off = false;
                        startPlace.text = 'Karl-Liebknecht-Straße 36, Leipzig';
                      },
                    ),
                  ])
                    SizedBox(
                      width: width,
                      child: KButton(
                        label: item.$1,
                        fullWidth: true,
                        variant: KButtonVariant.secondary,
                        leading: KIcon(item.$2, size: 18),
                        onPressed: () => setState(item.$3),
                      ),
                    ),
                ],
              );
            },
          ),
          SgGroup(
            children: [
              SgInset(
                child: KSwitch(
                  label: 'Freier Tag',
                  value: off,
                  onChanged: (value) => setState(() => off = value),
                ),
              ),
            ],
          ),
          if (!off) ...[
            SgGroup(
              title: 'Arbeitszeit',
              children: [
                SgInset(
                  child: KField(
                    label: 'Von',
                    helperText: status(start.text != standard.start),
                    child: KInput(
                      controller: start,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                SgInset(
                  child: KField(
                    label: 'Bis',
                    helperText: status(end.text != standard.end),
                    errorText: valid ? null : 'Prüfe Zeiten und Standorte.',
                    child: KInput(
                      controller: end,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ],
            ),
            SgGroup(
              title: 'Standorte',
              children: [
                SgInset(
                  child: KField(
                    label: 'Startort',
                    helperText: status(startPlace.text != standard.startPlace),
                    child: KInput(
                      controller: startPlace,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                SgInset(
                  child: KField(
                    label: 'Endort',
                    helperText: status(endPlace.text != standard.endPlace),
                    child: KInput(
                      controller: endPlace,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ],
            ),
            SgGroup(
              title: 'Fahrten',
              children: [
                SgInset(
                  child: KSwitch(
                    label: 'Erste Fahrt in der Arbeitszeit',
                    value: firstIn,
                    onChanged: (value) => setState(() => firstIn = value),
                  ),
                ),
                SgInset(
                  child: KSwitch(
                    label: 'Letzte Fahrt in der Arbeitszeit',
                    value: lastIn,
                    onChanged: (value) => setState(() => lastIn = value),
                  ),
                ),
              ],
            ),
            KField(
              label: 'Verkehrsmittel',
              child: KSelect(
                value: mode,
                options: const [
                  KSelectOption(value: 'Auto', label: 'Auto'),
                  KSelectOption(value: 'Fahrrad', label: 'Fahrrad'),
                  KSelectOption(value: 'Zu Fuß', label: 'Zu Fuß'),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => mode = value);
                },
              ),
            ),
          ],
          const SgMuted('Zeitzone Europa/Berlin.'),
          if (discard)
            SgGroup(
              title: 'Änderungen verwerfen?',
              children: [
                SgInset(
                  child: KInline(
                    wrap: true,
                    children: [
                      KButton(
                        label: 'Weiter bearbeiten',
                        variant: KButtonVariant.secondary,
                        onPressed: () => setState(() => discard = false),
                      ),
                      KButton(
                        label: 'Verwerfen',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
    return switch (widget.presentation) {
      OverhaulPresentation.adaptive => KAdaptiveDialog(
        title: title,
        actions: actions,
        onClose: close,
        closeLabel: 'Schließen',
        child: body,
      ),
      OverhaulPresentation.page => KPageSheet(
        title: title,
        actions: actions,
        onClose: close,
        closeLabel: 'Schließen',
        child: body,
      ),
      OverhaulPresentation.drawer => KStack(
        gap: KLayoutGap.action,
        align: KLayoutAlign.stretch,
        children: [
          KButton(
            label: 'Schließen',
            variant: KButtonVariant.ghost,
            onPressed: close,
          ),
          body,
          actions,
        ],
      ),
    };
  }
}

class OverhaulPageSheetFixture extends StatefulWidget {
  const OverhaulPageSheetFixture({
    this.initial = OverhaulPresentation.page,
    super.key,
  });
  final OverhaulPresentation initial;

  @override
  State<OverhaulPageSheetFixture> createState() =>
      _OverhaulPageSheetFixtureState();
}

class _OverhaulPageSheetFixtureState extends State<OverhaulPageSheetFixture> {
  late OverhaulPresentation presentation = widget.initial;
  OverhaulDayDraft saved = const OverhaulDayDraft();
  String notice = '';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Material(
      color: t.colorSurfaceCanvas,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(t.spaceLayoutGutter),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: t.layoutPanelWidth * 2),
            child: KStack(
              gap: KLayoutGap.section,
              align: KLayoutAlign.stretch,
              children: [
                const SgMuted('OVERLAY-VERGLEICH · WIDGETBOOK'),
                const KText(
                  'Ein Tag. Drei Darstellungen.',
                  variant: KTextVariant.heading2,
                ),
                const KText(
                  'Gleicher Inhalt und gleiche Aktionen in drei Präsentationen.',
                ),
                KField(
                  label: 'Darstellung',
                  child: KSelect(
                    value: presentation.name,
                    options: const [
                      KSelectOption(
                        value: 'adaptive',
                        label: 'Dialog / Bottom Sheet',
                      ),
                      KSelectOption(
                        value: 'drawer',
                        label: 'Seitenleiste / Bottom Sheet',
                      ),
                      KSelectOption(value: 'page', label: 'Page Sheet'),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(
                          () => presentation = OverhaulPresentation.values
                              .byName(value),
                        );
                      }
                    },
                  ),
                ),
                KCard(
                  child: KStack(
                    gap: KLayoutGap.action,
                    align: KLayoutAlign.stretch,
                    children: [
                      SgMuted(overhaulDateLabel(saved.day)),
                      const KText('Mein Tag', variant: KTextVariant.heading3),
                      KText(
                        saved.off
                            ? 'Freier Tag'
                            : '${saved.start}–${saved.end} · ${saved.startPlace}',
                      ),
                      KButton(
                        label: 'Tag anpassen',
                        onPressed: () async {
                          final next = await showOverhaulDay(
                            context,
                            saved,
                            presentation: presentation,
                          );
                          if (!mounted || next == null) return;
                          setState(() {
                            saved = next;
                            notice = 'In dieser Vorschau übernommen.';
                          });
                        },
                      ),
                      if (notice.isNotEmpty) SgMuted(notice),
                    ],
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
