import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/k_map_style.dart';

import 'map_fixture_coordinate_input.dart';

typedef TokenOverrideChanged = void Function(String key, String? value);

class MapFixtureControls extends StatelessWidget {
  const MapFixtureControls({
    required this.zoom,
    required this.longitude,
    required this.latitude,
    required this.interactive,
    required this.showZoomControls,
    required this.settings,
    required this.inheritedTokens,
    required this.effectiveTokens,
    required this.tokenOverrides,
    required this.onZoomChanged,
    required this.onLongitudeChanged,
    required this.onLatitudeChanged,
    required this.onInteractiveChanged,
    required this.onZoomControlsChanged,
    required this.onSettingsChanged,
    required this.onTokenOverrideChanged,
    this.tokenError,
    super.key,
  });

  final double zoom;
  final double longitude;
  final double latitude;
  final bool interactive;
  final bool showZoomControls;
  final KMapSettings settings;
  final KMapTokens inheritedTokens;
  final KMapTokens effectiveTokens;
  final Map<String, Object?> tokenOverrides;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<double> onLongitudeChanged;
  final ValueChanged<double> onLatitudeChanged;
  final ValueChanged<bool> onInteractiveChanged;
  final ValueChanged<bool> onZoomControlsChanged;
  final ValueChanged<KMapSettings> onSettingsChanged;
  final TokenOverrideChanged onTokenOverrideChanged;
  final String? tokenError;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spaceControlGap,
      children: [
        KDisclosure(
          title: 'Kartenoptionen',
          child: _SettingsControls(
            zoom: zoom,
            longitude: longitude,
            latitude: latitude,
            interactive: interactive,
            showZoomControls: showZoomControls,
            settings: settings,
            onZoomChanged: onZoomChanged,
            onLongitudeChanged: onLongitudeChanged,
            onLatitudeChanged: onLatitudeChanged,
            onInteractiveChanged: onInteractiveChanged,
            onZoomControlsChanged: onZoomControlsChanged,
            onSettingsChanged: onSettingsChanged,
          ),
        ),
        KDisclosure(
          title: 'Token-Namen, Vererbung und aktuelle Werte',
          child: Padding(
            padding: EdgeInsets.only(top: tokens.spaceControlGap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.spaceControlGap,
              children: [
                const KText(
                  'Leere Overrides erben den aktuellen KDS-Theme-Wert. '
                  'Die Kartenschrift verwendet vorerst Noto Sans, da die '
                  'eingebundene Glyphenquelle keine Inter-Glyphen bereitstellt.',
                  variant: KTextVariant.bodySmall,
                ),
                if (tokenError != null)
                  Semantics(
                    liveRegion: true,
                    child: KText(
                      tokenError!,
                      variant: KTextVariant.bodySmall,
                      style: TextStyle(
                        color: Theme.of(context)
                            .extension<KDesignTokens>()!
                            .colorStatusErrorForeground,
                      ),
                    ),
                  ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1040,
                    child: Column(
                      children: [
                        const _TokenHeader(),
                        for (final metadata in kMapTokenMetadata)
                          _TokenRow(
                            metadata: metadata,
                            inherited: metadata.valueFrom(inheritedTokens),
                            effective: metadata.valueFrom(effectiveTokens),
                            overrideValue: tokenOverrides[metadata.key],
                            onChanged: (value) =>
                                onTokenOverrideChanged(metadata.key, value),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsControls extends StatelessWidget {
  const _SettingsControls({
    required this.zoom,
    required this.longitude,
    required this.latitude,
    required this.interactive,
    required this.showZoomControls,
    required this.settings,
    required this.onZoomChanged,
    required this.onLongitudeChanged,
    required this.onLatitudeChanged,
    required this.onInteractiveChanged,
    required this.onZoomControlsChanged,
    required this.onSettingsChanged,
  });

  final double zoom;
  final double longitude;
  final double latitude;
  final bool interactive;
  final bool showZoomControls;
  final KMapSettings settings;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<double> onLongitudeChanged;
  final ValueChanged<double> onLatitudeChanged;
  final ValueChanged<bool> onInteractiveChanged;
  final ValueChanged<bool> onZoomControlsChanged;
  final ValueChanged<KMapSettings> onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final controlWidth = constraints.maxWidth.clamp(0.0, 300.0);
        return Padding(
          padding: EdgeInsets.only(top: tokens.spaceControlGap),
          child: Wrap(
            spacing: tokens.spaceCardPadding,
            runSpacing: tokens.spaceControlGap,
            children: [
              SizedBox(
                width: controlWidth,
                child: MapCoordinateInput(
                  label: 'Längengrad',
                  value: longitude,
                  min: -180,
                  max: 180,
                  onChanged: onLongitudeChanged,
                ),
              ),
              SizedBox(
                width: controlWidth,
                child: MapCoordinateInput(
                  label: 'Breitengrad',
                  value: latitude,
                  min: -90,
                  max: 90,
                  onChanged: onLatitudeChanged,
                ),
              ),
              SizedBox(
                width: controlWidth,
                child: KSlider(
                  label: 'Zoom',
                  value: zoom.clamp(3, 19),
                  min: 3,
                  max: 19,
                  divisions: 32,
                  valueLabel: _numberLabel,
                  onChanged: onZoomChanged,
                ),
              ),
              SizedBox(
                width: controlWidth,
                child: KSwitch(
                  label: 'Interaktiv',
                  value: interactive,
                  onChanged: onInteractiveChanged,
                ),
              ),
              SizedBox(
                width: controlWidth,
                child: KSwitch(
                  label: 'Zoom-Steuerung anzeigen',
                  value: showZoomControls,
                  onChanged: onZoomControlsChanged,
                ),
              ),
              for (final metadata in kMapSettingsMetadata)
                SizedBox(width: controlWidth, child: _settingControl(metadata)),
            ],
          ),
        );
      },
    );
  }

  Widget _settingControl(KMapSettingMetadata metadata) {
    final value = settings.toMap()[metadata.key]!;
    return switch (metadata.type) {
      KMapSettingType.toggle => KSwitch(
        label: metadata.label,
        value: value as bool,
        onChanged: (next) =>
            onSettingsChanged(_copySetting(settings, metadata.key, next)),
      ),
      KMapSettingType.range => KSlider(
        label: metadata.label,
        value: value as double,
        min: metadata.min!,
        max: metadata.max!,
        divisions: ((metadata.max! - metadata.min!) / metadata.step!).round(),
        valueLabel: _numberLabel,
        onChanged: (next) =>
            onSettingsChanged(_copySetting(settings, metadata.key, next)),
      ),
      KMapSettingType.select => KField(
        label: metadata.label,
        helperText: metadata.description,
        child: KSelect(
          value: value as String,
          options: [
            for (final option in metadata.options)
              KSelectOption(value: option, label: option),
          ],
          onChanged: (next) {
            if (next != null) {
              onSettingsChanged(_copySetting(settings, metadata.key, next));
            }
          },
        ),
      ),
    };
  }
}

class _TokenHeader extends StatelessWidget {
  const _TokenHeader();

  @override
  Widget build(BuildContext context) => const _TokenColumns(
    token: KText('Token', variant: KTextVariant.label),
    inherited: KText('KDS-Default im Theme', variant: KTextVariant.label),
    effective: KText('Wirksamer Wert', variant: KTextVariant.label),
    source: KText('Vererbung', variant: KTextVariant.label),
    editor: KText('Override', variant: KTextVariant.label),
  );
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({
    required this.metadata,
    required this.inherited,
    required this.effective,
    required this.overrideValue,
    required this.onChanged,
  });

  final KMapTokenMetadata metadata;
  final Object inherited;
  final Object effective;
  final Object? overrideValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => _TokenColumns(
    token: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KText(metadata.tokenName, variant: KTextVariant.label),
        KText(metadata.key, variant: KTextVariant.caption),
      ],
    ),
    inherited: KText(_display(inherited), variant: KTextVariant.bodySmall),
    effective: KText(_display(effective), variant: KTextVariant.bodySmall),
    source: KText(
      overrideValue == null ? 'Geerbt' : 'Override',
      variant: KTextVariant.bodySmall,
    ),
    editor: _TokenOverrideEditor(
      tokenKey: metadata.key,
      overrideValue: overrideValue,
      inherited: inherited,
      onChanged: onChanged,
    ),
  );
}

class _TokenColumns extends StatelessWidget {
  const _TokenColumns({
    required this.token,
    required this.inherited,
    required this.effective,
    required this.source,
    required this.editor,
  });

  final Widget token;
  final Widget inherited;
  final Widget effective;
  final Widget source;
  final Widget editor;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: tokens.colorBorderDefault,
            width: tokens.borderWidthDefault,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spaceControlGap),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 230, child: token),
            SizedBox(width: 190, child: inherited),
            SizedBox(width: 190, child: effective),
            SizedBox(width: 100, child: source),
            SizedBox(width: 300, child: editor),
          ],
        ),
      ),
    );
  }
}

