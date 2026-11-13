import 'package:flutter/material.dart';
import 'chat_presentation_player_stub.dart'
    if (dart.library.js_interop) 'chat_presentation_player_web.dart'
    as platform;

/// Platform views have no intrinsic height inside the gallery's scroll column.
Widget presentationMediaPlayer(
  BuildContext context,
  String src, {
  bool audio = false,
  bool youtube = false,
  String? poster,
}) {
  final player = platform.presentationMediaPlayer(
    context,
    src,
    audio: audio,
    youtube: youtube,
    poster: poster,
  );
  return audio
      ? SizedBox(height: 54, child: player)
      : AspectRatio(aspectRatio: 16 / 9, child: player);
}
