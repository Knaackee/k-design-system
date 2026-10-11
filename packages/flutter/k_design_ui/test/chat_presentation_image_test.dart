import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/src/components/chat_presentation_image.dart';

void main() {
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
