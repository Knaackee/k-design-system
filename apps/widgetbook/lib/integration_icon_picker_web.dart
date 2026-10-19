import 'dart:async';
import 'dart:js_interop';

import 'package:k_design_ui/k_design_ui.dart';
import 'package:web/web.dart' as web;

Future<KIntegrationIconSelection?> pickIntegrationIcon() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/png,image/jpeg,image/webp';
  final completion = Completer<KIntegrationIconSelection?>();
  input.addEventListener(
    'cancel',
    ((web.Event _) {
      if (!completion.isCompleted) completion.complete();
    }).toJS,
  );
  input.addEventListener(
    'change',
    ((web.Event _) {
      Future<void>(() async {
        try {
          final file = input.files?.item(0);
          if (file == null) {
            completion.complete();
            return;
          }
          final buffer = await file.arrayBuffer().toDart;
          completion.complete(
            KIntegrationIconSelection(
              bytes: buffer.toDart.asUint8List(),
              contentType: file.type,
            ),
          );
        } catch (error, stack) {
          completion.completeError(error, stack);
        }
      });
    }).toJS,
  );
  input.click();
  return completion.future;
}
