import 'dart:typed_data';

class DemoFile {
  const DemoFile(this.name, this.bytes, this.type);
  final String name, type;
  final Uint8List bytes;
}
