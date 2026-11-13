import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'settings_grouped_parts.dart';
import 'avatar_editor_fixture.dart';
part 'booking_page_management_view.dart';

const _designNames = {
  'clear': 'Klar',
  'editorial': 'Editorial',
  'handwritten': 'Notizbuch',
  'bold': 'Pop',
  'soft': 'Pastell',
  'natural': 'Retro',
  'immersive': 'Vollbild',
  'night': 'Nacht',
  'postcard': 'Postkarte',
  'bento': 'Bento',
  'monogram': 'Monogramm',
};

class BookingPageManagementFixture extends StatefulWidget {
  const BookingPageManagementFixture({
    this.dark = false,
    this.mobile = false,
    super.key,
  });
  final bool dark, mobile;
  @override
  State<BookingPageManagementFixture> createState() =>
      _BookingPageManagementFixtureState();
}

class _BookingPageManagementFixtureState
    extends State<BookingPageManagementFixture> {
  void refresh(VoidCallback fn) => setState(fn);
  String design = 'handwritten', flow = 'guided';
  bool phone = false, online = true, dirty = false, round = false;
  Uint8List? portrait;
  final avatarData = AvatarEditorFixtureData();
  final slug = TextEditingController(text: 'mila-berger');
  final fields = <String, TextEditingController>{
    'Begrüßung': TextEditingController(text: 'Schön, dass du da bist!'),
    'Willkommenstext': TextEditingController(
      text:
          'Schnitt, Farbe oder Styling – ich komme zu dir nach Hause. Gemeinsam finden wir deinen Look.',
    ),
    'Gruß am Ende (optional)': TextEditingController(text: 'Deine Mila'),
    'Text auf dem Knopf': TextEditingController(text: 'Angebote auswählen'),
    'Name deines Betriebs': TextEditingController(text: 'Mila · Hair at Home'),
    'Kurzbeschreibung': TextEditingController(
      text: 'Mobiler Friseur-Service in Berlin und Umgebung.',
    ),
    'Kontakt-E-Mail (optional)': TextEditingController(),
  };
  @override
  void dispose() {
    slug.dispose();
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget image(String id) => Image.asset(
    'assets/booking-themes/$id.webp',
    fit: BoxFit.cover,
    alignment: Alignment.topCenter,
  );
  Widget card(List<Widget> children) => KBookingPageCard(
    child: KStack(
      gap: KLayoutGap.control,
      align: KLayoutAlign.stretch,
      children: children,
    ),
  );
  Widget field(String label, {bool multiline = false}) => KField(
    label: label,
    child: multiline
        ? KTextarea(
            controller: fields[label],
            onChanged: (_) => setState(() => dirty = true),
          )
        : KInput(
            controller: fields[label],
            onChanged: (_) => setState(() => dirty = true),
          ),
  );
  Future<void> dialog(BuildContext context, String title, Widget child) =>
      KAdaptiveDialog.show<void>(
        context: context,
        builder: (_) => KDialog(
          title: Text(title),
          actions: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              KButton(
                label: 'Schließen',
                variant: KButtonVariant.ghost,
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
              ),
            ],
          ),
          child: child,
        ),
      );
  Widget action(
    String label,
    KIconName icon,
    VoidCallback callback, {
    bool primary = false,
  }) => SizedBox(
    height: 64,
    child: KButton(
      label: label,
      paddingInline: 2,
      variant: primary ? KButtonVariant.primary : KButtonVariant.secondary,
      onPressed: callback,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KIcon(icon, size: 20),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => buildView(context);
}

/// Matching Web booking settings controls, using the gallery's own image assets.
class BookingPageSettingsFixture extends StatefulWidget {
  const BookingPageSettingsFixture({super.key});
  @override
  State<BookingPageSettingsFixture> createState() =>
      _BookingPageSettingsFixtureState();
}

class _BookingPageSettingsFixtureState
    extends State<BookingPageSettingsFixture> {
  String design = 'handwritten', color = 'blue';
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final compact = MediaQuery.sizeOf(context).width < 700;
    return KPage(
      width: KPageWidth.fluid,
      children: [
        KBookingPageLayout(
          settings: true,
          previewHelp: '',
          preview: Image.asset(
            'assets/booking-themes/$design.webp',
            fit: BoxFit.cover,
          ),
          child: KStack(
            gap: KLayoutGap.section,
            align: KLayoutAlign.stretch,
            children: [
              KList(
                children: [
                  const KListItem(
                    title: 'Online',
                    description: 'example.test/u/mila',
                  ),
                  Padding(
                    padding: EdgeInsets.all(t.componentListRowPaddingInline),
                    child: KBookingPageActions(
                      compact: compact,
                      actions: [
                        KBookingPageAction(
                          label: 'Teilen',
                          icon: KIconName.share,
                          onPressed: () {},
                          primary: true,
                        ),
                        KBookingPageAction(
                          label: 'Kopieren',
                          icon: KIconName.copy,
                          onPressed: () {},
                        ),
                        KBookingPageAction(
                          label: 'QR-Code',
                          icon: KIconName.qrCode,
                          onPressed: () {},
                        ),
                      ],
                      previewAction: KBookingPageAction(
                        label: 'Vorschau',
                        icon: KIconName.eye,
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
              KBookingThemePicker(
                carousel: true,
                value: design,
                onChanged: (v) => setState(() => design = v),
                options: [
                  for (final entry in _designNames.entries)
                    KBookingThemeChoice(
                      id: entry.key,
                      label: entry.value,
                      image: Image.asset(
                        'assets/booking-themes/${entry.key}.webp',
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
                footer: KColorSwatches(
                  label: 'Farbe',
                  value: color,
                  onChanged: (v) => setState(() => color = v),
                  options: [
                    KColorSwatch(
                      value: 'blue',
                      label: 'Marke',
                      color: t.colorActionPrimaryBackground,
                    ),
                    KColorSwatch(
                      value: 'red',
                      label: 'Rot',
                      color: t.colorStatusErrorForeground,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