class _TokenOverrideEditor extends StatefulWidget {
  const _TokenOverrideEditor({
    required this.tokenKey,
    required this.overrideValue,
    required this.inherited,
    required this.onChanged,
  });

  final String tokenKey;
  final Object? overrideValue;
  final Object inherited;
  final ValueChanged<String?> onChanged;

  @override
  State<_TokenOverrideEditor> createState() => _TokenOverrideEditorState();
}

class _TokenOverrideEditorState extends State<_TokenOverrideEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _display(widget.overrideValue));
  }

  @override
  void didUpdateWidget(covariant _TokenOverrideEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overrideValue != widget.overrideValue) {
      _controller.text = _display(widget.overrideValue);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KInput(
    controller: _controller,
    label: '${widget.tokenKey} override',
    placeholder: _display(widget.inherited),
    clearable: true,
    clearLabel: 'Override entfernen',
    onChanged: (value) {
      if (value.isEmpty) widget.onChanged(null);
    },
    onSubmitted: (value) => widget.onChanged(value),
  );
}

KMapSettings _copySetting(
  KMapSettings settings,
  String key,
  Object value,
) => switch (key) {
  'lang' => settings.copyWith(lang: value as String),
  'roadWidthScale' => settings.copyWith(roadWidthScale: value as double),
  'casingScale' => settings.copyWith(casingScale: value as double),
  'labelScale' => settings.copyWith(labelScale: value as double),
  'haloWidth' => settings.copyWith(haloWidth: value as double),
  'showLanduse' => settings.copyWith(showLanduse: value as bool),
  'showBuildings' => settings.copyWith(showBuildings: value as bool),
  'buildingMinZoom' => settings.copyWith(buildingMinZoom: value as double),
  'showRail' => settings.copyWith(showRail: value as bool),
  'showPaths' => settings.copyWith(showPaths: value as bool),
  'showPois' => settings.copyWith(showPois: value as bool),
  'poiMinZoom' => settings.copyWith(poiMinZoom: value as double),
  'poiMaxRank' => settings.copyWith(poiMaxRank: value as double),
  'poiDotScale' => settings.copyWith(poiDotScale: value as double),
  'roadLabelMinZoom' => settings.copyWith(roadLabelMinZoom: value as double),
  'showQuarterLabels' => settings.copyWith(showQuarterLabels: value as bool),
  _ => throw ArgumentError.value(key, 'key', 'Unknown map setting'),
};

String _display(Object? value) => switch (value) {
  null => '',
  List<Object?> values => values.join(', '),
  double number => _numberLabel(number),
  _ => '$value',
};

String _numberLabel(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
