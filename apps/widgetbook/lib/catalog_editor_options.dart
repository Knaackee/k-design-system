part of 'catalog_editor_fixture.dart';

class _DemoOption {
  _DemoOption(String name, String price)
    : name = TextEditingController(text: name),
      price = TextEditingController(text: price);
  final TextEditingController name, price;
  bool active = true;
  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _DemoGroup {
  _DemoGroup(String title, List<(String, String)> rows)
    : name = TextEditingController(text: title),
      options = rows.map((r) => _DemoOption(r.$1, r.$2)).toList();
  final TextEditingController name;
  final min = TextEditingController(text: '0'),
      max = TextEditingController(text: '1');
  final List<_DemoOption> options;
  String rule = 'optional';
  void dispose() {
    name.dispose();
    min.dispose();
    max.dispose();
    for (final o in options) {
      o.dispose();
    }
  }
}

extension _CatalogEditorOptions on _CatalogEditorFixtureState {
  Widget optionsSection(KDesignTokens tokens) => KCatalogEditorSection(
    title: 'Zusatzoptionen mit Aufpreis',
    child: KStack(
      gap: KLayoutGap.action,
      align: KLayoutAlign.stretch,
      children: [
        for (final group in groups)
          KCatalogEditorCard(
            inset: false,
            child: KStack(
              gap: KLayoutGap.control,
              align: KLayoutAlign.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.all(tokens.spaceContentActionGap),
                  child: Row(
                    children: [
                      Expanded(child: input('Gruppenname', group.name)),
                      KIconButton(
                        label: 'Gruppe löschen',
                        icon: KIconName.trash,
                        onPressed: () => update(() {
                          groups.remove(group);
                          group.dispose();
                          status = 'Ungespeichert';
                        }),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceControlInsetInline,
                  ),
                  child: KSelect(
                    label: 'Auswahlregel',
                    value: group.rule,
                    options: const [
                      KSelectOption(
                        value: 'optional',
                        label: 'Optional · höchstens 1',
                      ),
                      KSelectOption(
                        value: 'multiple',
                        label: 'Optional · mehrere',
                      ),
                      KSelectOption(
                        value: 'required',
                        label: 'Pflicht · genau 1',
                      ),
                      KSelectOption(value: 'custom', label: 'Eigene Regel …'),
                    ],
                    onChanged: (v) =>
                        update(() => group.rule = v ?? group.rule),
                  ),
                ),
                if (group.rule == 'custom')
                  Padding(
                    padding: EdgeInsets.all(tokens.spaceControlInsetInline),
                    child: Row(
                      children: [
                        Expanded(child: input('Mindestens', group.min)),
                        SizedBox(width: tokens.spaceControlGap),
                        Expanded(child: input('Höchstens', group.max)),
                      ],
                    ),
                  ),
                for (final option in group.options)
                  Padding(
                    padding: EdgeInsets.all(tokens.spaceControlGap),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: input('Option', option.name)),
                        SizedBox(width: tokens.spaceControlGap),
                        SizedBox(
                          width: 80,
                          child: input('Aufpreis', option.price, suffix: '€'),
                        ),
                        KSwitch(
                          label: 'Option aktiv',
                          showLabel: false,
                          value: option.active,
                          onChanged: (v) => update(() => option.active = v),
                        ),
                        KIconButton(
                          label: 'Option löschen',
                          icon: KIconName.x,
                          onPressed: () => update(() {
                            group.options.remove(option);
                            option.dispose();
                            status = 'Ungespeichert';
                          }),
                        ),
                      ],
                    ),
                  ),
                KButton(
                  label: 'Option hinzufügen',
                  variant: KButtonVariant.ghost,
                  leading: const KIcon(KIconName.plus, size: 17),
                  fullWidth: true,
                  onPressed: () => update(() {
                    group.options.add(_DemoOption('', '0'));
                    status = 'Ungespeichert';
                  }),
                ),
              ],
            ),
          ),
        KButton(
          label: 'Gruppe hinzufügen',
          variant: KButtonVariant.secondary,
          leading: const KIcon(KIconName.plus, size: 17),
          fullWidth: true,
          onPressed: () => update(() {
            groups.add(_DemoGroup('Neue Gruppe', []));
            status = 'Ungespeichert';
          }),
        ),
      ],
    ),
  );
}
