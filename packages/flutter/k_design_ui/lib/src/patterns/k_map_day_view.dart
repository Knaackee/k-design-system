import 'package:flutter/material.dart';

import 'k_map_day_panel.dart';
import 'k_map_day_sheet_controller.dart';
import 'k_map_day_types.dart';

export 'k_map_day_sheet_controller.dart' show KMapDaySheetController;
export 'k_map_day_types.dart';

/// Controlled or uncontrolled map + itinerary composition.
///
/// Routing, live location, camera movement and scrolling side effects remain
/// consumer owned through [mapBuilder] and the callbacks.
class KMapDayView extends StatefulWidget {
  const KMapDayView({
    required this.items,
    required this.currentTime,
    required this.title,
    required this.dayLabel,
    required this.mapBuilder,
    this.summary,
    this.description,
    this.footer,
    this.selectedItemId,
    this.selectionControlled = false,
    this.defaultSelectedItemId,
    this.panelState,
    this.defaultPanelState = KMapDayPanelState.medium,
    this.panelHeights = const KMapDayPanelHeights(),
    this.panelWidth = 404,
    this.presentation = KMapDayPresentation.auto,
    this.mobileBreakpoint = 700,
    this.showCurrentTime = true,
    this.showForecasts = true,
    this.formatTime,
    this.labels = const KMapDayLabels(),
    this.forecastBuilder,
    this.itemDetailsBuilder,
    this.onSelectionChanged,
    this.onItemTap,
    this.onMapItemTap,
    this.onAction,
    this.onPanelStateChanged,
    this.sheetController,
    this.onSheetFractionChanged,
    super.key,
  }) : assert(panelWidth >= 280 && panelWidth < double.infinity),
       assert(mobileBreakpoint > 0 && mobileBreakpoint < double.infinity),
       assert(currentTime >= 0 && currentTime <= 1440);

  final List<KMapDayItem> items;
  final int currentTime;
  final String title;
  final String dayLabel;
  final Widget? summary;
  final Widget? description;
  final Widget? footer;
  final KMapDayMapBuilder mapBuilder;
  final String? selectedItemId;

  /// Distinguishes a controlled `null` selection from uncontrolled state.
  final bool selectionControlled;
  final String? defaultSelectedItemId;
  final KMapDayPanelState? panelState;
  final KMapDayPanelState defaultPanelState;
  final KMapDayPanelHeights panelHeights;
  final double panelWidth;
  final KMapDayPresentation presentation;
  final double mobileBreakpoint;
  final bool showCurrentTime;
  final bool showForecasts;
  final KMapDayTimeFormatter? formatTime;
  final KMapDayLabels labels;
  final KMapDayItemBuilder? forecastBuilder;
  final KMapDayItemBuilder? itemDetailsBuilder;
  final ValueChanged<String>? onSelectionChanged;
  final ValueChanged<String>? onItemTap;
  final ValueChanged<String>? onMapItemTap;
  final ValueChanged<KMapDayActionEvent>? onAction;
  final ValueChanged<KMapDayPanelState>? onPanelStateChanged;
  final KMapDaySheetController? sheetController;
  final ValueChanged<double>? onSheetFractionChanged;

  @override
  State<KMapDayView> createState() => _KMapDayViewState();
}

class _KMapDayViewState extends State<KMapDayView> {
  late String? _selection = widget.defaultSelectedItemId;
  late KMapDayPanelState _panelState = widget.defaultPanelState;

  String? get _selected =>
      widget.selectionControlled ? widget.selectedItemId : _selection;
  KMapDayPanelState get _snap => widget.panelState ?? _panelState;

  void _select(String id, {required bool fromMap}) {
    if (!widget.items.any((item) => item.id == id)) return;
    final changed = _selected != id;
    if (!widget.selectionControlled) setState(() => _selection = id);
    if (changed) widget.onSelectionChanged?.call(id);
    if (fromMap) {
      widget.onMapItemTap?.call(id);
    } else {
      widget.onItemTap?.call(id);
    }
  }

  void _changePanel(KMapDayPanelState state) {
    if (state == _snap) return;
    if (widget.panelState == null) setState(() => _panelState = state);
    widget.onPanelStateChanged?.call(state);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final sheet = switch (widget.presentation) {
        KMapDayPresentation.sheet => true,
        KMapDayPresentation.sidebar => false,
        KMapDayPresentation.auto =>
          constraints.maxWidth <= widget.mobileBreakpoint,
      };
      final mapContext = KMapDayMapContext(
        selectedItemId: _selected,
        onItemTap: (id) => _select(id, fromMap: true),
      );
      return Stack(
        key: const ValueKey('k-map-day-view'),
        fit: StackFit.expand,
        children: [
          widget.mapBuilder(context, mapContext),
          KMapDayPanel(
            items: widget.items,
            currentTime: widget.currentTime,
            title: widget.title,
            dayLabel: widget.dayLabel,
            summary: widget.summary,
            description: widget.description,
            footer: widget.footer,
            selectedItemId: _selected,
            state: _snap,
            heights: widget.panelHeights,
            width: widget.panelWidth,
            sheet: sheet,
            showCurrentTime: widget.showCurrentTime,
            showForecasts: widget.showForecasts,
            formatTime: widget.formatTime ?? formatKMapDayTime,
            labels: widget.labels,
            forecastBuilder: widget.forecastBuilder,
            itemDetailsBuilder: widget.itemDetailsBuilder,
            onSelect: (id) => _select(id, fromMap: false),
            onAction: widget.onAction,
            onStateChanged: _changePanel,
            sheetController: widget.sheetController,
            onSheetFractionChanged: widget.onSheetFractionChanged,
          ),
        ],
      );
    },
  );
}

String formatKMapDayTime(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';
