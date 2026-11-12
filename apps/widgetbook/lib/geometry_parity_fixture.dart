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
  'card-header': 'h',
  'list-swipe': 'h',
  'save-bar': 'h',
  'avatar-picker': 'h',
  'settings-group': 'h',
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
                'card-header',
                SizedBox(
                  width: double.infinity,
                  child: KCard(
                    title: 'Rocky',
                    description: 'Agent · working',
                    menu: const [KMenuAction(id: 'edit', label: 'Edit')],
                    actions: [KButton(label: 'Open', onPressed: () {})],
                    child: const KText('Groups the feedback by theme.'),
                  ),
                ),
              ),
              entry(
                'list-swipe',
                SizedBox(
                  width: double.infinity,
                  child: KList(
                    children: [
                      KListItem(
                        title: 'Mara Feld',
                        description: 'Moved the appointment',
                        onPressed: () {},
                        trailingActions: const [
                          KSwipeAction(
                            id: 'delete',
                            label: 'Delete',
                            icon: KIconName.trash,
                            tone: KSwipeActionTone.destructive,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              entry(
                'save-bar',
                SizedBox(
                  width: double.infinity,
                  child: KSaveBar(changes: 2, onSave: () {}, onDiscard: () {}),
                ),
              ),
              entry(
                'avatar-picker',
                SizedBox(
                  width: double.infinity,
                  child: KAvatarPicker(
                    shapes: const [
                      KAvatarShape(
                        id: 'circle',
                        label: 'Circle',
                        icon: KIcon(KIconName.circle),
                      ),
                      KAvatarShape(
                        id: 'star',
                        label: 'Star',
                        icon: KIcon(KIconName.star),
                      ),
                      KAvatarShape(
                        id: 'drop',
                        label: 'Drop',
                        icon: KIcon(KIconName.droplet),
                      ),
                      KAvatarShape(
                        id: 'heart',
                        label: 'Heart',
                        icon: KIcon(KIconName.heart),
                      ),
                      KAvatarShape(
                        id: 'cloud',
                        label: 'Cloud',
                        icon: KIcon(KIconName.cloud),
                      ),
                    ],
                    colors: const [
                      KAvatarColor(value: Color(0xFFF43F5E), label: 'Rose'),
                      KAvatarColor(value: Color(0xFF22D3EE), label: 'Cyan'),
                      KAvatarColor(value: Color(0xFF8B5CF6), label: 'Violet'),
                    ],
                    shape: 'drop',
                    color: const Color(0xFF22D3EE),
                    onShapeChanged: (_) {},
                    onColorChanged: (_) {},
                  ),
                ),
              ),
              entry(
                'settings-group',
                SizedBox(
                  width: double.infinity,
                  child: KList(
                    title: 'Network',
                    children: [
                      KSettingsRow(
                        title: 'Browser permissions',
                        description: 'None yet.',
                        control: KButton(
                          label: 'Refresh',
                          variant: KButtonVariant.secondary,
                          onPressed: () {},
                        ),
                      ),
                      KSettingsRow(
                        title: 'Memories',
                        description: 'What Rocky remembers.',
                        control: KButton(
                          label: 'Open',
                          variant: KButtonVariant.secondary,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
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
