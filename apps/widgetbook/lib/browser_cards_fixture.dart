import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Gallery-only state. Preview and viewer are supplied widgets: no dependency
/// on WebView, VNC or a transport protocol belongs to the card.
class BrowserCardsFixture extends StatefulWidget {
  const BrowserCardsFixture({
    this.mobile = false,
    this.initialControl = false,
    this.disconnected = false,
    super.key,
  });
  final bool mobile;
  final bool initialControl, disconnected;
  @override
  State<BrowserCardsFixture> createState() => _BrowserCardsFixtureState();
}

class _BrowserCardsFixtureState extends State<BrowserCardsFixture> {
  bool continued = false;
  final stopped = <int>{};
  String notice = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialControl || widget.disconnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) open(0, widget.initialControl);
      });
    }
  }

  Future<void> open(int index, bool control) async {
    final returned = await showDialog<bool>(
      context: context,
      builder: (_) => _BrowserViewer(
        control: control,
        complete: index == 2,
        stopped: stopped.contains(index),
        disconnected: widget.disconnected,
        preview: _BrowserPreview(login: index == 1 && !continued),
      ),
    );
    if (mounted && returned == true) {
      setState(() {
        continued = true;
        stopped.remove(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.mobile ? 390 : 1200),
          child: Padding(
            padding: EdgeInsets.all(t.spaceLayoutGutter),
            child: LayoutBuilder(
              builder: (context, bounds) {
                final columns = bounds.maxWidth > 820 ? 3 : 1;
                final width =
                    (bounds.maxWidth - t.spaceLayoutGutter * (columns - 1)) /
                    columns;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: t.spaceLayoutGutter,
                      runSpacing: t.spaceLayoutGutter,
                      children: [
                        for (var i = 0; i < 3; i++)
                          SizedBox(width: width, child: _card(i)),
                      ],
                    ),
                    if (notice.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: t.spaceControlGap),
                        child: Semantics(liveRegion: true, child: Text(notice)),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(int index) {
    final help = index == 1 && !continued && !stopped.contains(index);
    final titles = [
      'Ada steuert den Browser',
      continued ? 'Ada setzt die Suche fort' : 'Ada braucht deine Anmeldung',
      'Ada hat die Recherche abgeschlossen',
    ];
    final descriptions = [
      'Ich vergleiche Hotels in Tokyo bis 200 € pro Nacht.',
      continued
          ? 'Ich prüfe jetzt die verfügbaren Mitgliederpreise.'
          : 'Melde dich bei Stay an, damit ich die Mitgliederpreise prüfen kann.',
      'Drei Hotels passen zu deinen Wünschen. Es wurde nichts gebucht.',
    ];
    return _BrowserCard(
      title: stopped.contains(index) ? 'Aufgabe gestoppt' : titles[index],
      description: descriptions[index],
      preview: _BrowserPreview(login: index == 1 && !continued),
      needsHelp: help,
      complete: index == 2,
      stopped: stopped.contains(index),
      onOpen: (control) => open(index, control),
      onStop: () => setState(() {
        if (!stopped.remove(index)) stopped.add(index);
      }),
      onCopy: () async {
        try {
          await Clipboard.setData(
            const ClipboardData(text: 'https://stay.example/tokyo'),
          );
          if (mounted) setState(() => notice = 'Beispieladresse kopiert');
        } catch (_) {
          if (mounted) setState(() => notice = 'Kopieren nicht möglich');
        }
      },
    );
  }
}

class _BrowserCard extends StatelessWidget {
  const _BrowserCard({
    required this.title,
    required this.description,
    required this.preview,
    required this.needsHelp,
    required this.complete,
    required this.stopped,
    required this.onOpen,
    required this.onStop,
    required this.onCopy,
  });
  final String title, description;
  final Widget preview;
  final bool needsHelp, complete, stopped;
  final ValueChanged<bool> onOpen;
  final VoidCallback onStop, onCopy;
  @override
  Widget build(BuildContext context) {
    return KBrowserTaskCard(
      title: title,
      description: description,
      preview: preview,
      actions: LayoutBuilder(
        builder: (context, bounds) {
          final compact = bounds.maxWidth < 420;
          final secondary = KMenuAction(
            id: 'secondary',
            label: needsHelp ? 'Browser öffnen' : 'Kontrolle übernehmen',
            icon: needsHelp ? KIconName.maximize : KIconName.mousePointer,
            onSelect: () => onOpen(!needsHelp),
          );
          return Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: KButton(
                    label: needsHelp ? 'Übernehmen' : 'Browser öffnen',
                    leading: KIcon(
                      needsHelp ? KIconName.mousePointer : KIconName.maximize,
                    ),
                    variant: needsHelp
                        ? KButtonVariant.primary
                        : KButtonVariant.ghost,
                    onPressed: () => onOpen(needsHelp),
                  ),
                ),
              ),
              if (!compact && !complete && !stopped)
                KButton(
                  label: secondary.label,
                  onPressed: secondary.onSelect,
                  variant: KButtonVariant.ghost,
                ),
              KMenuButton(
                label: 'Weitere Browseraktionen',
                overflow: true,
                alignEnd: true,
                actions: [
                  if (compact && !complete && !stopped) secondary,
                  KMenuAction(
                    id: 'copy',
                    label: 'Seitenadresse kopieren',
                    icon: KIconName.copy,
                    onSelect: onCopy,
                  ),
                  if (!complete)
                    KMenuAction(
                      id: 'stop',
                      label: stopped ? 'Aufgabe fortsetzen' : 'Aufgabe stoppen',
                      icon: KIconName.square,
                      destructive: !stopped,
                      separatorBefore: true,
                      onSelect: onStop,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrowserPreview extends StatelessWidget {
  const _BrowserPreview({this.login = false});
  final bool login;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 640,
        height: 360,
        child: ColoredBox(
          color: const Color(0xfff7f8f9),
          child: DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'Arial',
              fontSize: 14,
              color: Color(0xff23343d),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'STAY /                                  Unterkünfte    Reiseziele    Mein Konto',
                    ),
                  ),
                ),
                if (login)
                  Center(
                    child: Container(
                      width: 300,
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      color: Colors.white,
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Willkommen zurück',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('Melde dich für deine Mitgliederpreise an.'),
                          SizedBox(height: 24),
                          Text('E-Mail-Adresse'),
                          Divider(),
                          SizedBox(height: 16),
                          ColoredBox(
                            color: Color(0xff23343d),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Weiter',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Hotels in Tokyo',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (final hotel in [
                    'Hotel Metropolitan                     138 €',
                    'Mercure Haneda                          102 €',
                  ])
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 100,
                            height: 70,
                            child: ColoredBox(color: Color(0xffd8d1c4)),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            hotel,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _BrowserViewer extends StatefulWidget {
  const _BrowserViewer({
    required this.control,
    required this.complete,
    required this.stopped,
    required this.preview,
    this.disconnected = false,
  });
  final bool control, complete, stopped;
  final bool disconnected;
  final Widget preview;
  @override
  State<_BrowserViewer> createState() => _BrowserViewerState();
}

class _BrowserViewerState extends State<_BrowserViewer> {
  late bool control = widget.control;
  late bool disconnected = widget.disconnected;
  final transform = TransformationController();
  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: KText(
                    disconnected
                        ? 'Verbindung unterbrochen'
                        : control
                        ? 'Du steuerst · Ada pausiert'
                        : widget.complete
                        ? 'Recherche abgeschlossen'
                        : widget.stopped
                        ? 'Aufgabe gestoppt'
                        : 'Ada steuert den Browser',
                  ),
                ),
                KButton(
                  label: 'Schließen',
                  variant: KButtonVariant.ghost,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: disconnected
                ? const Center(
                    child: Text(
                      'Der Browser ist gerade nicht erreichbar.\nVerbinde dich erneut, um weiterzumachen.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : InteractiveViewer(
                    transformationController: transform,
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: widget.preview,
                      ),
                    ),
                  ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Simulierte Browseransicht · Zum Vergrößern zoomen und verschieben.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                KButton(
                  label: 'Ansicht zurücksetzen',
                  variant: KButtonVariant.ghost,
                  onPressed: disconnected
                      ? null
                      : () => transform.value = Matrix4.identity(),
                ),
                if (disconnected)
                  KButton(
                    label: 'Neu verbinden',
                    onPressed: () => setState(() {
                      disconnected = false;
                      control = false;
                    }),
                  )
                else if (control)
                  KButton(
                    label: 'Fertig – Ada fortsetzen lassen',
                    onPressed: () => Navigator.pop(context, true),
                  )
                else if (!widget.complete && !widget.stopped)
                  KButton(
                    label: 'Übernehmen',
                    onPressed: () => setState(() => control = true),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
