import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:maplibre/maplibre.dart' as maplibre;

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

/// Camera values reported after map movement finishes.
@immutable
class KMapView {
  const KMapView({required this.center, required this.zoom});

  final KMapCenter center;
  final double zoom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KMapView && center == other.center && zoom == other.zoom;

  @override
  int get hashCode => Object.hash(center, zoom);
}

/// Host-facing camera and projection controller for [KMap].
///
/// Projection methods return null until the renderer is ready or after it has
/// been disposed. One controller must only be attached to one map at a time.
class KMapController extends ChangeNotifier {
  maplibre.MapController? _delegate;
  KMapView? _view;

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
      nativeDuration: duration,
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
    _view = KMapView(
      center: KMapCenter(
        longitude: camera.center.lon,
        latitude: camera.center.lat,
      ),
      zoom: camera.zoom,
    );
    return _view;
  }
}

maplibre.Geographic _geographic(KMapCenter position) =>
    maplibre.Geographic(lon: position.longitude, lat: position.latitude);

KMapCenter _center(maplibre.Geographic position) =>
    KMapCenter(longitude: position.lon, latitude: position.lat);
