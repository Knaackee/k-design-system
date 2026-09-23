part of 'k_symbol_picker.dart';

// Match the SVG as well as the value: consumers may replace a built-in emoji.
final _builtInEmojiSvg = <String, String>{
  for (final item in kEmojiCatalog) ...{
    item.value!: item.svg!,
    for (final tone in item.tones) tone.value: tone.svg,
  },
};

final _rasterBytes = <String, Uint8List>{};

Widget _emojiPicture(KSymbolItem item) {
  final raster = rasters.kEmojiRasters[item.value];
  if (raster != null && _builtInEmojiSvg[item.value] == item.svg) {
    return Image.memory(
      _rasterBytes.putIfAbsent(item.value!, () => base64Decode(raster)),
      width: 24,
      height: 24,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }
  return SvgPicture.string(
    item.svg!,
    width: 24,
    height: 24,
    excludeFromSemantics: true,
  );
}
