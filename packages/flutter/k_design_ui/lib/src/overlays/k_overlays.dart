import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'k_sheet_drag.dart';
import 'k_sheet_detail_body.dart';

import '../primitives/k_surface.dart';
import '../actions/k_icon_button.dart';
import '../primitives/k_icon.dart';

/// Token-styled modal content. Open it with [KDialog.show].
class KDialog extends StatelessWidget {
  const KDialog({
    required this.title,
    required this.child,
    this.description,
    this.actions,
    this.onClose,
    this.closeLabel,
    this.maxWidth = 520,
    this.maxHeight,
    this.expandBody = false,
    super.key,
  });

  final Widget title;
  final Widget? description;
  final Widget child;
  final Widget? actions;
  final VoidCallback? onClose;
  final String? closeLabel;
  final double maxWidth;

  /// Optional consumer height constraint, matching Web's CSS max-height.
  /// Defaults to 80% of the viewport; keyboard and safe-area constraints remain.
  final double? maxHeight;
  final bool expandBody;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget title,
    required Widget child,
    Widget? description,
    Widget? actions,
    String? closeLabel,
    double maxWidth = 520,
    double? maxHeight,
    bool dismissible = true,
  }) => showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    builder: (routeContext) => PopScope(
      canPop: dismissible,
      child: KDialog(
        title: title,
        description: description,
        actions: actions,
        closeLabel: closeLabel,
        // maybePop: a PopScope in the sheet (unsaved changes) can ask first.
        onClose: dismissible
            ? () => Navigator.of(routeContext).maybePop()
            : null,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        child: child,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final inset = media.viewInsets.bottom;
        // Scaffold/sheet consumers may already have reserved the keyboard.
        final alreadyResized =
            constraints.maxHeight <= media.size.height - inset + 1;
        return Padding(
          padding: EdgeInsets.only(bottom: alreadyResized ? 0 : inset),
          child: MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight:
                      maxHeight ?? MediaQuery.sizeOf(context).height * .8,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: KSurface(
                    radius: KSurfaceRadius.overlay,
                    elevation: KSurfaceElevation.overlay,
                    child: _OverlayBody(
                      title: title,
                      description: description,
                      actions: actions,
                      onClose: onClose,
                      closeLabel: closeLabel,
                      padding: t.spaceLayoutGutter,
                      expandBody: expandBody,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Token-styled bottom sheet with native drag and scroll coordination.
class KBottomSheet extends StatelessWidget {
  const KBottomSheet({
    required this.title,
    required this.child,
    this.description,
    this.actions,
    this.hero,
    this.floatingActions,
    this.heroOverlays,
    this.footer,
    this.onClose,
    this.closeLabel,
    this.maxWidth = 640,
    this.expandBody = false,
    this.onDragUpdate,
    this.onDragEnd,
    super.key,
  });

  final Widget title;
  final Widget? description;

  /// Full-bleed media replaces the visible title and overlays the grip.
  final Widget? hero;
  final Widget? floatingActions;
  final Widget? heroOverlays;
  final Widget? footer;
  final Widget child;
  final Widget? actions;
  final VoidCallback? onClose;
  final String? closeLabel;
  final double maxWidth;
  final bool expandBody;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget title,
    required Widget child,
    Widget? description,
    Widget? actions,
    Widget? hero,
    Widget? floatingActions,
    Widget? heroOverlays,
    Widget? footer,
    String? closeLabel,
    double maxWidth = 640,
    bool dismissible = true,
    bool enableDrag = true,
    bool useRootNavigator = false,
    bool expandBody = false,
  }) => showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    isDismissible: dismissible,
    // The sheet handles its own swipe-down so that a PopScope inside it
    // (unsaved changes) can ask before it closes (Decision 0012, HIG Sheets);
    // the framework's drag would close it unconditionally.
    enableDrag: false,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (routeContext) => KSheetDrag(
      enabled: dismissible && enableDrag,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: expandBody ? MediaQuery.viewInsetsOf(routeContext).bottom : 0,
        ),
        child: KBottomSheet(
          title: title,
          description: description,
          actions: actions,
          hero: hero,
          floatingActions: floatingActions,
          heroOverlays: heroOverlays,
          footer: footer,
          closeLabel: closeLabel,
          // maybePop: a PopScope in the sheet (unsaved changes) can ask first.
          onClose: dismissible
              ? () => Navigator.of(routeContext).maybePop()
              : null,
          maxWidth: maxWidth,
          expandBody: expandBody,
          child: child,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: Material(
          color: t.colorSurfaceRaised,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: t.colorBorderDefault,
              width: t.borderWidthDefault,
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(t.radiusOverlay),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: hero != null
              ? KSheetDetailBody(
                  hero: hero!,
                  floatingActions: floatingActions,
                  heroOverlays: heroOverlays,
                  footer: footer ?? actions,
                  onClose: onClose,
                  closeLabel: closeLabel,
                  showGrip: true,
                  child: child,
                )
              : SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: expandBody
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: onDragUpdate,
                        onVerticalDragEnd: onDragEnd,
                        child: SizedBox(
                          height: t.componentBottomSheetGripAreaMinHeight,
                          child: Center(
                            child: Container(
                              width: t.componentBottomSheetGripWidth,
                              height: t.componentBottomSheetGripHeight,
                              decoration: BoxDecoration(
                                color: t.colorBorderStrong,
                                borderRadius: BorderRadius.circular(
                                  t.radiusExtraSmall,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (expandBody)
                        Expanded(
                          child: _OverlayBody(
                            title: title,
                            description: description,
                            actions: actions,
                            onClose: onClose,
                            closeLabel: closeLabel,
                            padding: t.spaceLayoutGutter,
                            expandBody: true,
                            child: child,
                          ),
                        )
                      else
                        Flexible(
                          fit: FlexFit.loose,
                          child: _OverlayBody(
                            title: title,
                            description: description,
                            actions: actions,
                            onClose: onClose,
                            closeLabel: closeLabel,
                            padding: t.spaceLayoutGutter,
                            child: child,
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

class _OverlayBody extends StatelessWidget {
  const _OverlayBody({
    required this.title,
    required this.child,
    required this.padding,
    this.description,
    this.actions,
    this.onClose,
    this.closeLabel,
    this.expandBody = false,
  });

  final Widget title;
  final Widget? description;
  final Widget child;
  final Widget? actions;
  final VoidCallback? onClose;
  final String? closeLabel;
  final double padding;
  final bool expandBody;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final body = Padding(
      padding: expandBody ? EdgeInsets.zero : EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: expandBody
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.start,
        mainAxisSize: expandBody ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Padding(
            padding: expandBody
                ? EdgeInsets.fromLTRB(padding, padding, padding, 0)
                : EdgeInsets.zero,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontFamily: t.fontFamily,
                      fontSize: t.fontHeading5Size,
                      height: t.fontHeading5LineHeight / t.fontHeading5Size,
                      fontWeight: t.fontHeadingWeight,
                      color: t.colorTextPrimary,
                    ),
                    child: title,
                  ),
                ),
                if (onClose != null)
                  KIconButton(
                    label:
                        closeLabel ??
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: KIconName.x,
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
          if (description != null) ...[
            SizedBox(height: t.spaceTight),
            DefaultTextStyle(
              style: TextStyle(
                fontFamily: t.fontFamily,
                fontSize: t.fontBodySmallSize,
                color: t.colorTextMuted,
              ),
              child: description!,
            ),
          ],
          SizedBox(height: t.spaceLayoutGutter),
          if (expandBody) Expanded(child: child) else child,
          if (actions != null) ...[
            SizedBox(height: t.spaceLayoutGutter),
            Align(alignment: Alignment.centerRight, child: actions!),
          ],
        ],
      ),
    );
    return expandBody ? body : SingleChildScrollView(child: body);
  }
}
