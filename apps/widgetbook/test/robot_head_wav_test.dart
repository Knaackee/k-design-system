import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_widgetbook/robot_head_wav.dart';

void main() {
  test('parses PCM WAV and reports real amplitude and spectral bands', () {
    final wav = RobotHeadWav.parse(
      _pcm16Wav(
        sampleRate: 8000,
        samples: List.generate(
          800,
          (index) =>
              (math.sin(2 * math.pi * 440 * index / 8000) * 16000).round(),
        ),
      ),
    );

    expect(wav.channels, 1);
    expect(wav.sampleRate, 8000);
    expect(wav.bitsPerSample, 16);
    expect(wav.duration, const Duration(milliseconds: 100));
    final frame = wav.frameAt(const Duration(milliseconds: 50));
    expect(frame.level, greaterThan(0.5));
    expect(frame.bands, hasLength(12));
    expect(frame.bands!.reduce(math.max), greaterThan(0.1));
  });

  test('rejects compressed WAV rather than fabricating animation', () {
    final bytes = _pcm16Wav(sampleRate: 8000, samples: const [0, 1]);
    ByteData.sublistView(bytes).setUint16(20, 3, Endian.little);

    expect(
      () => RobotHeadWav.parse(bytes),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('unkomprimierte PCM'),
        ),
      ),
    );
  });

  test('rejects malformed and truncated chunks', () {
    expect(
      () => RobotHeadWav.parse(Uint8List.fromList('not wave'.codeUnits)),
      throwsFormatException,
    );
    final bytes = _pcm16Wav(sampleRate: 8000, samples: const [0, 1]);
    ByteData.sublistView(bytes).setUint32(40, 9999, Endian.little);
    expect(() => RobotHeadWav.parse(bytes), throwsFormatException);
  });
}

Uint8List _pcm16Wav({required int sampleRate, required List<int> samples}) {
  final bytes = Uint8List(44 + samples.length * 2);
  final data = ByteData.sublistView(bytes);
  void ascii(int offset, String value) {
    bytes.setRange(offset, offset + value.length, value.codeUnits);
  }

  ascii(0, 'RIFF');
  data.setUint32(4, bytes.length - 8, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  return bytes;
}
