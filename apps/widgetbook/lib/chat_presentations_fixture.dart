import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'files_demo_io.dart';
import 'chat_presentation_player.dart';
import 'files_demo_stub.dart'
    if (dart.library.js_interop) 'files_demo_web.dart'
    as downloads;

const _coast =
    'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=900&auto=format&fit=crop&q=85';
const _mountain =
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=900&auto=format&fit=crop&q=85';
const _forest =
    'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=900&auto=format&fit=crop&q=85';
const _images = [
  KPresentationImage(
    src: _coast,
    alt: 'See zwischen grünen Bergen',
    caption: 'Ein ruhiger Ort am Wasser',
  ),
  KPresentationImage(
    src: _mountain,
    alt: 'Berggipfel im Abendlicht',
    caption: 'Die Berge im letzten Licht',
  ),
  KPresentationImage(
    src: _forest,
    alt: 'Sonnenlicht zwischen Waldbäumen',
    caption: 'Unterwegs im Wald',
  ),
];

/// Matching Storybook fixture: chat-presentations-review.
class ChatPresentationsFixture extends StatefulWidget {
  const ChatPresentationsFixture({this.initialChat = false, super.key});
  final bool initialChat;
  @override
  State<ChatPresentationsFixture> createState() =>
      _ChatPresentationsFixtureState();
}

class _ChatPresentationsFixtureState extends State<ChatPresentationsFixture> {
  late bool _chat = widget.initialChat;
  int? _selected;
  String _notice = '';

  void _open(String name) =>
      setState(() => _notice = 'Vorschau ausgewählt: $name');
  void _download() {
    final saved = downloads.downloadFile(
      DemoFile(
        'Wochenende.md',
        Uint8List.fromList(
          utf8.encode(
            '# Wochenende\n\nZeit am See, ein Spaziergang und eine gute Pause.\n',
          ),
        ),
        'text/markdown',
      ),
    );
    if (!saved) {
      setState(
        () => _notice = 'Herunterladen ist in dieser Vorschau nicht verfügbar.',
      );
    }
  }

  Widget _card(
    int index, {
    bool cover = false,
    String? title,
    String? description,
    String? eyebrow,
    String action = 'Mehr erfahren',
    String? openName,
  }) => KPresentationCard(
    title:
        title ?? ['Zeit am See', 'Über den Wolken', 'Grün statt Grau'][index],
    image: _images[index],
    variant: cover
        ? KPresentationCardVariant.cover
        : KPresentationCardVariant.standard,
    description: description,
    eyebrow: eyebrow,
    action: KPresentationAction(
      label: action,
      onPressed: () => _open(openName ?? _images[index].caption!),
    ),
  );

