part of 'k_command_palette.dart';

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.closeLabel,
    required this.onClose,
  });
  final String title;
  final String closeLabel;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: t.spaceControlInsetInline,
        end: t.spaceTight,
        top: t.spaceControlGap,
        bottom: t.spaceControlGap,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: t.colorTextPrimary,
                fontFamily: t.fontFamily,
                fontSize: t.fontHeading5Size,
                fontWeight: t.fontHeadingWeight,
              ),
            ),
          ),
          KIconButton(label: closeLabel, icon: KIconName.x, onPressed: onClose),
        ],
      ),
    );
  }
}

class _Search extends StatelessWidget {
  const _Search({
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.backLabel,
    required this.showBack,
    required this.loading,
    required this.onBack,
    required this.onChanged,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final String backLabel;
  final bool showBack;
  final bool loading;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: t.colorBorderDefault,
            width: t.borderWidthDefault,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showBack)
            KIconButton(
              label: backLabel,
              icon: KIconName.arrowLeft,
              onPressed: onBack,
            ),
          Expanded(
            child: KSearchField(
              controller: controller,
              focusNode: focusNode,
              placeholder: placeholder,
              label: placeholder,
              onChanged: onChanged,
            ),
          ),
          if (loading)
            Padding(
              padding: EdgeInsets.all(t.spaceControlGap),
              child: SizedBox.square(
                dimension: t.sizeIndicatorMedium,
                child: CircularProgressIndicator(
                  strokeWidth: t.componentSpinnerStrokeWidth,
                  color: t.colorTextMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: t.spaceControlInsetInline,
        vertical: t.spaceControlGap,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: t.colorTextMuted,
          fontFamily: t.fontFamily,
          fontSize: t.fontCaptionSize,
          fontWeight: t.fontLabelWeight,
        ),
      ),
    );
  }
}

class _CommandRow extends StatelessWidget {
  const _CommandRow({
    required this.item,
    required this.active,
    required this.executing,
    required this.onHover,
    required this.onPressed,
    this.itemBuilder,
  });
  final KCommandPaletteItem item;
  final bool active;
  final bool executing;
  final VoidCallback onHover;
  final VoidCallback onPressed;
  final KCommandPaletteItemBuilder? itemBuilder;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      button: true,
      enabled: !item.disabled,
      selected: active,
      label: item.label,
      child: MouseRegion(
        onEnter: (_) => onHover(),
        child: Material(
          color: active ? t.colorActionSecondaryHover : Colors.transparent,
          borderRadius: BorderRadius.circular(t.radiusControl),
          child: InkWell(
            onTap: item.disabled ? null : onPressed,
            borderRadius: BorderRadius.circular(t.radiusControl),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(t.sizeControl, t.sizeHitTarget),
              ),
              child:
                  itemBuilder?.call(context, item, active) ??
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: t.spaceControlInsetInline,
                      vertical: t.spaceControlGap,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: t.sizeIconDefault,
                          child: item.icon == null
                              ? null
                              : KIcon(item.icon!, color: t.colorTextMuted),
                        ),
                        SizedBox(width: t.spaceControlGap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: item.disabled
                                    ? TextStyle(color: t.colorTextMuted)
                                    : null,
                              ),
                              if (item.description != null)
                                Text(
                                  item.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: t.colorTextMuted,
                                    fontSize: t.fontCaptionSize,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (executing)
                          SizedBox.square(
                            dimension: t.sizeIndicatorMedium,
                            child: CircularProgressIndicator(
                              strokeWidth: t.componentSpinnerStrokeWidth,
                            ),
                          )
                        else if (item.children.isNotEmpty)
                          const KIcon(KIconName.chevronRight)
                        else if (item.shortcut.isNotEmpty)
                          _Shortcut(keys: item.shortcut),
                      ],
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.keys});
  final List<String> keys;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: keys
          .map(
            (key) => Container(
              constraints: BoxConstraints(minWidth: t.componentKbdMinSize),
              margin: EdgeInsetsDirectional.only(start: t.spaceTight),
              padding: EdgeInsets.symmetric(
                horizontal: t.componentKbdPaddingInline,
              ),
              decoration: BoxDecoration(
                color: t.colorSurfaceSubtle,
                border: Border.all(color: t.colorBorderDefault),
                borderRadius: BorderRadius.circular(t.radiusExtraSmall),
              ),
              alignment: Alignment.center,
              child: Text(
                key,
                style: TextStyle(
                  color: t.colorTextMuted,
                  fontSize: t.fontCaptionSize,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StateLabel extends StatelessWidget {
  const _StateLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Center(
      child: Text(label, style: TextStyle(color: t.colorTextMuted)),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.navigate, required this.select});
  final String navigate;
  final String select;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: t.spaceControlInsetInline,
        vertical: t.spaceControlGap,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.colorBorderDefault)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _Shortcut(keys: const ['↑', '↓']),
          SizedBox(width: t.spaceControlGap),
          Text(
            navigate,
            style: TextStyle(
              color: t.colorTextMuted,
              fontSize: t.fontCaptionSize,
            ),
          ),
          SizedBox(width: t.spaceControlInsetInline),
          _Shortcut(keys: const ['↵']),
          SizedBox(width: t.spaceControlGap),
          Text(
            select,
            style: TextStyle(
              color: t.colorTextMuted,
              fontSize: t.fontCaptionSize,
            ),
          ),
        ],
      ),
    );
  }
}
