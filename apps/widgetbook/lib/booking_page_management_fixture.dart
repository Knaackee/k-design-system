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
  void refresh(VoidCallback fn)=>setState(fn);
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
          KIcon(icon, size: 19),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => buildView(context);
}
