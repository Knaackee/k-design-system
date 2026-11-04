import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'avatar_editor_fixture.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'settings_grouped_parts.dart';
part 'catalog_editor_view.dart';
part 'catalog_editor_options.dart';
part 'catalog_editor_overlays.dart';

// Same composition and fixture IDs as Patterns/CatalogEditor in Storybook.
// Gallery state only; no production inventory or account writes.
class CatalogEditorFixture extends StatefulWidget {
  const CatalogEditorFixture({
    this.product = false,
    this.dark = false,
    this.panel,
    this.initialName,
    this.initialPrice,
    this.onSaved,
    this.onClose,
    super.key,
  });
  final bool product, dark;
  final String? panel, initialName, initialPrice;
  final void Function(String name, String price)? onSaved;
  final VoidCallback? onClose;
  @override
  State<CatalogEditorFixture> createState() => _CatalogEditorFixtureState();
}

class _CatalogEditorFixtureState extends State<CatalogEditorFixture> {
  late final name = TextEditingController(
    text:
        widget.initialName ??
        (widget.product ? 'Styling-Set' : 'Kurzhaarschnitt'),
  );
  late final description = TextEditingController(
    text: widget.product
        ? 'Dein Styling für zu Hause – mit Wachs und Finish-Spray.'
        : 'Persönliche Beratung, Waschen, Schneiden und Styling.',
  );
  late final price = TextEditingController(
    text: widget.initialPrice ?? (widget.product ? '24,90' : '32,00'),
  );
  final duration = TextEditingController(text: '30'),
      threshold = TextEditingController(text: '3');
  late final groups = <_DemoGroup>[
    _DemoGroup(
      widget.product ? 'Verpackung' : 'Haarlänge',
      widget.product
          ? [('Geschenkbox', '2,50'), ('Stoffbeutel', '4,00')]
          : [('Schulterlang', '8,00'), ('Sehr lang', '15,00')],
    ),
  ];
  Uint8List? imageBytes;
  final avatarData = AvatarEditorFixtureData();
  final history = <String>['+12 · Erstbestand'];
  String kind = 'fixed', status = 'Gespeichert';
  late String category = widget.product ? 'Pflege & Styling' : 'Haarschnitte';
  bool active = true, featured = false, track = true, hide = true;
  int stock = 12;
  late final recommended = <String>{
    if (!widget.product) 'Pflege-Shampoo',
    'Kopfmassage',
  };
  KDesignTokens get t => Theme.of(context).extension<KDesignTokens>()!;
  @override
  void initState() {
    super.initState();
    if (widget.panel != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (widget.panel == 'stock') {
            stockDialog();
          } else {
            recommendations();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in [name, description, price, duration, threshold]) {
      c.dispose();
    }
    for (final g in groups) {
      g.dispose();
    }
    super.dispose();
  }

  void update(VoidCallback fn) => setState(fn);
  void changed([String? _]) => setState(() => status = 'Ungespeichert');
  TextStyle get fieldLabelStyle => TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: settingsGroupedTokens(
      t,
      widget.dark || Theme.of(context).brightness == Brightness.dark,
    ).colorTextMuted,
  );
  TextStyle get fieldHelperStyle =>
      TextStyle(fontSize: 13, height: 1.45, color: t.colorTextMuted);
  Widget input(String label, TextEditingController c, {String? suffix}) =>
      KField(
        labelStyle: fieldLabelStyle,
        helperStyle: fieldHelperStyle,
        label: label,
        child: KInput(
          controller: c,
          onChanged: changed,
          trailingAction: suffix == null ? null : Text(suffix),
        ),
      );
  Widget card(List<Widget> children) => KCatalogEditorCard(
    child: KStack(
      gap: KLayoutGap.action,
      align: KLayoutAlign.stretch,
      children: children,
    ),
  );
  Widget toggle(
    String label,
    String help,
    bool value,
    ValueChanged<bool> update, {
    bool divider = false,
  }) => KCatalogEditorRow(
    title: label,
    help: help,
    divider: divider,
    trailing: KSwitch(
      label: label,
      showLabel: false,
      value: value,
      onChanged: (v) {
        setState(() => update(v));
        changed();
      },
    ),
  );
  @override
  Widget build(BuildContext context) => editorView(context);
}
