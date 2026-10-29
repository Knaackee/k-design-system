import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class ImageCropperFixture extends StatefulWidget {
  const ImageCropperFixture({super.key, this.shape = KImageCropShape.round});
  final KImageCropShape shape;
  @override
  State<ImageCropperFixture> createState() => _ImageCropperFixtureState();
}

class _ImageCropperFixtureState extends State<ImageCropperFixture> {
  Uint8List? output;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: KStack(
          align: KLayoutAlign.stretch,
          children: [
            const KText('Adjust the crop and apply it.'),
            KImageCropper(
              image: const AssetImage('assets/image-cropper/jordan.png'),
              shape: widget.shape,
              onConfirm: (bytes) => setState(() => output = bytes),
            ),
            if (output != null)
              KAvatar(
                alt: 'Cropped portrait',
                image: MemoryImage(output!),
                size: KAvatarSize.large,
              ),
          ],
        ),
      ),
    ),
  );
}
