import 'dart:math' as math;
import 'dart:typed_data';

import 'package:k_design_ui/k_design_ui.dart';

/// Decoded, uncompressed PCM data used only by the Widgetbook audio demo.
class RobotHeadWav {
  RobotHeadWav._({
    required this.bytes,
    required this.dataOffset,
    required this.dataLength,
    required this.channels,
    required this.sampleRate,
    required this.bitsPerSample,
  });

  final Uint8List bytes;
  final int dataOffset;
  final int dataLength;
  final int channels;
  final int sampleRate;
  final int bitsPerSample;

  int get _bytesPerSample => bitsPerSample ~/ 8;
  int get _frameSize => channels * _bytesPerSample;
  int get frameCount => dataLength ~/ _frameSize;
  Duration get duration => Duration(
    microseconds: (frameCount * Duration.microsecondsPerSecond) ~/ sampleRate,
  );

  static RobotHeadWav parse(Uint8List bytes) {
    if (bytes.length < 12 ||
        _ascii(bytes, 0, 4) != 'RIFF' ||
        _ascii(bytes, 8, 4) != 'WAVE') {
      throw const FormatException(
        'Die Datei ist keine gültige RIFF/WAVE-Datei.',
      );
    }

    final data = ByteData.sublistView(bytes);
    int? channels;
    int? sampleRate;
    int? bitsPerSample;
    int? dataOffset;
    int? dataLength;
    var offset = 12;

    while (offset + 8 <= bytes.length) {
      final chunkId = _ascii(bytes, offset, 4);
      final chunkLength = data.getUint32(offset + 4, Endian.little);
      final payload = offset + 8;
      if (payload + chunkLength > bytes.length) {
        throw const FormatException(
          'Die WAV-Datei enthält einen beschädigten Chunk.',
        );
      }
      if (chunkId == 'fmt ') {
        if (chunkLength < 16) {
          throw const FormatException('Der WAV-Formatblock ist unvollständig.');
        }
        final format = data.getUint16(payload, Endian.little);
        if (format != 1) {
          throw const FormatException(
            'Nur unkomprimierte PCM-WAV-Dateien werden unterstützt.',
          );
        }
        channels = data.getUint16(payload + 2, Endian.little);
        sampleRate = data.getUint32(payload + 4, Endian.little);
        bitsPerSample = data.getUint16(payload + 14, Endian.little);
      } else if (chunkId == 'data' && dataOffset == null) {
        dataOffset = payload;
        dataLength = chunkLength;
      }
      offset = payload + chunkLength + (chunkLength.isOdd ? 1 : 0);
    }

    if (channels == null || sampleRate == null || bitsPerSample == null) {
      throw const FormatException('Der WAV-Datei fehlt ein PCM-Formatblock.');
    }
    if (dataOffset == null || dataLength == null || dataLength == 0) {
      throw const FormatException('Die WAV-Datei enthält keine Audiodaten.');
    }
    if (channels < 1 ||
        sampleRate < 1 ||
        !const [8, 16, 24, 32].contains(bitsPerSample)) {
      throw const FormatException(
        'PCM-Kanäle, Abtastrate oder Bittiefe werden nicht unterstützt.',
      );
    }
    final frameSize = channels * (bitsPerSample ~/ 8);
    if (dataLength < frameSize) {
      throw const FormatException(
        'Die WAV-Datei enthält keine vollständige Audioprobe.',
      );
    }
    return RobotHeadWav._(
      bytes: bytes,
      dataOffset: dataOffset,
      dataLength: dataLength,
      channels: channels,
      sampleRate: sampleRate,
      bitsPerSample: bitsPerSample,
    );
  }

  KRobotHeadAudioFrame frameAt(Duration position) {
    if (frameCount == 0) return const KRobotHeadAudioFrame(level: 0);
    final center =
        (position.inMicroseconds * sampleRate) ~/
        Duration.microsecondsPerSecond;
    const windowSize = 512;
    final start = (center - windowSize ~/ 2)
        .clamp(0, math.max(0, frameCount - 1))
        .toInt();
    final count = math.min(windowSize, frameCount - start).toInt();
    final samples = List<double>.generate(
      count,
      (index) => _monoSample(start + index),
    );
    if (samples.isEmpty) return const KRobotHeadAudioFrame(level: 0);

    var sumSquares = 0.0;
    for (final sample in samples) {
      sumSquares += sample * sample;
    }
    final level = (math.sqrt(sumSquares / samples.length) * 2.4).clamp(
      0.0,
      1.0,
    );
    return KRobotHeadAudioFrame(level: level, bands: _spectralBands(samples));
  }

  double _monoSample(int frame) {
    var sum = 0.0;
    for (var channel = 0; channel < channels; channel++) {
      final offset =
          dataOffset + frame * _frameSize + channel * _bytesPerSample;
      sum += _sampleAt(offset);
    }
    return sum / channels;
  }

  double _sampleAt(int offset) {
    final data = ByteData.sublistView(bytes);
    return switch (bitsPerSample) {
      8 => (bytes[offset] - 128) / 128,
      16 => data.getInt16(offset, Endian.little) / 32768,
      24 => _int24(data, offset) / 8388608,
      32 => data.getInt32(offset, Endian.little) / 2147483648,
      _ => 0,
    };
  }

  List<double> _spectralBands(List<double> samples) {
    const bandCount = 12;
    final nyquist = sampleRate / 2;
    final minFrequency = math.min(80.0, nyquist);
    final maxFrequency = math.min(8000.0, nyquist);
    if (maxFrequency <= minFrequency || samples.length < 2) {
      return List<double>.filled(bandCount, 0);
    }
    final bands = List<double>.filled(bandCount, 0);
    for (var bin = 1; bin <= samples.length ~/ 2; bin++) {
      final frequency = bin * sampleRate / samples.length;
      if (frequency < minFrequency || frequency > maxFrequency) continue;
      final angular = 2 * math.pi * frequency / sampleRate;
      var real = 0.0;
      var imaginary = 0.0;
      for (var i = 0; i < samples.length; i++) {
        final window =
            0.5 - 0.5 * math.cos(2 * math.pi * i / (samples.length - 1));
        final value = samples[i] * window;
        real += value * math.cos(angular * i);
        imaginary -= value * math.sin(angular * i);
      }
      final magnitude =
          math.sqrt(real * real + imaginary * imaginary) * 4 / samples.length;
      final ratio =
          math.log(frequency / minFrequency) /
          math.log(maxFrequency / minFrequency);
      final band = (ratio * bandCount).floor().clamp(0, bandCount - 1);
      bands[band] = math.max(bands[band], (magnitude * 2.2).clamp(0.0, 1.0));
    }
    return bands;
  }

  static int _int24(ByteData data, int offset) {
    var value =
        data.getUint8(offset) |
        (data.getUint8(offset + 1) << 8) |
        (data.getUint8(offset + 2) << 16);
    if ((value & 0x800000) != 0) value |= ~0xffffff;
    return value;
  }

  static String _ascii(Uint8List bytes, int offset, int length) =>
      String.fromCharCodes(bytes.sublist(offset, offset + length));
}
