import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_surface.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';

/// Coordinates define the fixed OSM embed; the host supplies its platform player.
class KPresentationMap extends StatefulWidget {
  const KPresentationMap({
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.onOpen,
    required this.mapBuilder,
    this.description,
    super.key,
  });
  final String title;
  final double latitude, longitude;
  final String? description;
  final VoidCallback onOpen;
  final Widget Function(BuildContext context, String embedUrl) mapBuilder;
  static Uri target(double latitude, double longitude) => Uri.https(
    'www.openstreetmap.org',
    '/',
    {'mlat': '$latitude', 'mlon': '$longitude'},
  ).replace(fragment: 'map=14/$latitude/$longitude');
  static Uri embed(
    double latitude,
    double longitude,
  ) => Uri.https('www.openstreetmap.org', '/export/embed.html', {
    'bbox':
        '${(longitude - .02).clamp(-180, 180)},${(latitude - .01).clamp(-90, 90)},${(longitude + .02).clamp(-180, 180)},${(latitude + .01).clamp(-90, 90)}',
    'layer': 'mapnik',
    'marker': '$latitude,$longitude',
  });
  @override
  State<KPresentationMap> createState() => _KPresentationMapState();
}

class _KPresentationMapState extends State<KPresentationMap> {
  bool _loaded = false;
  @override
  void didUpdateWidget(KPresentationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _loaded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final valid =
        widget.latitude.isFinite &&
        widget.longitude.isFinite &&
        widget.latitude.abs() <= 90 &&
        widget.longitude.abs() <= 180;
    return KSurface(
      radius: KSurfaceRadius.card,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontFamily: tokens.fontFamily,
                fontSize: tokens.fontHeading4Size,
              ),
            ),
            if (widget.description != null) Text(widget.description!),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: valid && _loaded
                  ? widget.mapBuilder(
                      context,
                      KPresentationMap.embed(
                        widget.latitude,
                        widget.longitude,
                      ).toString(),
                    )
                  : Center(
                      child: KButton(
                        label: valid ? 'Karte laden' : 'Karte nicht verfügbar',
                        leading: const KIcon(KIconName.mapPin),
                        onPressed: valid
                            ? () => setState(() => _loaded = true)
                            : null,
                      ),
                    ),
            ),
            KButton(
              label: 'In OpenStreetMap öffnen',
              variant: KButtonVariant.ghost,
              onPressed: valid ? widget.onOpen : null,
            ),
            Text(
              '© OpenStreetMap contributors',
              style: TextStyle(
                color: tokens.colorTextMuted,
                fontSize: tokens.fontBodySmallSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
