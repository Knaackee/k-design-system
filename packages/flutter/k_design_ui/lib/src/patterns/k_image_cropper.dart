import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../primitives/k_button.dart';
import '../primitives/k_layout.dart';
import '../primitives/k_text.dart';
import '../extended_components.dart';

enum KImageCropShape { round, square }

/// Source rectangle shared by preview and exported PNG. Offsets range from -1 to 1.
Rect kImageCropRect(Size source, double zoom, Offset position) {
  final side = math.min(source.width, source.height) / zoom.clamp(1, 4);
  final left = (source.width - side) * (position.dx.clamp(-1, 1) + 1) / 2;
  final top = (source.height - side) * (position.dy.clamp(-1, 1) + 1) / 2;
  return Rect.fromLTWH(left, top, side, side);
}

class KImageCropper extends StatefulWidget {
  const KImageCropper({
    super.key,
    required this.image,
    required this.onConfirm,
    this.shape = KImageCropShape.round,
    this.outputSize = 320,
    this.confirmLabel = 'Use image',
    this.resetLabel = 'Reset',
    this.zoomLabel = 'Zoom',
    this.horizontalLabel = 'Horizontal position',
    this.verticalLabel = 'Vertical position',
    this.errorLabel = 'Could not load image',
  });
  final ImageProvider image;
  final KImageCropShape shape;
  final int outputSize;
  final ValueChanged<Uint8List> onConfirm;
  final String confirmLabel,
      resetLabel,
      zoomLabel,
      horizontalLabel,
      verticalLabel,
      errorLabel;
  @override
  State<KImageCropper> createState() => _KImageCropperState();
}

class _KImageCropperState extends State<KImageCropper> {
  ui.Image? _image;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double _zoom = 1;
  Offset _position = Offset.zero;
  bool _error = false, _busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream == null) _load();
  }

  @override
  void didUpdateWidget(KImageCropper old) {
    super.didUpdateWidget(old);
    if (old.image != widget.image) _load();
  }

  void _load() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _image?.dispose();
    _image = null;
    _error = false;
    _zoom = 1;
    _position = Offset.zero;
    _stream = widget.image.resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener(
      (info, synchronousCall) {
        if (!mounted) return;
        setState(() {
          _image?.dispose();
          _image = info.image.clone();
        });
      },
      onError: (Object error, StackTrace? stack) {
        if (mounted) setState(() => _error = true);
      },
    );
    _stream!.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _image?.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_image == null || _busy) return;
    setState(() => _busy = true);
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = widget.outputSize.clamp(1, 4096).toDouble();
      _CropPainter(
        _image!,
        _zoom,
        _position,
        widget.shape,
      ).paint(canvas, Size.square(size));
      final picture = recorder.endRecording();
      final output = await picture.toImage(size.toInt(), size.toInt());
      picture.dispose();
      final data = await output.toByteData(format: ui.ImageByteFormat.png);
      output.dispose();
      if (mounted && data != null) widget.onConfirm(data.buffer.asUint8List());
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => KStack(
    align: KLayoutAlign.stretch,
    children: [
      if (_error) KText(widget.errorLabel),
      if (_image != null) ...[
        LayoutBuilder(
          builder: (context, constraints) {
            final dimension = math.min(
              constraints.maxWidth,
              math.min(
                widget.outputSize.toDouble(),
                (MediaQuery.sizeOf(context).height -
                        MediaQuery.viewInsetsOf(context).bottom) *
                    .3,
              ),
            );
            return Center(
              child: SizedBox.square(
                dimension: dimension,
                child: GestureDetector(
                  onPanUpdate: _busy
                      ? null
                      : (event) {
                          final image = _image!;
                          final source = Size(
                            image.width.toDouble(),
                            image.height.toDouble(),
                          );
                          final rect = kImageCropRect(source, _zoom, _position);
                          final scale = rect.width / dimension;
                          setState(
                            () => _position = Offset(
                              (_position.dx -
                                      event.delta.dx *
                                          scale *
                                          2 /
                                          math.max(
                                            1,
                                            source.width - rect.width,
                                          ))
                                  .clamp(-1, 1),
                              (_position.dy -
                                      event.delta.dy *
                                          scale *
                                          2 /
                                          math.max(
                                            1,
                                            source.height - rect.height,
                                          ))
                                  .clamp(-1, 1),
                            ),
                          );
                        },
                  child: CustomPaint(
                    painter: _CropPainter(
                      _image!,
                      _zoom,
                      _position,
                      widget.shape,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        KSlider(
          value: _zoom,
          min: 1,
          max: 4,
          label: widget.zoomLabel,
          onChanged: _busy ? null : (v) => setState(() => _zoom = v),
        ),
        KSlider(
          value: _position.dx,
          min: -1,
          max: 1,
          label: widget.horizontalLabel,
          onChanged: _busy
              ? null
              : (v) => setState(() => _position = Offset(v, _position.dy)),
        ),
        KSlider(
          value: _position.dy,
          min: -1,
          max: 1,
          label: widget.verticalLabel,
          onChanged: _busy
              ? null
              : (v) => setState(() => _position = Offset(_position.dx, v)),
        ),
        KInline(
          wrap: true,
          gap: KLayoutGap.action,
          children: [
            KButton(
              label: widget.resetLabel,
              variant: KButtonVariant.ghost,
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _zoom = 1;
                      _position = Offset.zero;
                    }),
            ),
            KButton(
              label: widget.confirmLabel,
              onPressed: _busy ? null : _confirm,
            ),
          ],
        ),
      ],
    ],
  );
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.image, this.zoom, this.position, this.shape);
  final ui.Image image;
  final double zoom;
  final Offset position;
  final KImageCropShape shape;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (shape == KImageCropShape.round) {
      canvas.clipPath(Path()..addOval(Offset.zero & size));
    }
    canvas.drawImageRect(
      image,
      kImageCropRect(
        Size(image.width.toDouble(), image.height.toDouble()),
        zoom,
        position,
      ),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.image != image ||
      old.zoom != zoom ||
      old.position != position ||
      old.shape != shape;
}
