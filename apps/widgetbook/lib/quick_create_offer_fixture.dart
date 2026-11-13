import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'offer_overview_fixture.dart';

/// UI-only review of the same creation action in the overview and shell FAB.
class QuickCreateOfferFixture extends StatefulWidget {
  const QuickCreateOfferFixture({super.key});
  @override
  State<QuickCreateOfferFixture> createState() =>
      _QuickCreateOfferFixtureState();
}

class _QuickCreateOfferFixtureState extends State<QuickCreateOfferFixture> {
  String _selected = '';

  static const _options = [
    ('Termin', KIconName.calendar),
    ('Kund:in', KIconName.users),
    ('Leistung', KIconName.clock),
    ('Produkt', KIconName.package),
    ('Privater Termin', KIconName.lock),
  ];
  void _select(String label) => setState(() => _selected = label);

  Widget _action(bool floating) => floating
      ? KFab(
          label: 'Neu erstellen',
          showLabels: true,
          child: const KIcon(KIconName.plus),
          items: [
            for (final option in _options)
              KFabItem(
                id: option.$1,
                label: option.$1,
                child: KIcon(option.$2),
                onSelected: () => _select(option.$1),
              ),
          ],
        )
      : KMenuButton(
          label: 'Neu erstellen',
          triggerContent: const KIcon(KIconName.plus),
          actions: [
            for (final option in _options)
              KMenuAction(
                id: option.$1,
                label: option.$1,
                icon: option.$2,
                onSelect: () => _select(option.$1),
              ),
          ],
        );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final phone = constraints.maxWidth < 600;
      final floating =
          phone && KAdaptive.maybeOf(context)?.style == KStyle.material;
      return KAppShell(
        primaryActionPlacement: KPrimaryActionPlacement.auto,
        destinations: const [
          KAppDestination(
            id: 'offers',
            label: 'Angebot',
            icon: KIconName.store,
          ),
          KAppDestination(
            id: 'calendar',
            label: 'Kalender',
            icon: KIconName.calendar,
          ),
        ],
        selectedId: 'offers',
        onSelected: (_) {},
        child: Column(
          children: [
            KPageHeader(
              title: 'Angebot',
              actions: [if (phone) _action(floating)],
            ),
            KText(
              _selected.isEmpty
                  ? 'UI-Vorschau'
                  : '$_selected ausgewählt · UI-Vorschau',
            ),
            Expanded(
              child: OfferOverviewFixture(
                headerAction: phone ? const SizedBox.shrink() : _action(false),
                embedded: true,
              ),
            ),
          ],
        ),
      );
    },
  );
}
