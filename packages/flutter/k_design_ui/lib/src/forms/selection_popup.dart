import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../primitives/k_icon.dart';
import 'form_style.dart';
import 'k_select.dart';
import 'option_media.dart';

class KSelectionPopup extends StatelessWidget {
  const KSelectionPopup({
    required this.options,
    required this.active,
    required this.value,
    required this.maxHeight,
    required this.onActive,
    required this.onSelected,
    required this.optionKeys,
    super.key,
  });
  final List<KSelectOption> options;
  final int active;
  final String? value;
  final double maxHeight;
  final ValueChanged<int> onActive;
  final ValueChanged<KSelectOption> onSelected;
  final Map<String, GlobalKey> optionKeys;
  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    final target = math.max(t.sizeControl, t.sizeHitTarget);
    return TextFieldTapRegion(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          padding: EdgeInsets.all(t.spaceControlGap),
          decoration: BoxDecoration(
            color: t.colorSurfaceRaised,
            border: Border.all(color: t.colorBorderDefault),
            borderRadius: BorderRadius.circular(t.radiusOverlay),
            boxShadow: t.elevationOverlay,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (options.isEmpty)
                  Container(
                    constraints: BoxConstraints(minHeight: target),
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(
                      horizontal: t.spaceControlInsetInline,
                      vertical: t.spaceControlGap,
                    ),
                    child: Text(
                      'No results',
                      style: formTextStyle(context, color: t.colorTextMuted),
                    ),
                  ),
                for (var i = 0; i < options.length; i++)
                  Semantics(
                    key: optionKeys.putIfAbsent(
                      options[i].value,
                      GlobalKey.new,
                    ),
                    selected: options[i].value == value,
                    enabled: !options[i].disabled,
                    onTap: options[i].disabled
                        ? null
                        : () => onSelected(options[i]),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: options[i].disabled
                          ? null
                          : () => onSelected(options[i]),
                      child: MouseRegion(
                        onEnter: options[i].disabled
                            ? null
                            : (_) => onActive(i),
                        child: Opacity(
                          opacity: options[i].disabled ? .48 : 1,
                          child: Container(
                            constraints: BoxConstraints(minHeight: target),
                            padding: EdgeInsets.symmetric(
                              horizontal: t.spaceControlInsetInline,
                              vertical: t.spaceControlGap,
                            ),
                            decoration: BoxDecoration(
                              color: i == active
                                  ? t.colorActionGhostHover
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                t.radiusControl,
                              ),
                            ),
                            foregroundDecoration: i == active
                                ? BoxDecoration(
                                    border: Border.all(
                                      color: t.colorBorderFocus,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      t.radiusControl,
                                    ),
                                  )
                                : null,
                            child: Row(
                              children: [
                                if (options[i].hasMedia) ...[
                                  KOptionMedia(options[i]),
                                  SizedBox(width: t.spaceControlGap),
                                ],
                                Expanded(
                                  child: Text(
                                    options[i].label,
                                    style: formTextStyle(context),
                                  ),
                                ),
                                if (options[i].value == value) ...[
                                  SizedBox(width: t.spaceControlGap),
                                  const KIcon(KIconName.check),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
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
