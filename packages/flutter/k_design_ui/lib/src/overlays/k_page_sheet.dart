import 'package:flutter/widgets.dart';

import 'k_adaptive_dialog.dart';

/// A tall, scroll-coordinated page sheet on phones and tablets.
///
/// This opt-in presentation leaves the normal adaptive-dialog default intact.
/// The body scrolls with the sheet; actions stay outside that scroll area.
/// Use [show] with a [KPageSheet] builder to keep route and surface consistent.
class KPageSheet extends KAdaptiveDialog {
  const KPageSheet({
    required super.title,
    required super.child,
    super.description,
    super.actions,
    super.onClose,
    super.closeLabel,
    super.maxWidth = 640,
    super.key,
  }) : super(pageSheet: true);

  static Future<T?> show<T>({
    required BuildContext context,
    WidgetBuilder? builder,
    Widget? title,
    Widget? child,
    Widget? description,
    Widget? actions,
    double maxWidth = 640,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
  }) => KAdaptiveDialog.show<T>(
    context: context,
    builder: builder,
    title: title,
    child: child,
    description: description,
    actions: actions,
    maxWidth: maxWidth,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    pageSheet: true,
  );
}
