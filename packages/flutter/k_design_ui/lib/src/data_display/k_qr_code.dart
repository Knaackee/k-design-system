import 'package:flutter/material.dart';
import 'package:qr/qr.dart';
import '../primitives/k_layout.dart';
import '../primitives/k_text.dart';

enum KQrCodeModuleShape { square, rounded, dots, fluid }

enum KQrCodeEyeShape { square, rounded, circle }

enum KQrCodeVariant { classic, soft, portrait, card }

/// Light canvas and four-module quiet zone are preserved in every theme.
class KQrCode extends StatelessWidget {
  const KQrCode({
    super.key,
    required this.data,
    required this.label,
    this.variant = KQrCodeVariant.classic,
    this.size = 240,
    this.moduleShape,
    this.eyeShape = KQrCodeEyeShape.square,
    this.color = const Color(0xff18181b),
    this.image,
    this.title,
    this.caption,
  });
  final String data, label;
  final KQrCodeVariant variant;
  final double size;
  final KQrCodeModuleShape? moduleShape;
  final KQrCodeEyeShape eyeShape;
  final Color color;
  final ImageProvider? image;
  final String? title, caption;
  @override
  Widget build(BuildContext context) {
    QrImage matrix;
    try {
      matrix = QrImage(
        QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.H),
      );
    } catch (_) {
      return Semantics(label: label, child: const KText('—'));
    }
    final max = [color.r, color.g, color.b].reduce((a, b) => a > b ? a : b);
    final scale = max > 150 / 255 ? (150 / 255) / max : 1.0;
    final ink = Color.from(
      red: color.r * scale,
      green: color.g * scale,
      blue: color.b * scale,
      alpha: 1,
    );
    return SizedBox(
      width: size,
      child: KStack(
        align: KLayoutAlign.center,
        gap: KLayoutGap.control,
        children: [
          if (variant == KQrCodeVariant.card && image != null)
            ClipOval(
              child: Image(
                image: image!,
                width: size * .22,
                height: size * .22,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => const SizedBox.shrink(),
              ),
            ),
          if (variant == KQrCodeVariant.card && title != null)
            KText(title!, variant: KTextVariant.heading3),
          Semantics(
            image: true,
            label: label,
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, c) {
                  final unit = c.maxWidth / (matrix.moduleCount + 8);
                  final avatar = matrix.moduleCount * .16 * unit;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _QrPainter(
                            matrix,
                            ink,
                            eyeShape,
                            moduleShape ??
                                (variant == KQrCodeVariant.classic
                                    ? KQrCodeModuleShape.square
                                    : KQrCodeModuleShape.rounded),
                          ),
                        ),
                      ),
                      if (variant == KQrCodeVariant.portrait && image != null)
                        Image(
                          image: image!,
                          width: avatar,
                          height: avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, s) => const SizedBox.shrink(),
                          frameBuilder: (context, child, frame, sync) =>
                              frame == null && !sync
                              ? const SizedBox.shrink()
                              : Container(
                                  padding: EdgeInsets.all(unit * .6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(child: child),
                                ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (variant == KQrCodeVariant.card && caption != null)
            KText(caption!),
        ],
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.matrix, this.ink, this.eyes, this.shape);
  final KQrCodeEyeShape eyes;
  final QrImage matrix;
  final Color ink;
  final KQrCodeModuleShape shape;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final n = matrix.moduleCount;
    final unit = size.width / (n + 8);
    final paint = Paint()..color = ink;
    final positionCount = matrix.typeNumber ~/ 7 + 2;
    final interval = n == 145
        ? 26
        : ((n - 13) / (2 * positionCount - 2)).ceil() * 2;
    final positions = matrix.typeNumber == 1
        ? <int>[]
        : [
            6,
            for (var i = positionCount - 2; i >= 0; i--) n - 7 - i * interval,
          ];
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (!matrix.isDark(y, x)) continue;
        final finderArea =
            (x < 8 && y < 8) || (x >= n - 8 && y < 8) || (x < 8 && y >= n - 8);
        if (finderArea && eyes != KQrCodeEyeShape.square) continue;
        final alignment = positions.any(
          (cx) => positions.any(
            (cy) =>
                !((cx == 6 && cy == 6) ||
                    (cx == 6 && cy == n - 7) ||
                    (cx == n - 7 && cy == 6)) &&
                (x - cx).abs() <= 2 &&
                (y - cy).abs() <= 2,
          ),
        );
        final finder =
            finderArea ||
            x == 6 ||
            y == 6 ||
            x == 8 ||
            y == 8 ||
            alignment ||
            (matrix.typeNumber >= 7 &&
                ((x < 6 && y >= n - 11) || (y < 6 && x >= n - 11)));
        bool dark(int dx, int dy) =>
            x + dx >= 0 &&
            y + dy >= 0 &&
            x + dx < n &&
            y + dy < n &&
            matrix.isDark(y + dy, x + dx);
        if (shape == KQrCodeModuleShape.fluid && !finder) {
          Radius corner(bool round) => Radius.circular(round ? unit * .5 : 0);
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTWH((x + 4) * unit, (y + 4) * unit, unit, unit),
              topLeft: corner(!dark(-1, 0) && !dark(0, -1)),
              topRight: corner(!dark(1, 0) && !dark(0, -1)),
              bottomLeft: corner(!dark(-1, 0) && !dark(0, 1)),
              bottomRight: corner(!dark(1, 0) && !dark(0, 1)),
            ),
            paint,
          );
          continue;
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH((x + 4) * unit, (y + 4) * unit, unit, unit),
            Radius.circular(
              shape == KQrCodeModuleShape.square || finder
                  ? 0
                  : unit * (shape == KQrCodeModuleShape.dots ? .5 : .35),
            ),
          ),
          paint,
        );
      }
    }
    if (eyes != KQrCodeEyeShape.square) {
      for (final pos in [Offset(4, 4), Offset(n - 3, 4), Offset(4, n - 3)]) {
        for (var offset = 0; offset < 3; offset++) {
          final width = (7 - offset * 2) * unit;
          final rect = Rect.fromLTWH(
            (pos.dx + offset) * unit,
            (pos.dy + offset) * unit,
            width,
            width,
          );
          final p = Paint()..color = offset == 1 ? Colors.white : ink;
          if (eyes == KQrCodeEyeShape.circle) {
            canvas.drawOval(rect, p);
          } else {
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(width * .25)),
              p,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) =>
      old.matrix != matrix ||
      old.ink != ink ||
      old.shape != shape ||
      old.eyes != eyes;
}
