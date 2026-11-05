import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class DataTableOverflowFixture extends StatefulWidget {
  const DataTableOverflowFixture({super.key});

  @override
  State<DataTableOverflowFixture> createState() =>
      _DataTableOverflowFixtureState();
}

class _DataTableOverflowFixtureState extends State<DataTableOverflowFixture> {
  bool _ascending = true;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: SizedBox(
      width: 620,
      child: KStack(
        gap: KLayoutGap.control,
        children: [
          SizedBox(
            width: 620,
            child: KTable(
              label: 'Text overflow',
              columns: [
                KTableColumn(
                  id: 'property',
                  header: KButton(
                    label: 'Wirtschaftseinheit',
                    variant: KButtonVariant.ghost,
                    paddingInline: 0,
                    trailing: KIcon(
                      _ascending ? KIconName.arrowUp : KIconName.arrowDown,
                    ),
                    onPressed: () => setState(() => _ascending = !_ascending),
                  ),
                  width: 180,
                ),
                const KTableColumn(
                  id: 'owner',
                  header: Text('Verantwortliche Person'),
                  width: 140,
                ),
                const KTableColumn(
                  id: 'budget',
                  header: Text('Budget'),
                  width: 140,
                  align: KTableAlign.end,
                  overflow: KTableTextOverflow.visible,
                ),
                const KTableColumn(
                  id: 'actions',
                  header: Text('Aktionen'),
                  width: 160,
                  overflow: KTableTextOverflow.visible,
                ),
              ],
              rows: [
                KTableRow(
                  id: 'property-1',
                  cells: [
                    const Text('Wohnquartier Am Sonnenhang mit langem Namen'),
                    const Text('Alexandra Musterfrau'),
                    const Text('1.234.567,89 €'),
                    KButton(
                      label: 'Wirtschaftseinheit öffnen',
                      variant: KButtonVariant.ghost,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 320,
            child: KTable(
              label: 'Multiline description',
              columns: [
                KTableColumn(
                  id: 'description',
                  header: Text('Beschreibung'),
                  overflow: KTableTextOverflow.wrap,
                ),
              ],
              rows: [
                KTableRow(
                  id: 'description-1',
                  cells: [
                    Text(
                      'Diese Beschreibung darf ausdrücklich mehrere Zeilen verwenden. Alle anderen Textspalten bleiben einzeilig.',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
