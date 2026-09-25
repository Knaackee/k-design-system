import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../primitives/k_button.dart';
import 'k_editor_types.dart';

class KEditorFormatBar extends StatelessWidget {
  const KEditorFormatBar({
    required this.labels,
    required this.onAction,
    this.actions = kDefaultMarkdownFormatActions,
    this.activeActions = const <KMarkdownFormatAction>{},
    this.floating = false,
    this.minimumItemExtent,
    super.key,
  });

  final KEditorLabels labels;
  final List<KMarkdownFormatAction> actions;
  final Set<KMarkdownFormatAction> activeActions;
  final ValueChanged<KMarkdownFormatAction> onAction;
  final bool floating;

  /// Minimum visual and interactive size of each formatting action.
  ///
  /// By default the bar derives this from the resolved density and input-mode
  /// tokens. Consumers may override it for an embedded editor without changing
  /// the formatting actions or their semantics.
  final double? minimumItemExtent;

  static const _glyphs = {
    KMarkdownFormatAction.undo: '↶',
    KMarkdownFormatAction.redo: '↷',
    KMarkdownFormatAction.bold: 'B',
    KMarkdownFormatAction.italic: 'I',
    KMarkdownFormatAction.strike: 'S',
    KMarkdownFormatAction.code: '</>',
    KMarkdownFormatAction.link: '↗',
    KMarkdownFormatAction.bulletList: '•≡',
    KMarkdownFormatAction.orderedList: '1≡',
    KMarkdownFormatAction.taskList: '☑',
    KMarkdownFormatAction.quote: '❞',
    KMarkdownFormatAction.codeBlock: '{ }',
  };

  String _label(KMarkdownFormatAction action) => switch (action) {
    KMarkdownFormatAction.undo => labels.undo,
    KMarkdownFormatAction.redo => labels.redo,
    KMarkdownFormatAction.bold => labels.bold,
    KMarkdownFormatAction.italic => labels.italic,
    KMarkdownFormatAction.strike => labels.strike,
    KMarkdownFormatAction.code => labels.code,
    KMarkdownFormatAction.link => labels.link,
    KMarkdownFormatAction.bulletList => labels.bulletList,
    KMarkdownFormatAction.orderedList => labels.orderedList,
    KMarkdownFormatAction.taskList => labels.taskList,
    KMarkdownFormatAction.quote => labels.quote,
    KMarkdownFormatAction.codeBlock => labels.codeBlock,
  };

  @override
  Widget build(BuildContext context) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final itemExtent = math.max(
      minimumItemExtent ?? 0,
      math.max(t.sizeHitTarget, t.sizeControl + t.spaceControlGap * 2),
    );
    return Semantics(
      container: true,
      label: 'Text formatting',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: floating ? t.colorSurfaceRaised : Colors.transparent,
          border: floating ? Border.all(color: t.colorBorderDefault) : null,
          borderRadius: BorderRadius.circular(t.radiusOverlay),
          boxShadow: floating ? t.elevationOverlay : const [],
        ),
        child: SizedBox(
          height: itemExtent,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: const {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.stylus,
                PointerDeviceKind.trackpad,
              },
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: t.spaceTight),
              child: Row(
                children: [
                  for (final action in actions)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: t.spaceHairline,
                      ),
                      child: Tooltip(
                        message: _label(action),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: itemExtent,
                            minHeight: itemExtent,
                          ),
                          child: KButton(
                            label: _glyphs[action]!,
                            variant: activeActions.contains(action)
                                ? KButtonVariant.primary
                                : KButtonVariant.ghost,
                            paddingInline: 0,
                            onPressed: () => onAction(action),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
