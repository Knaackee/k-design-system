import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:widgetbook/widgetbook.dart';

class CoverFlowFixture extends StatelessWidget {
  const CoverFlowFixture({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: KText(
                'Wähle deinen ersten Agenten',
                variant: KTextVariant.heading2,
              ),
            ),
            KCoverFlow(
              label: 'Charakter auswählen',
              initialIndex: 1,
              previousLabel: 'Vorheriger Charakter',
              nextLabel: 'Nächster Charakter',
              height: context.knobs.double.slider(
                label: 'Height',
                initialValue: 460,
                min: 200,
                max: 700,
              ),
              itemWidth: context.knobs.double.slider(
                label: 'Item width',
                initialValue: 500,
                min: 160,
                max: 700,
              ),
              itemWidthFraction: context.knobs.double.slider(
                label: 'Item width fraction', initialValue: .66, min: .1, max: 1,
              ),
              sideAngle: context.knobs.double.slider(
                label: 'Side angle',
                initialValue: 0,
                min: 0,
                max: 80,
              ),
              sideOffset: context.knobs.double.slider(
                label: 'Side offset',
                initialValue: 100,
                min: 40,
                max: 150,
              ),
              sideScale: context.knobs.double.slider(
                label: 'Side scale',
                initialValue: .72,
                min: .3,
                max: 1,
              ),
              depth: context.knobs.double.slider(
                label: 'Depth',
                initialValue: 180,
                min: 0,
                max: 300,
              ),
              spacing: context.knobs.double.slider(
                label: 'Spacing',
                initialValue: 28,
                min: 10,
                max: 70,
              ),
              perspective: context.knobs.double.slider(
                label: 'Perspective',
                initialValue: 1100,
                min: 600,
                max: 2000,
              ),
              contentPadding: context.knobs.double.slider(
                label: 'Content padding',
                initialValue: 16,
                min: 0,
                max: 80,
              ),
              clipSides: context.knobs.boolean(
                label: 'Clip sides',
                initialValue: true,
              ),
              showControls: context.knobs.boolean(
                label: 'Show controls',
                initialValue: true,
              ),
              showCaption: context.knobs.boolean(
                label: 'Show caption',
                initialValue: true,
              ),
              reducedMotion: context.knobs.boolean(label: 'Reduced motion'),
              items: [
                for (final item in [
                  ('comet', 'Komet'),
                  ('sun', 'Sonne'),
                  ('saturn', 'Saturn'),
                ])
                  KCoverFlowItem(
                    id: item.$1,
                    label: item.$2,
                    child: SvgPicture.asset(
                      'assets/cover-flow/orbit-${item.$1}.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
