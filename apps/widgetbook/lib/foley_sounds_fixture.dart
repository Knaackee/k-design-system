import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'foley_event_preview.dart';

Widget buildFoleySoundsReview(BuildContext context) =>
    const FoleySoundsFixture();

class _Cue {
  _Cue(Map<String, dynamic> value)
    : id = value['id'] as String,
      name = value['name'] as String,
      family = value['family'] as String,
      category = value['category'] as String,
      description = value['description'] as String,
      recommended = value['recommended'] as bool;
  final String id, name, family, category, description;
  final bool recommended;
  KIconName get icon => switch (family) {
    'pointer' || 'press' => KIconName.mousePointer2,
    'toggle' => KIconName.toggleLeft,
    'feedback' => KIconName.circleCheck,
    'notify' => KIconName.bell,
    'motion' => KIconName.moveRight,
    _ => KIconName.flag,
  };
}

class FoleySoundsFixture extends StatefulWidget {
  const FoleySoundsFixture({super.key});
  @override
  State<FoleySoundsFixture> createState() => _FoleySoundsFixtureState();
}

class _FoleySoundsFixtureState extends State<FoleySoundsFixture> {
  final _player = AudioPlayer();
  List<_Cue> _cues = [];
  bool _expanded = false;
  StreamSubscription<void>? _completion;
  Future<void> _pending = Future.value();
  double _volume = 50;
  bool _muted = false;
  bool _eventsEnabled = true, _chatEnabled = true, _toolsEnabled = true;
  String _eventStatus = 'Bereit für ein Beispielereignis.';
  int _request = 0;
  String? _active;
  String _status = 'Bereit zum Anhören. Wähle einen Klang.';

  @override
  void initState() {
    super.initState();
    unawaited(_loadCues());
    _completion = _player.onPlayerComplete.listen((_) {
      if (!mounted || _active == null) return;
      final cue = _cues.firstWhere((cue) => cue.id == _active);
      setState(() {
        _active = null;
        _status = '${cue.name} angehört.';
      });
    });
  }

  Future<void> _loadCues() async {
    try {
      final text = await rootBundle.loadString(
        'assets/foley/export-metadata.json',
      );
      final metadata = jsonDecode(text) as Map<String, dynamic>;
      final recordings = metadata['recordings'] as Map<String, dynamic>;
      final loaded = recordings.values
          .map((value) => _Cue(value as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _cues = loaded);
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Klangpalette konnte nicht geladen werden.');
      }
    }
  }

  void _audition(_Cue cue) {
    final request = ++_request;
    // Serialize commands on the single preview player. A newer click supersedes
    // a pending load, so rapid auditions cannot stack or finish out of order.
    _pending = _pending.then((_) async {
      if (!mounted || request != _request) return;
      try {
        await _player.stop();
        if (!mounted || request != _request || _muted || _volume == 0) return;
        setState(() {
          _active = cue.id;
          _status = '${cue.name} wird abgespielt.';
        });
        await _player.play(
          AssetSource('foley/${cue.id}.wav'),
          volume: _muted ? 0 : _volume / 100,
        );
        if (!mounted || request != _request) await _player.stop();
      } catch (_) {
        if (!mounted || request != _request) return;
        setState(() {
          _active = null;
          _status =
              'Klang konnte nicht abgespielt werden. Bitte erneut versuchen.';
        });
      }
    });
  }

  void _eventPreview(String category, String cueId, String message) {
    setState(() => _eventStatus = message);
    if (!_eventsEnabled ||
        !(category == 'chat' ? _chatEnabled : _toolsEnabled) ||
        _muted ||
        _volume == 0) {
      return;
    }
    final matching = _cues.where((cue) => cue.id == cueId);
    if (matching.isNotEmpty) _audition(matching.first);
  }

