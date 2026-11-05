import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../forms/k_input.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_leading.dart';
import '../primitives/k_surface.dart';
import '../primitives/k_text.dart';
import 'k_map.dart';
import 'k_map_controller.dart';
import 'k_map_location_picker_models.dart';
import 'k_map_overlays.dart';

part 'k_map_location_picker_views.dart';
part 'k_map_location_picker_marker.dart';

enum _PickerPanel { choice, search, closed }

/// Visual treatment applied around the location picker's marker content.
enum KMapLocationPickerMarkerAppearance {
  /// The token-styled circular surface used by default.
  defaultStyle,

  /// Renders the marker content without a forced surface, border, or shadow.
  bare,
}

/// A provider-neutral map location picker with consumer-owned async callbacks.
class KMapLocationPicker extends StatefulWidget {
  const KMapLocationPicker({
    required this.mapStyle,
    required this.center,
    required this.onSearch,
    this.zoom = 13,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.onLocate,
    this.onReverseGeocode,
    this.onConfirm,
    this.labels = const KMapLocationPickerLabels(),
    this.leading,
    this.overlayInsets = EdgeInsets.zero,
    this.onPanelOpenChanged,
    this.hint,
    this.marker,
    this.markerAppearance = KMapLocationPickerMarkerAppearance.defaultStyle,
    this.transitionDuration,
    this.searchDebounce,
    this.blur = 8,
    this.selectedZoom = 16,
    this.bounce = true,
    this.reducedMotion,
    this.mapController,
    this.pinDrag = const KMapPinDragOptions(),
    this.mapLabel = 'Karte zur Ortsauswahl',
    super.key,
  }) : assert(zoom >= 0 && zoom <= 22),
       assert(selectedZoom >= 0 && selectedZoom <= 22),
       assert(blur >= 0);

  final String mapStyle;
  final KMapCenter center;
  final double zoom;
  final KMapLocation? value;
  final KMapLocation? defaultValue;
  final ValueChanged<KMapLocation>? onChanged;
  final KMapLocationSearch onSearch;
  final KMapCurrentLocation? onLocate;
  final KMapReverseGeocoder? onReverseGeocode;
  final ValueChanged<KMapLocation>? onConfirm;
  final KMapLocationPickerLabels labels;
  final Widget? leading;

  /// Space reserved for host header and wizard overlays; map remains full size.
  final EdgeInsets overlayInsets;
  final ValueChanged<bool>? onPanelOpenChanged;
  final Widget? hint;

  /// Optional visual content rendered inside the draggable map marker.
  final Widget? marker;

  /// Whether the marker content receives the default circular decoration.
  final KMapLocationPickerMarkerAppearance markerAppearance;

  /// Camera and blur duration. Defaults to the theme's 700 ms spinner motion.
  final Duration? transitionDuration;

  /// Search delay. Defaults to responsive plus entry motion (250 ms).
  final Duration? searchDebounce;
  final double blur;
  final double selectedZoom;
  final bool bounce;

  /// Overrides the ambient platform accessibility preference when non-null.
  final bool? reducedMotion;
  final KMapController? mapController;
  final KMapPinDragOptions pinDrag;
  final String mapLabel;

  @override
  State<KMapLocationPicker> createState() => _KMapLocationPickerState();
}

class _KMapLocationPickerState extends State<KMapLocationPicker> {
  late KMapLocation? _localValue;
  late KMapCenter _cameraCenter;
  late double _cameraZoom;
  late _PickerPanel _panel;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _pillFocus = FocusNode();
  Timer? _searchTimer;
  Timer? _arrivalTimer;
  Timer? _hintTimer;
  List<KMapLocation> _results = const [];
  bool? _reportedOpen;
  bool _searchBusy = false;
  bool _operationBusy = false;
  bool _error = false;
  bool _arrived = false;
  bool _showHint = false;
  bool _selectionWasAdjusted = false;
  int _searchGeneration = 0;
  int _operationGeneration = 0;
  int _arrival = 0;

