import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:widgetbook/widgetbook.dart';

import 'button_fixtures.dart';
import 'typography_fixtures.dart';
import 'color_fixtures.dart';
import 'foundation_fixtures.dart';
import 'configuration_addon.dart';
import 'gallery_navigation.dart';
import 'additional_primitive_fixtures.dart';

export 'foundation_fixtures.dart' show buildCardVariants, buildSurfaceTones;
export 'configuration_addon.dart';

void main() => runApp(const KDesignWidgetbook());

class KDesignWidgetbook extends StatelessWidget {
  const KDesignWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      lightTheme: kDesignTheme(),
      darkTheme: kDesignTheme(brightness: Brightness.dark),
      header: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('K Design System'),
      ),
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Orbit Light', data: kDesignTheme()),
            WidgetbookTheme(
              name: 'Orbit Dark',
              data: kDesignTheme(brightness: Brightness.dark),
            ),
            WidgetbookTheme(
              name: 'Reference Light',
              data: kDesignTheme(brand: KBrand.reference),
            ),
            WidgetbookTheme(
              name: 'Reference Dark',
              data: kDesignTheme(
                brand: KBrand.reference,
                brightness: Brightness.dark,
              ),
            ),
          ],
        ),
        ViewportAddon(const [
          ViewportData(
            name: 'Compact · 375',
            width: 375,
            height: 812,
            pixelRatio: 1,
            platform: TargetPlatform.android,
          ),
          ViewportData(
            name: 'Medium · 700',
            width: 700,
            height: 900,
            pixelRatio: 1,
            platform: TargetPlatform.android,
          ),
          ViewportData(
            name: 'Expanded · 1024',
            width: 1024,
            height: 900,
            pixelRatio: 1,
            platform: TargetPlatform.windows,
          ),
          ViewportData(
            name: 'Large · 1440',
            width: 1440,
            height: 1000,
            pixelRatio: 1,
            platform: TargetPlatform.windows,
          ),
          ViewportData(
            name: 'Extra large · 1680',
            width: 1680,
            height: 1050,
            pixelRatio: 1,
            platform: TargetPlatform.windows,
          ),
        ]),
        KDesignConfigurationAddon(),
        TextScaleAddon(initialScale: 1, min: 1, max: 2, divisions: 4),
      ],
      directories: sortGalleryNodes([
        WidgetbookCategory(
          name: 'Primitives',
          children: [
            WidgetbookFolder(
              name: 'Container',
              children: [
                WidgetbookUseCase(
                  name: 'container-bounds',
                  builder: buildContainerBounds,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Grid',
              children: [
                WidgetbookUseCase(
                  name: 'grid-responsive',
                  builder: buildGridResponsive,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Icon',
              children: [
                WidgetbookUseCase(
                  name: 'icon-lucide',
                  builder: buildIconLucide,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Separator',
              children: [
                WidgetbookUseCase(
                  name: 'separator-orientations',
                  builder: buildSeparatorOrientations,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Button',
              children: [
                WidgetbookUseCase(
                  name: 'button-primary',
                  builder: buildButtonPrimary,
                ),
                WidgetbookUseCase(
                  name: 'button-variants',
                  builder: buildButtonVariants,
                ),
                WidgetbookUseCase(
                  name: 'button-states',
                  builder: buildButtonStates,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Typography',
              children: [
                WidgetbookUseCase(
                  name: 'typography-primary',
                  builder: buildTypographyPrimary,
                ),
                WidgetbookUseCase(
                  name: 'typography-scale',
                  builder: buildTypographyScale,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Colors',
              children: [
                WidgetbookUseCase(
                  name: 'colors-semantic-roles',
                  builder: buildSemanticColors,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Shape',
              children: [
                WidgetbookUseCase(
                  name: 'shape-radius-scale',
                  builder: buildRadiusScale,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Elevation',
              children: [
                WidgetbookUseCase(
                  name: 'elevation-levels',
                  builder: buildElevationLevels,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Surface',
              children: [
                WidgetbookUseCase(
                  name: 'surface-tones',
                  builder: buildSurfaceTones,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Layout',
              children: [
                WidgetbookUseCase(
                  name: 'layout-composition',
                  builder: buildLayoutComposition,
                ),
              ],
            ),
            WidgetbookFolder(
              name: 'Card',
              children: [
                WidgetbookUseCase(
                  name: 'card-variants',
                  builder: buildCardVariants,
                ),
              ],
            ),
          ],
        ),
      ]),
    );
  }
}
