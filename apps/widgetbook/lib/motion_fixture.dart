import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Same fixture as Storybook Primitives/Motion/motion-roles. Switch the
/// style in the K Design addon (motion: apple, expressive, reduced).
class MotionRolesFixture extends StatefulWidget {
  const MotionRolesFixture({super.key});

  @override
  State<MotionRolesFixture> createState() => _MotionRolesFixtureState();
}

class _MotionRolesFixtureState extends State<MotionRolesFixture> {
  static const _roles = {
    KMotionRole.feedback: 'Press, hover, focus',
    KMotionRole.control: 'Toggle, select, expand',
    KMotionRole.enter: 'Sheet, dialog, toast appears',
    KMotionRole.exit: 'Something leaves',
    KMotionRole.page: 'Screen and tab change',
    KMotionRole.attention: 'Rare emphasis',
  };
  var _on = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(t.spaceLayoutGutter),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: KStack(
          gap: KLayoutGap.action,
          align: KLayoutAlign.stretch,
          children: [
            KInline(
              gap: KLayoutGap.control,
              wrap: true,
              children: [
                KButton(
                  label: _on ? 'Back' : 'Play',
                  onPressed: () => setState(() => _on = !_on),
                ),
                const KText(
                  'Switch the style in the K Design addon: motion.',
                  variant: KTextVariant.bodySmall,
                ),
              ],
            ),
            for (final MapEntry(key: role, value: use) in _roles.entries)
              _row(t, role, use),
          ],
        ),
      ),
    );
  }

  Widget _row(KDesignTokens t, KMotionRole role, String use) {
    final spec = t.motion(role);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return KStack(
      gap: KLayoutGap.control,
      align: KLayoutAlign.stretch,
      children: [
        KText(
          '${role.name} · $use · ${spec.settle.inMilliseconds} ms',
          variant: KTextVariant.label,
        ),
        Container(
          height: t.sizeControl,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: t.colorSurfaceSubtle,
            borderRadius: BorderRadius.circular(t.radiusFull),
          ),
          child: AnimatedAlign(
            duration: reduced ? Duration.zero : spec.settle,
            curve: spec.curve,
            // Travel is scaled by the role's distance: 0 = fade only.
            alignment: Alignment(_on ? -1 + 2 * spec.distance : -1, 0),
            child: AnimatedOpacity(
              duration: reduced ? Duration.zero : spec.settle,
              opacity: _on ? 1 : 0.4,
              child: Container(
                width: t.sizeControl - 8,
                decoration: BoxDecoration(
                  color: t.colorActionPrimaryBackground,
                  borderRadius: BorderRadius.circular(t.radiusFull),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