  KMapLocation? get _location => widget.value ?? _localValue;
  bool get _open => _panel != _PickerPanel.closed;
  bool _reducedMotion(BuildContext context) =>
      widget.reducedMotion ?? MediaQuery.disableAnimationsOf(context);
  Duration _duration(BuildContext context) {
    if (_reducedMotion(context)) return Duration.zero;
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return widget.transitionDuration ?? tokens.motionSpinner;
  }

  @override
  void initState() {
    super.initState();
    _validateConfiguration();
    _localValue = widget.defaultValue;
    _cameraCenter = _location?.position ?? widget.center;
    _cameraZoom = _location == null ? widget.zoom : widget.selectedZoom;
    _panel = _location == null ? _PickerPanel.choice : _PickerPanel.closed;
    _arrived = _location != null;
    _showHint = _location != null;
  }

  @override
  void didUpdateWidget(covariant KMapLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _validateConfiguration();
    if (widget.value != oldWidget.value &&
        widget.value != null &&
        widget.value != _localValue) {
      _localValue = widget.value;
      _cameraCenter = widget.value!.position;
      _cameraZoom = widget.selectedZoom;
      _selectionWasAdjusted = false;
      _panel = _PickerPanel.closed;
      _beginArrival();
    }
  }

  void _validateConfiguration() {
    if (!widget.blur.isFinite || widget.blur < 0) {
      throw ArgumentError.value(
        widget.blur,
        'blur',
        'Must be finite and nonnegative',
      );
    }
    if (widget.transitionDuration?.isNegative ?? false) {
      throw ArgumentError.value(
        widget.transitionDuration,
        'transitionDuration',
        'Must be nonnegative',
      );
    }
    if (widget.searchDebounce?.isNegative ?? false) {
      throw ArgumentError.value(
        widget.searchDebounce,
        'searchDebounce',
        'Must be nonnegative',
      );
    }
  }

  @override
  void dispose() {
    _searchGeneration++;
    _operationGeneration++;
    _searchTimer?.cancel();
    _arrivalTimer?.cancel();
    _hintTimer?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _pillFocus.dispose();
    super.dispose();
  }

  void _update(KMapLocation next) {
    setState(() => _localValue = next);
    widget.onChanged?.call(next);
  }

