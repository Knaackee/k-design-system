import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// SVG logos are isolated vector images, with no external subresources.
@visibleForTesting
String validatePresentationSvg(Uint8List bytes) {
  const sizeLimit = 1024 * 1024;
  if (bytes.length > sizeLimit) {
    throw const FormatException('SVG logo exceeds size limit');
  }
  // A known SVG DTD is only metadata: discard it before parsing, never fetch it.
  final xml = utf8
      .decode(bytes)
      .replaceAll(
        RegExp(
          r'''<!DOCTYPE\s+svg\s+PUBLIC\s+"-//W3C//DTD SVG 1\.1//EN"\s+"http://www\.w3\.org/Graphics/SVG/1\.1/DTD/svg11\.dtd"\s*>''',
        ),
        '',
      );
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
  final document = XmlDocument.parse(xml);
  if (document.rootElement.name.local != 'svg') {
    throw const FormatException('SVG logo requires an svg root');
  }
  final elements = document.descendants.whereType<XmlElement>().toList();
  for (final element in elements) {
    if (const {
      'script',
      'foreignobject',
      'image',
    }.contains(element.name.local.toLowerCase())) {
      throw const FormatException('SVG logo contains unsupported content');
    }
    for (final attribute in element.attributes) {
      final value = attribute.value.trim();
      if ((attribute.name.local == 'href' && !value.startsWith('#')) ||
          RegExp(
            r'''url\s*\(\s*["']?(?!#)[^\s"')]+''',
            caseSensitive: false,
          ).hasMatch(value)) {
        throw const FormatException('SVG logo contains external resources');
      }
    }
  }
  final styles = elements.where((e) => e.name.local == 'style').toList();
  if (styles.isEmpty) return xml;

  // flutter_svg does not apply stylesheets. Support only inert class paint rules.
  final rulePattern = RegExp(r'\.([a-zA-Z_][\w-]*)\s*\{([^{}]*)\}');
  final declarationPattern = RegExp(
    r'^(?:(?:fill|stroke):(?:#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3})?|none)|stroke-width:(?:\d+(?:\.\d+)?|\.\d+)|stroke-linecap:(?:butt|round|square)|stroke-linejoin:(?:miter|round|bevel))$',
  );
  final rules = <(String, String)>[];
  for (final style in styles) {
    final css = style.innerText;
    if (css.replaceAll(rulePattern, '').trim().isNotEmpty) {
      throw const FormatException('Unsupported SVG stylesheet');
    }
    for (final rule in rulePattern.allMatches(css)) {
      final declarations = rule[2]!
          .split(';')
          .map((value) => value.replaceAll(RegExp(r'\s+'), ''))
          .where((value) => value.isNotEmpty)
          .toList();
      if (declarations.any((value) => !declarationPattern.hasMatch(value))) {
        throw const FormatException('Unsupported SVG style declaration');
      }
      rules.add((rule[1]!, declarations.join(';')));
    }
    style.parent!.children.remove(style);
  }
  if (elements.length * rules.length > 100000) {
    throw const FormatException('SVG stylesheet exceeds work limit');
  }
  var normalizedBytes = utf8.encode(document.toXmlString()).length;
  if (normalizedBytes > sizeLimit) {
    throw const FormatException('Normalized SVG exceeds size limit');
  }
  for (final element in elements) {
    final classes = (element.getAttribute('class') ?? '')
        .split(RegExp(r'\s+'))
        .toSet();
    final inline = element.getAttribute('style');
    final declarations = <String>[];
    for (final rule in rules) {
      if (!classes.contains(rule.$1)) continue;
      // Rules are ASCII; reserve separators and a new attribute before joining.
      normalizedBytes += rule.$2.length + 1;
      if (declarations.isEmpty && inline == null) normalizedBytes += 9;
      if (normalizedBytes > sizeLimit) {
        throw const FormatException('Normalized SVG exceeds size limit');
      }
      declarations.add(rule.$2);
    }
    if (declarations.isNotEmpty) {
      if (inline != null) declarations.add(inline);
      element.setAttribute('style', declarations.join(';'));
    }
  }
  return document.toXmlString();
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
