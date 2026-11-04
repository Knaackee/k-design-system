import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../overlays/k_adaptive_dialog.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_layout.dart';
import '../primitives/k_text.dart';
import 'k_image_cropper.dart';

class KAvatarEditorImage {
  const KAvatarEditorImage({
    required this.id,
    required this.image,
    required this.alt,
  });
  final String id, alt;
  final ImageProvider image;
}

/// Native picking and permission handling belong to the host.
class KAvatarEditorFile {
  const KAvatarEditorFile({
    required this.bytes,
    required this.mimeType,
    required this.name,
  });
  final Uint8List bytes;
  final String mimeType, name;
}

class KAvatarEditorLabels {
  const KAvatarEditorLabels({
    this.title = 'Your image',
    this.choose = 'Choose image',
    this.camera = 'Take photo',
    this.remove = 'Remove image',
    this.omit = 'Use no image',
    this.close = 'Close',
    this.back = 'Back',
    this.apply = 'Use image',
    this.gallery = 'Gallery',
    this.error = 'The image or camera could not be opened. Please try again.',
    this.invalidFile =
        'Choose a JPEG, PNG or WebP image within the file size limit.',
    this.loading = 'Opening image…',
    this.zoom = 'Zoom',
    this.reset = 'Reset',
    this.horizontal = 'Horizontal position',
    this.vertical = 'Vertical position',
  });
  final String title,
      choose,
      camera,
      remove,
      omit,
      close,
      back,
      apply,
      gallery,
      error,
      invalidFile,
      loading,
      zoom,
      reset,
      horizontal,
      vertical;
}

/// Controlled gallery with a local crop draft. Persistence belongs to the host.
/// Open using KAdaptiveDialog.show with barrierDismissible: false; close and
/// sheet gestures remain available while idle, and commits cannot be dismissed.
class KAvatarEditor extends StatefulWidget {
  const KAvatarEditor({
    super.key,
    required this.images,
    required this.onApply,
    required this.onOmit,
    required this.onClose,
    this.selectedId,
    this.onRemove,
    this.onChoose,
    this.onCamera,
    this.maxFileBytes = 32 * 1024 * 1024,
    this.labels = const KAvatarEditorLabels(),
  }) : assert(maxFileBytes > 0);
  final List<KAvatarEditorImage> images;
  final String? selectedId;
  final FutureOr<void> Function(Uint8List png, KAvatarEditorImage source)
  onApply;
  final FutureOr<void> Function() onOmit;
  final FutureOr<void> Function(String id)? onRemove;
  final Future<KAvatarEditorFile?> Function()? onChoose, onCamera;
  final VoidCallback onClose;
  final int maxFileBytes;
  final KAvatarEditorLabels labels;
  @override
  State<KAvatarEditor> createState() => _KAvatarEditorState();
}

