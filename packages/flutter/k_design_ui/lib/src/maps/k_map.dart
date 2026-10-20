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
    this.selectedPinId,
    this.selectionControlled = false,
    this.defaultSelectedPinId,
    this.selectedRouteId,
    this.onPinTap,
    this.onSelectionChanged,
    this.onPinMove,
    this.pinDrag = const KMapPinDragOptions(),
    this.onPinDragStart,
    this.onPinDrag,
    this.onPinDragEnd,
    this.pinBuilder,
    this.fitContent = false,
    this.fitPadding = 64,
    this.overlayBuilder,
    this.blurSigma = 0,
    super.key,
  }) : assert(zoom >= 0 && zoom <= 22),
       assert(fitPadding >= 0),
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
  final String? selectedPinId;
  final bool selectionControlled;
  final String? defaultSelectedPinId;
  final String? selectedRouteId;
  final KMapPinCallback? onPinTap;
  final KMapPinCallback? onSelectionChanged;
  final KMapPinMoveCallback? onPinMove;
  final KMapPinDragOptions pinDrag;
  final KMapPinDragCallback? onPinDragStart;
  final KMapPinDragCallback? onPinDrag;
  final KMapPinDragCallback? onPinDragEnd;
  final KMapPinBuilder? pinBuilder;
  final bool fitContent;
  final double fitPadding;
  final KMapOverlayBuilder? overlayBuilder;

  /// Scoped backdrop blur above this map renderer, including Web platform views.
  final double blurSigma;

  @override
  State<KMap> createState() => _KMapState();
}

enum _KMapStatus { loading, ready, error }

class _KMapState extends State<KMap> {
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
    if (widget.fitContent &&
        (oldWidget.pins != widget.pins ||
            oldWidget.routes != widget.routes ||
            oldWidget.fitPadding != widget.fitPadding)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitContent());
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    final delegate = _controller;
    if (delegate != null) {
      applyKMapBlur(delegate, 0);
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
    _scheduleRendererSync(camera: true, blur: true);
    _fitContent();
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

  Future<void> _fitContent() async {
    if (!widget.fitContent || !_publicController.isReady) return;
    await _publicController.fitCoordinates([
      for (final pin in widget.pins) pin.position,
      for (final route in widget.routes) ...route.coordinates,
    ], padding: EdgeInsets.all(widget.fitPadding));
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

    return Listener(
      key: const ValueKey('k-map-pointer-signals'),
      behavior: HitTestBehavior.opaque,
      onPointerSignal: widget.interactive ? _onPointerSignal : null,
      child: Semantics(
        label: widget.label,
        container: true,
        child: ClipRRect(
          borderRadius: radius,
          child: ColoredBox(
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
                    layers: buildKMapRouteLayers(
                      widget.routes,
                      tokens,
                      selectedRouteId: widget.selectedRouteId,
                    ),
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
