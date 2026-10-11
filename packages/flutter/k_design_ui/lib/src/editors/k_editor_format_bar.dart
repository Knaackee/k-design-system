import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/k_icon_button.dart';
import '../primitives/k_icon.dart';
import 'k_editor_types.dart';

class KEditorFormatBar extends StatelessWidget {
  const KEditorFormatBar({
    required this.labels,
    required this.onAction,
    this.actions = kDefaultMarkdownFormatActions,
    this.activeActions = const <KMarkdownFormatAction>{},
    this.floating = false,
    this.minimumItemExtent,
    this.trailingAction,
    this.leadingAction,
    super.key,
  });

  final KEditorLabels labels;
  final List<KMarkdownFormatAction> actions;
  final Set<KMarkdownFormatAction> activeActions;
  final ValueChanged<KMarkdownFormatAction> onAction;
  final bool floating;

  /// Final action inside the bar, kept visible after the scrollable formatting actions.
  final Widget? trailingAction;
  final Widget? leadingAction;

  /// Minimum visual and interactive size of each formatting action.
  ///
  /// By default the bar derives this from the resolved density and input-mode
  /// tokens. Consumers may override it for an embedded editor without changing
  /// the formatting actions or their semantics.
  final double? minimumItemExtent;

  static const _glyphs = {
    KMarkdownFormatAction.undo: KIconName.undo2,
    KMarkdownFormatAction.redo: KIconName.redo2,
    KMarkdownFormatAction.bold: KIconName.bold,
    KMarkdownFormatAction.italic: KIconName.italic,
    KMarkdownFormatAction.strike: KIconName.strikethrough,
    KMarkdownFormatAction.code: KIconName.code,
    KMarkdownFormatAction.link: KIconName.link,
    KMarkdownFormatAction.bulletList: KIconName.list,
    KMarkdownFormatAction.orderedList: KIconName.listOrdered,
    KMarkdownFormatAction.taskList: KIconName.listChecks,
    KMarkdownFormatAction.quote: KIconName.quote,
    KMarkdownFormatAction.codeBlock: KIconName.squareCode,
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
      math.max(t.sizeHitTarget, t.sizeControl),
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
        child: Padding(
          padding: EdgeInsets.all(floating ? t.spaceControlGap : 0),
          child: SizedBox(
            height: itemExtent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?leadingAction,
                Flexible(
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
                                horizontal: t.spaceHairline / 2,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: itemExtent,
                                  minHeight: itemExtent,
                                ),
                                child: KIconButton(
                                  label: _label(action),
                                  icon: _glyphs[action]!,
                                  selected: activeActions.contains(action),
                                  onPressed: () => onAction(action),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (trailingAction != null)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: t.spaceTight),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: itemExtent,
                        minHeight: itemExtent,
                      ),
                      child: trailingAction!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