class _KAvatarEditorState extends State<KAvatarEditor> {
  KAvatarEditorImage? _draft;
  bool _busy = false;
  String? _error;
  int _generation = 0;

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  Future<void> _run(
    FutureOr<void> Function() action, {
    bool close = false,
  }) async {
    if (_busy) return;
    final request = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted || request != _generation) return;
      if (close) widget.onClose();
    } catch (_) {
      if (mounted && request == _generation) {
        setState(() => _error = widget.labels.error);
      }
    } finally {
      if (mounted && request == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _pick(Future<KAvatarEditorFile?> Function() pick) => _run(
    () async {
      final file = await pick();
      if (!mounted || file == null) return;
      if (file.bytes.isEmpty ||
          file.bytes.length > widget.maxFileBytes ||
          !['image/jpeg', 'image/png', 'image/webp'].contains(file.mimeType)) {
        setState(() => _error = widget.labels.invalidFile);
        return;
      }
      setState(
        () => _draft = KAvatarEditorImage(
          id: 'local-$_generation',
          image: MemoryImage(file.bytes),
          alt: file.name,
        ),
      );
    },
  );

  Widget _source(
    String label,
    KIconName icon,
    Future<KAvatarEditorFile?> Function()? pick,
  ) {
    final theme = Theme.of(context);
    final tokens = theme.extension<KDesignTokens>()!;
    return Expanded(
      child: Theme(
        data: theme.copyWith(
          extensions: [
            ...theme.extensions.values.where(
              (value) => value is! KDesignTokens,
            ),
            tokens.copyWith(
              colorActionSecondaryBackground: tokens.colorSurfaceSubtle,
              radiusControl: tokens.radiusOverlay,
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: tokens.sizeAvatarLarge + tokens.spaceLayoutGutter * 2,
          ),
          child: KButton(
            label: label,
            variant: KButtonVariant.secondary,
            onPressed: _busy || pick == null ? null : () => _pick(pick),
            content: Padding(
              padding: EdgeInsets.symmetric(
                vertical: Theme.of(
                  context,
                ).extension<KDesignTokens>()!.spaceControlInsetInline,
              ),
              child: KStack(
                align: KLayoutAlign.center,
                children: [
                  KIcon(icon, size: 32),
                  Text(label, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.labels;
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final draft = _draft;
    return PopScope(
      canPop: !_busy,
      child: KAdaptiveDialog(
        title: KText(t.title, variant: KTextVariant.heading3),
        expandBody: draft != null || widget.images.isNotEmpty,
        closeLabel: t.close,
        onClose: () {
          if (!_busy) widget.onClose();
        },
        actions: draft != null
            ? null
            : KStack(
                align: KLayoutAlign.stretch,
                children: [
                  KInline(
                    gap: KLayoutGap.action,
                    children: [
                      _source(t.choose, KIconName.image, widget.onChoose),
                      _source(t.camera, KIconName.camera, widget.onCamera),
                    ],
                  ),
                  KButton(
                    label: t.omit,
                    fullWidth: true,
                    variant: KButtonVariant.ghost,
                    content: Center(child: Text(t.omit)),
                    onPressed: _busy
                        ? null
                        : () => _run(widget.onOmit, close: true),
                  ),
                ],
              ),
        child: KStack(
          align: KLayoutAlign.stretch,
          children: [
            if (_error != null)
              Semantics(liveRegion: true, child: KText(_error!)),
            if (_busy) Semantics(liveRegion: true, child: KText(t.loading)),
            if (draft != null) ...[
              AbsorbPointer(
                absorbing: _busy,
                child: ExcludeFocus(
                  excluding: _busy,
                  child: KImageCropper(
                    image: draft.image,
                    confirmLabel: t.apply,
                    errorLabel: t.error,
                    resetLabel: t.reset,
                    zoomLabel: t.zoom,
                    horizontalLabel: t.horizontal,
                    verticalLabel: t.vertical,
                    onConfirm: (png) =>
                        _run(() => widget.onApply(png, draft), close: true),
                  ),
                ),
              ),
              KButton(
                label: t.back,
                variant: KButtonVariant.ghost,
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _draft = null;
                        _error = null;
                      }),
              ),
            ] else
              Semantics(
                label: t.gallery,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size =
                        (constraints.maxWidth - tokens.spaceControlGap * 2) / 3;
                    return Wrap(
                      spacing: tokens.spaceControlGap,
                      runSpacing: tokens.spaceControlGap,
                      children: widget.images
                          .map(
                            (item) => SizedBox(
                              width: size,
                              child: KStack(
                                align: KLayoutAlign.center,
                                children: [
                                  Semantics(
                                    selected: widget.selectedId == item.id,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: widget.selectedId == item.id
                                            ? Border.all(
                                                color: tokens.colorBorderFocus,
                                                width: tokens.borderWidthStrong,
                                              )
                                            : null,
                                      ),
                                      child: KButton(
                                        label: item.alt,
                                        paddingInline: 0,
                                        variant: KButtonVariant.ghost,
                                        content: Image(
                                          image: item.image,
                                          width: size,
                                          height: size,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, error, stack) =>
                                              SizedBox(
                                                width: size,
                                                height: size,
                                                child: const KIcon(
                                                  KIconName.image,
                                                ),
                                              ),
                                        ),
                                        onPressed: _busy
                                            ? null
                                            : () => setState(() {
                                                _draft = item;
                                                _error = null;
                                              }),
                                      ),
                                    ),
                                  ),
                                  if (widget.onRemove != null)
                                    KButton(
                                      label: '${t.remove}: ${item.alt}',
                                      variant: KButtonVariant.ghost,
                                      content: const KIcon(KIconName.trash),
                                      onPressed: _busy
                                          ? null
                                          : () => _run(
                                              () => widget.onRemove!(item.id),
                                            ),
                                    ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
