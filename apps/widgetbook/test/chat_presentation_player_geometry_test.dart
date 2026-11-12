import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_widgetbook/chat_presentation_player.dart';

void main() {
  for (final width in [360.0, 840.0]) {
    testWidgets(
      'media views keep finite geometry in a scrolling catalog at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KeyedSubtree(
                        key: const ValueKey('video'),
                        child: presentationMediaPlayer(context, 'video.mp4'),
                      ),
                      KeyedSubtree(
                        key: const ValueKey('audio'),
                        child: presentationMediaPlayer(
                          context,
                          'audio.wav',
                          audio: true,
                        ),
                      ),
                      const Text('File cards follow the media'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        final video = tester.getSize(find.byKey(const ValueKey('video')));
        final audio = tester.getSize(find.byKey(const ValueKey('audio')));
        expect(video.height, closeTo(video.width * 9 / 16, .01));
        expect(audio.height, 54);
        expect(
          tester.getTopLeft(find.text('File cards follow the media')).dy,
          greaterThanOrEqualTo(
            tester.getBottomLeft(find.byKey(const ValueKey('audio'))).dy,
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
