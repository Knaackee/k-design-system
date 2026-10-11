import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_surface.dart';
import '../overlays/k_adaptive_dialog.dart';
import 'chat_presentations.dart' show KPresentationImage;
import 'chat_presentation_image.dart';

/// A real platform player supplied by the host; playback remains host-owned.
typedef KPresentationPlayerBuilder =
    Widget Function(BuildContext context, String src);

class KPresentationGallery extends StatefulWidget {
  const KPresentationGallery({
    required this.images,
    required this.selectedIndex,
    required this.onSelectedIndexChange,
    this.title = 'Images',
    this.closeLabel = 'Close',
    this.previousLabel = 'Previous image',
    this.nextLabel = 'Next image',
    super.key,
  });
  final List<KPresentationImage> images;
  final int? selectedIndex;
  final ValueChanged<int?> onSelectedIndexChange;
  final String title, closeLabel, previousLabel, nextLabel;
  @override
  State<KPresentationGallery> createState() => _KPresentationGalleryState();
}

class _KPresentationGalleryState extends State<KPresentationGallery> {
  final _revision = ValueNotifier<int>(0);
  BuildContext? _dialogContext;
  bool _opening = false;
  bool get _valid =>
      widget.selectedIndex != null &&
      widget.selectedIndex! >= 0 &&
      widget.selectedIndex! < widget.images.length;
  @override
  void initState() {
    super.initState();
    _syncDialog();
  }

  @override
  void didUpdateWidget(KPresentationGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    _revision.value++;
    _syncDialog();
  }

