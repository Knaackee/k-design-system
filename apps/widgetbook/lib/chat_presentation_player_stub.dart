import 'package:flutter/material.dart';

/// Native consumers supply their decoding/player integration to the DS builder.
Widget presentationMediaPlayer(
  BuildContext context,
  String src, {
  bool audio = false,
  bool youtube = false,
  String? poster,
}) => const Center(
  child: Text('Media playback is available in the web preview.'),
);
