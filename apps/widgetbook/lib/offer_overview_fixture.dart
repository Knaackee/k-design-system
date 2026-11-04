import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'settings_grouped_parts.dart';
import 'catalog_editor_fixture.dart';

class OfferOverviewFixture extends StatefulWidget {
  const OfferOverviewFixture({
    this.dark = false,
    this.empty = false,
    super.key,
  });
  final bool dark, empty;
  @override
  State<OfferOverviewFixture> createState() => _OfferOverviewFixtureState();
}

class _OfferOverviewFixtureState extends State<OfferOverviewFixture> {
  final _categories = <(String, String, String, Color)>[
    (
      'c1',
      'Haarschnitt & Styling',
      'Wähle deinen Schnitt oder ein Styling-Set für zu Hause.',
      const Color(0xffdb2777),
    ),
    (
      'c2',
      'Pflege & Extras',
      'Pflege, Entspannung und passende Produkte für deinen Termin.',
      const Color(0xff0d9488),
    ),
    (
      'c3',
      'Farbe & Farbschutz',
      'Farbfrische im Termin oder Pflege für zu Hause.',
      const Color(0xff7c3aed),
    ),
    ('c4', 'Hochzeit & Events', '', const Color(0xffca8a04)),
  ];
  late final _items = widget.empty
      ? <Map<String, dynamic>>[]
      : [
          {
            'id': 'l1',
            'category': 'c1',
            'name': 'Kurzhaarschnitt',
            'kind': 'service',
            'price': '32,00 €',
            'detail': '30 Min. · + Optionen',
          },
          {
            'id': 'l2',
            'category': 'c1',
            'name': 'Langhaarschnitt mit Pflegekur und Föhnfrisur',
            'kind': 'service',
            'price': '58,00 €',
            'detail': '1 Std. · Hervorgehoben',
          },
          {
            'id': 'p1',
            'category': 'c1',
            'name': 'Styling-Set',
            'kind': 'product',
            'price': '24,90 €',
            'detail': '12 verfügbar · + Optionen',
          },
          {
            'id': 'l3',
            'category': 'c2',
            'name': 'Haare waschen',
            'kind': 'service',
            'price': '8,00 €',
            'detail': '10 Min.',
          },
          {
            'id': 'l4',
            'category': 'c2',
            'name': 'Kopfhautmassage',
            'kind': 'service',
            'price': '12,00 €',
            'detail': '10 Min.',
          },
          {
            'id': 'p2',
            'category': 'c2',
            'name': 'Feuchtigkeitsshampoo',
            'kind': 'product',
            'price': '14,90 €',
            'detail': 'Nur noch 2',
          },
          {
            'id': 'p3',
            'category': 'c2',
            'name': 'Pflegeconditioner',
            'kind': 'product',
            'price': '16,90 €',
            'detail': '12 verfügbar',
          },
          {
            'id': 'l5',
            'category': 'c3',
            'name': 'Ansatzfarbe',
            'kind': 'service',
            'price': 'ab 65,00 €',
            'detail': '75 Min.',
          },
          {
            'id': 'l6',
            'category': 'c3',
            'name': 'Glanz-Glossing',
            'kind': 'service',
            'price': '39,00 €',
            'detail': '40 Min. · Nicht buchbar',
          },
          {
            'id': 'p4',
            'category': 'c3',
            'name': 'Farbschutzmaske',
            'kind': 'product',
            'price': '22,90 €',
            'detail': 'Ausverkauft',
          },
          {
            'id': 'l7',
            'category': 'c3',
            'name': 'Balayage',
            'kind': 'service',
            'price': 'Auf Anfrage',
            'detail': '3 Std.',
            'archived': true,
          },
          {
            'id': 'p5',
            'category': 'c3',
            'name': 'Glanzspray',
            'kind': 'product',
            'price': '11,90 €',
            'detail': '5 verfügbar',
            'archived': true,
          },
        ];
  bool _draft = false;
  void _edit(bool product, [Map<String, dynamic>? item, String? categoryId]) =>
      showDialog<void>(
        context: context,
        builder: (dialogContext) => CatalogEditorFixture(
          product: product,
          dark: widget.dark,
          initialName: item?['name'],
          initialPrice: item == null
              ? null
              : (item['price'] as String)
                        .replaceAll(' €', '')
                        .replaceAll('ab ', '') ==
                    'Auf Anfrage'
              ? '0'
              : (item['price'] as String)
                    .replaceAll(' €', '')
                    .replaceAll('ab ', ''),
          onClose: () => Navigator.pop(dialogContext),
          onSaved: (name, price) {
            setState(() {
              if (item != null) {
                item['name'] = name;
                item['price'] = '$price €';
              } else {
                _items.add({
                  'id': 'new${_items.length}',
                  'category': categoryId ?? _categories.first.$1,
                  'kind': product ? 'product' : 'service',
                  'name': name,
                  'price': '$price €',
                  'detail': product ? 'Produkt' : '30 Min.',
                });
              }
              _draft = true;
            });
            Navigator.pop(dialogContext);
          },
        ),
      );
  Future<void> _newKind(String category) async {
    final product = await KAdaptiveDialog.show<bool>(
      context: context,
      builder: (dialogContext) => KAdaptiveDialog(
        title: const Text('Angebot hinzufügen'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KButton(
              label: 'Leistung',
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            KButton(
              label: 'Produkt',
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
      ),
    );
    if (product != null && mounted) _edit(product, null, category);
  }

  Future<void> _category([String? id]) async {
    final existing = _categories.where((c) => c.$1 == id).firstOrNull;
    final text = TextEditingController(text: existing?.$2 ?? '');
    final name = await KAdaptiveDialog.show<String>(
      context: context,
      builder: (context) => KAdaptiveDialog(
        title: Text(id == null ? 'Neue Kategorie' : 'Kategorie bearbeiten'),
        actions: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            KButton(
              label: 'Abbrechen',
              variant: KButtonVariant.secondary,
              onPressed: () => Navigator.pop(context),
            ),
            KButton(
              label: 'Speichern',
              onPressed: () {
                if (text.text.trim().isNotEmpty) {
                  Navigator.pop(context, text.text.trim());
                }
              },
            ),
          ],
        ),
        child: KInput(
          controller: text,
          label: 'Name',
          placeholder: 'Name der Kategorie',
        ),
      ),
    );
    if (name != null && mounted) {
      setState(() {
        if (existing != null) {
          _categories[_categories.indexOf(existing)] = (
            existing.$1,
            name,
            existing.$3,
            existing.$4,
          );
        } else {
          _categories.add((
            'c${_categories.length + 1}',
            name,
            '',
            const Color(0xff0891b2),
          ));
        }
        _draft = true;
      });
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    text.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = settingsGroupedTokens(
      Theme.of(context).extension<KDesignTokens>()!,
      widget.dark,
    ).copyWith(radiusControl: 12, sizeControl: 42);
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [t],
        brightness: widget.dark ? Brightness.dark : Brightness.light,
      ),
      child: ColoredBox(
        color: t.colorSurfaceCanvas,
        child: LayoutBuilder(
          builder: (context, c) => Row(
            children: [
              if (c.maxWidth >= 900)
                SizedBox(
                  width: 240,
                  child: KSidebar(
                    mode: KSidebarMode.expanded,
                    expandedWidth: 240,
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: KText(
                            'onzeit.',
                            variant: KTextVariant.heading3,
                          ),
                        ),
                        for (final nav in const [
                          ('Heute', KIconName.house),
                          ('Kalender', KIconName.calendar),
                          ('Posteingang', KIconName.inbox),
                          ('Verwaltung', KIconName.briefcase),
                          ('Einstellungen', KIconName.settings),
                          ('Kund:innen', KIconName.users),
                          ('Angebot', KIconName.store),
                          ('Buchungsseite & QR', KIconName.qrCode),
                        ])
                          KSidebarItem(
                            label: nav.$1,
                            active: nav.$1 == 'Angebot',
                            leading: KIcon(nav.$2, size: 20),
                            onPressed: () {},
                          ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: c.maxWidth >= 900 ? 48 : 16,
                    vertical: 32,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 880),
                      child: KOfferOverview(
                        onMoveEntry: (id, category, before) => setState(() {
                          final item = _items.firstWhere((e) => e['id'] == id);
                          _items.remove(item);
                          item['category'] = category;
                          final index = _items.indexWhere(
                            (e) => e['id'] == before,
                          );
                          _items.insert(
                            index < 0 ? _items.length : index,
                            item,
                          );
                          _draft = true;
                        }),
                        onAddCategory: _category,
                        newActions: [
                          KMenuAction(
                            id: 'service',
                            label: 'Leistung',
                            icon: KIconName.scissors,
                            onSelect: () => _edit(false),
                          ),
                          KMenuAction(
                            id: 'product',
                            label: 'Produkt',
                            icon: KIconName.package,
                            onSelect: () => _edit(true),
                          ),
                          KMenuAction(
                            id: 'category',
                            label: 'Kategorie',
                            icon: KIconName.folders,
                            onSelect: _category,
                          ),
                        ],
                        onReorderCategories: (ids, from, to) => setState(() {
                          final item = _categories.removeAt(from);
                          _categories.insert(to > from ? to - 1 : to, item);
                          _draft = true;
                        }),
                        onReorderEntries: (_, ids, from, to) => setState(() {
                          final target = _items.firstWhere(
                            (i) => i['id'] == ids[from],
                          );
                          final ordered = ids.toList()..removeAt(from);
                          ordered.insert(to > from ? to - 1 : to, target['id']);
                          final positions = <int>[];
                          for (var i = 0; i < _items.length; i++) {
                            if (ids.contains(_items[i]['id'])) positions.add(i);
                          }
                          final values = ordered
                              .map(
                                (id) => _items.firstWhere((i) => i['id'] == id),
                              )
                              .toList();
                          for (var i = 0; i < positions.length; i++) {
                            _items[positions[i]] = values[i];
                          }
                          _draft = true;
                        }),
                        categories: [
                          for (final cat in _categories)
                            KOfferCategory(
                              id: cat.$1,
                              name: cat.$2,
                              description: cat.$3,
                              color: cat.$4,
                              onAdd: () => _newKind(cat.$1),
                              actions: [
                                KMenuAction(
                                  id: 'edit',
                                  label: 'Kategorie bearbeiten',
                                  onSelect: () => _category(cat.$1),
                                ),
                              ],
                              entries: [
                                for (final i in _items.where(
                                  (i) => i['category'] == cat.$1,
                                ))
                                  KOfferEntry(
                                    id: i['id'],
                                    name: i['name'],
                                    kind: i['kind'],
                                    price: i['price'],
                                    detail: i['detail'],
                                    archived: i['archived'] == true,
                                    onEdit: () =>
                                        _edit(i['kind'] == 'product', i),
                                    actions: [
                                      KMenuAction(
                                        id: 'edit',
                                        label: 'Bearbeiten',
                                        onSelect: () =>
                                            _edit(i['kind'] == 'product', i),
                                      ),
                                      KMenuAction(
                                        id: 'archive',
                                        label: i['archived'] == true
                                            ? 'Wiederherstellen'
                                            : 'Archivieren',
                                        icon: KIconName.archive,
                                        onSelect: () => setState(() {
                                          i['archived'] = i['archived'] != true;
                                          _draft = true;
                                        }),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                        ],
                        footer: KCatalogEditorCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _draft
                                      ? 'Änderungen als Entwurf'
                                      : 'Alles veröffentlicht',
                                ),
                              ),
                              KButton(
                                label: 'Veröffentlichen',
                                onPressed: _draft
                                    ? () => setState(() => _draft = false)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
