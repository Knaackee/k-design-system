import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Geometry parity reference (Decision 0010). Same content and IDs as the
/// Storybook story `Review/GeometryParity` (`geometry-parity-fixture.tsx`).
/// `test/geometry_parity_test.dart` measures each entry; the Web gate
/// `tooling/geometry-parity.mjs` measures the story and compares.
///
/// The column has a fixed width so both platforms wrap at the same width,
/// independent of the gallery chrome.
const kGeometryParityWidth = 320.0;

/// Entry id → axes compared (`w` width, `h` height). Wrapping text compares
/// height only: CSS fit-content takes the available width, Flutter the
/// longest line.
const kGeometryParityEntries = <String, String>{
  'text-heading1': 'h',
  'text-body': 'h',
  'text-small': 'h',
  'button-primary': 'wh',
  'button-secondary': 'wh',
  'button-ghost': 'wh',
  'badge': 'wh',
  'checkbox': 'wh',
  'input': 'h',
  'card': 'h',
};

class GeometryParityFixture extends StatelessWidget {
  const GeometryParityFixture({super.key});

  static Key keyFor(String id) => ValueKey('parity:$id');

  @override
  Widget build(BuildContext context) {
    Widget entry(String id, Widget child) =>
        KeyedSubtree(key: keyFor(id), child: child);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: kGeometryParityWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              entry(
                'text-heading1',
                const KText('Heading one', variant: KTextVariant.heading1),
              ),
              entry(
                'text-body',
                const KText(
                  'Body text that wraps across two lines on a phone width.',
                ),
              ),
              entry(
                'text-small',
                const KText(
                  'Small supporting text under a field.',
                  variant: KTextVariant.bodySmall,
                ),
              ),
              entry('button-primary', KButton(label: 'Save', onPressed: () {})),
              entry(
                'button-secondary',
                KButton(
                  label: 'Cancel',
                  variant: KButtonVariant.secondary,
                  onPressed: () {},
                ),
              ),
              entry(
                'button-ghost',
                KButton(
                  label: 'Details',
                  variant: KButtonVariant.ghost,
                  onPressed: () {},
                ),
              ),
              entry('badge', const KBadge(child: Text('Active'))),
              entry(
                'checkbox',
                KCheckbox(label: 'Remember me', value: true, onChanged: (_) {}),
              ),
              entry(
                'input',
                const SizedBox(
                  width: double.infinity,
                  child: KInput(label: 'Name', placeholder: 'Name'),
                ),
              ),
              entry(
                'card',
                const SizedBox(
                  width: double.infinity,
                  child: KCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        KText('Card title', variant: KTextVariant.heading5),
                        KText('One inset, title and body share the edge.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
