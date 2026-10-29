import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../actions/k_icon_button.dart';
import '../forms/k_checkbox.dart';
import '../forms/k_input.dart';
import '../maps/k_map.dart';
import '../maps/k_map_controller.dart';
import '../maps/k_map_overlays.dart';
import '../maps/k_map_polygon.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_text.dart';
import 'k_map_zone_editor_labels.dart';
import 'k_map_zone_boolean.dart';
import 'k_map_zone_geometry.dart';
import 'k_map_zone_properties.dart';
import 'k_map_zone_feedback.dart';

export 'k_map_zone_editor_labels.dart';
export 'k_map_zone_boolean.dart' show createKMapCircleCoordinates;

// Each visible vertex also creates one midpoint handle, so keep the pair under
// roughly 200 controls even for very large imported rings.
const _maxVisibleZoneHandles = 100;
const _minimumHandleSpacing = 44.0;

String _zoneCreationIllustration(String kind) {
  final shape = switch (kind) {
    'circle' =>
      '<circle cx="48" cy="36" r="25"/><path d="M48 36H73" stroke-dasharray="3 3"/><circle cx="48" cy="36" r="3" fill-opacity="1"/>',
    'postal' =>
      '<path d="M15 12L42 9L53 29L34 45L12 36Z"/><path d="M53 29L80 18L85 49L61 61L34 45Z" fill-opacity=".32"/>',
    _ =>
      '<path d="M17 19L49 10L79 28L66 60L29 55L12 38Z"/>${[(17, 19), (49, 10), (79, 28), (66, 60), (29, 55), (12, 38)].map((p) => '<circle cx="${p.$1}" cy="${p.$2}" r="2.5" fill-opacity="1"/>').join()}',
  };
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 72"><path d="M0 16H96M0 48H96M24 0V72M67 0V72M0 70L96 4" fill="none" stroke="currentColor" opacity=".14" stroke-width="5"/><g fill="currentColor" fill-opacity=".16" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round">$shape</g></svg>';
}

String _postalAreaName(KMapPostalArea area) =>
    area.label.trim() == area.code ? area.code : '${area.code} ${area.label}';

List<int> _visibleRingIndices(
  List<KMapCenter> ring,
  KMapView? view,
  int budget,
  int? activeIndex,
) {
  if (budget <= 0) {
    return activeIndex != null && activeIndex >= 0 && activeIndex < ring.length
        ? [activeIndex]
        : const [];
  }
  final maxHandles = math.min(
    budget,
    (view?.zoom ?? 13) >= 14 ? _maxVisibleZoneHandles : 64,
  );
  if (ring.length <= maxHandles) {
    return [for (var index = 0; index < ring.length; index++) index];
  }
  final bounds = view?.bounds;
  final visible = [
    for (var index = 0; index < ring.length; index++)
      if (bounds == null ||
          (ring[index].longitude >= bounds.west &&
              ring[index].longitude <= bounds.east &&
              ring[index].latitude >= bounds.south &&
              ring[index].latitude <= bounds.north))
        index,
  ];
  final candidates = visible.isEmpty
      ? [for (var index = 0; index < ring.length; index++) index]
      : visible;
  final step = math.max(1, (candidates.length / maxHandles).ceil());
  final selected = [
    for (var index = 0; index < candidates.length; index += step)
      candidates[index],
  ];
  if (activeIndex != null &&
      activeIndex >= 0 &&
      activeIndex < ring.length &&
      !selected.contains(activeIndex)) {
    selected[selected.length - 1] = activeIndex;
  }
  return selected;
}

class _VisibleRingHandles {
  const _VisibleRingHandles({required this.vertices, required this.midpoints});

  final List<int> vertices;
  final List<int> midpoints;
}

_VisibleRingHandles _screenSpacedRingHandles(
  List<KMapCenter> ring,
  List<int> indices,
  KMapController controller,
  int? activeIndex,
  String? activeKind,
  List<Offset> occupied,
) {
  final vertices = <int>[];
  final midpoints = <int>[];
  Offset? positionFor(({int index, bool midpoint}) handle) {
    final position = controller.toScreenOffset(ring[handle.index]);
    if (!handle.midpoint) return position;
    final next = controller.toScreenOffset(
      ring[(handle.index + 1) % ring.length],
    );
    if (position == null || next == null) return null;
    return Offset((position.dx + next.dx) / 2, (position.dy + next.dy) / 2);
  }

  final candidates = <({int index, bool midpoint})>[
    for (final index in indices) (index: index, midpoint: false),
    for (final index in indices) (index: index, midpoint: true),
  ];
  if (activeIndex != null && activeKind != null) {
    final match = candidates.indexWhere(
      (handle) =>
          handle.index == activeIndex &&
          handle.midpoint == (activeKind == 'midpoint'),
    );
    if (match >= 0) candidates.insert(0, candidates.removeAt(match));
  }
  for (final handle in candidates) {
    final position = positionFor(handle);
    final isActive =
        activeIndex == handle.index &&
        (activeKind == 'midpoint') == handle.midpoint;
    if (!isActive &&
        position != null &&
        occupied.any(
          (other) => (position - other).distance < _minimumHandleSpacing,
        )) {
      continue;
    }
    (handle.midpoint ? midpoints : vertices).add(handle.index);
    if (position != null) occupied.add(position);
  }
  return _VisibleRingHandles(vertices: vertices, midpoints: midpoints);
}

enum KMapZoneEditorMode { move, draw }

@immutable
class KMapZoneUndoAction {
  const KMapZoneUndoAction({
    required this.message,
    required this.label,
    required this.undo,
  });
  final String message, label;
  final VoidCallback undo;
}

/// Controlled map-first zone editor. All edits, overlap reductions and removals
/// are committed together through [onChange]; no gallery-specific behavior.
class KMapZoneEditor extends StatefulWidget {
  const KMapZoneEditor({
    required this.mapStyle,
    required this.center,
    required this.zones,
    required this.onChange,
    required this.onSelect,
    this.onValidationError,
    this.selectedZoneId,
    this.editRequest,
    this.zoom = 13,
    this.showZoomControls = true,
    this.labels = const KMapZoneEditorLabels(),
    this.disabled = false,
    this.postalAreas = const [],
    this.defaultRadiusKm = 3,
    this.propertyOptions,
    this.onPostalQueryChange,
    this.onPendingChangesChanged,
    this.onUndoActionChange,
    this.bottomOverlayInset = 0,
    this.onMapViewChange,
    this.defaultZoneSettings,
    this.panelOpen,
    this.defaultPanelOpen = false,
    this.onPanelOpenChange,
    this.onExitRequested,
    this.fitMaxZoom = 17.5,
    this.fitDuration = const Duration(milliseconds: 320),
    super.key,
  }) : assert(bottomOverlayInset >= 0 && bottomOverlayInset < double.infinity);
  final String mapStyle;
  final KMapCenter center;
  final double zoom;
  final bool showZoomControls;
  final List<KMapZone> zones;
  final String? selectedZoneId;