  void _choose(KMapLocation next) {
    _operationGeneration++;
    _selectionWasAdjusted = false;
    _error = false;
    _operationBusy = false;
    _update(next);
    setState(() {
      _cameraCenter = next.position;
      _cameraZoom = widget.selectedZoom;
      _panel = _PickerPanel.closed;
      _arrival++;
    });
    _beginArrival();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pillFocus.requestFocus();
    });
  }

  void _beginArrival() {
    _arrivalTimer?.cancel();
    _hintTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _arrived = false;
      _showHint = false;
    });
    final duration = _duration(context);
    _arrivalTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() => _arrived = true);
      final tokens = Theme.of(context).extension<KDesignTokens>()!;
      final bounceDelay = _reducedMotion(context) || !widget.bounce
          ? Duration.zero
          : tokens.motionEmphasis + tokens.motionStandard;
      _hintTimer = Timer(bounceDelay, () {
        if (mounted) setState(() => _showHint = true);
      });
    });
  }

  void _openSearch() {
    _operationGeneration++;
    _operationBusy = false;
    _error = false;
    final location = _location;
    if (!_selectionWasAdjusted && location != null) {
      _searchController.text = location.label;
    }
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
    setState(() => _panel = _PickerPanel.search);
    _queueSearch(_searchController.text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocus.requestFocus();
      _searchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchController.text.length,
      );
    });
  }

  void _showChoice() => setState(() => _panel = _PickerPanel.choice);

  void _closePanel() => setState(() => _panel = _PickerPanel.closed);

  void _queueSearch(String rawQuery) {
    _searchTimer?.cancel();
    final generation = ++_searchGeneration;
    final query = rawQuery.trim();
    setState(() {
      _error = false;
      _results = const [];
      _searchBusy = query.length >= 2;
    });
    if (query.length < 2) return;
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final debounce =
        widget.searchDebounce ?? tokens.motionResponsive + tokens.motionEntry;
    _searchTimer = Timer(debounce, () async {
      try {
        final results = await widget.onSearch(query);
        if (!mounted || generation != _searchGeneration) return;
        setState(() => _results = List.unmodifiable(results));
      } on Object {
        if (!mounted || generation != _searchGeneration) return;
        setState(() => _error = true);
      } finally {
        if (mounted && generation == _searchGeneration) {
          setState(() => _searchBusy = false);
        }
      }
    });
  }

  Future<void> _locate() async {
    final locate = widget.onLocate;
    if (locate == null) return;
    final generation = ++_operationGeneration;
    setState(() {
      _operationBusy = true;
      _error = false;
    });
    try {
      final next = await locate();
      if (mounted && generation == _operationGeneration) _choose(next);
    } on Object {
      if (mounted && generation == _operationGeneration) {
        setState(() => _error = true);
      }
    } finally {
      if (mounted && generation == _operationGeneration) {
        setState(() => _operationBusy = false);
      }
    }
  }

  Future<bool> _movePin(KMapCenter position) async {
    final generation = ++_operationGeneration;
    final reverse = widget.onReverseGeocode;
    _selectionWasAdjusted = true;
    setState(() {
      _operationBusy = reverse != null;
      _error = false;
    });
    _update(
      KMapLocation(
        id: 'adjusted',
        label: widget.labels.adjusted,
        position: position,
      ),
    );
    if (reverse != null) {
      unawaited(() async {
        try {
          final resolved = await reverse(position);
          if (!mounted || generation != _operationGeneration) return;
          _update(resolved.copyWith(position: position));
        } on Object {
          if (mounted && generation == _operationGeneration) {
            setState(() => _error = true);
          }
        } finally {
          if (mounted && generation == _operationGeneration) {
            setState(() => _operationBusy = false);
          }
        }
      }());
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final duration = _duration(context);
    final location = _location;
    if (_reportedOpen != _open) {
      _reportedOpen = _open;
      final open = _open;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPanelOpenChanged?.call(open);
      });
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusCard),
      child: ColoredBox(
        color: tokens.colorSurfaceSubtle,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: _open ? widget.blur : 0),
              duration: duration,
              builder: (context, blur, child) => AbsorbPointer(
                absorbing: _open,
                child: _buildMap(location, duration, blur),
              ),
            ),
            IgnorePointer(
              child: AnimatedContainer(
                duration: duration,
                color: _open
                    ? tokens.colorSurfaceSubtle.withValues(
                        alpha:
                            tokens.opacityGlassLiquid + tokens.opacityPreview,
                      )
                    : Colors.transparent,
              ),
            ),
            Padding(
              padding: widget.overlayInsets,
              child: _buildPanel(context, tokens, location),
            ),
            if (!_open && _showHint && location != null)
              _buildHint(tokens, duration, location),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(KMapLocation? location, Duration duration, double blur) =>
      KMap(
        mapStyle: widget.mapStyle,
        center: _cameraCenter,
        zoom: _cameraZoom,
        interactive: !_open,
        showZoomControls: !_open,
        label: widget.mapLabel,
        blurSigma: blur,
        controller: widget.mapController,
        cameraTransition: duration,
        pins: location != null && !_open && _arrived
            ? [
                KMapPin(
                  id: 'location',
                  label: location.label,
                  position: location.position,
                  size: 44,
                  draggable: true,
                  child:
                      widget.marker == null &&
                          widget.markerAppearance ==
                              KMapLocationPickerMarkerAppearance.defaultStyle
                      ? _LandingMarker(
                          key: ValueKey(_arrival),
                          animate: widget.bounce && !_reducedMotion(context),
                        )
                      : _PickerLandingMarker(
                          key: ValueKey(_arrival),
                          animate: widget.bounce && !_reducedMotion(context),
                          appearance: widget.markerAppearance,
                          child: widget.marker,
                        ),
                ),
              ]
            : const [],
        pinDrag: widget.pinDrag,
        onPinMove: (event) => _movePin(event.position),
      );

  Widget _buildPanel(
    BuildContext context,
    KDesignTokens tokens,
    KMapLocation? location,
  ) => AnimatedAlign(
    duration: _reducedMotion(context)
        ? Duration.zero
        : tokens.motion(KMotionRole.control).settle,
    curve: tokens.motion(KMotionRole.control).curve,
    alignment: _open ? Alignment.center : Alignment.topCenter,
    child: SafeArea(
      minimum: EdgeInsets.all(tokens.spaceHairline * 20),
      child: LayoutBuilder(
        builder: (context, constraints) => PointerInterceptor(
          child: AnimatedContainer(
            duration: _reducedMotion(context)
                ? Duration.zero
                : tokens.motion(KMotionRole.control).settle,
            curve: tokens.motion(KMotionRole.control).curve,
            width: _open
                ? math.min(constraints.maxWidth, 420)
                : math.min(math.max(0, constraints.maxWidth - 60), 460),
            child: KSurface(
              border: KSurfaceBorder.none,
              radius: _open ? KSurfaceRadius.card : KSurfaceRadius.full,
              elevation: KSurfaceElevation.medium,
              child: AnimatedSwitcher(
                duration: _reducedMotion(context)
                    ? Duration.zero
                    : tokens.motionResponsive + tokens.motionFast,
                child: switch (_panel) {
                  _PickerPanel.choice => _buildChoice(tokens, location),
                  _PickerPanel.search => _buildSearch(tokens),
                  _PickerPanel.closed => _buildPill(tokens, location!),
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PickerLandingMarker extends StatefulWidget {
  const _PickerLandingMarker({
    required this.animate,
    required this.appearance,
    this.child,
    super.key,
  });

  final bool animate;
  final KMapLocationPickerMarkerAppearance appearance;
  final Widget? child;

  @override
  State<_PickerLandingMarker> createState() => _PickerLandingMarkerState();
}

class _PickerLandingMarkerState extends State<_PickerLandingMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this, value: 1);
    if (widget.animate) {
      _controller.value = 0;
      _controller.animateWith(
        SpringSimulation(
          const SpringDescription(mass: 1, stiffness: 350, damping: 18),
          0,
          1,
          0,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final content = KeyedSubtree(
      key: const ValueKey('k-map-location-marker-content'),
      child: widget.child ?? const KIcon(KIconName.mapPin, size: 32),
    );
    final marker = switch (widget.appearance) {
      KMapLocationPickerMarkerAppearance.defaultStyle => DecoratedBox(
        key: const ValueKey('k-map-location-marker-decoration'),
        decoration: BoxDecoration(
          color: tokens.colorSurfaceRaised,
          border: Border.all(
            color: tokens.colorBrandPrimaryAccent,
            width: tokens.borderWidthStrong,
          ),
          borderRadius: BorderRadius.circular(tokens.radiusFull),
          boxShadow: tokens.elevationMedium,
        ),
        child: SizedBox.square(
          dimension: tokens.spaceHairline * 44,
          child: Center(child: content),
        ),
      ),
      KMapLocationPickerMarkerAppearance.bare => content,
    };
    if (!widget.animate) return marker;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, -20 * (1 - value)),
            child: Transform.scale(scale: .8 + .2 * value, child: child),
          ),
        );
      },
      child: marker,
    );
  }
}
