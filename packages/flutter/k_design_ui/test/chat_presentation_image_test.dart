import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/src/components/chat_presentation_image.dart';
import 'package:xml/xml.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Wikimedia originals: commons/b/ba/Flag_of_Germany.svg and
  // commons/f/ff/Flag_of_Serbia.svg on https://upload.wikimedia.org/wikipedia/.
  for (final flag in ['germany', 'serbia']) {
    test('$flag SVG fixture renders its original national colors', () async {
      final source = File('test/fixtures/presentation_flags/$flag.svg');
      final normalized = validatePresentationSvg(source.readAsBytesSync());
      expect(normalized, isNot(contains('<!DOCTYPE')));
      expect(normalized, isNot(contains('<style')));
      final picture = await vg.loadPicture(SvgStringLoader(normalized), null);
      final recorder = ui.PictureRecorder();
      final scale = 600 / picture.size.width;
      ui.Canvas(recorder)
        ..scale(scale)
        ..drawPicture(picture.picture);
      final scaled = recorder.endRecording();
      final image = await scaled.toImage(
        600,
        (picture.size.height * scale).round(),
      );
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final colors = <int, int>{};
      for (var offset = 0; offset < pixels.lengthInBytes; offset += 4) {
        final rgb = pixels.getUint32(offset) >> 8;
        colors[rgb] = (colors[rgb] ?? 0) + 1;
      }
      for (final color
          in flag == 'germany'
              ? [0x000000, 0xdd0000, 0xffce00]
              : [0xc6363c, 0x0c4076, 0xffffff, 0xedb92e]) {
        expect(colors[color] ?? 0, greaterThan(1000), reason: '$flag $color');
      }
      image.dispose();
      scaled.dispose();
      picture.picture.dispose();
    });
  }
  test(
    'class paint rules follow source order and preserve inline precedence',
    () {
      const source = '''<svg xmlns="http://www.w3.org/2000/svg">
<style><![CDATA[.second {fill:#fff;} .first {fill:#abc;stroke:#123;stroke-width:1;}]]></style>
<g class="first second"><path style="fill:#def"/></g></svg>''';
      final document = XmlDocument.parse(
        validatePresentationSvg(Uint8List.fromList(utf8.encode(source))),
      );
      expect(
        document.findAllElements('g').single.getAttribute('style'),
        'fill:#fff;fill:#abc;stroke:#123;stroke-width:1',
      );
      expect(
        document.findAllElements('path').single.getAttribute('style'),
        'fill:#def',
      );
    },
  );
  test('SVG stylesheet work is bounded below the download size limit', () {
    final source =
        '<svg><style>${'.a{fill:#fff;}' * 500}</style>'
        '${'<path class="a"/>' * 500}</svg>';
    final bytes = Uint8List.fromList(utf8.encode(source));
    expect(bytes.length, lessThan(1024 * 1024));
    expect(
      () => validatePresentationSvg(bytes),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('work limit'),
        ),
      ),
    );
  });
  test('SVG stylesheet output is bounded before concatenating styles', () {
    final rule = '.a{stroke-width:${'1' * 1000};}';
    final source =
        '<svg><style>${rule * 100}</style>'
        '${'<path class="a"/>' * 100}</svg>';
    final bytes = Uint8List.fromList(utf8.encode(source));
    expect(bytes.length, lessThan(1024 * 1024));
    expect(
      () => validatePresentationSvg(bytes),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Normalized SVG'),
        ),
      ),
    );
  });
  test('SVG download bounds streamed bytes and closes on failure', () async {
    final client = _StreamClient(Stream.value(List.filled(1024 * 1024 + 1, 0)));
    await expectLater(
      loadPresentationSvg(
        Uri.parse('https://example.com/logo.svg'),
        client: client,
      ),
      throwsFormatException,
    );
    expect(client.closed, isTrue);
  });
  test('SVG deadline closes an unresponsive response', () async {
    final stream = StreamController<List<int>>();
    final client = _StreamClient(stream.stream);
    await expectLater(
      loadPresentationSvg(
        Uri.parse('https://example.com/logo.svg'),
        client: client,
        timeout: const Duration(milliseconds: 10),
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(client.closed, isTrue);
    unawaited(stream.close());
  });
  test('SVG logos support vector paths and local references', () {
    const svg =
        '<svg xmlns="http://www.w3.org/2000/svg"><defs><path id="a" d="M0 0"/></defs><use href="#a" fill="url(#a)"/></svg>';
    expect(validatePresentationSvg(Uint8List.fromList(utf8.encode(svg))), svg);
  });
  test(
    'SVG logos reject scripts, entity expansion, external resources and oversized input',
    () {
      for (final xml in [
        '<!DOCTYPE svg><svg/>',
        '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd" [<!ENTITY a "boom">]><svg/>',
        '<!DOCTYPE svg SYSTEM "https://example.com/evil.dtd"><svg/>',
        '<svg><use href="&#104;ttps://example.com/x"/></svg>',
        '<svg><path fill="&#117;rl(https://example.com/x)"/></svg>',
        '<svg><style>.a {fill:url(#local);}</style></svg>',
        '<svg><style>.a:hover {fill:#fff;}</style></svg>',
        '<svg><style>.a {fill:#fff!important;}</style></svg>',
        '<svg><style>.a {filter:blur(1px);}</style></svg>',
        '<svg><style>@font-face {src:url(https://example.com/x);}</style></svg>',
        '<svg><script>alert(1)</script></svg>',
        '<svg><foreignObject/></svg>',
        '<svg><style>@import "https://example.com/style.css";</style></svg>',
        '<svg><image href="data:image/png;base64,AAA"/></svg>',
        '<svg><use href="https://example.com/x.svg#a"/></svg>',
        '<svg><path fill="url(https://example.com/x)"/></svg>',
      ]) {
        expect(
          () => validatePresentationSvg(Uint8List.fromList(utf8.encode(xml))),
          throwsFormatException,
        );
      }
      expect(
        () => validatePresentationSvg(Uint8List(1024 * 1024 + 1)),
        throwsFormatException,
      );
    },
  );
}

class _StreamClient extends http.BaseClient {
  _StreamClient(this.stream);
  final Stream<List<int>> stream;
  bool closed = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(stream, 200);
  @override
  void close() => closed = true;
}