  void _stopPreview() {
    _request++;
    setState(() {
      if (_active != null) _status = 'Wiedergabe beendet.';
      _active = null;
    });
    // Silence immediately, then finish stopping on the same queue as play.
    // A later audition waits for this stop rather than being stopped by it.
    final silence = _player.setVolume(0).catchError((Object _) {});
    _pending = _pending.then((_) => _silence(silence));
  }

  Future<void> _silence(Future<void> silence) async {
    try {
      await silence;
      await _player.stop();
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Klang konnte nicht gestoppt werden.');
      }
    }
  }

  Future<void> _updateVolume() async {
    try {
      await _player.setVolume(_muted ? 0 : _volume / 100);
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Lautstärke konnte nicht geändert werden.');
      }
    }
  }

  @override
  void dispose() {
    _request++;
    _completion?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final gap = t.spaceCardPadding;
    final mutedStyle = TextStyle(color: t.colorTextMuted);
    Widget card(_Cue cue) => KSurface(
      radius: KSurfaceRadius.card,
      tone: _active == cue.id ? KSurfaceTone.subtle : KSurfaceTone.raised,
      border: _active == cue.id
          ? KSurfaceBorder.strong
          : KSurfaceBorder.standard,
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                KIcon(cue.icon, color: t.colorTextMuted),
                Flexible(
                  child: KText(
                    cue.category,
                    variant: KTextVariant.caption,
                    style: mutedStyle,
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
            KText(cue.name, variant: KTextVariant.heading4),
            SizedBox(height: gap),
            KText(
              cue.description,
              variant: KTextVariant.bodySmall,
              style: mutedStyle,
            ),
            SizedBox(height: gap),
            Semantics(
              label: '${cue.name} anhören',
              child: KButton(
                label: _active == cue.id ? 'Erneut anhören' : 'Anhören',
                variant: KButtonVariant.secondary,
                leading: const KIcon(KIconName.play),
                onPressed: _muted || _volume == 0 ? null : () => _audition(cue),
              ),
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      key: const ValueKey('foley-sounds-review'),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: LayoutBuilder(
            builder: (context, outer) {
              final inset = outer.maxWidth <= 460
                  ? gap
                  : t.spaceLayoutSectionGap;
              return Padding(
                padding: EdgeInsets.all(inset),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth <= 428
                        ? 1
                        : constraints.maxWidth <= 636
                        ? 2
                        : 3;
                    List<Widget> cueRows(List<_Cue> items) {
                      final rows = <Widget>[];
                      for (
                        var start = 0;
                        start < items.length;
                        start += columns
                      ) {
                        if (start > 0) rows.add(SizedBox(height: gap));
                        rows.add(
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (
                                var offset = 0;
                                offset < columns;
                                offset++
                              ) ...[
                                if (offset > 0) SizedBox(width: gap),
                                Expanded(
                                  child: start + offset < items.length
                                      ? card(items[start + offset])
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ],
                          ),
                        );
                      }
                      return rows;
                    }

                    final recommended =
                        [
                              'tap',
                              'swoosh',
                              'bubble',
                              'success',
                              'warning',
                              'complete',
                            ]
                            .expand((id) => _cues.where((cue) => cue.id == id))
                            .toList();
                    final families = _cues.map((cue) => cue.family).toSet();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KText(
                          'FOLEY · KLANGPALETTE',
                          variant: KTextVariant.caption,
                          style: mutedStyle,
                        ),
                        SizedBox(height: t.spaceControlGap),
                        const KText(
                          'Kleine Klänge. Klares Feedback.',
                          variant: KTextVariant.heading2,
                        ),
                        SizedBox(height: t.spaceControlGap),
                        const KText(
                          '28 kurze Signale für bewusste Momente. Sechs Favoriten als Einstieg.',
                        ),
                        SizedBox(height: t.spaceLayoutSectionGap),
                        KSurface(
                          tone: KSurfaceTone.subtle,
                          child: Padding(
                            padding: EdgeInsets.all(gap),
                            child: Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                  width: (constraints.maxWidth - gap * 3 - 180)
                                      .clamp(180.0, double.infinity),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      KText(
                                        'Lautstärke · ${_volume.round()}%',
                                        variant: KTextVariant.label,
                                      ),
                                      Semantics(
                                        label: 'Lautstärke',
                                        child: KSlider(
                                          label: 'Lautstärke',
                                          value: _volume,
                                          valueLabel: (value) =>
                                              '${value.round()}%',
                                          onChanged: (value) {
                                            setState(() => _volume = value);
                                            if (value == 0) _stopPreview();
                                            unawaited(_updateVolume());
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Semantics(
                                  toggled: _muted,
                                  child: KButton(
                                    label: _muted
                                        ? 'Ton einschalten'
                                        : 'Stummschalten',
                                    variant: KButtonVariant.secondary,
                                    leading: KIcon(
                                      _muted
                                          ? KIconName.volumeX
                                          : KIconName.volume2,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _muted = !_muted;
                                        _status = _muted
                                            ? 'Ton ist stummgeschaltet.'
                                            : 'Ton ist eingeschaltet.';
                                      });
                                      if (_muted) _stopPreview();
                                      unawaited(_updateVolume());
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: gap),
                        FoleyEventPreview(
                          enabled: _eventsEnabled,
                          chat: _chatEnabled,
                          tools: _toolsEnabled,
                          status: _eventStatus,
                          onEnabledChanged: (value) {
                            setState(() => _eventsEnabled = value);
                            if (!value) _stopPreview();
                          },
                          onChatChanged: (value) {
                            setState(() => _chatEnabled = value);
                            if (!value) _stopPreview();
                          },
                          onToolsChanged: (value) {
                            setState(() => _toolsEnabled = value);
                            if (!value) _stopPreview();
                          },
                          onEvent: _eventPreview,
                        ),
                        SizedBox(height: t.spaceLayoutSectionGap),
                        const KText(
                          'Empfohlene Klänge',
                          variant: KTextVariant.heading4,
                        ),
                        SizedBox(height: gap),
                        ...cueRows(recommended),
                        SizedBox(height: t.spaceLayoutSectionGap),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Semantics(
                            expanded: _expanded,
                            child: KButton(
                              label: _expanded
                                  ? 'Weitere Klänge ausblenden'
                                  : 'Alle 28 Klänge entdecken',
                              variant: KButtonVariant.secondary,
                              leading: KIcon(
                                _expanded
                                    ? KIconName.chevronUp
                                    : KIconName.chevronDown,
                              ),
                              onPressed: () =>
                                  setState(() => _expanded = !_expanded),
                            ),
                          ),
                        ),
                        if (_expanded)
                          for (final family in families) ...[
                            SizedBox(height: t.spaceLayoutSectionGap),
                            KText(
                              _cues
                                  .firstWhere((cue) => cue.family == family)
                                  .category,
                              variant: KTextVariant.heading4,
                            ),
                            SizedBox(height: gap),
                            ...cueRows(
                              _cues
                                  .where(
                                    (cue) =>
                                        cue.family == family &&
                                        !cue.recommended,
                                  )
                                  .toList(),
                            ),
                          ],
                        SizedBox(height: gap),
                        Semantics(
                          liveRegion: true,
                          child: KText(
                            _status,
                            variant: KTextVariant.bodySmall,
                          ),
                        ),
                        SizedBox(height: t.spaceLayoutSectionGap),
                        KText(
                          'Klänge ergänzen sichtbares Feedback. Sie starten nur auf Klick.',
                          variant: KTextVariant.caption,
                          style: mutedStyle,
                        ),
                        SizedBox(height: t.spaceControlGap),
                        KText(
                          'Foley · Default · gleiche WAV-Aufnahmen auf Web und Flutter.',
                          variant: KTextVariant.caption,
                          style: mutedStyle,
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
