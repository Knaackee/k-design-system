import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/src/components/chat_presentation_media.dart';

Widget harness(Widget child) => MaterialApp(
  theme: kDesignTheme(),
  home: Scaffold(
    body: SizedBox(
      width: 600,
      child: Align(alignment: Alignment.topLeft, child: child),
    ),
  ),
);

void main() {
  testWidgets(
    'native video reserves height for playback controls and caption',
    (tester) async {
      await tester.pumpWidget(
        harness(
          SizedBox(
            width: 320,
            child: KPresentationVideo(
              src: 'https://example.com/video.mp4',
              title: 'Native video',
              playerBuilder: (_, source) => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ColoredBox(color: Colors.black),
                  ),
                  SizedBox(height: 64, child: Text('Playback controls')),
                ],
              ),
              caption: const Text('Caption below controls'),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.text('Caption below controls')).dy,
        greaterThanOrEqualTo(
          tester.getBottomLeft(find.text('Playback controls')).dy,
        ),
      );
    },
  );

  testWidgets('YouTube player is constructed only after explicit activation', (
    tester,
  ) async {
    final sources = <String>[];
    await tester.pumpWidget(
      harness(
        KPresentationVideo.youtube(
          youtubeVideoId: 'M7lc1UVf-VE',
          title: 'Video',
          playerBuilder: (context, source) {
            sources.add(source);
            return const Text('Real host player');
          },
        ),
      ),
    );
    expect(sources, isEmpty);
    await tester.tap(find.text('Load YouTube video'));
    await tester.pump();
    expect(sources, [
      'https://www.youtube-nocookie.com/embed/M7lc1UVf-VE?autoplay=0',
    ]);
    expect(find.text('Real host player'), findsOneWidget);
  });

  testWidgets('invalid YouTube ID cannot activate a player', (tester) async {
    var loaded = false;
    await tester.pumpWidget(
      harness(
        KPresentationVideo.youtube(
          youtubeVideoId: '../invalid',
          title: 'Video',
          playerBuilder: (context, source) {
            loaded = true;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.tap(find.text('Load YouTube video'));
    await tester.pump();
    expect(loaded, isFalse);
  });

  testWidgets('file actions remain usable in a narrow surface', (tester) async {
    var opened = false;
    var downloaded = false;
    await tester.pumpWidget(
      harness(
        SizedBox(
          width: 180,
          child: KPresentationFile(
            name: 'long-file-name-for-a-presentation.pdf',
            onOpen: () => opened = true,
            onDownload: () => downloaded = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.tap(find.text('Download'));
    expect(opened, isTrue);
    expect(downloaded, isTrue);
    expect(tester.takeException(), isNull);
  });
}
