import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

/// SVG logos are isolated vector images, with no external subresources.
@visibleForTesting
String validatePresentationSvg(Uint8List bytes) {
  if (bytes.length > 1024 * 1024) {
    throw const FormatException('SVG logo exceeds size limit');
  }
  final xml = utf8.decode(bytes);
  if (RegExp(
        r'<!DOCTYPE|<!ENTITY|@import\b|<(?:script|foreignObject|image)\b',
        caseSensitive: false,
      ).hasMatch(xml) ||
      RegExp(
        r'''(?:href|url)\s*(?:=\s*["']|\(\s*["']?)(?!#)[^\s"')]+''',
        caseSensitive: false,
      ).hasMatch(xml)) {
    throw const FormatException(
      'SVG logo contains unsupported external content',
    );
  }
  return xml;
}

class _LogoLoader extends SvgNetworkLoader {
  const _LogoLoader(super.url);
  @override
  Future<Uint8List?> prepareMessage(BuildContext? context) =>
      loadPresentationSvg(Uri.parse(url));
  @override
  String provideSvg(Uint8List? message) => validatePresentationSvg(message!);
}

@visibleForTesting
Future<Uint8List> loadPresentationSvg(
  Uri uri, {
  http.Client? client,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final connection = client ?? http.Client();
  const limit = 1024 * 1024;
  final deadline = Timer(timeout, connection.close);
  try {
    return await (() async {
      final response = await connection.send(http.Request('GET', uri));
      if (response.statusCode != 200 || (response.contentLength ?? 0) > limit) {
        throw const FormatException('SVG logo response exceeds size limit');
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.stream) {
        if (bytes.length + chunk.length > limit) {
          throw const FormatException('SVG logo exceeds size limit');
        }
        bytes.add(chunk);
      }
      return bytes.takeBytes();
    })().timeout(timeout);
  } finally {
    deadline.cancel();
    connection.close();
  }
}

class KPresentationNetworkImage extends StatelessWidget {
  const KPresentationNetworkImage({
    required this.src,
    this.alt,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    super.key,
  });
  final String src;
  final String? alt;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;
  @override
  Widget build(BuildContext context) {
    Widget error(BuildContext context, Object exception, StackTrace? stack) =>
        errorBuilder?.call(context, exception, stack) ??
        const SizedBox.shrink();
    return Uri.tryParse(src)?.path.toLowerCase().endsWith('.svg') == true
        ? SvgPicture(
            _LogoLoader(src),
            fit: fit,
            semanticsLabel: alt,
            excludeFromSemantics: alt == null || alt!.isEmpty,
            errorBuilder: error,
          )
        : Image.network(
            src,
            fit: fit,
            semanticLabel: alt,
            excludeFromSemantics: alt == null || alt!.isEmpty,
            errorBuilder: error,
          );
  }
}
