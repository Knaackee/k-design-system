part of 'k_map_day_panel.dart';

mixin _KMapDayEntries on State<KMapDayPanel> {
  final _itemKeys = <String, GlobalKey>{};
  Widget _entry(KDesignTokens tokens, KMapDayItem item, bool last) {
    final selected = widget.selectedItemId == item.id;
    final active =
        widget.showCurrentTime &&
        widget.currentTime >= item.start &&
        widget.currentTime < item.end;
    final past = item.end <= widget.currentTime && !active;
    final forecast =
        widget.showForecasts &&
        item.expectedStart != null &&
        item.expectedStart != item.start;
    final textColor = past ? tokens.colorTextMuted : tokens.colorTextPrimary;
    return Semantics(
      key: _itemKeys.putIfAbsent(item.id, GlobalKey.new),
      label: active ? '${item.title}, ${widget.labels.now}' : item.title,
      child: Stack(
        children: [
          if (!last)
            PositionedDirectional(
              top: tokens.spaceControlInsetInline + tokens.sizeAvatarSmall,
              bottom: 0,
              start:
                  (tokens.sizeControl -
                      (item.kind == KMapDayItemKind.travel
                          ? tokens.borderWidthDefault
                          : tokens.borderWidthStrong)) /
                  2,
              child: Container(
                width: item.kind == KMapDayItemKind.travel
                    ? tokens.borderWidthDefault
                    : tokens.borderWidthStrong,
                color: tokens.colorBorderDefault,
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: tokens.sizeControl),
              SizedBox(width: tokens.spaceControlGap),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: tokens.spaceControlGap),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        button: true,
                        selected: selected,
                        child: InkWell(
                          key: ValueKey('k-map-day-item-${item.id}'),
                          onTap: () => widget.onSelect(item.id),
                          borderRadius: BorderRadius.circular(
                            tokens.radiusCard,
                          ),
                          child: Container(
                            key: ValueKey('k-map-day-item-card-${item.id}'),
                            padding: EdgeInsets.symmetric(
                              horizontal: tokens.spaceControlInsetInline,
                              vertical: tokens.spaceControlGap,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? tokens.colorStatusInfoBackground
                                  : item.kind == KMapDayItemKind.stop
                                  ? tokens.colorSurfaceSubtle
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                tokens.radiusCard,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Row(
                                      key: ValueKey(
                                        'k-map-day-item-header-${item.id}',
                                      ),
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: KText(
                                            item.title,
                                            variant: widget.sheet
                                                ? KTextVariant.bodySmall
                                                : KTextVariant.body,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: widget.sheet
                                                  ? FontWeight.w500
                                                  : item.kind ==
                                                        KMapDayItemKind.stop
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsetsDirectional.only(
                                            start: tokens.spaceControlGap,
                                          ),
                                          child: KText(
                                            widget.formatTime(item.start),
                                            variant: KTextVariant.caption,
                                            style: TextStyle(color: textColor),
                                          ),
                                        ),
                                        if (item.routeDescription
                                            case final description?)
                                          Padding(
                                            padding: EdgeInsetsDirectional.only(
                                              start: tokens.spaceTight,
                                            ),
                                            child: KPopover(
                                              label:
                                                  'Routeninformationen anzeigen',
                                              belowAnchor: true,
                                              content: Padding(
                                                padding: EdgeInsets.all(
                                                  tokens.spaceCardPadding,
                                                ),
                                                child: KText(
                                                  description,
                                                  variant:
                                                      KTextVariant.bodySmall,
                                                ),
                                              ),
                                              trigger: SizedBox.square(
                                                key: ValueKey(
                                                  'k-map-day-route-info-${item.id}',
                                                ),
                                                dimension: KDesignTokenVariants
                                                    .inputModeTouchSizeHitTarget,
                                                child: Center(
                                                  child: KIcon(
                                                    KIconName.info,
                                                    size: tokens
                                                        .componentContextMenuIconSize,
                                                    color:
                                                        tokens.colorTextMuted,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    PositionedDirectional(
                                      start:
                                          -tokens.sizeControl -
                                          tokens.spaceControlGap -
                                          tokens.spaceControlInsetInline,
                                      top: 0,
                                      bottom: 0,
                                      width: tokens.sizeControl,
                                      child: Center(
                                        child: Container(
                                          key: ValueKey(
                                            'k-map-day-item-icon-${item.id}',
                                          ),
                                          width: tokens.sizeAvatarSmall,
                                          height: tokens.sizeAvatarSmall,
                                          decoration: BoxDecoration(
                                            color: selected || active
                                                ? tokens.colorStatusInfoAccent
                                                : tokens.colorSurfaceSubtle,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: KIcon(
                                            item.icon,
                                            size: tokens.sizeContent,
                                            color: selected || active
                                                ? tokens.colorSurfaceRaised
                                                : textColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: tokens.spaceTight),
                                KText(
                                  item.detail,
                                  variant: widget.sheet
                                      ? KTextVariant.caption
                                      : KTextVariant.bodySmall,
                                  maxLines: item.routeDescription == null
                                      ? null
                                      : 2,
                                  overflow: item.routeDescription == null
                                      ? null
                                      : TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: tokens.colorTextMuted,
                                  ),
                                ),
                                if (forecast) ...[
                                  SizedBox(height: tokens.spaceSmallInset),
                                  widget.forecastBuilder?.call(context, item) ??
                                      buildKMapDayForecast(
                                        tokens: tokens,
                                        item: item,
                                        labels: widget.labels,
                                        formatTime: widget.formatTime,
                                      ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (widget.itemDetailsBuilder case final builder?)
                        builder(context, item),
                      if (item.actions.isNotEmpty)
                        Wrap(
                          spacing: tokens.spaceControlGap,
                          runSpacing: tokens.spaceControlGap,
                          children: [
                            for (final action in item.actions)
                              KButton(
                                label: action.label,
                                leading: action.icon == null
                                    ? null
                                    : KIcon(action.icon!),
                                variant: KButtonVariant.ghost,
                                onPressed: () => widget.onAction?.call(
                                  KMapDayActionEvent(
                                    itemId: item.id,
                                    actionId: action.id,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      if (active)
                        buildKMapDayNowLine(
                          tokens: tokens,
                          currentTime: widget.currentTime,
                          labels: widget.labels,
                          formatTime: widget.formatTime,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