  /// Opens existing properties through the normal unsaved-change guard.
  final ({String zoneId, int requestId})? editRequest;
  final KMapZonesChanged onChange;
  final KMapZoneSelected onSelect;
  final KMapZoneValidationErrorCallback? onValidationError;
  final KMapZoneEditorLabels labels;
  final bool disabled;
  final List<KMapPostalArea> postalAreas;
  final double defaultRadiusKm;
  final KMapZonePropertyOptions? propertyOptions;
  final ValueChanged<String>? onPostalQueryChange;
  final ValueChanged<bool>? onPendingChangesChanged;
  final ValueChanged<KMapZoneUndoAction?>? onUndoActionChange;
  final ValueChanged<KMapView>? onMapViewChange;
  final KMapZoneSettings? defaultZoneSettings;
  final bool? panelOpen;
  final bool defaultPanelOpen;
  final ValueChanged<bool>? onPanelOpenChange;

  /// Called after internal panels and unsaved editor changes have been handled.
  /// The consumer owns the route or host-screen exit that follows.
  final VoidCallback? onExitRequested;

  /// Extra logical pixels reserved for a consumer-owned bottom overlay.
  final double bottomOverlayInset;
  final double fitMaxZoom;
  final Duration fitDuration;
  @override
  State<KMapZoneEditor> createState() => _KMapZoneEditorState();
}

class _KMapZoneEditorState extends State<KMapZoneEditor> {
  late List<KMapZone> _working = _snapshot(widget.zones);
  late List<KMapZone> _base = _snapshot(widget.zones);
  late String? _selectedId = widget.selectedZoneId;
  late bool _open = widget.panelOpen ?? widget.defaultPanelOpen;
  String _stage = 'list';
  final _mapController = KMapController();
  final _history = <List<KMapZone>>[];
  List<KMapZone>? _undoBefore;
  List<KMapZone>? _dragBefore;
  KMapZone? _dragZone;
  KMapView? _view;
  bool _suppressMapClick = false;
  String? _undoAfter, _externalError, _propertyZoneId;
  String? _activeDragPinId;
  List<KMapZone>? _preview;
  bool _propertiesValid = true;
  bool _propertiesReturnToList = false;
  final _postalSelection = <String>{};
  final _postalQuery = TextEditingController();
  final _radiusInput = TextEditingController();
  double _panelHeight = 0;
  bool _dialogOpen = false;
  bool? _lastPendingValue;
  int _pendingNotification = 0;
  int _undoRevision = 0, _announcedUndoRevision = -1;
  KMapZoneEditorLabels get l => widget.labels;
  KMapZone? get _selected => _find(_working, _selectedId);
  KMapZone? get _propertyZone => _find(_working, _propertyZoneId);
  bool get _dirty => _key(_working) != _key(_base);
  bool get _properties => _stage == 'properties';
  bool get _canUndoCommit =>
      _undoBefore != null &&
      _undoAfter == _key(widget.zones) &&
      !_dirty &&
      !widget.disabled;

