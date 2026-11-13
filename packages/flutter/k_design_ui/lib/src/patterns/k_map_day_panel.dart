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

part 'k_map_day_panel_entry.dart';

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
    this.panelHeaderBuilder,
    this.panelBodyBuilder,
    this.layout = KMapDayPanelLayout.floating,
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
  final KMapDayPanelHeaderBuilder? panelHeaderBuilder;
  final KMapDayPanelBodyBuilder? panelBodyBuilder;
  final KMapDayPanelLayout layout;
  final ValueChanged<String> onSelect;
  final ValueChanged<KMapDayActionEvent>? onAction;
  final ValueChanged<KMapDayPanelState> onStateChanged;
  final KMapDaySheetController? sheetController;
  final ValueChanged<double>? onSheetFractionChanged;

  @override
  State<KMapDayPanel> createState() => _KMapDayPanelState();
}

class _KMapDayPanelState extends State<KMapDayPanel> with _KMapDayEntries {
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

  KMapDayPanelContext _panelContext(KMapDayPanelState? actualState) =>
      KMapDayPanelContext(
        isSheet: widget.sheet,
        expanded: (actualState ?? widget.state) == KMapDayPanelState.expanded,
        toggleExpanded: () => widget.onStateChanged(
          (actualState ?? widget.state) == KMapDayPanelState.expanded
              ? KMapDayPanelState.medium
              : KMapDayPanelState.expanded,
        ),
        selectedItemId: widget.selectedItemId,
        onItemTap: widget.onSelect,
      );

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final docked = widget.layout == KMapDayPanelLayout.docked;
    final radius = widget.sheet
        ? BorderRadius.vertical(
            top: Radius.circular(
              widget.panelBodyBuilder != null
                  ? tokens.radiusSheet
                  : tokens.radiusCard * 3,
            ),
          )
        : BorderRadius.circular(docked ? 0 : tokens.radiusCard);
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
            borderRadius: radius,
            border: docked
                ? Border.all(
                    color: tokens.colorBorderDefault,
                    width: tokens.spaceHairline,
                  )
                : null,
            boxShadow: docked ? null : tokens.elevationMedium,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: ClipRRect(
              borderRadius: radius,
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
                  if (widget.panelHeaderBuilder != null) ...[
                    if (widget.panelHeaderBuilder!(
                          context,
                          _panelContext(actualState),
                        )
                        case final header?)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spaceContentActionGap,
                          vertical: tokens.spaceControlGap,
                        ),
                        child: header,
                      ),
                  ] else
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
                  if (!compact || widget.panelBodyBuilder != null)
                    Expanded(child: _body(tokens, actualState)),
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
        top: docked ? 0 : tokens.spaceLayoutGutter,
        end: docked ? 0 : tokens.spaceLayoutGutter,
        bottom: docked ? 0 : tokens.spaceLayoutGutter,
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

  Widget _body(
    KDesignTokens tokens,
    KMapDayPanelState? actualState,
  ) => SingleChildScrollView(
    key: const ValueKey('k-map-day-timeline'),
    padding: widget.panelBodyBuilder != null
        ? EdgeInsets.fromLTRB(
            tokens.spaceContentActionGap,
            widget.sheet ? 0 : tokens.spaceContentActionGap,
            tokens.spaceContentActionGap,
            widget.sheet
                ? tokens.sizeAppBarFloating + tokens.spaceLayoutSectionGap
                : tokens.componentSettingsDialogContentPadding,
          )
        : EdgeInsets.fromLTRB(
            tokens.spaceLayoutGutter,
            0,
            tokens.spaceLayoutGutter,
            tokens.spaceLayoutGutter,
          ),
    child:
        widget.panelBodyBuilder?.call(context, _panelContext(actualState)) ??
        Column(
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
              _entry(
                tokens,
                widget.items[index],
                index == widget.items.length - 1,
              ),
          ],
        ),
  );
}
