part of 'k_symbol_picker.dart';

// Match the SVG as well as the value: consumers may replace a built-in emoji.
final _builtInEmojiSvg = <String, String>{
  for (final item in kEmojiCatalog) ...{
    item.value!: item.svg!,
    for (final tone in item.tones) tone.value: tone.svg,
  },
};

Widget _emojiPicture(KSymbolItem item) {
  final compiled = vectors.kEmojiVectors[item.value];
  if (compiled != null && _builtInEmojiSvg[item.value] == item.svg) {
    return SvgPicture(
      _EmojiBytesLoader(item.value!, compiled),
      width: 24,
      height: 24,
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

class _EmojiBytesLoader extends BytesLoader {
  const _EmojiBytesLoader(this.value, this.encoded);
  final String value, encoded;
  // Bound decoded-byte memory; mounted visible pictures keep their own data.
  static final _cache = <String, ByteData>{};

  @override
  Future<ByteData> loadBytes(BuildContext? context) {
    final bytes =
        _cache.remove(value) ?? base64Decode(encoded).buffer.asByteData();
    _cache[value] = bytes;
    if (_cache.length > 128) _cache.remove(_cache.keys.first);
    return SynchronousFuture(bytes);
  }

  @override
  Object cacheKey(BuildContext? context) => (_EmojiBytesLoader, value);
}
