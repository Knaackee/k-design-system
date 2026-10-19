import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'form_style.dart';

@immutable
class KRadioOption<T> {
  const KRadioOption({
    required this.value,
    required this.label,
    this.disabled = false,
  });
  final T value;
  final String label;
  final bool disabled;
}

/// Controlled single selection with native radio keyboard and accessibility behavior.
class KRadioGroup<T> extends StatelessWidget {
  const KRadioGroup({
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.horizontal = false,
    super.key,
  });
  final String label;
  final List<KRadioOption<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.isNotEmpty) ...[
            Text(label, style: formTextStyle(context)),
            SizedBox(height: t.spaceControlGap),
          ],
          RadioGroup<T>(
            groupValue: value,
            onChanged: (next) => onChanged?.call(next),
            child: Builder(
              builder: (context) {
                final options = items
                    .map(
                      (item) => _RadioOption<T>(
                        key: ValueKey(item.value),
                        item: item,
                        enabled: onChanged != null && !item.disabled,
                      ),
                    )
                    .toList();
                return horizontal
                    ? Wrap(
                        spacing: t.spaceControlGap,
                        runSpacing: t.spaceTight,
                        children: options,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < options.length; i++) ...[
                            if (i > 0) SizedBox(height: t.spaceTight),
                            options[i],
                          ],
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioOption<T> extends StatefulWidget {
  const _RadioOption({required this.item, required this.enabled, super.key});
  final KRadioOption<T> item;
  final bool enabled;
  @override
  State<_RadioOption<T>> createState() => _RadioOptionState<T>();
}

class _RadioOptionState<T> extends State<_RadioOption<T>> {
  final _focusNode = FocusNode();
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    return RawRadio<T>(
      value: widget.item.value,
      enabled: widget.enabled,
      groupRegistry: RadioGroup.maybeOf<T>(context),
      focusNode: _focusNode,
      autofocus: false,
      toggleable: false,
      mouseCursor: WidgetStatePropertyAll(
        widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      ),
      builder: (context, state) {
        final selected = state.states.contains(WidgetState.selected);
        final focused = state.states.contains(WidgetState.focused);
        return Opacity(
          opacity: widget.enabled ? 1 : t.opacityDisabled,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(t.sizeControl, t.sizeHitTarget),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: t.componentRadioSize,
                  height: t.componentRadioSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? t.componentSelectionSelectedBackground
                        : t.componentSelectionBackground,
                    border: Border.all(
                      width: t.borderWidthDefault,
                      color: selected
                          ? t.componentSelectionSelectedBorder
                          : t.componentSelectionBorder,
                    ),
                    boxShadow: focused
                        ? [
                            BoxShadow(
                              color: t.componentSelectionFocusRing,
                              spreadRadius: t.borderWidthStrong,
                            ),
                          ]
                        : null,
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: t.componentRadioDotSize,
                            height: t.componentRadioDotSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: t.componentSelectionSelectedForeground,
                            ),
                          ),
                        )
                      : null,
                ),
                SizedBox(width: t.spaceControlGap),
                Flexible(
                  child: Text(
                    widget.item.label,
                    style: formTextStyle(
                      context,
                      color: t.componentSelectionForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