  Widget _file({
    String name = 'Wochenende.md',
    String meta = 'Markdown · 2,4 KB',
    bool download = true,
  }) => KPresentationFile(
    name: name,
    meta: Text(meta),
    openLabel: 'Öffnen',
    downloadLabel: 'Herunterladen',
    saveLabel: 'In Dateien speichern',
    onSave: () => _open('Kopie im persönlichen Zielordner speichern'),
    onOpen: () => _open(name),
    onDownload: download ? _download : null,
  );

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth <= 640;
        final padding = (constraints.maxWidth * .04).clamp(16.0, 48.0);
        final modes = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KButton(
              label: 'Katalog',
              variant: !_chat ? KButtonVariant.secondary : KButtonVariant.ghost,
              onPressed: () => setState(() => _chat = false),
            ),
            const SizedBox(width: 4),
            KButton(
              label: 'Im Chat',
              variant: _chat ? KButtonVariant.secondary : KButtonVariant.ghost,
              onPressed: () => setState(() => _chat = true),
            ),
          ],
        );
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KText(
              'CHAT · PRÄSENTATIONEN',
              variant: KTextVariant.caption,
              style: TextStyle(
                color: tokens.colorTextMuted,
                letterSpacing: tokens.fontCaptionSize * .12,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: KText(
                'Mehr als eine Antwort.',
                variant: KTextVariant.heading1,
                style: TextStyle(
                  height: 1.2,
                  letterSpacing: tokens.fontHeading1Size * -.035,
                ),
              ),
            ),
            KText(
              'Bilder, Fundstücke und Details. Direkt im Gespräch.',
              style: TextStyle(color: tokens.colorTextMuted),
            ),
          ],
        );
        return SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1136),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (narrow)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [heading, const SizedBox(height: 16), modes],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: heading),
                          const SizedBox(width: 24),
                          modes,
                        ],
                      ),
                    const SizedBox(height: 24),
                    Semantics(
                      liveRegion: true,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 24),
                        child: KText(
                          _notice.isEmpty
                              ? 'Interaktive Beispiele · Aktionen öffnen noch keine Tasks-Daten.'
                              : _notice,
                          variant: KTextVariant.caption,
                          style: TextStyle(color: tokens.colorTextMuted),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_chat) _conversation(tokens) else _catalog(narrow),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _section(String id, String title, List<Widget> children) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Column(
      key: ValueKey('chat-presentations-$id'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            KText(
              id,
              variant: KTextVariant.caption,
              style: TextStyle(color: tokens.colorTextMuted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KText(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        for (final child in children) ...[const SizedBox(height: 12), child],
      ],
    );
  }

  Widget _catalog(bool narrow) {
    final sections = [
      _section('01', 'Bild, Titel & Text', [
        KPresentationCard(
          title: 'Offener Befund',
          description: '25 Ereignisse · Heute aktiv',
          action: KPresentationAction(
            label: 'Befund öffnen',
            onPressed: () => _open('Offener Befund'),
          ),
        ),
        _card(
          0,
          title: 'Ein Wochenende am See',
          eyebrow: 'Inspiration · 4 Minuten',
          description:
              'Weniger planen, mehr draußen sein. Drei kleine Ideen für deine nächste Auszeit.',
          action: 'Entdecken',
          openName: 'Wochenende am See',
        ),
      ]),
      _section('02', 'Bild im Mittelpunkt', [
        _card(
          1,
          cover: true,
          title: 'Eine neue Perspektive',
          eyebrow: 'Für deine nächste Auszeit',
          description: 'Manchmal reicht ein anderer Blickwinkel.',
          action: 'Ansehen',
          openName: 'Eine neue Perspektive',
        ),
      ]),
      _section('03', 'Direkt zum richtigen Ort', [
        KPresentationCollection(
          label: 'Passende Ergebnisse',
          layout: KPresentationCollectionLayout.list,
          children: [
            KPresentationReference(
              title: 'Chat-Präsentationen abstimmen',
              metadata: 'Issue · In Arbeit · Designsystem',
              icon: KIconName.circle,
              onOpen: () => _open('Issue: Chat-Präsentationen'),
            ),
            KPresentationReference(
              title: 'Unser nächster Release',
              metadata: 'Projekt · 8 offene Aufgaben',
              icon: KIconName.folder,
              onOpen: () => _open('Projekt: Release'),
            ),
            KPresentationReference(
              title: 'Ideen für das Wochenende',
              metadata: 'Notiz · Heute bearbeitet',
              image: _coast,
              onOpen: () => _open('Notiz: Wochenende'),
            ),
          ],
        ),
      ]),
      _section('04', 'Mehrere Empfehlungen', [
        KPresentationCollection(
          label: 'Das könnte dir gefallen',
          children: [
            for (var i = 0; i < 3; i++)
              _card(i, description: 'Ein guter Ort für eine kleine Pause.'),
          ],
        ),
      ]),
      _section('05', 'Zwei Seiten, ein Ergebnis', [
        const KPresentationComparison(
          label: 'Freundschaftsspiel · Beendet',
          left: KPresentationParty(
            name: 'Nord',
            image: 'https://flagcdn.com/de.svg',
            detail: 'Heim',
          ),
          right: KPresentationParty(
            name: 'Süd',
            image: 'https://flagcdn.com/at.svg',
            detail: 'Gast',
          ),
          value: '2 : 1',
          detail: 'Endstand',
        ),
      ]),
      _section('06', 'Das Wichtigste auf einen Blick', [
        const KPresentationMetrics(
          label: 'Berlin · Heute',
          value: '18°',
          description: 'Leicht bewölkt. Gutes Wetter für einen Spaziergang.',
          icon: KIconName.cloud,
          metrics: [
            KPresentationMetric(label: 'Gefühlt', value: '19°'),
            KPresentationMetric(label: 'Regen', value: '10 %'),
            KPresentationMetric(label: 'Wind', value: '12 km/h'),
          ],
        ),
      ]),
      _section('07', 'Ein klarer Verlauf', [
        const KPresentationTimeline(
          label: 'Deine Verbindung · ICE 706',
          stops: [
            KPresentationStop(
              id: 'a',
              time: '09:04',
              title: 'Berlin Hauptbahnhof',
              description: 'Gleis 8 · Abfahrt',
              current: true,
            ),
            KPresentationStop(
              id: 'b',
              time: '10:42',
              title: 'Leipzig Hauptbahnhof',
              description: 'Direkt weiterfahren',
            ),
            KPresentationStop(
              id: 'c',
              time: '13:02',
              title: 'München Hauptbahnhof',
              description: 'Gleis 19 · Ankunft',
            ),
          ],
        ),
      ]),
      _section('08', 'Bilder entdecken', [
        KPresentationGallery(
          title: 'Drei Momente draußen',
          images: _images,
          selectedIndex: _selected,
          onSelectedIndexChange: (value) => setState(() => _selected = value),
          closeLabel: 'Schließen',
          previousLabel: 'Vorheriges Bild',
          nextLabel: 'Nächstes Bild',
        ),
      ]),
      _section('09', 'Video direkt im Gespräch', [
        KPresentationVideo(
          title: 'Ein Moment in Bewegung',
          src:
              'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
          poster: _forest,
          caption: const Text('Videobeispiel · Wiedergabe erst auf Klick'),
          playerBuilder: (context, src) =>
              presentationMediaPlayer(context, src, poster: _forest),
        ),
      ]),
      _section('10', 'Zuhören, ohne den Chat zu verlassen', [
        KPresentationAudio(
          title: 'Ein kurzer Klang',
          meta: const Text('Audiobeispiel · Foley'),
          src: 'assets/assets/foley/chime.wav',
          playerBuilder: (context, src) =>
              presentationMediaPlayer(context, src, audio: true),
        ),
      ]),
      _section('11', 'Dateien zum Mitnehmen', [
        _file(),
        _file(
          name: 'Reiseunterlagen.pdf',
          meta: 'PDF · 1,8 MB',
          download: false,
        ),
      ]),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (narrow)
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 32),
            sections[i],
          ]
        else
          for (var i = 0; i < sections.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 36),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: sections[i]),
                const SizedBox(width: 28),
                Expanded(
                  child: i + 1 < sections.length
                      ? sections[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
      ],
    );
  }

  Widget _conversation(KDesignTokens tokens) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: .85,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: tokens.colorSurfaceSubtle,
                  borderRadius: BorderRadius.circular(tokens.radiusCard),
                ),
                child: const KText(
                  'Hast du eine Idee für ein Wochenende in den Bergen? Und zeig mir bitte die offenen Aufgaben dazu.',
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Row(
            children: [
              KIcon(KIconName.sparkles),
              SizedBox(width: 8),
              KText(
                'Dein Begleiter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const KText(
            'Wie wäre es mit zwei Tagen am See? Hier sind drei Orte, an denen du gut abschalten kannst.',
          ),
          const SizedBox(height: 20),
          KPresentationCollection(
            label: 'Deine kleine Auszeit',
            children: [
              for (var i = 0; i < 3; i++)
                _card(
                  i,
                  cover: true,
                  eyebrow: 'Wochenende draußen',
                  title: [
                    'Am Wasser ankommen',
                    'Hoch hinaus',
                    'Einfach losgehen',
                  ][i],
                  action: 'Ort ansehen',
                ),
            ],
          ),
          const SizedBox(height: 20),
          const KText(
            'Für die Vorbereitung sind diese beiden Aufgaben noch offen:',
          ),
          const SizedBox(height: 20),
          KPresentationCollection(
            label: 'Deine Aufgaben',
            layout: KPresentationCollectionLayout.list,
            children: [
              KPresentationReference(
                title: 'Unterkunft für das Wochenende buchen',
                metadata: 'Reiseplanung · Offen',
                icon: KIconName.circle,
                onOpen: () => _open('Issue: Unterkunft buchen'),
              ),
              KPresentationReference(
                title: 'Packliste zusammenstellen',
                metadata: 'Reiseplanung · In Arbeit',
                icon: KIconName.fileText,
                onOpen: () => _open('Issue: Packliste'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const KText('Die Notizen habe ich dir hier zusammengefasst.'),
          const SizedBox(height: 20),
          _file(),
        ],
      ),
    ),
  );
}
