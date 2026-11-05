import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:maplibre/maplibre.dart' as maplibre;
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../actions/k_icon_button.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_text.dart';
import 'k_map_attribution.dart';
import 'k_map_blur.dart';
import 'k_map_controller.dart';
import 'k_map_overlays.dart';
import 'k_map_polygon.dart';
import 'k_map_gesture_surface.dart';

typedef KMapViewChangeCallback = void Function(KMapView view);
typedef KMapOverlayBuilder =
    Widget Function(BuildContext context, KMapController controller);

/// A token-styled MapLibre renderer.
///
/// The host supplies a complete MapLibre style JSON document and must place
/// the map in finite, non-zero constraints. Changing [mapStyle] replaces the
/// active style without recreating the renderer, so the current camera is
/// preserved.
class KMap extends StatefulWidget {
  const KMap({
    required this.mapStyle,
    required this.center,
    this.zoom = 13,
    this.interactive = true,
    this.showZoomControls = true,
    this.label = 'Karte',
    this.onViewChange,
    this.controller,
    this.cameraTransition = Duration.zero,
    this.controlsPadding = const EdgeInsetsDirectional.all(16),
    this.pins = const [],
    this.routes = const [],
    this.zones = const [],
    this.selectedPinId,
    this.selectionControlled = false,
    this.defaultSelectedPinId,
    this.selectedRouteId,
    this.selectedZoneId,
    this.invalidZoneIds = const {},
    this.onPinTap,
    this.onZoneClick,
    this.onMapTap,
    this.zoneFillOpacity = .16,
    this.selectedZoneFillOpacity = .30,
    this.zoneStrokeWidth = 2,
    this.selectedZoneStrokeWidth = 4,
    this.onSelectionChanged,
    this.onPinMove,
    this.pinDrag = const KMapPinDragOptions(),
    this.onPinDragStart,
    this.onPinDrag,
    this.onPinDragEnd,
    this.onPinDragCancel,
    this.pinBuilder,
    this.fitContent = false,
    this.fitContentOnLoad = false,
    this.fitPadding = 64,
    this.fitContentPadding,
    this.overlayBuilder,
    this.blurSigma = 0,
    super.key,
  }) : assert(zoom >= 0 && zoom <= 22),
       assert(fitPadding >= 0),
       assert(zoneFillOpacity >= 0 && zoneFillOpacity <= 1),
       assert(selectedZoneFillOpacity >= 0 && selectedZoneFillOpacity <= 1),
       assert(zoneStrokeWidth > 0),
       assert(selectedZoneStrokeWidth > 0),
       assert(blurSigma >= 0);

  final String mapStyle;
  final KMapCenter center;
  final double zoom;
  final bool interactive;
  final bool showZoomControls;
  final String label;
  final KMapViewChangeCallback? onViewChange;
  final KMapController? controller;
  final Duration cameraTransition;
  final EdgeInsetsDirectional controlsPadding;
  final List<KMapPin> pins;
  final List<KMapRoute> routes;
  final List<KMapZone> zones;
  final String? selectedPinId;
  final bool selectionControlled;
  final String? defaultSelectedPinId;
  final String? selectedRouteId;
  final String? selectedZoneId;
  final Set<String> invalidZoneIds;
  final KMapPinCallback? onPinTap;
  final KMapZoneCallback? onZoneClick;
  final KMapTapCallback? onMapTap;
  final double zoneFillOpacity;
  final double selectedZoneFillOpacity;
  final double zoneStrokeWidth;
  final double selectedZoneStrokeWidth;
  final KMapPinCallback? onSelectionChanged;
  final KMapPinMoveCallback? onPinMove;
  final KMapPinDragOptions pinDrag;
  final KMapPinDragCallback? onPinDragStart;
  final KMapPinDragCallback? onPinDrag;
  final KMapPinDragCallback? onPinDragEnd;
  final KMapPinDragCallback? onPinDragCancel;
  final KMapPinBuilder? pinBuilder;
  final bool fitContent;
  final bool fitContentOnLoad;
  final double fitPadding;
  final EdgeInsets? fitContentPadding;
  final KMapOverlayBuilder? overlayBuilder;

