import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:maplibre/maplibre.dart' as maplibre;
import 'k_map_blur.dart' show waitForKMapRendererResize;

/// A longitude/latitude pair used by [KMapController].
@immutable
class KMapCenter {
  const KMapCenter({required this.longitude, required this.latitude})
    : assert(longitude >= -180 && longitude <= 180),
      assert(latitude >= -90 && latitude <= 90);

  final double longitude;
  final double latitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KMapCenter &&
          longitude == other.longitude &&
          latitude == other.latitude;

  @override
  int get hashCode => Object.hash(longitude, latitude);
}

/// Visible geographic extent of a map viewport.
@immutable
class KMapBounds {
  const KMapBounds({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  final double west;
  final double south;
  final double east;
  final double north;

  List<double> toList() => [west, south, east, north];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KMapBounds &&
          west == other.west &&
          south == other.south &&
          east == other.east &&
          north == other.north;

  @override
  int get hashCode => Object.hash(west, south, east, north);
}

/// Camera values reported after map movement finishes.
@immutable
class KMapView {
  const KMapView({required this.center, required this.zoom, this.bounds});

  final KMapCenter center;
  final double zoom;
  final KMapBounds? bounds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KMapView &&
          center == other.center &&
          zoom == other.zoom &&
          bounds == other.bounds;

  @override
  int get hashCode => Object.hash(center, zoom, bounds);
}

/// Host-facing camera and projection controller for [KMap].
///
/// Projection methods return null until the renderer is ready or after it has
/// been disposed. One controller must only be attached to one map at a time.
class KMapController extends ChangeNotifier {
  maplibre.MapController? _delegate;
  KMapView? _view;

  /// Logical-pixel viewport in global Flutter coordinates for drag anchoring.
  @internal
  Rect? viewport;

  bool get isReady => _delegate != null;
  KMapView? get view => _view;

  Offset? toScreenOffset(KMapCenter position) {
    final delegate = _delegate;
    if (delegate == null) return null;
    return delegate.toScreenLocation(_geographic(position));
  }

  KMapCenter? toMapCenter(Offset offset) {
    final delegate = _delegate;
    if (delegate == null) return null;
    final result = delegate.toLngLat(offset);
    return KMapCenter(longitude: result.lon, latitude: result.lat);
  }

  Future<void> moveCamera({KMapCenter? center, double? zoom}) async {
    final delegate = _delegate;
    if (delegate == null) return;
    await delegate.moveCamera(
      center: center == null ? null : _geographic(center),
      zoom: zoom,
    );
  }

  Future<void> animateCamera({
    KMapCenter? center,
    double? zoom,
    Duration duration = Duration.zero,
  }) async {
    final delegate = _delegate;
    if (delegate == null) return;
    if (duration == Duration.zero) {
      await moveCamera(center: center, zoom: zoom);
      return;
    }
    await delegate.animateCamera(
      center: center == null ? null : _geographic(center),
      zoom: zoom,
      nativeDuration: duration,
      webMaxDuration: duration,
    );
  }

  Future<void> fitCoordinates(
    Iterable<KMapCenter> coordinates, {
    EdgeInsets padding = EdgeInsets.zero,
    Duration duration = Duration.zero,
    double maxZoom = 16,
  }) async {
    final delegate = _delegate;
    final points = coordinates.map(_geographic).toList(growable: false);
    if (delegate == null || points.isEmpty) return;
    if (kIsWeb) {
      // HtmlElementView attaches after Flutter layout. endOfFrame requests the
      // next frame itself, unlike registering a second postframe callback.
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
      if (!identical(_delegate, delegate)) return;
      await waitForKMapRendererResize(delegate);
      if (!identical(_delegate, delegate)) return;
    }
    if (points.length == 1) {
      await animateCamera(
        center: _center(points.single),
        zoom: maxZoom,
        duration: duration,
      );
      return;
    }
    await delegate.fitBounds(
      bounds: maplibre.LngLatBounds.fromPoints(points),
      padding: padding,
      // Android MapLibre rejects a zero millisecond native camera animation.
      // Keep reduced-motion fits effectively immediate while supplying the
      // positive duration required by the native API.
      nativeDuration: duration == Duration.zero
          ? const Duration(milliseconds: 1)
          : duration,
      webMaxDuration: duration,
      webMaxZoom: maxZoom,
    );
  }

  @internal
  void attachDelegate(maplibre.MapController delegate) {
    if (identical(_delegate, delegate)) return;
    _delegate = delegate;
    updateView();
    notifyListeners();
  }

  @internal
  void detachDelegate(maplibre.MapController delegate) {
    if (!identical(_delegate, delegate)) return;
    _delegate = null;
    notifyListeners();
  }

  @internal
  KMapView? updateView() {
    final delegate = _delegate;
    if (delegate == null) return _view;
    final camera = delegate.getCamera();
    final visible = delegate.getVisibleRegion();
    _view = KMapView(
      center: KMapCenter(
        longitude: camera.center.lon,
        latitude: camera.center.lat,
      ),
      zoom: camera.zoom,
      bounds: KMapBounds(
        west: visible.longitudeWest,
        south: visible.latitudeSouth,
        east: visible.longitudeEast,
        north: visible.latitudeNorth,
      ),
    );
    notifyListeners();
    return _view;
  }
}

maplibre.Geographic _geographic(KMapCenter position) =>
    maplibre.Geographic(lon: position.longitude, lat: position.latitude);

KMapCenter _center(maplibre.Geographic position) =>
    KMapCenter(longitude: position.lon, latitude: position.lat);
