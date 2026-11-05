import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'k_icon.dart';

enum KDisclosurePresentation { normal, compact }

class KDisclosure extends StatefulWidget {
  const KDisclosure({
    required this.title,
    required this.child,
    this.titleWidget,
    this.titleLineHeight,
    this.leadingIcon,
    this.titleIcon,
    this.actions,
    this.open,
    this.defaultOpen = false,
    this.scrollOnOpen = false,
    this.onOpenChange,
    this.disabled = false,
    this.presentation = KDisclosurePresentation.normal,
    this.showContentBorder = true,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? titleWidget;

  /// Logical first-line height for a custom title whose style is not readable.
  final double? titleLineHeight;
  final Widget? leadingIcon;
  final Widget? titleIcon;
  final Widget? actions;
  final bool? open;
  final bool defaultOpen;
  final bool scrollOnOpen;
  final ValueChanged<bool>? onOpenChange;
  final bool disabled;
  final KDisclosurePresentation presentation;

  /// Suppress content separators in a borderless workflow composition.
  final bool showContentBorder;

  @override
  State<KDisclosure> createState() => _KDisclosureState();
}

class _KDisclosureState extends State<KDisclosure> {
  late bool _open = widget.defaultOpen;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final expanded = widget.open ?? _open;
    final radius = BorderRadius.circular(t.radiusControl);
    final compact = widget.presentation == KDisclosurePresentation.compact;
    final customTitle = widget.titleWidget;
    final titleStyle = customTitle is Text
        ? DefaultTextStyle.of(context).style.merge(customTitle.style)
        : TextStyle(
            fontSize: t.fontBodySize,
            height: t.fontBodyLineHeight / t.fontBodySize,
          );
    final firstLineHeight = MediaQuery.textScalerOf(context).scale(
      widget.titleLineHeight ??
          (titleStyle.fontSize ?? t.fontBodySize) *
              (titleStyle.height ?? t.fontBodyLineHeight / t.fontBodySize),
    );
    Widget firstLineIcon(Widget icon) => SizedBox(
      height: firstLineHeight,
      child: Center(child: icon),
    );
    void toggle() {
      final next = !expanded;
      if (widget.open == null) setState(() => _open = next);
      widget.onOpenChange?.call(next);
      if (next && widget.scrollOnOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Scrollable.ensureVisible(
            context,
            alignment: 0,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : t.motion(KMotionRole.control).settle,
            curve: t.motion(KMotionRole.control).curve,
          );
        });
      }
    }

    // Container includes the normal disclosure border in layout, as Web does.
    // Compact presentation has no border and keeps its existing geometry.
    return Container(
      decoration: BoxDecoration(
        color: compact ? Colors.transparent : t.colorSurfaceCanvas,
        border: compact
            ? null
            : Border.all(
                color: t.colorBorderDefault,
                width: t.borderWidthDefault,
              ),
        borderRadius: compact ? null : radius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  expanded: expanded,
                  enabled: !widget.disabled,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: t.sizeHitTarget),
                    child: InkWell(
                      borderRadius: radius,
                      excludeFromSemantics: true,
                      onTap: widget.disabled ? null : toggle,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 0 : t.spaceControlInsetInline,
                          vertical: t.spaceControlGap,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          heightFactor: 1,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              firstLineIcon(
                                KIcon(
                                  expanded
                                      ? KIconName.chevronDown
                                      : KIconName.chevronRight,
                                  size: 20,
                                ),
                              ),
                              if (widget.leadingIcon != null) ...[
                                SizedBox(width: t.spaceControlGap),
                                firstLineIcon(widget.leadingIcon!),
                              ],
                              SizedBox(width: t.spaceControlGap),
                              Flexible(
                                child:
                                    widget.titleWidget ??
                                    Text(
                                      widget.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: compact
                                            ? t.colorTextMuted
                                            : t.colorTextPrimary,
                                        fontFamily: t.fontFamily,
                                        fontSize: t.fontBodySize,
                                        fontWeight: compact
                                            ? t.fontBodyWeight
                                            : t.fontLabelWeight,
                                        fontVariations: [
                                          FontVariation.weight(
                                            (compact
                                                    ? t.fontBodyWeight
                                                    : t.fontLabelWeight)
                                                .value
                                                .toDouble(),
                                          ),
                                          FontVariation.opticalSize(
                                            MediaQuery.textScalerOf(context)
                                                .scale(t.fontBodySize)
                                                .clamp(14, 32),
                                          ),
                                        ],
                                        height:
                                            t.fontBodyLineHeight /
                                            t.fontBodySize,
                                        letterSpacing: t.fontBodyLetterSpacing,
                                      ),
                                    ),
                              ),
                              if (widget.titleIcon != null) ...[
                                SizedBox(width: t.spaceControlGap),
                                firstLineIcon(widget.titleIcon!),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.actions != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: compact ? 0 : t.spaceControlInsetInline,
                  ),
                  child: widget.actions!,
                ),
            ],
          ),
          Visibility(
            visible: expanded,
            maintainState: true,
            child: Container(
              margin: compact
                  ? EdgeInsetsDirectional.only(start: t.spaceControlInsetInline)
                  : null,
              decoration: BoxDecoration(
                border: !widget.showContentBorder
                    ? null
                    : compact
                    ? BorderDirectional(
                        start: BorderSide(
                          color: t.colorBorderDefault,
                          width: t.borderWidthDefault,
                        ),
                      )
                    : Border(
                        top: BorderSide(
                          color: t.colorBorderDefault,
                          width: t.borderWidthDefault,
                        ),
                      ),
              ),
              child: Padding(
                padding: EdgeInsets.all(t.spaceControlInsetInline),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KAccordionItem {
  const KAccordionItem({
    required this.id,
    required this.title,
    required this.child,
    this.leadingIcon,
    this.titleIcon,
    this.actions,
    this.disabled = false,
  });

  final String id;
  final String title;
  final Widget child;
  final Widget? leadingIcon;
  final Widget? titleIcon;
  final Widget? actions;
  final bool disabled;
}

class KAccordion extends StatefulWidget {
  const KAccordion({
    required this.items,
    this.multiple = false,
    this.value,
    this.defaultValue = const [],
    this.onValueChange,
    super.key,
  });

  final List<KAccordionItem> items;
  final bool multiple;
  final List<String>? value;
  final List<String> defaultValue;
  final ValueChanged<List<String>>? onValueChange;

  @override
  State<KAccordion> createState() => _KAccordionState();
}

class _KAccordionState extends State<KAccordion> {
  late List<String> _value = List.of(widget.defaultValue);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final expanded = widget.value ?? _value;
    void update(String id, bool open) {
      final next = open
          ? widget.multiple
                ? [...expanded.where((item) => item != id), id]
                : [id]
          : expanded.where((item) => item != id).toList();
      if (widget.value == null) setState(() => _value = next);
      widget.onValueChange?.call(next);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.items.length; i++) ...[
          if (i > 0) SizedBox(height: t.spaceControlGap),
          KDisclosure(
            key: ValueKey(widget.items[i].id),
            title: widget.items[i].title,
            leadingIcon: widget.items[i].leadingIcon,
            titleIcon: widget.items[i].titleIcon,
            actions: widget.items[i].actions,
            disabled: widget.items[i].disabled,
            open: expanded.contains(widget.items[i].id),
            onOpenChange: (open) => update(widget.items[i].id, open),
            child: widget.items[i].child,
          ),
        ],
      ],
    );
  }
}