  /// Scoped backdrop blur above this map renderer, including Web platform views.
  final double blurSigma;

  @override
  State<KMap> createState() => _KMapState();
}

enum _KMapStatus { loading, ready, error }

class _KMapState extends State<KMap> {
  final _viewportKey = GlobalKey();
  static const _loadTimeout = Duration(seconds: 20);

  maplibre.MapController? _controller;
  late KMapController _publicController;
  late bool _ownsPublicController;
  Timer? _timeout;
  _KMapStatus _status = _KMapStatus.loading;
  int _attempt = 0;
  late bool _styleValid;
  bool _rendererSyncScheduled = false;
  bool _syncCamera = false;
  bool _syncBlur = false;
  bool _initialFitComplete = false;
  bool _initialFitRunning = false;

  static bool _isValidStyle(String style) {
    try {
      return jsonDecode(style) is Map<String, dynamic>;
    } on FormatException {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _styleValid = _isValidStyle(widget.mapStyle);
    _ownsPublicController = widget.controller == null;
    _publicController = widget.controller ?? KMapController();
    _beginLoading();
  }

  @override
  void didUpdateWidget(covariant KMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapStyle != widget.mapStyle) {
      _styleValid = _isValidStyle(widget.mapStyle);
      _replaceStyle();
    }
    _scheduleRendererSync(
      camera:
          oldWidget.center != widget.center || oldWidget.zoom != widget.zoom,
      blur: oldWidget.blurSigma != widget.blurSigma,
    );
    if (oldWidget.controller != widget.controller) {
      final delegate = _controller;
      if (delegate != null) _publicController.detachDelegate(delegate);
      if (_ownsPublicController) _publicController.dispose();
      _ownsPublicController = widget.controller == null;
      _publicController = widget.controller ?? KMapController();
      if (delegate != null) _publicController.attachDelegate(delegate);
    }
    if (!oldWidget.fitContentOnLoad && widget.fitContentOnLoad) {
      _initialFitComplete = false;
      _scheduleInitialFit();
    }
    final fitInputChanged =
        oldWidget.pins != widget.pins ||
        oldWidget.routes != widget.routes ||
        oldWidget.zones != widget.zones ||
        oldWidget.fitPadding != widget.fitPadding ||
        oldWidget.fitContentPadding != widget.fitContentPadding;
    if (fitInputChanged) {
      if (widget.fitContent) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitContent());
      }
      if (widget.fitContentOnLoad && !_initialFitComplete) {
        _scheduleInitialFit();
      }
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    final delegate = _controller;
    if (delegate != null) {
      applyKMapBlur(delegate, 0);
      releaseKMapRendererResize(delegate);
      _publicController.detachDelegate(delegate);
    }
    if (_ownsPublicController) _publicController.dispose();
    _controller = null;
    super.dispose();
  }

  void _beginLoading() {
    _timeout?.cancel();
    if (!_styleValid) {
      _status = _KMapStatus.error;
      return;
    }
    _status = _KMapStatus.loading;
    _timeout = Timer(_loadTimeout, () {
      if (mounted && _status == _KMapStatus.loading) {
        setState(() => _status = _KMapStatus.error);
      }
    });
  }

  void _onMapCreated(maplibre.MapController controller) {
    _controller = controller;
    _publicController.attachDelegate(controller);
    _scheduleRendererSync(camera: true, blur: true);
    if (mounted) setState(() {});
  }

  void _onStyleLoaded(maplibre.StyleController _) {
    _timeout?.cancel();
    if (mounted && _status != _KMapStatus.ready) {
      setState(() => _status = _KMapStatus.ready);
    }
    if (widget.fitContentOnLoad || widget.fitContent) {
      // A camera sync queued by onMapCreated must not overwrite the one-time
      // content fit after the style becomes ready.
      _syncCamera = false;
      _scheduleRendererSync(blur: true);
      if (widget.fitContentOnLoad && !_initialFitComplete) {
        _scheduleInitialFit();
      } else if (widget.fitContent) {
        unawaited(_fitAfterRendererLayout());
      }
    } else {
      _scheduleRendererSync(camera: true, blur: true);
    }
  }

  Future<void> _fitAfterRendererLayout() async {
    final controller = _controller;
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || controller == null || !identical(_controller, controller)) {
      return;
    }
    requestKMapRendererResize(controller);
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !identical(_controller, controller)) return;
    await _fitContent();
  }

  void _scheduleInitialFit() {
    if (_initialFitComplete || _initialFitRunning) return;
    _initialFitRunning = true;
    unawaited(_fitInitialContentAfterStableLayout());
  }

  Future<void> _fitInitialContentAfterStableLayout() async {
    try {
      final controller = _controller;
      if (_status != _KMapStatus.ready || controller == null) return;
      Size? previousSize;
      var stableFrames = 0;
      var sampledFrames = 0;
      while (mounted && stableFrames < 2 && sampledFrames < 60) {
        sampledFrames += 1;
        WidgetsBinding.instance.scheduleFrame();
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || !identical(_controller, controller)) return;
        final box = _viewportKey.currentContext?.findRenderObject();
        if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return;
        stableFrames = box.size == previousSize ? stableFrames + 1 : 0;
        previousSize = box.size;
      }
      if (stableFrames < 2) return;
      requestKMapRendererResize(controller);
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !identical(_controller, controller)) return;
      _initialFitComplete = await _fitContent(force: true);
    } finally {
      _initialFitRunning = false;
    }
  }

  void _scheduleRendererSync({bool camera = false, bool blur = false}) {
    _syncCamera = _syncCamera || camera;
    _syncBlur = _syncBlur || blur;
    if (_rendererSyncScheduled || (!_syncCamera && !_syncBlur)) return;
    _rendererSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rendererSyncScheduled = false;
      if (!mounted) return;
      final syncCamera = _syncCamera;
      final syncBlur = _syncBlur;
      _syncCamera = false;
      _syncBlur = false;
      final controller = _controller;
      if (syncBlur && controller != null) {
        applyKMapBlur(controller, widget.blurSigma);
      }
      if (syncCamera) {
        unawaited(_moveCamera(center: widget.center, zoom: widget.zoom));
      }
    });
  }

  void _onMapEvent(maplibre.MapEvent event) {
    if (event is maplibre.MapEventClick) {
      final position = KMapCenter(
        longitude: event.point.lon,
        latitude: event.point.lat,
      );
      final zoneId = hitTestKMapZones(widget.zones, position);
      if (zoneId != null && widget.onZoneClick != null) {
        widget.onZoneClick?.call(zoneId);
      } else {
        widget.onMapTap?.call(position);
      }
    }
    if (event is maplibre.MapEventMoveCamera) _publicController.updateView();
    if (event is! maplibre.MapEventCameraIdle) return;
    final view = _publicController.updateView();
    if (view != null) widget.onViewChange?.call(view);
  }

  void _replaceStyle() {
    _beginLoading();
    final controller = _controller;
    if (!_styleValid) {
      _controller = null;
      if (mounted) setState(() {});
      return;
    }
    if (controller == null) {
      _attempt += 1;
      if (mounted) setState(() {});
      return;
    }
    if (mounted) setState(() {});
    try {
      controller.setStyle(widget.mapStyle);
    } on Object {
      _timeout?.cancel();
      if (mounted) setState(() => _status = _KMapStatus.error);
    }
  }

  Future<void> _moveCamera({KMapCenter? center, double? zoom}) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final current = controller.getCamera();
      final centerMatches =
          center == null ||
          ((current.center.lon - center.longitude).abs() <= 1e-8 &&
              (current.center.lat - center.latitude).abs() <= 1e-8);
      final zoomMatches = zoom == null || (current.zoom - zoom).abs() <= 1e-8;
      if (centerMatches && zoomMatches) return;
      final duration = MediaQuery.maybeDisableAnimationsOf(context) ?? false
          ? Duration.zero
          : widget.cameraTransition;
      await _publicController.animateCamera(
        center: center,
        zoom: zoom,
        duration: duration,
      );
    } on Object {
      // The renderer can disappear while an asynchronous camera update runs.
    }
  }

  Future<bool> _fitContent({bool force = false}) async {
    if ((!widget.fitContent && !force) || !_publicController.isReady) {
      return false;
    }
    final coordinates = [
      for (final pin in widget.pins) pin.position,
      for (final route in widget.routes) ...route.coordinates,
      for (final zone in widget.zones)
        for (final polygon in zone.geometry) ...polygon.outer,
    ];
    if (coordinates.isEmpty) return false;
    await _publicController.fitCoordinates(
      coordinates,
      padding: widget.fitContentPadding ?? EdgeInsets.all(widget.fitPadding),
    );
    return _publicController.isReady;
  }

  void _zoomBy(double delta) {
    final controller = _controller;
    if (controller == null) return;
    try {
      final camera = controller.getCamera();
      _moveCamera(zoom: (camera.zoom + delta).clamp(0, 22).toDouble());
    } on Object {
      // The renderer can disappear while a pointer event is being handled.
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (!widget.interactive || event is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (
      resolvedEvent,
    ) {
      if (resolvedEvent is! PointerScrollEvent) return;
      final verticalDelta = resolvedEvent.scrollDelta.dy;
      if (verticalDelta == 0) return;
      final zoomDelta = (-verticalDelta / 240).clamp(-1.0, 1.0);
      _zoomBy(zoomDelta);
    });
  }

  void _retry() {
    _controller = null;
    setState(() {
      _attempt += 1;
      _beginLoading();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final radius = BorderRadius.circular(tokens.radiusCard);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The map can leave the tree before the frame ends (navigation, a
      // rebuilt screen), or its platform view can fail to build (no MapLibre
      // on this platform); its viewport has no render object then.
      final viewport = _viewportKey.currentContext as Element?;
      if (!mounted || viewport == null || viewport.debugIsDefunct) return;
      RenderObject? box;
      try {
        box = viewport.findRenderObject();
      } on FlutterError {
        return; // debug-only assertion for an inactive or failed element
      }
      if (box is RenderBox && box.hasSize) {
        _publicController.viewport = box.localToGlobal(Offset.zero) & box.size;
        if (widget.fitContentOnLoad && !_initialFitComplete) {
          _scheduleInitialFit();
        }
      }
    });
    final surface = Listener(
      key: const ValueKey('k-map-pointer-signals'),
      behavior: HitTestBehavior.opaque,
      onPointerSignal: widget.interactive ? _onPointerSignal : null,
      child: Semantics(
        label: widget.label,
        container: true,
        child: ClipRRect(
          borderRadius: radius,
          child: ColoredBox(
            key: _viewportKey,
            color: tokens.colorSurfaceSubtle,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_styleValid)
                  maplibre.MapLibreMap(
                    key: ValueKey(_attempt),
                    options: maplibre.MapOptions(
                      initStyle: widget.mapStyle,
                      initCenter: maplibre.Geographic(
                        lon: widget.center.longitude,
                        lat: widget.center.latitude,
                      ),
                      initZoom: widget.zoom,
                      gestures: widget.interactive
                          ? const maplibre.MapGestures.all()
                          : const maplibre.MapGestures.none(),
                    ),
                    onMapCreated: _onMapCreated,
                    onStyleLoaded: _onStyleLoaded,
                    onEvent: _onMapEvent,
                    layers: [
                      ...buildKMapZoneLayers(
                        widget.zones,
                        tokens,
                        selectedZoneId: widget.selectedZoneId,
                        fillOpacity: widget.zoneFillOpacity,
                        selectedFillOpacity: widget.selectedZoneFillOpacity,
                        strokeWidth: widget.zoneStrokeWidth,
                        selectedStrokeWidth: widget.selectedZoneStrokeWidth,
                        invalidZoneIds: widget.invalidZoneIds,
                      ),
                      ...buildKMapRouteLayers(
                        widget.routes,
                        tokens,
                        selectedRouteId: widget.selectedRouteId,
                      ),
                    ],
                    children: [
                      KMapOverlays(
                        controller: _publicController,
                        pins: widget.pins,
                        routes: widget.routes,
                        selectedPinId: widget.selectedPinId,
                        selectionControlled: widget.selectionControlled,
                        defaultSelectedPinId: widget.defaultSelectedPinId,
                        selectedRouteId: widget.selectedRouteId,
                        onPinTap: widget.onPinTap,
                        onSelectionChanged: widget.onSelectionChanged,
                        onPinMove: widget.onPinMove,
                        pinDrag: widget.pinDrag,
                        onPinDragStart: widget.onPinDragStart,
                        onPinDrag: widget.onPinDrag,
                        onPinDragEnd: widget.onPinDragEnd,
                        onPinDragCancel: widget.onPinDragCancel,
                        pinBuilder: widget.pinBuilder,
                      ),
                      if (widget.overlayBuilder case final builder?)
                        Builder(
                          builder: (context) =>
                              builder(context, _publicController),
                        ),
                      const KMapAttribution(),
                    ],
                  ),
                if (widget.blurSigma > 0)
                  Positioned.fill(
                    child: KMapNativeBlurOverlay(sigma: widget.blurSigma),
                  ),
                ..._overlays(context, tokens),
              ],
            ),
          ),
        ),
      ),
    );
    return widget.interactive && widget.pins.any((pin) => pin.draggable)
        ? KMapGestureSurface(controller: _publicController, child: surface)
        : surface;
  }

  List<Widget> _overlays(BuildContext context, KDesignTokens tokens) => [
    if (widget.showZoomControls)
      PositionedDirectional(
        top: widget.controlsPadding.top,
        end: widget.controlsPadding.end,
        child: PointerInterceptor(
          child: Semantics(
            label: 'Kartenansicht',
            container: true,
            child: Theme(
              data: Theme.of(context).copyWith(
                extensions: [
                  for (final extension in Theme.of(context).extensions.values)
                    if (extension is! KDesignTokens) extension,
                  tokens.copyWith(
                    colorActionGhostBackground:
                        tokens.colorActionSecondaryBackground,
                    colorActionGhostHover: tokens.colorActionSecondaryHover,
                    colorActionGhostPressed: tokens.colorActionSecondaryPressed,
                    colorActionGhostForeground:
                        tokens.colorActionSecondaryForeground,
                    colorActionGhostBorder: tokens.colorActionSecondaryBorder,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KIconButton(
                    label: 'Vergrößern',
                    icon: KIconName.plus,
                    onPressed: _controller == null ? null : () => _zoomBy(1),
                  ),
                  SizedBox(height: tokens.spaceControlGap),
                  KIconButton(
                    label: 'Verkleinern',
                    icon: KIconName.minus,
                    onPressed: _controller == null ? null : () => _zoomBy(-1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    if (_status != _KMapStatus.ready)
      PositionedDirectional(
        start: tokens.spaceCardPadding,
        bottom: tokens.sizeSwitch,
        child: PointerInterceptor(
          child: Semantics(
            liveRegion: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.colorSurfaceRaised,
                borderRadius: BorderRadius.circular(tokens.radiusCard),
              ),
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceCardPadding),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: tokens.spaceControlGap,
                  runSpacing: tokens.spaceControlGap,
                  children: [
                    KText(
                      _status == _KMapStatus.loading
                          ? 'Karte wird geladen …'
                          : 'Karte konnte nicht geladen werden.',
                    ),
                    if (_status == _KMapStatus.error)
                      KButton(
                        label: 'Erneut versuchen',
                        variant: KButtonVariant.secondary,
                        onPressed: _retry,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
  ];
}
