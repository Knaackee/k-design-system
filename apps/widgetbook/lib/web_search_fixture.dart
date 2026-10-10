import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

const webSearchResults = [
  KWebSearchResult(
    id: 'flutter',
    url: 'https://docs.flutter.dev/ui/animations',
    title: 'Flutter: Animationen und interaktive Oberflächen',
    description:
        'Offizielle Dokumentation zu Animationen, Übergängen und responsiven Oberflächen in Flutter.',
  ),
  KWebSearchResult(
    id: 'rive',
    url: 'https://rive.app/docs/',
    title:
        'Rive: State Machines für interaktive Animationen in Web und Flutter',
    description:
        'Animationen mit Zustandsmaschinen verbinden und auf Benutzereingaben reagieren.',
  ),
  KWebSearchResult(
    id: 'foley',
    url: 'https://usefoley.dev/',
    title: 'Foley: Soundeffekte für interaktive Oberflächen',
    description: 'Soundeffekte für interaktive Oberflächen.',
  ),
];

class WebSearchFixture extends StatefulWidget {
  const WebSearchFixture({
    this.state = KWebSearchState.succeeded,
    this.mobile = false,
    this.empty = false,
    this.animatedLoading = false,
    super.key,
  });
  final KWebSearchState state;
  final bool mobile;
  final bool empty;
  final bool animatedLoading;

  @override
  State<WebSearchFixture> createState() => _WebSearchFixtureState();
}

class _WebSearchFixtureState extends State<WebSearchFixture> {
  late bool _expanded = widget.mobile;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final labels = KWebSearchLabels(
      title: 'Websuche',
      running: 'Suche läuft…',
      empty: 'Keine Quellen gefunden.',
      failed: 'Suche fehlgeschlagen',
      sourceCount: (count) => '$count ${count == 1 ? 'Quelle' : 'Quellen'}',
    );

    Widget favicon(
      BuildContext context,
      KWebSearchResult result,
      double size,
    ) => Container(
      decoration: BoxDecoration(
        color: switch (result.id) {
          'flutter' => const Color(0xff027DFD),
          'rive' => const Color(0xff171717),
          _ => const Color(0xff7860C5),
        },
        borderRadius: BorderRadius.circular(t.radiusControl),
        border: size == t.sizeIconDefault * .75
            ? Border.all(color: t.colorSurfaceCanvas)
            : null,
      ),
      child: Center(
        child: Text(
          switch (result.id) {
            'flutter' => 'F',
            'rive' => 'R',
            _ => 'F',
          },
          style: TextStyle(
            fontFamily: 'sans-serif',
            fontSize: size * 2 / 3,
            height: 1,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: widget.mobile ? 360 : 640,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(t.spaceLayoutGutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const KText('Hier sind die gefundenen Quellen.'),
              SizedBox(height: t.spaceControlGap),
              KWebSearch(
                id: 'web-search-${widget.state.name}',
                state: widget.state,
                loadingIndicator: widget.animatedLoading
                    ? KWebSearchLoadingIndicator.animatedIcon
                    : KWebSearchLoadingIndicator.shimmer,
                query: 'Interaktive Oberflächen',
                results:
                    widget.empty || widget.state != KWebSearchState.succeeded
                    ? const []
                    : webSearchResults,
                error: widget.state == KWebSearchState.failed
                    ? 'Die Suche konnte nicht abgeschlossen werden. Bitte später erneut versuchen.'
                    : null,
                labels: labels,
                expanded: _expanded,
                onExpandedChanged: (value) => setState(() => _expanded = value),
                onSourceActivate: (_) {},
                faviconBuilder: favicon,
              ),
              if (widget.state == KWebSearchState.running) ...[
                SizedBox(height: t.spaceLayoutSectionGap),
                KWebSearch(
                  id: 'web-search-${widget.state.name}-with-sources',
                  state: KWebSearchState.succeeded,
                  query: 'Interaktive Oberflächen',
                  results: webSearchResults,
                  labels: labels,
                  onSourceActivate: (_) {},
                  faviconBuilder: favicon,
                ),
              ],
              if (widget.state == KWebSearchState.succeeded &&
                  !widget.empty) ...[
                SizedBox(height: t.spaceControlGap),
                const KText(
                  'Du kannst die Quellen aufklappen und die jeweiligen Websites öffnen.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
