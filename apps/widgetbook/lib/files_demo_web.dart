import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'files_demo_io.dart';

Future<List<DemoFile>> pickFiles() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..multiple = true;
  final completion = Completer<List<DemoFile>>();
  input.addEventListener(
    'cancel',
    ((web.Event _) {
      if (!completion.isCompleted) completion.complete([]);
    }).toJS,
  );
  input.addEventListener(
    'change',
    ((web.Event _) {
      final files = input.files;
      Future<void>(() async {
        try {
          final result = <DemoFile>[];
          for (var i = 0; i < (files?.length ?? 0); i++) {
            final file = files!.item(i)!;
            final buffer = await file.arrayBuffer().toDart;
            result.add(
              DemoFile(file.name, buffer.toDart.asUint8List(), file.type),
            );
          }
          completion.complete(result);
        } catch (error, stack) {
          completion.completeError(error, stack);
        }
      });
    }).toJS,
  );
  input.click();
  return completion.future;
}

bool downloadFile(DemoFile file) {
  final blob = web.Blob(
    [file.bytes.toJS].toJS,
    web.BlobPropertyBag(type: file.type),
  );
  final url = web.URL.createObjectURL(blob);
  (web.HTMLAnchorElement()
        ..href = url
        ..download = file.name)
      .click();
  Timer(const Duration(seconds: 1), () => web.URL.revokeObjectURL(url));
  return true;
}
