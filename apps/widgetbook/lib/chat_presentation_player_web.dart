import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Native browser playback: controls and seeking use the real media element.
Widget presentationMediaPlayer(
  BuildContext context,
  String src, {
  bool audio = false,
  bool youtube = false,
  String? poster,
}) => _BrowserPlayer(
  key: ValueKey('$audio:$youtube:$src:$poster'),
  src: src,
  audio: audio,
  youtube: youtube,
  poster: poster,
);

class _BrowserPlayer extends StatefulWidget {
  const _BrowserPlayer({
    required this.src,
    required this.audio,
    required this.youtube,
    this.poster,
    super.key,
  });
  final String src;
  final bool audio, youtube;
  final String? poster;
  @override
  State<_BrowserPlayer> createState() => _BrowserPlayerState();
}

class _BrowserPlayerState extends State<_BrowserPlayer> {
  web.HTMLMediaElement? _media;
  web.HTMLIFrameElement? _frame;
  @override
  void dispose() {
    _media?.pause();
    _media?.removeAttribute('src');
    _media?.load();
    _frame?.src = 'about:blank';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = HtmlElementView.fromTagName(
      tagName: widget.youtube
          ? 'iframe'
          : widget.audio
          ? 'audio'
          : 'video',
      onElementCreated: (element) {
        final html = element as web.HTMLElement;
        html.style.width = '100%';
        html.style.height = '100%';
        html.style.border = '0';
        html.style.display = 'block';
        html.style.colorScheme = Theme.of(context).brightness == Brightness.dark
            ? 'dark'
            : 'light';
        if (widget.youtube) {
          final frame = element as web.HTMLIFrameElement;
          _frame = frame;
          frame.src = widget.src;
          frame.title = 'YouTube video';
          frame.allow = 'encrypted-media; picture-in-picture; fullscreen';
          frame.allowFullscreen = true;
          frame.referrerPolicy = 'strict-origin-when-cross-origin';
        } else {
          final media = element as web.HTMLMediaElement;
          _media = media;
          media.src = widget.src;
          media.controls = true;
          media.preload = 'none';
          media.autoplay = false;
          if (!widget.audio) {
            final video = element as web.HTMLVideoElement;
            video.playsInline = true;
            if (widget.poster != null) video.poster = widget.poster!;
          }
        }
      },
    );
    return player;
  }
}
