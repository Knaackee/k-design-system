import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:widgetbook/widgetbook.dart';

class QrCodeFixture extends StatefulWidget {
  const QrCodeFixture({super.key});
  @override
  State<QrCodeFixture> createState() => _QrCodeFixtureState();
}

class _QrCodeFixtureState extends State<QrCodeFixture> {
  KQrCodeVariant variant = KQrCodeVariant.portrait;
  KQrCodeModuleShape shape = KQrCodeModuleShape.fluid;
  KQrCodeEyeShape eyes = KQrCodeEyeShape.rounded;
  Color color = const Color(0xff2563eb);
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: KStack(
          align: KLayoutAlign.center,
          gap: KLayoutGap.section,
          children: [
            const KStack(
              align: KLayoutAlign.center,
              children: [
                KText('Dein QR-Code', variant: KTextVariant.heading2),
                KText('Ein Scan. Direkt zu deiner Buchungsseite.'),
              ],
            ),
            KInline(
              wrap: true,
              gap: KLayoutGap.control,
              children: [
                for (final e in {
                  KQrCodeVariant.classic: 'Klassisch',
                  KQrCodeVariant.soft: 'Soft',
                  KQrCodeVariant.portrait: 'Persönlich',
                  KQrCodeVariant.card: 'Visitenkarte',
                }.entries)
                  KButton(
                    label: e.value,
                    variant: variant == e.key
                        ? KButtonVariant.primary
                        : KButtonVariant.secondary,
                    onPressed: () => setState(() => variant = e.key),
                  ),
              ],
            ),
            KInline(
              wrap: true,
              gap: KLayoutGap.control,
              children: [
                for (final e in {
                  KQrCodeModuleShape.square: 'Eckig',
                  KQrCodeModuleShape.rounded: 'Abgerundet',
                  KQrCodeModuleShape.dots: 'Punkte',
                  KQrCodeModuleShape.fluid: 'Fließend',
                }.entries)
                  KButton(
                    label: e.value,
                    variant: shape == e.key
                        ? KButtonVariant.primary
                        : KButtonVariant.secondary,
                    onPressed: () => setState(() => shape = e.key),
                  ),
              ],
            ),
            KInline(
              wrap: true,
              gap: KLayoutGap.control,
              children: [
                for (final e in {
                  KQrCodeEyeShape.square: 'Eckige Ecken',
                  KQrCodeEyeShape.rounded: 'Weiche Ecken',
                  KQrCodeEyeShape.circle: 'Runde Ecken',
                }.entries)
                  KButton(
                    label: e.value,
                    variant: eyes == e.key
                        ? KButtonVariant.primary
                        : KButtonVariant.secondary,
                    onPressed: () => setState(() => eyes = e.key),
                  ),
              ],
            ),
            KQrCode(
              eyeShape: eyes,
              moduleShape: shape,
              data: context.knobs.string(
                label: 'data',
                initialValue: 'https://example.com/book/alex',
              ),
              label: 'Buchungsseite öffnen',
              variant: variant,
              color: color,
              size: context.knobs.double.slider(
                label: 'size',
                initialValue: 240,
                min: 160,
                max: 400,
              ),
              image: const AssetImage('assets/image-cropper/jordan.png'),
              title: 'Alex Morgan',
              caption: 'Termin buchen',
            ),
            KInline(
              wrap: true,
              gap: KLayoutGap.control,
              children: [
                for (final e in {
                  const Color(0xff2563eb): 'Blau',
                  const Color(0xff7c3aed): 'Violett',
                  const Color(0xff059669): 'Grün',
                  const Color(0xff18181b): 'Graphit',
                }.entries)
                  KButton(
                    label: e.value,
                    variant: color == e.key
                        ? KButtonVariant.primary
                        : KButtonVariant.secondary,
                    onPressed: () => setState(() => color = e.key),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
