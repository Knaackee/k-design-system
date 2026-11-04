import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_text.dart';
import '../overlays/k_popover.dart';
import 'k_map_day_annotations.dart';
import 'k_map_day_footer.dart';
import 'k_map_day_header.dart';
import 'k_map_day_selected_visibility.dart';
import 'k_map_day_sheet_controller.dart';
import 'k_map_day_sheet_handle.dart';
import 'k_map_day_sheet_motion.dart';
import 'k_map_day_types.dart';

class KMapDayPanel extends StatefulWidget {
  const KMapDayPanel({
    required this.items,
    required this.currentTime,
    required this.title,
    required this.dayLabel,
    required this.selectedItemId,
    required this.state,
    required this.heights,
    required this.width,
    required this.sheet,
    required this.showCurrentTime,
    required this.showForecasts,
    required this.formatTime,
    required this.labels,
    required this.onSelect,
    required this.onStateChanged,
    this.summary,
    this.description,
    this.footer,
    this.forecastBuilder,
    this.itemDetailsBuilder,
    this.onAction,
    this.sheetController,
    this.onSheetFractionChanged,
    super.key,
  });

  final List<KMapDayItem> items;
  final int currentTime;
  final String title;
  final String dayLabel;
  final String? selectedItemId;
  final KMapDayPanelState state;
  final KMapDayPanelHeights heights;
  final double width;
  final bool sheet;
  final bool showCurrentTime;
  final bool showForecasts;
  final KMapDayTimeFormatter formatTime;
  final KMapDayLabels labels;
  final Widget? summary;
  final Widget? description;
  final Widget? footer;
  final KMapDayItemBuilder? forecastBuilder;
  final KMapDayItemBuilder? itemDetailsBuilder;
  final ValueChanged<String> onSelect;
  final ValueChanged<KMapDayActionEvent>? onAction;
  final ValueChanged<KMapDayPanelState> onStateChanged;
  final KMapDaySheetController? sheetController;
  final ValueChanged<double>? onSheetFractionChanged;

  @override
  State<KMapDayPanel> createState() => _KMapDayPanelState();
}

class _KMapDayPanelState extends State<KMapDayPanel> {
  final _itemKeys = <String, GlobalKey>{};
  double? _lastSheetFraction;

  @override
  void initState() {
    super.initState();
    widget.sheetController?.addListener(_onSheetPosition);
  }

  @override
  void didUpdateWidget(covariant KMapDayPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.sheetController, widget.sheetController)) {
      oldWidget.sheetController?.removeListener(_onSheetPosition);
      widget.sheetController?.addListener(_onSheetPosition);
      _lastSheetFraction = null;
    }
    if (oldWidget.selectedItemId != widget.selectedItemId) _ensureSelected();
  }

  @override
  void dispose() {
    widget.sheetController?.removeListener(_onSheetPosition);
    super.dispose();
  }

  void _onSheetPosition() {
    final fraction = widget.sheetController?.fraction;
    if (fraction != null &&
        _lastSheetFraction != null &&
        fraction < _lastSheetFraction!) {
      _ensureSelected();
    }
    _lastSheetFraction = fraction;
  }

  void _ensureSelected() {
    final itemKey = _itemKeys[widget.selectedItemId];
    if (itemKey == null) return;
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    ensureKMapDayItemVisible(
      state: this,
      itemKey: itemKey,
      duration: tokens.motionStandard,
    );
  }

  void _step(int delta) => widget.onStateChanged(widget.state.step(delta));

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    Widget panel({
      required bool compact,
      KMapDayPanelState? actualState,
      ValueChanged<double>? onDragUpdate,
      VoidCallback? onDragEnd,
    }) => PointerInterceptor(
      child: Semantics(
        label: widget.labels.panel,
        container: true,
        child: DecoratedBox(
          key: const ValueKey('k-map-day-panel'),
          decoration: BoxDecoration(
            color: tokens.colorSurfaceRaised,
            borderRadius: widget.sheet
                ? BorderRadius.vertical(
                    top: Radius.circular(tokens.radiusCard * 3),
                  )
                : BorderRadius.circular(tokens.radiusCard),
            boxShadow: tokens.elevationMedium,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: ClipRRect(
              borderRadius: widget.sheet
                  ? BorderRadius.vertical(
                      top: Radius.circular(tokens.radiusCard * 3),
                    )
                  : BorderRadius.circular(tokens.radiusCard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.sheet)
                    KMapDaySheetHandle(
                      state: actualState ?? widget.state,
                      labels: widget.labels,
                      onStateChanged: widget.onStateChanged,
                      onDragUpdate: onDragUpdate!,
                      onDragEnd: onDragEnd!,
                    ),
                  buildKMapDayHeader(
                    tokens: tokens,
                    items: widget.items,
                    currentTime: widget.currentTime,
                    dayLabel: widget.dayLabel,
                    title: widget.title,
                    sheet: widget.sheet,
                    state: widget.state,
                    labels: widget.labels,
                    formatTime: widget.formatTime,
                    showCurrentTime: widget.showCurrentTime,
                    onStep: _step,
                    summary: widget.summary,
                  ),
                  if (!compact) Expanded(child: _body(tokens)),
                  if (widget.footer != null && !compact)
                    buildKMapDayFooter(tokens, widget.footer!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!widget.sheet) {
      return PositionedDirectional(
        top: tokens.spaceLayoutGutter,
        end: tokens.spaceLayoutGutter,
        bottom: tokens.spaceLayoutGutter,
        width: widget.width,
        child: panel(compact: false),
      );
    }
    return KMapDaySheetMotion(
      state: widget.state,
      heights: widget.heights,
      controller: widget.sheetController,
      onFractionChanged: widget.onSheetFractionChanged,
      onStateChanged: widget.onStateChanged,
      builder: (context, fraction, actualState, onDragUpdate, onDragEnd) =>
          panel(
            compact: actualState == KMapDayPanelState.compact,
            actualState: actualState,
            onDragUpdate: onDragUpdate,
            onDragEnd: onDragEnd,
          ),
    );
  }

  Widget _body(KDesignTokens tokens) => SingleChildScrollView(
    key: const ValueKey('k-map-day-timeline'),
    padding: EdgeInsets.fromLTRB(
      tokens.spaceLayoutGutter,
      0,
      tokens.spaceLayoutGutter,
      tokens.spaceLayoutGutter,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.description != null) ...[
          DefaultTextStyle.merge(
            style: TextStyle(
              color: tokens.colorTextMuted,
              fontFamily: tokens.fontFamily,
              fontSize: tokens.fontCaptionSize,
              height: tokens.fontCaptionLineHeight / tokens.fontCaptionSize,
            ),
            child: widget.description!,
          ),
          SizedBox(height: tokens.spaceContentActionGap),
        ],
        for (var index = 0; index < widget.items.length; index++)
          _entry(tokens, widget.items[index], index == widget.items.length - 1),
      ],
    ),
  );

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
