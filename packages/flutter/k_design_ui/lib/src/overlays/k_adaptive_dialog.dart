import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'k_overlays.dart';
import 'k_sheet_drag.dart';

/// A modal sheet on phones and a centered dialog on larger screens.
/// Use [show] so route behavior matches the rendered surface.
class KAdaptiveDialog extends StatelessWidget {
  const KAdaptiveDialog({
    required this.title,
    required this.child,
    this.description,
    this.actions,
    this.onClose,
    this.closeLabel,
    this.maxWidth = 520,
    this.expandBody = true,
    this.pageSheet = false,
    super.key,
  });

  static const breakpoint = 600.0;
  final Widget title;
  final Widget child;
  final Widget? description;
  final Widget? actions;
  final VoidCallback? onClose;
  final String? closeLabel;
  final double maxWidth;
  final bool expandBody;

  /// Use the coordinated tall sheet on every window size for page journeys.
  final bool pageSheet;

  static Future<T?> show<T>({
    required BuildContext context,
    WidgetBuilder? builder,
    Widget? title,
    Widget? child,
    Widget? description,
    Widget? actions,
    double maxWidth = 520,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
    bool pageSheet = false,
  }) {
    assert(builder != null || title != null && child != null);
    final contentBuilder =
        builder ??
        (BuildContext routeContext) => KAdaptiveDialog(
          title: title!,
          description: description,
          actions: actions,
          maxWidth: maxWidth,
          pageSheet: pageSheet,
          onClose: () => Navigator.of(routeContext).pop(),
          child: child!,
        );
    if (pageSheet || MediaQuery.sizeOf(context).width < breakpoint) {
      return showModalBottomSheet<T>(
        context: context,
        useRootNavigator: useRootNavigator,
        useSafeArea: true,
        isScrollControlled: true,
        isDismissible: barrierDismissible,
        // The coordinated sheet below owns dragging and guarded dismissal.
        enableDrag: false,
        backgroundColor: Colors.transparent,
        constraints: pageSheet ? BoxConstraints(maxWidth: maxWidth) : null,
        builder: (routeContext) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(routeContext).bottom,
          ),
          child: contentBuilder(routeContext),
        ),
      );
    }
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
      builder: contentBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = Theme.of(
      context,
    ).extension<KDesignTokens>()!.spaceLayoutGutter;
    final descriptionContent = description == null
        ? null
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: description!,
          );
    final paddedActions = actions == null
        ? null
        : Padding(
            padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
            child: actions!,
          );
    final actionContent = actions == null
        ? null
        : MediaQuery.sizeOf(context).height >= 400
        ? paddedActions
        : ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .25,
            ),
            child: SingleChildScrollView(child: paddedActions),
          );
    final body = SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: child,
    );
    if (pageSheet || MediaQuery.sizeOf(context).width < breakpoint) {
      if (!expandBody && !pageSheet) {
        // One drag model for every sheet (Decision 0015).
        return KSheetDrag(
          onDismiss: onClose,
          child: KBottomSheet(
            title: title,
            description: description,
            actions: actions,
            onClose: onClose,
            closeLabel: closeLabel,
            maxWidth: double.infinity,
            child: child,
          ),
        );
      }
      return _DraggableDialog(
        dialog: this,
        padding: padding,
        description: descriptionContent,
        actions: actionContent,
      );
    }
    return KDialog(
      title: title,
      description: expandBody ? descriptionContent : description,
      actions: expandBody ? actionContent : actions,
      onClose: onClose,
      closeLabel: closeLabel,
      maxWidth: maxWidth,
      expandBody: expandBody,
      child: expandBody ? body : child,
    );
  }
}

/// The tall sheet for long content and page journeys: 90 % of the height,
/// dragged and dismissed like every other sheet (Decision 0015).
class _DraggableDialog extends StatelessWidget {
  const _DraggableDialog({
    required this.dialog,
    required this.padding,
    this.description,
    this.actions,
  });
  final KAdaptiveDialog dialog;
  final double padding;
  final Widget? description;
  final Widget? actions;

  static const _expandedExtent = .9;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: SizedBox(
        height: constraints.maxHeight * _expandedExtent,
        child: KSheetDrag(
          onDismiss: dialog.onClose,
          child: KBottomSheet(
            title: dialog.title,
            description: description,
            actions: actions,
            maxWidth: dialog.pageSheet ? dialog.maxWidth : double.infinity,
            onClose: dialog.pageSheet ? dialog.onClose : null,
            closeLabel: dialog.closeLabel,
            expandBody: true,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: dialog.child,
            ),
          ),
        ),
      ),
    ),
  );
}