  void _syncDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!_valid) {
        if (_dialogContext != null) Navigator.of(_dialogContext!).pop();
        return;
      }
      if (_opening) return;
      _opening = true;
      await KAdaptiveDialog.show<void>(
        context: context,
        builder: (routeContext) {
          _dialogContext = routeContext;
          return ValueListenableBuilder<int>(
            valueListenable: _revision,
            builder: (context, _, child) {
              if (!_valid) return const SizedBox.shrink();
              final index = widget.selectedIndex!;
              final image = widget.images[index];
              final tokens = _tokens(context);
              void close() => Navigator.of(routeContext).pop();
              return KAdaptiveDialog(
                title: Text(image.caption ?? widget.title),
                closeLabel: widget.closeLabel,
                onClose: close,
                maxWidth: MediaQuery.sizeOf(context).width * .9,
                expandBody: false,
                actions: KButton(
                  label: widget.closeLabel,
                  variant: KButtonVariant.secondary,
                  onPressed: close,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .65,
                      ),
                      child: KPresentationNetworkImage(
                        src: image.src,
                        alt: image.alt,
                        fit: BoxFit.contain,
                        errorBuilder: _imageError,
                      ),
                    ),
                    if (image.caption != null)
                      Padding(
                        padding: EdgeInsets.only(top: tokens.spaceControlGap),
                        child: Text(
                          image.caption!,
                          style: TextStyle(color: tokens.colorTextMuted),
                        ),
                      ),
                    if (widget.images.length > 1)
                      Padding(
                        padding: EdgeInsets.only(top: tokens.spaceControlGap),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: tokens.spaceControlGap,
                          runSpacing: tokens.spaceControlGap,
                          children: [
                            KButton(
                              label: widget.previousLabel,
                              leading: const KIcon(KIconName.chevronLeft),
                              variant: KButtonVariant.ghost,
                              onPressed: index == 0
                                  ? null
                                  : () =>
                                        widget.onSelectedIndexChange(index - 1),
                            ),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                '${index + 1} / ${widget.images.length}',
                                style: TextStyle(color: tokens.colorTextMuted),
                              ),
                            ),
                            KButton(
                              label: widget.nextLabel,
                              trailing: const KIcon(KIconName.chevronRight),
                              variant: KButtonVariant.ghost,
                              onPressed: index == widget.images.length - 1
                                  ? null
                                  : () =>
                                        widget.onSelectedIndexChange(index + 1),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
      _dialogContext = null;
      _opening = false;
      if (mounted && widget.selectedIndex != null) {
        widget.onSelectedIndexChange(null);
      }
    });
  }

  @override
  void dispose() {
    _revision.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();
    final tokens = _tokens(context);
    return _MediaSurface(
      label: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading(
            icon: KIconName.image,
            title: widget.title,
            trailing: Text(
              '${widget.images.length}',
              style: TextStyle(color: tokens.colorTextMuted),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceCardPadding,
              0,
              tokens.spaceCardPadding,
              tokens.spaceCardPadding,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = widget.images.length == 1 ? 1 : 2;
                final width =
                    (constraints.maxWidth -
                        tokens.spaceControlGap * (columns - 1)) /
                    columns;
                return Wrap(
                  spacing: tokens.spaceControlGap,
                  runSpacing: tokens.spaceControlGap,
                  children: [
                    for (var i = 0; i < widget.images.length; i++)
                      SizedBox(
                        width: width,
                        child: _thumbnail(context, widget.images[i], i),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnail(BuildContext context, KPresentationImage image, int index) {
    final tokens = _tokens(context);
    return Semantics(
      button: true,
      label: image.caption ?? image.alt,
      child: Material(
        color: tokens.colorSurfaceSubtle,
        borderRadius: BorderRadius.circular(tokens.radiusControl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => widget.onSelectedIndexChange(index),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: KPresentationNetworkImage(
                  src: image.thumbnailSrc ?? image.src,
                  fit: image.fit,
                  errorBuilder: _imageError,
                ),
              ),
              if (image.caption != null)
                Padding(
                  padding: EdgeInsets.all(tokens.spaceControlGap),
                  child: Text(image.caption!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class KPresentationVideo extends StatefulWidget {
  const KPresentationVideo({
    required String src,
    required this.title,
    required this.playerBuilder,
    this.poster,
    this.caption,
    super.key,
    // Keep the source non-null at the public constructor boundary.
    // ignore: prefer_initializing_formals
  }) : src = src,
       youtubeVideoId = null,
       loadLabel = 'Load YouTube video';
  const KPresentationVideo.youtube({
    required String youtubeVideoId,
    required this.title,
    required this.playerBuilder,
    this.poster,
    this.caption,
    this.loadLabel = 'Load YouTube video',
    super.key,
    // Keep the ID non-null at the public constructor boundary.
    // ignore: prefer_initializing_formals
  }) : youtubeVideoId = youtubeVideoId,
       src = null;
  final String? src, youtubeVideoId, poster;
  final String title, loadLabel;
  final Widget? caption;
  final KPresentationPlayerBuilder playerBuilder;
  @override
  State<KPresentationVideo> createState() => _KPresentationVideoState();
}

class _KPresentationVideoState extends State<KPresentationVideo> {
  String? _loadedVideoId;
  @override
  Widget build(BuildContext context) {
    final validId =
        widget.youtubeVideoId != null &&
            RegExp(r'^[\w-]{11}$').hasMatch(widget.youtubeVideoId!)
        ? widget.youtubeVideoId
        : null;
    final tokens = _tokens(context);
    return _MediaSurface(
      label: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading(icon: KIconName.video, title: widget.title),
          if (widget.src != null)
            widget.playerBuilder(context, widget.src!)
          else
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ColoredBox(
                color: tokens.colorSurfaceSubtle,
                child: validId != null && _loadedVideoId == validId
                    ? widget.playerBuilder(
                        context,
                        'https://www.youtube-nocookie.com/embed/$validId?autoplay=0',
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          if (widget.poster != null)
                            Image.network(
                              widget.poster!,
                              fit: BoxFit.cover,
                              excludeFromSemantics: true,
                              errorBuilder: _imageError,
                            ),
                          Center(
                            child: KButton(
                              label: widget.loadLabel,
                              variant: KButtonVariant.secondary,
                              leading: const KIcon(KIconName.play),
                              onPressed: validId == null
                                  ? null
                                  : () => setState(
                                      () => _loadedVideoId = validId,
                                    ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          if (widget.caption != null)
            Padding(
              padding: EdgeInsets.all(tokens.spaceCardPadding),
              child: widget.caption!,
            ),
        ],
      ),
    );
  }
}

class KPresentationAudio extends StatelessWidget {
  const KPresentationAudio({
    required this.src,
    required this.title,
    required this.playerBuilder,
    this.meta,
    super.key,
  });
  final String src, title;
  final Widget? meta;
  final KPresentationPlayerBuilder playerBuilder;
  @override
  Widget build(BuildContext context) {
    final tokens = _tokens(context);
    return _MediaSurface(
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading(icon: KIconName.music, title: title, meta: meta),
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceCardPadding,
              0,
              tokens.spaceCardPadding,
              tokens.spaceCardPadding,
            ),
            child: playerBuilder(context, src),
          ),
        ],
      ),
    );
  }
}

class KPresentationFile extends StatelessWidget {
  const KPresentationFile({
    required this.name,
    this.meta,
    this.icon = KIconName.file,
    this.onOpen,
    this.onDownload,
    this.openLabel = 'Open',
    this.downloadLabel = 'Download',
    super.key,
  });
  final String name, openLabel, downloadLabel;
  final Widget? meta;
  final KIconName icon;
  final VoidCallback? onOpen, onDownload;
  @override
  Widget build(BuildContext context) {
    final tokens = _tokens(context);
    return _MediaSurface(
      label: name,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceCardPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final details = Row(
              children: [
                KIcon(icon, size: 24),
                SizedBox(width: tokens.spaceControlGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (meta != null)
                        DefaultTextStyle.merge(
                          style: TextStyle(color: tokens.colorTextMuted),
                          child: meta!,
                        ),
                    ],
                  ),
                ),
              ],
            );
            final actions = Wrap(
              alignment: WrapAlignment.end,
              spacing: tokens.spaceControlGap,
              runSpacing: tokens.spaceControlGap,
              children: [
                if (onOpen != null)
                  Semantics(
                    label: '$openLabel: $name',
                    child: KButton(
                      label: openLabel,
                      variant: KButtonVariant.secondary,
                      leading: const KIcon(KIconName.externalLink),
                      onPressed: onOpen,
                    ),
                  ),
                if (onDownload != null)
                  Semantics(
                    label: '$downloadLabel: $name',
                    child: KButton(
                      label: downloadLabel,
                      variant: KButtonVariant.ghost,
                      leading: const KIcon(KIconName.download),
                      onPressed: onDownload,
                    ),
                  ),
              ],
            );
            if (constraints.maxWidth >= 520 &&
                (onOpen != null || onDownload != null)) {
              return Row(
                children: [
                  Expanded(child: details),
                  SizedBox(width: tokens.spaceControlGap),
                  Flexible(child: actions),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                if (onOpen != null || onDownload != null)
                  Padding(
                    padding: EdgeInsets.only(top: tokens.spaceControlGap),
                    child: actions,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

KDesignTokens _tokens(BuildContext context) =>
    Theme.of(context).extension<KDesignTokens>() ?? KDesignTokens.orbitLight;
Widget _imageError(BuildContext context, Object error, StackTrace? stack) =>
    const Center(child: KIcon(KIconName.imageOff, label: 'Image unavailable'));

class _MediaSurface extends StatelessWidget {
  const _MediaSurface({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final tokens = _tokens(context);
    return Semantics(
      label: label,
      container: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusCard),
        child: KSurface(
          radius: KSurfaceRadius.card,
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontFamily: tokens.fontFamily,
              fontSize: tokens.fontBodySmallSize,
              color: tokens.colorTextPrimary,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.icon,
    required this.title,
    this.meta,
    this.trailing,
  });
  final KIconName icon;
  final String title;
  final Widget? meta, trailing;
  @override
  Widget build(BuildContext context) {
    final tokens = _tokens(context);
    return Padding(
      padding: EdgeInsets.all(tokens.spaceCardPadding),
      child: Row(
        children: [
          KIcon(icon),
          SizedBox(width: tokens.spaceControlGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (meta != null)
                  DefaultTextStyle.merge(
                    style: TextStyle(color: tokens.colorTextMuted),
                    child: meta!,
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
