import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'k_adaptive_dialog.dart';
import 'k_overlays.dart';
import 'k_sheet_detail_body.dart';
import 'k_sheet_drag.dart';

/// Hero detail surface: a phone sheet or a non-overlapping inline side pane.
/// Open modally with [show]; place [inline] directly in a tablet master/detail row.
class KAdaptiveSheet extends StatelessWidget {
  const KAdaptiveSheet({
    required this.title,
    required this.hero,
    required this.child,
    this.floatingActions,
    this.heroOverlays,
    this.footer,
    this.onClose,
    this.closeLabel,
    this.inline = false,
    super.key,
  });

  final String title;
  final Widget hero;
  final Widget child;
  final Widget? floatingActions;
  final Widget? heroOverlays;
  final Widget? footer;
  final VoidCallback? onClose;
  final String? closeLabel;
  final bool inline;

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool dismissible = true,
    bool useRootNavigator = false,
  }) => KAdaptiveDialog.show<T>(
    context: context,
    builder: builder,
    barrierDismissible: dismissible,
    useRootNavigator: useRootNavigator,
  );

  @override
  Widget build(BuildContext context) {
    final side =
        inline ||
        MediaQuery.sizeOf(context).width >= KAdaptiveDialog.breakpoint;
    final content = side
        ? KSideSheet(
            hero: hero,
            floatingActions: floatingActions,
            heroOverlays: heroOverlays,
            footer: footer,
            onClose: onClose,
            closeLabel: closeLabel,
            child: child,
          )
        : KSheetDrag(
            enabled: onClose != null,
            onDismiss: onClose,
            child: KBottomSheet(
              title: Text(title),
              hero: hero,
              floatingActions: floatingActions,
              heroOverlays: heroOverlays,
              footer: footer,
              onClose: onClose,
              closeLabel: closeLabel,
              expandBody: true,
              maxWidth: double.infinity,
              child: child,
            ),
          );
    final surface = Semantics(container: true, label: title, child: content);
    if (inline) return surface;
    return Align(
      alignment: side ? Alignment.centerRight : Alignment.bottomCenter,
      heightFactor: 1,
      child: surface,
    );
  }
}

/// In-flow detail pane. Its parent reserves [KDesignTokens.layoutDrawerWidth].
class KSideSheet extends StatelessWidget {
  const KSideSheet({
    required this.hero,
    required this.child,
    this.floatingActions,
    this.heroOverlays,
    this.footer,
    this.onClose,
    this.closeLabel,
    super.key,
  });
  final Widget hero;
  final Widget child;
  final Widget? floatingActions;
  final Widget? heroOverlays;
  final Widget? footer;
  final VoidCallback? onClose;
  final String? closeLabel;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return SizedBox(
      width: t.layoutDrawerWidth,
      child: Material(
        color: t.colorSurfaceRaised,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: t.colorBorderDefault,
                width: t.borderWidthDefault,
              ),
            ),
          ),
          child: KSheetDetailBody(
            hero: hero,
            floatingActions: floatingActions,
            heroOverlays: heroOverlays,
            footer: footer,
            onClose: onClose,
            closeLabel: closeLabel,
            child: child,
          ),
        ),
      ),
    );
  }
}
