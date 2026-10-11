import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'k_overlays.dart';

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
  }) {
    assert(builder != null || title != null && child != null);
    final contentBuilder =
        builder ??
        (BuildContext routeContext) => KAdaptiveDialog(
          title: title!,
          description: description,
          actions: actions,
          maxWidth: maxWidth,
          onClose: () => Navigator.of(routeContext).pop(),
          child: child!,
        );
    if (MediaQuery.sizeOf(context).width < breakpoint) {
      return showModalBottomSheet<T>(
        context: context,
        useRootNavigator: useRootNavigator,
        useSafeArea: true,
        isScrollControlled: true,
        isDismissible: barrierDismissible,
        // The coordinated sheet below owns dragging and guarded dismissal.
        enableDrag: false,
        backgroundColor: Colors.transparent,
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
    if (MediaQuery.sizeOf(context).width < breakpoint) {
      if (!expandBody) {
        return KBottomSheet(
          title: title,
          description: description,
          actions: actions,
          maxWidth: double.infinity,
          onDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 300) {
              if (onClose != null) {
                onClose!();
              } else {
                Navigator.of(context).maybePop();
              }
            }
          },
          child: child,
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

class _DraggableDialog extends StatefulWidget {
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

  @override
  State<_DraggableDialog> createState() => _DraggableDialogState();
}

class _DraggableDialogState extends State<_DraggableDialog> {
  final _controller = DraggableScrollableController();
  bool _closing = false;

  void _close() {
    if (_closing) return;
    _closing = true;
    if (widget.dialog.onClose != null) {
      widget.dialog.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
    // A consumer may keep the route open to confirm unsaved changes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.isAttached) _controller.jumpTo(.9);
      _closing = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            if (notification.extent <= notification.minExtent + .001) _close();
            return true;
          },
          child: DraggableScrollableSheet(
            controller: _controller,
            initialChildSize: .9,
            minChildSize: .35,
            maxChildSize: .9,
            expand: false,
            shouldCloseOnMinExtent: false,
            builder: (context, scrollController) => KBottomSheet(
              title: widget.dialog.title,
              description: widget.description,
              actions: widget.actions,
              maxWidth: double.infinity,
              expandBody: true,
              onDragUpdate: (details) {
                _controller.jumpTo(
                  (_controller.size - details.delta.dy / constraints.maxHeight)
                      .clamp(.35, .9),
                );
              },
              onDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dy > 700 ||
                    _controller.size <= .36) {
                  _close();
                }
              },
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: widget.padding),
                child: widget.dialog.child,
              ),
            ),
          ),
        ),
  );
}
