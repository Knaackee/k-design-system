import 'package:flutter/material.dart';

void ensureKMapDayItemVisible({
  required State state,
  required GlobalKey itemKey,
  required Duration duration,
}) => WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!state.mounted) return;
  final itemContext = itemKey.currentContext;
  if (itemContext == null) return;
  Scrollable.ensureVisible(
    itemContext,
    duration: MediaQuery.disableAnimationsOf(state.context)
        ? Duration.zero
        : duration,
    alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
  );
});