  @override
  void didUpdateWidget(covariant KMapZoneEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final request = widget.editRequest;
    if (!widget.disabled &&
        request != null &&
        request != oldWidget.editRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final matching = _working.where((zone) => zone.id == request.zoneId);
        if (matching.isNotEmpty) _guard(() => _propertiesFor(matching.first));
      });
    }

    if (widget.disabled && _dragBefore != null) {
      _working = _dragBefore!;
      _dragBefore = null;
      _dragZone = null;
      _suppressMapClick = false;
    }
    if (_key(widget.zones) != _key(_base)) {
      if (_dirty) {
        _externalError = l.externalChange;
      } else {
        _working = _snapshot(widget.zones);
        _base = _snapshot(widget.zones);
      }
    }
    if (oldWidget.selectedZoneId != widget.selectedZoneId && !_dirty) {
      _selectedId = widget.selectedZoneId;
    }
    if (widget.panelOpen != null && oldWidget.panelOpen != widget.panelOpen) {
      _open = widget.panelOpen!;
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _postalQuery.dispose();
    _radiusInput.dispose();
    super.dispose();
  }

  void _openPanel(bool value) {
    if (!value && _dirty) {
      _guard(() => _setOpen(false));
      return;
    }
    _setOpen(value);
  }

  void _setOpen(bool value) {
    setState(() {
      _open = value;
      if (!value && _properties) _stage = 'list';
    });
    widget.onPanelOpenChange?.call(value);
    if (!_properties) _fit(_selected);
  }

  void _fit([KMapZone? zone]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCoordinates(
        (zone == null ? _working : [zone])
            .expand((zone) => zone.geometry)
            .expand((polygon) => polygon.outer),
        padding: EdgeInsets.fromLTRB(
          40,
          40,
          40,
          widget.bottomOverlayInset +
              (_open
                  ? math.min(
                      _panelHeight + 100,
                      MediaQuery.sizeOf(context).height * .65,
                    )
                  : 100),
        ),
        maxZoom: widget.fitMaxZoom,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : widget.fitDuration,
      );
    });
  }

  void _select(String? id) {
    if (_suppressMapClick) return;
    if (widget.disabled || _dialogOpen) return;
    if (id != _selectedId && _dirty) {
      _guard(() => _select(id));
      return;
    }
    setState(() {
      _selectedId = id;
      _stage = _selected == null
          ? 'list'
          : _selected!.kind == 'circle'
          ? 'radius'
          : 'polygon';
    });
    _setOpen(false);
    widget.onSelect(id);
    _fit(_selected);
  }

  void _remember() {
    _history.add(_snapshot(_working));
  }

  void _change(KMapZone zone, {bool remember = true}) {
    if (widget.disabled || _dialogOpen) return;
    if (remember && _dragBefore == null) _remember();
    setState(() {
      _working = [
        for (final current in _working) current.id == zone.id ? zone : current,
      ];
    });
  }

  void _new(String kind) {
    if (_dirty) {
      _guard(() => _new(kind));
      return;
    }
    if (kind == 'postal') {
      setState(() {
        _stage = 'postal';
        _postalSelection.clear();
      });
      _setOpen(true);
      widget.onPostalQueryChange?.call(_postalQuery.text);
      return;
    }
    var i = _working.length + 1;
    while (_working.any((zone) => zone.id == 'zone-$i')) {
      i++;
    }
    final center = _mapController.view?.center ?? widget.center;
    final zone = KMapZone(
      id: 'zone-$i',
      name: l.newZoneName,
      kind: kind,
      color: kMapZonePalette[(_working.length + 10) % kMapZonePalette.length]
          .light,
      settings: widget.defaultZoneSettings,
      circle: kind == 'circle'
          ? KMapZoneCircle(center: center, radiusKm: widget.defaultRadiusKm)
          : null,
      coordinates: kind == 'circle'
          ? createKMapCircleCoordinates(center, widget.defaultRadiusKm)
          : const [],
    );
    _remember();
    setState(() {
      _working = [..._working, zone];
      _selectedId = zone.id;
      _stage = kind == 'circle' ? 'radius' : 'polygon';
    });
    widget.onSelect(zone.id);
    _setOpen(false);
    if (kind == 'circle') {
      _radiusInput.text = widget.defaultRadiusKm.toStringAsFixed(1);
      _fit(zone);
    }
  }

  void _propertiesFor(KMapZone zone, {bool returnToList = false}) {
    if (_dirty && (_properties ? _propertyZoneId : _selectedId) != zone.id) {
      _guard(() => _propertiesFor(_find(_working, zone.id) ?? zone));
      return;
    }
    setState(() {
      _propertyZoneId = zone.id;
      _stage = 'properties';
      _propertiesValid = zone.name.trim().isNotEmpty;
      _propertiesReturnToList = returnToList;
    });
    _setOpen(true);
  }

  void _leavePanelLevel() {
    if (_stage == 'list') {
      _openPanel(false);
      return;
    }
    final wasProperties = _properties;
    final returnToList = wasProperties && _propertiesReturnToList;
    _guard(() {
      if (returnToList) {
        setState(() => _stage = 'list');
      } else if (wasProperties) {
        _setOpen(false);
      } else {
        setState(() => _stage = 'list');
      }
    });
  }

  void _discard() {
    setState(() {
      _working = _snapshot(widget.zones);
      _base = _snapshot(widget.zones);
      _history.clear();
      _externalError = null;
      _stage = 'list';
      if (_find(_working, _selectedId) == null) _selectedId = null;
    });
    widget.onSelect(_selectedId);
  }

  void _undo() {
    if (_history.isEmpty || widget.disabled) return;
    setState(() {
      _working = _history.removeLast();
      if (_find(_working, _selectedId) == null) {
        _selectedId = null;
        _stage = 'list';
      }
    });
  }

  KDesignTokens get _tokens => Theme.of(context).extension<KDesignTokens>()!;

  Future<String?> _ask(
    String title,
    Widget body,
    List<(String, String)> actions,
  ) async {
    if (_dialogOpen) return null;
    _dialogOpen = true;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: SizedBox(
          width: math.min(480, MediaQuery.sizeOf(context).width - 48),
          child: Padding(
            padding: EdgeInsets.all(
              _tokens.spaceCardPadding + _tokens.spaceControlGap,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KText(title, variant: KTextVariant.heading5),
                SizedBox(height: _tokens.spaceCardPadding),
                body,
                SizedBox(
                  height: _tokens.spaceCardPadding + _tokens.spaceControlGap,
                ),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < actions.length; i++)
                      KButton(
                        label: actions[i].$2,
                        variant: i == actions.length - 1
                            ? KButtonVariant.primary
                            : KButtonVariant.secondary,
                        onPressed: () => Navigator.pop(context, actions[i].$1),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    _dialogOpen = false;
    return result;
  }

  Future<void> _guard(VoidCallback next) async {
    if (!_dirty) {
      next();
      return;
    }
    final action = await _ask(l.unsavedTitle, KText(l.unsavedDescription), [
      ('continue', l.continueEditing),
      ('discard', l.discard),
      ('save', l.save),
    ]);
    if (!mounted) return;
    if (action == 'discard') {
      _discard();
      next();
    }
    if (action == 'save' &&
        (!_properties || _propertiesValid) &&
        await _commit()) {
      if (mounted) next();
    }
  }

  String? get _geometryError {
    if (_externalError != null) return _externalError;
    for (final zone in _working) {
      final error = validateKMapZones([zone]);
      if (error != null) return l.validationMessage(error.code.value);
    }
    return null;
  }

  Future<bool> _commit() async {
    if (widget.disabled || (_properties && !_propertiesValid)) return false;
    final error = _geometryError;
    if (error != null) {
      widget.onValidationError?.call(
        KMapZoneValidationError(
          code: _externalError != null
              ? KMapZoneValidationCode.externalChange
              : KMapZoneValidationCode.invalidCoordinate,
          message: error,
          zoneId: _selectedId,
        ),
      );
      setState(() {});
      return false;
    }
    final previous = _snapshot(widget.zones);
    if (_key(previous) != _key(_base)) {
      setState(() => _externalError = l.externalChange);
      return false;
    }
    var next = List<KMapZone>.of(_working);
    final impacts = <String>[];
    final changedIds = _working
        .where(
          (zone) =>
              zone.id == (_properties ? _propertyZoneId : _selectedId) ||
              _find(_base, zone.id) == null,
        )
        .map((zone) => zone.id)
        .toList();
    final impacted = <String, String>{};
    try {
      for (final id in changedIds) {
        final candidate = _find(next, id);
        if (candidate == null) continue;
        next = [
          for (final zone in next)
            if (zone.id == id)
              zone
            else
              ...() {
                final remaining = subtractKMapZoneGeometry(
                  zone.geometry,
                  candidate.geometry,
                );
                final originalArea = kMapZoneGeometryArea(zone.geometry),
                    remainingArea = kMapZoneGeometryArea(remaining);
                if ((originalArea - remainingArea).abs() <=
                    math.max(1e-13, originalArea * 1e-8)) {
                  return [zone];
                }
                impacted[zone.id] = zone.name;
                return remaining.isEmpty
                    ? <KMapZone>[]
                    : [
                        KMapZone(
                          id: zone.id,
                          name: zone.name,
                          color: zone.color,
                          kind: 'polygon',
                          coordinates: remaining.first.outer,
                          polygons: remaining,
                          source: zone.source,
                          settings: zone.settings,
                        ),
                      ];
              }(),
        ];
      }
      for (final entry in impacted.entries) {
        impacts.add(
          '${entry.value} · ${_find(next, entry.key) == null ? l.overlapRemoved : l.overlapReduced}',
        );
      }
      final invalid = validateKMapZones(next);
      if (invalid != null) {
        widget.onValidationError?.call(invalid);
        return false;
      }
    } catch (_) {
      widget.onValidationError?.call(
        KMapZoneValidationError(
          code: KMapZoneValidationCode.zoneOverlap,
          message: l.zoneOverlap,
          zoneId: _selectedId,
        ),
      );
      return false;
    }

    if (impacts.isNotEmpty) {
      setState(() => _preview = next);
      final action = await _ask(
        l.overlapTitle,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KText(l.overlapDescription),
            SizedBox(height: _tokens.spaceCardPadding),
            ...impacts.map((impact) => KText('• $impact')),
          ],
        ),
        [('cancel', l.cancel), ('confirm', l.confirmOverlap)],
      );
      if (!mounted) return false;
      setState(() => _preview = null);
      if (action != 'confirm') return false;
    }
    if (_key(widget.zones) != _key(previous)) {
      setState(() => _externalError = l.externalChange);
      return false;
    }
    setState(() {
      _undoRevision++;
      _undoBefore = previous;
      _undoAfter = _key(next);
      _working = next;
      _base = List.of(next);
      _history.clear();
      _stage = 'list';
      _externalError = null;
    });
    widget.onChange(_snapshot(next));
    return true;
  }

  Future<void> _delete(KMapZone zone) async {
    if (_dirty) {
      _guard(() => _delete(zone));
      return;
    }
    if (_find(_working, zone.id) == null) return;
    final result = await _ask(
      l.deleteZoneTitle,
      KText(l.deleteZoneDescription.replaceAll('{name}', zone.name)),
      [('cancel', l.cancel), ('delete', l.confirmDeleteZone)],
    );
    if (!mounted || result != 'delete' || widget.disabled) return;
    _remember();
    setState(() {
      _working = _working.where((current) => current.id != zone.id).toList();
      _selectedId = null;
      _stage = 'list';
    });
    await _commit();
    widget.onSelect(null);
  }

  void _radius(double value) {
    final zone = _selected, circle = _selected?.circle;
    if (zone == null || circle == null) return;
    final radius = value.clamp(.5, 100.0);
    _radiusInput.text = radius.toStringAsFixed(1);
    _change(
      zone.copyWith(
        circle: KMapZoneCircle(center: circle.center, radiusKm: radius),
        coordinates: createKMapCircleCoordinates(circle.center, radius),
      ),
    );
  }

  void _mapTap(KMapCenter point) {
    if (_suppressMapClick) return;
    if (widget.disabled || _dialogOpen || _properties) return;
    final zone = _selected;
    if (_stage == 'polygon' &&
        zone != null &&
        !_base.any((existing) => existing.id == zone.id)) {
      _replaceRing(zone, 0, 0, [...zone.coordinates, point]);
    }
  }

  void _dragStart(KMapPinMove event) {
    if (widget.disabled || _dialogOpen || _properties) return;
    _dragBefore = _snapshot(_working);
    _dragZone = _selected;
    _activeDragPinId = event.id;
    _suppressMapClick = true;
  }

  void _dragFinish(KMapPinMove event, {bool cancelled = false}) {
    final before = _dragBefore;
    _activeDragPinId = null;
    if (before != null) {
      setState(() {
        if (cancelled) {
          _working = before;
        } else if (_key(before) != _key(_working)) {
          _history.add(before);
        }
        _dragBefore = null;
        _dragZone = null;
        _activeDragPinId = null;
      });
    }
    Future<void>.delayed(_tokens.motionFast, () {
      if (mounted) _suppressMapClick = false;
    });
  }

  Future<bool?> _move(KMapPinMove event) async {
    final zone = _dragZone ?? _selected;
    if (zone == null || widget.disabled || _dialogOpen || _properties) {
      return false;
    }
    if (event.id == 'zone-center') {
      final center = _center(zone);
      if (zone.kind == 'circle' && zone.circle != null) {
        _change(
          zone.copyWith(
            circle: KMapZoneCircle(
              center: event.position,
              radiusKm: zone.circle!.radiusKm,
            ),
            coordinates: createKMapCircleCoordinates(
              event.position,
              zone.circle!.radiusKm,
            ),
          ),
        );
      } else {
        KMapCenter shift(KMapCenter point) => KMapCenter(
          longitude:
              (point.longitude + event.position.longitude - center.longitude)
                  .clamp(-180, 180),
          latitude: (point.latitude + event.position.latitude - center.latitude)
              .clamp(-90, 90),
        );
        _change(
          zone.copyWith(
            coordinates: zone.coordinates.map(shift).toList(),
            polygons: [
              for (final polygon in zone.geometry)
                KMapPolygon(
                  outer: polygon.outer.map(shift).toList(),
                  holes: [
                    for (final hole in polygon.holes) hole.map(shift).toList(),
                  ],
                ),
            ],
          ),
        );
      }
      return true;
    }
    if (event.id == 'zone-radius' && zone.circle != null) {
      final c = zone.circle!.center, p = event.position;
      final lat1 = c.latitude * math.pi / 180,
          lat2 = p.latitude * math.pi / 180;
      final a =
          math.pow(math.sin((lat2 - lat1) / 2), 2) +
          math.cos(lat1) *
              math.cos(lat2) *
              math.pow(
                math.sin((p.longitude - c.longitude) * math.pi / 360),
                2,
              );
      _radius(6371.0088 * 2 * math.asin(math.sqrt(a.toDouble()).clamp(0, 1)));
      return true;
    }
    final parts = event.id.split('-');
    if (parts.length != 5) return false;
    final polygon = int.tryParse(parts[2]),
        ringIndex = int.tryParse(parts[3]),
        index = int.tryParse(parts[4]);
    if (polygon == null ||
        ringIndex == null ||
        index == null ||
        polygon >= zone.geometry.length) {
      return false;
    }
    final rings = [
      zone.geometry[polygon].outer,
      ...zone.geometry[polygon].holes,
    ];
    if (ringIndex >= rings.length || index >= rings[ringIndex].length) {
      return false;
    }
    final ring = [...rings[ringIndex]];
    if (event.id.startsWith('zone-midpoint-')) {
      ring.insert(index + 1, event.position);
    } else {
      ring[index] = event.position;
    }
    _replaceRing(zone, polygon, ringIndex, ring);
    return true;
  }

  void _replaceRing(
    KMapZone zone,
    int polygonIndex,
    int ringIndex,
    List<KMapCenter> ring,
  ) {
    final polygons = [
      for (var p = 0; p < zone.geometry.length; p++)
        if (p != polygonIndex)
          zone.geometry[p]
        else
          KMapPolygon(
            outer: ringIndex == 0 ? ring : zone.geometry[p].outer,
            holes: [
              for (var h = 0; h < zone.geometry[p].holes.length; h++)
                h + 1 == ringIndex ? ring : zone.geometry[p].holes[h],
            ],
          ),
    ];
    _change(
      KMapZone(
        id: zone.id,
        name: zone.name,
        color: zone.color,
        kind: 'polygon',
        coordinates: polygons.first.outer,
        polygons: polygons,
        source: zone.source,
        settings: zone.settings,
      ),
    );
  }

  void _pinTap(String id) {
    if (!id.startsWith('zone-midpoint-')) return;
    final zone = _selected;
    final parts = id.split('-');
    if (zone == null || parts.length != 5) return;
    final polygon = int.tryParse(parts[2]),
        ringIndex = int.tryParse(parts[3]),
        index = int.tryParse(parts[4]);
    if (polygon == null ||
        ringIndex == null ||
        index == null ||
        polygon >= zone.geometry.length) {
      return;
    }
    final rings = [
      zone.geometry[polygon].outer,
      ...zone.geometry[polygon].holes,
    ];
    if (ringIndex >= rings.length || index >= rings[ringIndex].length) return;
    final ring = rings[ringIndex], a = rings[ringIndex][index];
    final b = ring[(index + 1) % ring.length];
    _move(
      KMapPinMove(
        id: id,
        source: KMapPinMoveSource.drag,
        position: KMapCenter(
          longitude: (a.longitude + b.longitude) / 2,
          latitude: (a.latitude + b.latitude) / 2,
        ),
      ),
    );
  }

  Color _color(KMapZone zone, KDesignTokens t) {
    final value = resolveKMapZoneColor(
      zone.color ?? '#155dfc',
      Theme.of(context).brightness == Brightness.dark,
    );
    return Color(
      int.tryParse('ff${value.replaceFirst('#', '')}', radix: 16) ??
          t.colorBrandPrimaryAccent.toARGB32(),
    );
  }

  List<KMapPin> _pins(KDesignTokens t) {
    final zone = _selected;
    if (zone == null || _properties || _dialogOpen || widget.disabled) {
      return [];
    }
    KMapPin pin(
      String id,
      KMapCenter point,
      String label, {
      bool midpoint = false,
      KIconName? icon,
    }) => KMapPin(
      id: id,
      position: point,
      label: label,
      size: 44,
      shape: KMapPinShape.circle,
      anchor: KMapPinAnchor.center,
      draggable: true,
      child: Center(
        child: Container(
          width: midpoint
              ? 18
              : icon == null
              ? 16
              : 30,
          height: midpoint
              ? 18
              : icon == null
              ? 16
              : 30,
          decoration: BoxDecoration(
            color: t.colorSurfaceRaised,
            shape: BoxShape.circle,
            border: Border.all(
              color: _color(zone, t),
              width: t.borderWidthStrong,
            ),
            boxShadow: t.elevationMedium,
          ),
          child: icon != null
              ? KIcon(icon, size: 16, color: _color(zone, t))
              : midpoint
              ? KIcon(KIconName.plus, size: 12, color: _color(zone, t))
              : null,
        ),
      ),
    );
    if (zone.kind == 'circle' && zone.circle != null) {
      return [
        pin(
          'zone-center',
          zone.circle!.center,
          l.moveCenter,
          icon: KIconName.move,
        ),
        pin(
          'zone-radius',
          createKMapCircleCoordinates(
            zone.circle!.center,
            zone.circle!.radiusKm,
          )[16],
          l.resizeRadius,
          icon: KIconName.moveHorizontal,
        ),
      ];
    }
    final entries = <({List<KMapCenter> ring, int polygon, int ringIndex})>[];
    for (var p = 0; p < zone.geometry.length; p++) {
      entries.add((ring: zone.geometry[p].outer, polygon: p, ringIndex: 0));
      for (var r = 0; r < zone.geometry[p].holes.length; r++) {
        entries.add((
          ring: zone.geometry[p].holes[r],
          polygon: p,
          ringIndex: r + 1,
        ));
      }
    }
    final pins = <KMapPin>[
      if (zone.coordinates.length >= 3)
        pin('zone-center', _center(zone), l.moveZone, icon: KIconName.move),
    ];
    var remaining = (_view?.zoom ?? 13) >= 14 ? _maxVisibleZoneHandles : 64;
    final occupiedHandlePositions = <Offset>[];
    for (var entryIndex = 0; entryIndex < entries.length; entryIndex++) {
      final entry = entries[entryIndex];
      final budget = remaining ~/ (entries.length - entryIndex);
      final activeParts = _activeDragPinId?.split('-');
      final activeIndex =
          activeParts != null &&
              activeParts.length == 5 &&
              int.tryParse(activeParts[2]) == entry.polygon &&
              int.tryParse(activeParts[3]) == entry.ringIndex
          ? int.tryParse(activeParts[4])
          : null;
      final indices = _visibleRingIndices(
        entry.ring,
        _view ?? _mapController.view,
        budget,
        activeIndex,
      );
      final handles = _screenSpacedRingHandles(
        entry.ring,
        indices,
        _mapController,
        activeIndex,
        activeIndex == null ? null : activeParts?[1],
        occupiedHandlePositions,
      );
      final renderedIndices = <int>{...handles.vertices, ...handles.midpoints};
      remaining -= renderedIndices.length;
      for (final i in renderedIndices) {
        if (handles.vertices.contains(i)) {
          pins.add(
            pin(
              'zone-vertex-${entry.polygon}-${entry.ringIndex}-$i',
              entry.ring[i],
              '${l.vertices} ${entry.polygon + 1}.${entry.ringIndex + 1}.${i + 1}',
            ),
          );
        }
        if (entry.ring.length >= 2 && handles.midpoints.contains(i)) {
          final next = entry.ring[(i + 1) % entry.ring.length];
          pins.add(
            pin(
              'zone-midpoint-${entry.polygon}-${entry.ringIndex}-$i',
              KMapCenter(
                longitude: (entry.ring[i].longitude + next.longitude) / 2,
                latitude: (entry.ring[i].latitude + next.latitude) / 2,
              ),
              '${l.addPointAfter} ${entry.polygon + 1}.${entry.ringIndex + 1}.${i + 1}',
              midpoint: true,
            ),
          );
        }
      }
    }
    return pins;
  }

  void _notifyUndoAction() {
    final revision = _canUndoCommit ? _undoRevision : -1;
    if (_announcedUndoRevision == revision) return;
    _announcedUndoRevision = revision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _announcedUndoRevision != revision) return;
      widget.onUndoActionChange?.call(
        revision < 0
            ? null
            : KMapZoneUndoAction(
                message: l.changesApplied,
                label: l.undo,
                undo: () {
                  if (!mounted ||
                      revision != _undoRevision ||
                      !_canUndoCommit) {
                    return;
                  }
                  final previous = _undoBefore!;
                  setState(() {
                    _working = previous;
                    _base = previous;
                    _undoBefore = null;
                    _undoAfter = null;
                    _undoRevision++;
                  });
                  widget.onChange(_snapshot(previous));
                },
              ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _notifyUndoAction();
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final pending =
        _dirty || (_stage == 'postal' && _postalSelection.isNotEmpty);
    if (_lastPendingValue != pending) {
      _lastPendingValue = pending;
      final notification = ++_pendingNotification;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && notification == _pendingNotification) {
          widget.onPendingChangesChanged?.call(pending);
        }
      });
    }
    return PopScope(
      canPop: widget.onExitRequested == null && !_open && !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_open) {
            _leavePanelLevel();
            return;
          }
          _guard(() {
            if (!mounted) return;
            final onExitRequested = widget.onExitRequested;
            if (onExitRequested != null) {
              onExitRequested();
            } else {
              Navigator.of(context).pop(result);
            }
          });
        }
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): _leavePanelLevel,
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
        },
        child: Semantics(
          label: l.editor,
          container: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final inset = t.spaceLayoutGutter;
              final toolbarHeight = math.max(
                48.0,
                math.max(t.sizeControl, t.sizeHitTarget),
              );
              final overlayInset = widget.bottomOverlayInset.clamp(
                0.0,
                math.max(
                  0.0,
                  constraints.maxHeight - toolbarHeight - inset * 2 - 24,
                ),
              );
              final bottomMotion = MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : t.motionStandard;
              final properties = _properties;
              final panelInset = t.spaceControlInsetInline;
              final panelBottom = 80.0 + overlayInset;
              final availableHeight = math.max(
                0.0,
                constraints.maxHeight - 100 - overlayInset,
              );
              final emptyIdle = _working.isEmpty && _stage == 'list';
              _panelHeight = math.min(
                properties
                    ? 720.0
                    : _stage == 'list'
                    ? math.min(500.0, 190.0 + _working.length * 64.0)
                    : 420.0,
                availableHeight,
              );
              return Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: emptyIdle,
                      child: Transform.scale(
                        scale: emptyIdle ? 1.02 : 1,
                        child: KMap(
                          mapStyle: widget.mapStyle,
                          blurSigma: emptyIdle ? 6 : 0,
                          center: widget.center,
                          zoom: widget.zoom,
                          showZoomControls: widget.showZoomControls,
                          controller: _mapController,
                          onViewChange: (view) {
                            if (_view != view && mounted) {
                              setState(() => _view = view);
                            }
                            widget.onMapViewChange?.call(view);
                          },
                          zones: [
                            for (final zone in _preview ?? _working)
                              if (zone.name.trim().isNotEmpty)
                                zone
                              else
                                zone.copyWith(name: l.newZoneName),
                            if (_stage == 'postal')
                              for (final area in widget.postalAreas)
                                KMapZone(
                                  id: area.id,
                                  name: _postalAreaName(area),
                                  coordinates: area.coordinates,
                                  polygons: area.polygons,
                                  color: _postalSelection.contains(area.id)
                                      ? '#155dfc'
                                      : '#525252',
                                ),
                          ],
                          selectedZoneId: _selectedId,
                          onZoneClick: _stage == 'postal'
                              ? _togglePostal
                              : properties
                              ? null
                              : _select,
                          onMapTap: _mapTap,
                          pins: _pins(t),
                          selectionControlled: true,
                          onPinTap: _pinTap,
                          onPinMove: _move,
                          onPinDragStart: _dragStart,
                          onPinDrag: (event) => _move(event),
                          onPinDragEnd: _dragFinish,
                          onPinDragCancel: (event) =>
                              _dragFinish(event, cancelled: true),
                          pinDrag: const KMapPinDragOptions(
                            edgePan: KMapPinEdgePanOptions(),
                          ),
                          fitContentOnLoad: true,
                          fitContentPadding: EdgeInsets.fromLTRB(
                            40,
                            40,
                            40,
                            100 + widget.bottomOverlayInset,
                          ),
                          controlsPadding: EdgeInsetsDirectional.fromSTEB(
                            inset,
                            inset,
                            inset,
                            toolbarHeight + inset * 2 + overlayInset,
                          ),
                          overlayBuilder: (context, controller) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                  if (_working.isEmpty && _stage == 'list')
                    Center(
                      child: _surface(
                        t,
                        SizedBox(
                          width: math.min(
                            440,
                            constraints.maxWidth - inset * 2,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(t.spaceCardPadding),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                spacing: t.spaceLayoutGutter,
                                children: [
                                  KText(
                                    l.createFirstZone,
                                    variant: KTextVariant.heading5,
                                  ),
                                  KText(l.empty),
                                  ..._creationButtons(t),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_open)
                    AnimatedPositioned(
                      duration: bottomMotion,
                      curve: Curves.easeOutCubic,
                      left: panelInset,
                      right: panelInset,
                      bottom: panelBottom,
                      child: Center(
                        child: PointerInterceptor(
                          child: AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : t.motionEmphasis,
                            curve: Curves.easeOutCubic,
                            width: math.min(
                              properties ? 600.0 : 440.0,
                              constraints.maxWidth - panelInset * 2,
                            ),
                            height: _panelHeight,
                            child: _surface(
                              t,
                              Padding(
                                padding: EdgeInsets.all(t.spaceLayoutGutter),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        if (_stage != 'list')
                                          KIconButton(
                                            label: l.back,
                                            icon: KIconName.arrowLeft,
                                            onPressed: _leavePanelLevel,
                                          ),
                                        Expanded(
                                          child: KText(
                                            properties
                                                ? _propertyZone?.name ??
                                                      _panelTitle
                                                : _panelTitle,
                                            variant: KTextVariant.heading5,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        KIconButton(
                                          label: l.closePanel,
                                          icon: KIconName.x,
                                          onPressed: () => _openPanel(false),
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        key: ValueKey('zone-panel-$_stage'),
                                        padding: EdgeInsets.symmetric(
                                          vertical: t.spaceControlGap,
                                        ),
                                        child: _panel(t),
                                      ),
                                    ),
                                    if (_stage == 'list') ...[
                                      SizedBox(
                                        width: double.infinity,
                                        child: KButton(
                                          label: l.addZone,
                                          onPressed: widget.disabled
                                              ? null
                                              : () => _guard(
                                                  () => setState(
                                                    () => _stage = 'create',
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                    if (properties || _stage == 'postal') ...[
                                      _panelActions(t),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_working.isNotEmpty || _open)
                    AnimatedPositioned(
                      duration: bottomMotion,
                      curve: Curves.easeOutCubic,
                      left: inset,
                      right: inset,
                      bottom: inset + overlayInset,
                      child: Center(
                        child: KMapZoneBarSlot(
                          dirtyVisible: _dirty && !properties,
                          duration: bottomMotion,
                          width: math.min(
                            340,
                            constraints.maxWidth - inset * 2,
                          ),
                          height: toolbarHeight,
                          selection: _surface(
                            t,
                            SizedBox(
                              key: const ValueKey('zone-selection-bar'),
                              height: toolbarHeight,
                              width: math.min(
                                340,
                                constraints.maxWidth - inset * 2,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          t.spaceControlInsetInline +
                                          t.spaceControlGap,
                                    ),
                                    child: KIcon(
                                      KIconName.layers,
                                      label:
                                          '${_working.length} ${l.zonePlural}',
                                    ),
                                  ),
                                  Expanded(
                                    child: KButton(
                                      label:
                                          _selected?.name.trim().isNotEmpty ==
                                              true
                                          ? _selected!.name
                                          : l.all,
                                      variant: KButtonVariant.ghost,
                                      trailing: KIcon(
                                        _open
                                            ? KIconName.chevronDown
                                            : KIconName.chevronUp,
                                      ),
                                      onPressed: () => _openPanel(!_open),
                                    ),
                                  ),
                                  if (_selected != null)
                                    KIconButton(
                                      label: l.editZoneProperties,
                                      icon: KIconName.pencil,
                                      onPressed: widget.disabled
                                          ? null
                                          : () => _propertiesFor(_selected!),
                                    ),
                                  KIconButton(
                                    label: l.addZone,
                                    icon: KIconName.plus,
                                    onPressed: widget.disabled
                                        ? null
                                        : () => _guard(() {
                                            setState(() => _stage = 'create');
                                            _setOpen(true);
                                          }),
                                  ),
                                ],
                              ),
                            ),
                            pill: true,
                          ),
                          dirty: KMapZoneFeedback(
                            key: const ValueKey('zone-dirty-feedback'),
                            width: math.min(
                              340,
                              constraints.maxWidth - inset * 2,
                            ),
                            height: toolbarHeight,
                            tokens: t,
                            labels: l,
                            dirty: _dirty && !properties,
                            canUndo: _history.isNotEmpty,
                            enabled: !widget.disabled,
                            canAccept: _geometryError == null,
                            onUndo: _undo,
                            onDiscard: _discard,
                            onAccept: () => _commit(),
                            surface: (child) => _surface(t, child, pill: true),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _surface(KDesignTokens t, Widget child, {bool pill = false}) {
    final radius = BorderRadius.circular(pill ? t.radiusFull : t.radiusCard);
    return PointerInterceptor(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: t.elevationMedium,
        ),
        child: Material(
          color: t.colorSurfaceRaised,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: t.colorBorderDefault),
              borderRadius: radius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  String get _panelTitle => switch (_stage) {
    'properties' => l.zoneProperties,
    'create' => l.addZone,
    'radius' => l.radiusTitle,
    'polygon' => l.polygonTitle,
    'postal' => l.postalTitle,
    _ => l.zones,
  };
  List<Widget> _creationButtons(KDesignTokens t) => [
    for (final entry in [
      (l.radiusTitle, l.radiusDescription, 'circle'),
      (l.postalTitle, l.postalDescription, 'postal'),
      (l.polygonTitle, l.polygonDescription, 'polygon'),
    ])
      KButton(
        label: '${entry.$1}. ${entry.$2}',
        fullWidth: true,
        variant: KButtonVariant.secondary,
        onPressed: widget.disabled ? null : () => _new(entry.$3),
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: t.spaceControlInsetInline),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(t.radiusControl),
                child: ColoredBox(
                  color: t.colorSurfaceRaised,
                  child: SvgPicture.string(
                    _zoneCreationIllustration(entry.$3),
                    width: t.sizeControl * 2,
                    height: t.sizeControl * 1.5,
                    theme: SvgTheme(
                      currentColor: t.colorActionPrimaryBackground,
                    ),
                  ),
                ),
              ),
              SizedBox(width: t.spaceControlGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: t.spaceTight,
                  children: [
                    KText(
                      entry.$1,
                      style: TextStyle(
                        fontSize: t.fontControlSize,
                        fontWeight: t.fontLabelWeight,
                      ),
                    ),
                    KText(
                      entry.$2,
                      style: TextStyle(
                        fontSize: t.fontCaptionSize,
                        color: t.colorTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
  ];

  Widget _panel(KDesignTokens t) {
    if (_properties && _propertyZone != null) {
      return AbsorbPointer(
        absorbing: widget.disabled,
        child: KMapZoneProperties(
          key: ValueKey('properties-$_propertyZoneId'),
          zone: _propertyZone!,
          otherZones: _working
              .where((zone) => zone.id != _propertyZoneId)
              .toList(growable: false),
          labels: l,
          options: widget.propertyOptions,
          onChange: (zone) => _change(zone, remember: false),
          onValidityChanged: (valid) {
            if (_propertiesValid != valid && mounted) {
              setState(() => _propertiesValid = valid);
            }
          },
        ),
      );
    }
    if (_stage == 'create') {
      return Column(
        spacing: t.spaceControlGap,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [KText(l.intro), ..._creationButtons(t)],
      );
    }
    if (_stage == 'postal') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: t.spaceControlGap,
        children: [
          KInput(
            controller: _postalQuery,
            label: l.postalSearch,
            placeholder: l.postalSearch,
            onChanged: (value) {
              setState(() {});
              widget.onPostalQueryChange?.call(value);
            },
          ),
          KText(
            '${l.sampleData}: ${widget.postalAreas.isEmpty ? '—' : widget.postalAreas.first.sourceLabel}',
            style: TextStyle(color: t.colorTextMuted),
          ),
          if (widget.postalAreas.isEmpty) KText(l.postalEmpty),
          for (final area in widget.postalAreas.where(
            (area) => '${area.code} ${area.label}'.toLowerCase().contains(
              _postalQuery.text.toLowerCase(),
            ),
          ))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KCheckbox(
                  label: area.label == area.code
                      ? area.code
                      : '${area.code} · ${area.label}',
                  value: _postalSelection.contains(area.id),
                  onChanged: widget.disabled || area.assignedZoneId != null
                      ? null
                      : (_) => _togglePostal(area.id),
                ),
                if (area.assignedZoneId != null) KText(l.assignedPostalArea),
              ],
            ),
        ],
      );
    }
    if ((_stage == 'radius' || _stage == 'polygon') && _selected != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: t.spaceControlGap,
        children: [
          if (_stage == 'radius' && _selected!.circle != null) ...[
            KText(
              '${l.radius} · ${_selected!.circle!.radiusKm.toStringAsFixed(1)} km',
            ),
            Slider(
              value: _selected!.circle!.radiusKm.clamp(.5, 100),
              min: .5,
              max: 100,
              label: '${l.radius} km',
              onChanged: widget.disabled ? null : _radius,
            ),
            KInput(
              controller: _radiusInput,
              label: '${l.radius} (km)',
              onChanged: (value) {
                final number = double.tryParse(value.replaceAll(',', '.'));
                if (number != null && number.isFinite) _radius(number);
              },
            ),
            KText(l.airDistance),
          ] else ...[
            KText(l.addVertexHint),
            KText('${l.vertices}: ${_selected!.coordinates.length}'),
            KButton(
              label: l.removePoint,
              variant: KButtonVariant.secondary,
              onPressed: _selected!.coordinates.isEmpty || widget.disabled
                  ? null
                  : () => _replaceRing(
                      _selected!,
                      0,
                      0,
                      [..._selected!.coordinates]..removeLast(),
                    ),
            ),
          ],
          if (_geometryError != null)
            KText(
              _geometryError!,
              style: TextStyle(color: t.colorStatusErrorForeground),
            ),
          KButton(
            label: l.editZoneProperties,
            variant: KButtonVariant.secondary,
            onPressed: () => _propertiesFor(_selected!),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _zoneRow(t, null),
        for (final zone in _working) _zoneRow(t, zone),
      ],
    );
  }

  Widget _zoneRow(KDesignTokens t, KMapZone? zone) => Row(
    children: [
      Expanded(
        child: Semantics(
          selected: zone?.id == _selectedId,
          button: true,
          child: InkWell(
            onTap: widget.disabled ? null : () => _select(zone?.id),
            borderRadius: BorderRadius.circular(t.radiusControl),
            child: Container(
              constraints: BoxConstraints(
                minHeight: t.sizeControl + t.sizeSmallControl,
              ),
              padding: EdgeInsets.all(t.spaceControlGap),
              decoration: BoxDecoration(
                color: zone?.id == _selectedId ? t.colorActionGhostHover : null,
                borderRadius: BorderRadius.circular(t.radiusControl),
              ),
              child: Row(
                children: [
                  if (zone != null) ...[
                    Container(
                      width: t.sizeIndicatorTiny,
                      height: t.sizeIndicatorTiny,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _color(zone, t),
                      ),
                    ),
                    SizedBox(width: t.spaceControlGap),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KText(
                          zone?.name ?? l.allZones,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (zone != null)
                          KText(
                            zone.kind == 'circle'
                                ? '${l.radiusTitle} · ${zone.circle?.radiusKm.toStringAsFixed(1)} km'
                                : zone.source != null
                                ? '${zone.kind == 'postal' ? l.postalTitle : l.customArea} · ${zone.source!.code}'
                                : l.customArea,
                            style: TextStyle(
                              color: t.colorTextMuted,
                              fontSize: t.fontCaptionSize,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      if (zone != null) ...[
        KIconButton(
          label: '${l.editZone}: ${zone.name}',
          icon: KIconName.pencil,
          onPressed: widget.disabled
              ? null
              : () => _propertiesFor(zone, returnToList: true),
        ),
        KIconButton(
          label: '${l.deleteZone}: ${zone.name}',
          icon: KIconName.trash,
          onPressed: widget.disabled ? null : () => _delete(zone),
        ),
      ],
    ],
  );

  Widget _panelActions(KDesignTokens t) {
    if (!_properties) {
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: t.spaceControlGap,
        runSpacing: t.spaceControlGap,
        children: [
          KText('${l.postalSelection}: ${_postalSelection.length}'),
          KButton(
            label: l.apply,
            onPressed: widget.disabled || _postalSelection.isEmpty
                ? null
                : _applyPostal,
          ),
        ],
      );
    }
    return Row(
      children: [
        KButton(
          label: l.deleteZone,
          leading: const KIcon(KIconName.trash),
          variant: KButtonVariant.ghost,
          onPressed: widget.disabled ? null : () => _delete(_propertyZone!),
        ),
        SizedBox(width: t.spaceControlGap),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: KButton(
                    label: l.cancel,
                    variant: KButtonVariant.secondary,
                    onPressed: _leavePanelLevel,
                  ),
                ),
                if (_dirty) ...[
                  SizedBox(width: t.spaceControlGap),
                  Flexible(
                    child: KButton(
                      label: l.done,
                      onPressed:
                          widget.disabled ||
                              !_propertiesValid ||
                              _geometryError != null
                          ? null
                          : () async {
                              final returnToList = _propertiesReturnToList;
                              if (await _commit() && mounted && !returnToList) {
                                _setOpen(false);
                              }
                            },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _togglePostal(String id) {
    if (widget.disabled ||
        widget.postalAreas.any(
          (area) => area.id == id && area.assignedZoneId != null,
        )) {
      return;
    }
    setState(() {
      if (!_postalSelection.add(id)) _postalSelection.remove(id);
    });
  }

  void _applyPostal() {
    _remember();
    final added = [
      for (final area in widget.postalAreas.where(
        (area) =>
            _postalSelection.contains(area.id) && area.assignedZoneId == null,
      ))
        KMapZone(
          id: 'postal-${area.id}',
          name: _postalAreaName(area),
          coordinates: area.coordinates,
          polygons: area.polygons,
          kind: 'postal',
          source: area,
          color: '#155dfc',
          settings: widget.defaultZoneSettings,
        ),
    ];
    if (added.isEmpty) return;
    setState(() {
      _working = [
        ..._working,
        ...added.where(
          (zone) => !_working.any((current) => current.id == zone.id),
        ),
      ];
      _selectedId = added.last.id;
      _stage = 'list';
    });
    _commit();
  }
}

KMapZone? _find(List<KMapZone> zones, String? id) {
  for (final zone in zones) {
    if (zone.id == id) return zone;
  }
  return null;
}

List<KMapZone> _snapshot(List<KMapZone> zones) => List.unmodifiable([
  for (final zone in zones)
    KMapZone(
      id: zone.id,
      name: zone.name,
      color: zone.color,
      kind: zone.kind,
      circle: zone.circle,
      source: zone.source,
      settings: zone.settings,
      coordinates: List.unmodifiable(zone.coordinates),
      polygons: zone.polygons == null
          ? null
          : List.unmodifiable([
              for (final polygon in zone.polygons!)
                KMapPolygon(
                  outer: List.unmodifiable(polygon.outer),
                  holes: List.unmodifiable([
                    for (final hole in polygon.holes)
                      List<KMapCenter>.unmodifiable(hole),
                  ]),
                ),
            ]),
    ),
]);

KMapCenter _center(KMapZone zone) {
  if (zone.circle != null && zone.kind == 'circle') return zone.circle!.center;
  if (zone.coordinates.isEmpty) {
    return const KMapCenter(longitude: 0, latitude: 0);
  }
  return KMapCenter(
    longitude:
        zone.coordinates
            .map((point) => point.longitude)
            .reduce((a, b) => a + b) /
        zone.coordinates.length,
    latitude:
        zone.coordinates
            .map((point) => point.latitude)
            .reduce((a, b) => a + b) /
        zone.coordinates.length,
  );
}

String _key(List<KMapZone> zones) => jsonEncode([
  for (final zone in zones)
    {
      'id': zone.id,
      'name': zone.name,
      'color': zone.color,
      'kind': zone.kind,
      'geometry': [
        for (final polygon in zone.geometry)
          [
            polygon.outer
                .map((point) => [point.longitude, point.latitude])
                .toList(),
            for (final hole in polygon.holes)
              hole.map((point) => [point.longitude, point.latitude]).toList(),
          ],
      ],
      'circle': zone.circle == null
          ? null
          : [
              zone.circle!.center.longitude,
              zone.circle!.center.latitude,
              zone.circle!.radiusKm,
            ],
      'source': zone.source == null
          ? null
          : [
              zone.source!.id,
              zone.source!.country,
              zone.source!.code,
              zone.source!.label,
              zone.source!.sourceVersion,
            ],
      'settings': zone.settings == null
          ? null
          : {
              'travel': zone.settings!.travelCost == null
                  ? null
                  : [
                      zone.settings!.travelCost!.kind,
                      zone.settings!.travelCost!.amount,
                      zone.settings!.travelCost!.currency,
                    ],
              'surcharge': [
                zone.settings!.surcharge,
                zone.settings!.surchargeCurrency,
              ],
              'requestRequired': zone.settings!.requestRequired,
              'workingHours': zone.settings!.workingHours
                  ?.map(
                    (day) => [
                      day.day,
                      day.intervals
                          .map((slot) => [slot.start, slot.end])
                          .toList(),
                    ],
                  )
                  .toList(),
              'availability': zone.settings!.availability == null
                  ? null
                  : [
                      zone.settings!.availability!.kind,
                      zone.settings!.availability!.rrule,
                      zone.settings!.availability!.startDate,
                      zone.settings!.availability!.timeZone,
                      zone.settings!.availability!.from,
                      zone.settings!.availability!.to,
                    ],
            },
    },
]);
