import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/k_map.dart';
import 'package:k_design_ui/k_map_style.dart';

import 'map_fixture_controls.dart';

const _initialCenter = KMapCenter(longitude: 13.388, latitude: 52.517);

typedef MapFixtureMapBuilder =
    Widget Function({
      required MapFixtureSession session,
      required String style,
      required double height,
      required ValueChanged<KMapView> onViewChange,
    });

class MapFixtureSession {
  KMapCenter center = _initialCenter;
  double zoom = 14;
  bool interactive = true;
  bool showZoomControls = true;
  KMapSettings settings = const KMapSettings();
  final Map<String, Object?> tokenOverrides = {};
  int mapRevision = 0;

  Widget build(BuildContext _) => MapFixture(session: this);

  void reset() {
    center = _initialCenter;
    zoom = 14;
    interactive = true;
    showZoomControls = true;
    settings = const KMapSettings();
    tokenOverrides.clear();
    mapRevision += 1;
  }
}

class MapFixture extends StatefulWidget {
  const MapFixture({required this.session, this.mapBuilder, super.key});

  final MapFixtureSession session;
  final MapFixtureMapBuilder? mapBuilder;

  @override
  State<MapFixture> createState() => _MapFixtureState();
}

class _MapFixtureState extends State<MapFixture> {
  String? _tokenError;

  void _reset() {
    setState(() {
      widget.session.reset();
      _tokenError = null;
    });
  }

  void _setTokenOverride(KMapTokens inherited, String key, String? value) {
    final next = Map<String, Object?>.of(widget.session.tokenOverrides);
    if (value == null || value.trim().isEmpty) {
      next.remove(key);
    } else {
      next[key] = value.trim();
    }
    try {
      inherited.withOverrides(next);
      setState(() {
        widget.session.tokenOverrides
          ..clear()
          ..addAll(next);
        _tokenError = null;
      });
    } on ArgumentError catch (error) {
      setState(() => _tokenError = error.message?.toString() ?? '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final designTokens = Theme.of(context).extension<KDesignTokens>()!;
    final inheritedTokens = KMapTokens.fromTokens(designTokens);
    final effectiveTokens = inheritedTokens.withOverrides(
      widget.session.tokenOverrides,
    );
    final style = jsonEncode(
      createKMapStyle(
        tokens: designTokens,
        settings: widget.session.settings,
        tokenOverrides: widget.session.tokenOverrides,
      ),
    );
    final spacing = designTokens.spaceLayoutGutter;

    return LayoutBuilder(
      builder: (context, viewport) {
        final mapHeight = (viewport.maxHeight * .6).clamp(360.0, 720.0);
        return ColoredBox(
          color: designTokens.colorSurfaceCanvas,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spacing),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: spacing,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: spacing,
                      runSpacing: designTokens.spaceControlGap,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const KText('KMap', variant: KTextVariant.label),
                            KText(
                              'KDS-Kartenstil · Optionen und Token-Overrides.',
                              variant: KTextVariant.bodySmall,
                              style: TextStyle(
                                color: designTokens.colorTextMuted,
                              ),
                            ),
                          ],
                        ),
                        KButton(
                          label: 'Defaults wiederherstellen',
                          variant: KButtonVariant.secondary,
                          onPressed: _reset,
                        ),
                      ],
                    ),
                    _buildMap(style, mapHeight),
                    MapFixtureControls(
                      longitude: widget.session.center.longitude,
                      latitude: widget.session.center.latitude,
                      zoom: widget.session.zoom,
                      interactive: widget.session.interactive,
                      showZoomControls: widget.session.showZoomControls,
                      settings: widget.session.settings,
                      inheritedTokens: inheritedTokens,
                      effectiveTokens: effectiveTokens,
                      tokenOverrides: widget.session.tokenOverrides,
                      tokenError: _tokenError,
                      onLongitudeChanged: (value) => setState(
                        () => widget.session.center = KMapCenter(
                          longitude: value,
                          latitude: widget.session.center.latitude,
                        ),
                      ),
                      onLatitudeChanged: (value) => setState(
                        () => widget.session.center = KMapCenter(
                          longitude: widget.session.center.longitude,
                          latitude: value,
                        ),
                      ),
                      onZoomChanged: (value) =>
                          setState(() => widget.session.zoom = value),
                      onInteractiveChanged: (value) =>
                          setState(() => widget.session.interactive = value),
                      onZoomControlsChanged: (value) => setState(
                        () => widget.session.showZoomControls = value,
                      ),
                      onSettingsChanged: (value) =>
                          setState(() => widget.session.settings = value),
                      onTokenOverrideChanged: (key, value) =>
                          _setTokenOverride(inheritedTokens, key, value),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMap(String style, double height) {
    void updateView(KMapView view) {
      if (view.zoom == widget.session.zoom &&
          view.center == widget.session.center) {
        return;
      }
      setState(() {
        widget.session.center = view.center;
        widget.session.zoom = view.zoom;
      });
    }

    final customBuilder = widget.mapBuilder;
    if (customBuilder != null) {
      return customBuilder(
        session: widget.session,
        style: style,
        height: height,
        onViewChange: updateView,
      );
    }
    return SizedBox(
      height: height,
      child: KMap(
        key: ValueKey(widget.session.mapRevision),
        mapStyle: style,
        center: widget.session.center,
        zoom: widget.session.zoom,
        interactive: widget.session.interactive,
        showZoomControls: widget.session.showZoomControls,
        label: 'Karte von Berlin-Mitte',
        onViewChange: updateView,
      ),
    );
  }
}
