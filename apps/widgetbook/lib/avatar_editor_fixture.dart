import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:k_design_ui/k_design_ui.dart';

Future<void> showAvatarEditorFixture(
  BuildContext context, {
  required ValueChanged<Uint8List?> onAvatarChange,
  required AvatarEditorFixtureData data,
}) => KAdaptiveDialog.show<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      _AvatarEditorDialog(onAvatarChange: onAvatarChange, data: data),
);

class _AvatarEditorDialog extends StatefulWidget {
  const _AvatarEditorDialog({required this.onAvatarChange, required this.data});
  final AvatarEditorFixtureData data;
  final ValueChanged<Uint8List?> onAvatarChange;
  @override
  State<_AvatarEditorDialog> createState() => _AvatarEditorDialogState();
}

class AvatarEditorFixtureData {
  String? selectedId;
  final images = <KAvatarEditorImage>[
    const KAvatarEditorImage(
      id: 'portrait',
      image: AssetImage('assets/image-cropper/jordan.png'),
      alt: 'Porträt Jordan',
    ),
  ];
}

class _AvatarEditorDialogState extends State<_AvatarEditorDialog> {
  Future<KAvatarEditorFile?> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source);
    if (file == null) return null;
    if (await file.length() > 32 * 1024 * 1024) {
      throw const FormatException('Image exceeds 32 MiB');
    }
    final bytes = await file.readAsBytes();
    // MIME metadata is optional on native platforms; validate magic bytes too.
    final mime =
        bytes.length >= 12 &&
            bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46 &&
            bytes[8] == 0x57 &&
            bytes[9] == 0x45 &&
            bytes[10] == 0x42 &&
            bytes[11] == 0x50
        ? 'image/webp'
        : bytes.length >= 8 &&
              bytes[0] == 0x89 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x4e &&
              bytes[3] == 0x47
        ? 'image/png'
        : bytes.length >= 3 &&
              bytes[0] == 0xff &&
              bytes[1] == 0xd8 &&
              bytes[2] == 0xff
        ? 'image/jpeg'
        : 'application/octet-stream';
    return KAvatarEditorFile(bytes: bytes, mimeType: mime, name: file.name);
  }

  @override
  Widget build(BuildContext context) => KAvatarEditor(
    images: widget.data.images,
    selectedId: widget.data.selectedId,
    onClose: () => Navigator.of(context).pop(),
    onChoose: () => _pick(ImageSource.gallery),
    onCamera: () => _pick(ImageSource.camera),
    onApply: (bytes, source) {
      final id = 'crop-${DateTime.now().microsecondsSinceEpoch}';
      widget.data.images.add(
        KAvatarEditorImage(
          id: id,
          image: MemoryImage(bytes),
          alt: 'Eigenes Bild',
        ),
      );
      widget.data.selectedId = id;
      widget.onAvatarChange(bytes);
    },
    onOmit: () {
      widget.data.selectedId = null;
      widget.onAvatarChange(null);
    },
    onRemove: (id) => setState(() {
      widget.data.images.removeWhere((image) => image.id == id);
      if (widget.data.selectedId == id) {
        widget.data.selectedId = null;
        widget.onAvatarChange(null);
      }
    }),
    labels: const KAvatarEditorLabels(
      title: 'Dein Bild',
      choose: 'Bild auswählen',
      camera: 'Foto aufnehmen',
      remove: 'Bild entfernen',
      omit: 'Kein Bild verwenden',
      close: 'Schließen',
      back: 'Zurück',
      apply: 'Bild verwenden',
      gallery: 'Deine Bilder',
      error:
          'Das Bild oder die Kamera konnte nicht geöffnet werden. Bitte versuche es erneut.',
      invalidFile: 'Bitte wähle ein JPG-, PNG- oder WebP-Bild bis 32 MB.',
      loading: 'Bild wird verarbeitet …',
      reset: 'Zurücksetzen',
      horizontal: 'Horizontale Position',
      vertical: 'Vertikale Position',
    ),
  );
}

class AvatarEditorFixture extends StatefulWidget {
  const AvatarEditorFixture({super.key});
  @override
  State<AvatarEditorFixture> createState() => _AvatarEditorFixtureState();
}

class _AvatarEditorFixtureState extends State<AvatarEditorFixture> {
  Uint8List? _image;
  final _data = AvatarEditorFixtureData();
  @override
  Widget build(BuildContext context) => Center(
    child: KStack(
      align: KLayoutAlign.center,
      children: [
        KAvatar(
          alt: 'Dein Bild',
          image: _image == null ? null : MemoryImage(_image!),
          size: KAvatarSize.large,
        ),
        KButton(
          label: 'Bild bearbeiten',
          onPressed: () => showAvatarEditorFixture(
            context,
            data: _data,
            onAvatarChange: (bytes) {
              if (mounted) setState(() => _image = bytes);
            },
          ),
        ),
        const KText('Die Vorschau bleibt nur für diese Sitzung gespeichert.'),
      ],
    ),
  );
}
