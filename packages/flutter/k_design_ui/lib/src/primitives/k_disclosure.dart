import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'k_icon.dart';

class KDisclosure extends StatefulWidget {
  const KDisclosure({
    required this.title,
    required this.child,
    this.leadingIcon,
    this.titleIcon,
    this.actions,
    this.open,
    this.defaultOpen = false,
    this.onOpenChange,
    this.disabled = false,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? leadingIcon;
  final Widget? titleIcon;
  final Widget? actions;
  final bool? open;
  final bool defaultOpen;
  final ValueChanged<bool>? onOpenChange;
  final bool disabled;

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
    void toggle() {
      final next = !expanded;
      if (widget.open == null) setState(() => _open = next);
      widget.onOpenChange?.call(next);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.colorSurfaceCanvas,
        border: Border.all(
          color: t.colorBorderDefault,
          width: t.borderWidthDefault,
        ),
        borderRadius: radius,
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
                          horizontal: t.spaceControlInsetInline,
                          vertical: t.spaceControlGap,
                        ),
                        child: Row(
                          children: [
                            KIcon(
                              expanded
                                  ? KIconName.chevronDown
                                  : KIconName.chevronRight,
                              size: 18,
                            ),
                            if (widget.leadingIcon != null) ...[
                              SizedBox(width: t.spaceControlGap),
                              widget.leadingIcon!,
                            ],
                            SizedBox(width: t.spaceControlGap),
                            Flexible(
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: t.colorTextPrimary,
                                  fontFamily: t.fontFamily,
                                  fontSize: t.fontBodySize,
                                  fontWeight: t.fontLabelWeight,
                                  fontVariations: [
                                    FontVariation.weight(
                                      t.fontLabelWeight.value.toDouble(),
                                    ),
                                    FontVariation.opticalSize(
                                      MediaQuery.textScalerOf(
                                        context,
                                      ).scale(t.fontBodySize).clamp(14, 32),
                                    ),
                                  ],
                                  height: t.fontBodyLineHeight / t.fontBodySize,
                                  letterSpacing: t.fontBodyLetterSpacing,
                                ),
                              ),
                            ),
                            if (widget.titleIcon != null) ...[
                              SizedBox(width: t.spaceControlGap),
                              widget.titleIcon!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.actions != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: t.spaceControlInsetInline,
                  ),
                  child: widget.actions!,
                ),
            ],
          ),
          Visibility(
            visible: expanded,
            maintainState: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
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
