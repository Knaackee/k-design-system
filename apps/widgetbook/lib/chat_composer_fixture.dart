import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class ChatComposerFixture extends StatefulWidget {
  const ChatComposerFixture({this.mobile = false, super.key});
  final bool mobile;
  @override
  State<ChatComposerFixture> createState() => _ChatComposerFixtureState();
}

class _ChatComposerFixtureState extends State<ChatComposerFixture> {
  String value = 'Check both platforms';
  bool voiceActive = false;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: widget.mobile ? 360 : 800,
      child: SingleChildScrollView(
        child: KStack(
          align: KLayoutAlign.stretch,
          gap: KLayoutGap.section,
          children: [
            KChatComposer(
              value: value,
              onValueChanged: (next) => setState(() => value = next),
              onSubmit: (_) {},
              onAttach: () {},
              voiceActive: voiceActive,
              voiceCapture: KChatVoiceCapture(
                samples: const [.001, .008, .03, .12, .008, .004],
                onCancel: () => setState(() => voiceActive = false),
                onSend: () => setState(() => voiceActive = false),
              ),
              onVoiceInput: () => setState(() => voiceActive = !voiceActive),
            ),
            KChatComposer(
              value: 'Recording',
              onValueChanged: (_) {},
              onSubmit: (_) {},
              onAttach: () {},
              voiceActive: true,
              voiceAudioLevel: 0.5,
              voiceCapture: KChatVoiceCapture(
                samples: const [.004, .06, .015, .2, .008],
                onCancel: () {},
                onSend: () {},
              ),
              onVoiceInput: () {},
            ),
            KChatComposer(
              value: 'Unavailable',
              disabled: true,
              onValueChanged: (_) {},
              onSubmit: (_) {},
              onVoiceInput: () {},
            ),
            KChatComposer(
              value: '',
              runState: KChatRunState.streaming,
              onValueChanged: (_) {},
              onSubmit: (_) {},
              onStop: () {},
              onVoiceInput: () {},
            ),
            KChatComposer(
              value: value,
              onValueChanged: (next) => setState(() => value = next),
              onSubmit: (_) => setState(() => value = ''),
              runState: KChatRunState.streaming,
              allowSubmitWhileRunning: true,
              onStop: () {},
              onVoiceInput: () {},
            ),
            for (final state in [
              KDictationState.processing,
              KDictationState.unavailable,
              KDictationState.error,
            ])
              KChatComposer(
                value: state.name,
                voiceState: state,
                onValueChanged: (_) {},
                onSubmit: (_) {},
                onVoiceInput: () {},
              ),
            KChatComposer(
              value: 'Voice omitted',
              onValueChanged: (_) {},
              onSubmit: (_) {},
            ),
          ],
        ),
      ),
    ),
  );
}

/// Deterministic interaction preview. Never captures audio or sends a message.
class VoiceComposerFixture extends StatefulWidget {
  const VoiceComposerFixture({this.mobile = false, super.key});

  final bool mobile;

  @override
  State<VoiceComposerFixture> createState() => _VoiceComposerFixtureState();
}

class _VoiceComposerFixtureState extends State<VoiceComposerFixture> {
  String _value = '';
  String _result = '';
  KDictationState _state = KDictationState.ready;
  List<double> _samples = const [];
  bool _failNext = false;
  bool _calling = false;
  Timer? _samplesTimer;
  Timer? _pending;

  @override
  void dispose() {
    _samplesTimer?.cancel();
    _pending?.cancel();
    super.dispose();
  }

  void _startRecording() {
    _samplesTimer?.cancel();
    var frame = 0;
    setState(() {
      _samples = const [];
      _state = KDictationState.recording;
    });
    _samplesTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      frame++;
      final level = (math.sin(frame * .47) * math.sin(frame * .13)).abs() * .12;
      setState(
        () => _samples = [
          ..._samples.skip(math.max(0, _samples.length - 79)),
          level,
        ],
      );
    });
  }

  void _finish({required bool send}) {
    if (_state == KDictationState.processing) return;
    _samplesTimer?.cancel();
    setState(() => _state = KDictationState.processing);
    _pending?.cancel();
    _pending = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_failNext) {
        setState(() {
          _failNext = false;
          _state = KDictationState.error;
        });
        return;
      }
      final text = [
        _value.trim(),
        'Erinnere mich morgen daran, den Entwurf zu prüfen.',
      ].where((part) => part.isNotEmpty).join(' ');
      setState(() {
        _state = KDictationState.ready;
        _samples = const [];
        if (send) {
          _result = text;
          _value = '';
        } else {
          _value = text;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: SizedBox(
      width: widget.mobile ? 360 : 920,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: KStack(
          align: KLayoutAlign.stretch,
          gap: KLayoutGap.section,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eine Zeile. Schreiben, diktieren, sprechen.',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Interaktive Vorschau · simulierte Aufnahme, kein Mikrofonzugriff.',
                ),
              ],
            ),
            KChatComposer(
              value: _value,
              onValueChanged: (value) => setState(() => _value = value),
              onSubmit: (text) => setState(() {
                _result = text;
                _value = '';
              }),
              disabled: _calling,
              leadingTools: [
                KMenuButton(
                  label: 'Hinzufügen',
                  overflow: true,
                  triggerContent: const KIcon(KIconName.plus),
                  disabled: _calling,
                  actions: [
                    KMenuAction(
                      id: 'image',
                      label: 'Bild auswählen',
                      iconContent: const KIcon(
                        KIconName.image,
                        strokeWidth: 1.5,
                      ),
                      onSelect: () => setState(
                        () => _result = 'Bildauswahl geöffnet (Vorschau).',
                      ),
                    ),
                    KMenuAction(
                      id: 'camera',
                      label: 'Foto aufnehmen',
                      iconContent: const KIcon(
                        KIconName.camera,
                        strokeWidth: 1.5,
                      ),
                      onSelect: () => setState(
                        () => _result = 'Kamera geöffnet (Vorschau).',
                      ),
                    ),
                    KMenuAction(
                      id: 'document',
                      label: 'Datei auswählen',
                      iconContent: const KIcon(
                        KIconName.file,
                        strokeWidth: 1.5,
                      ),
                      onSelect: () => setState(
                        () => _result = 'Dateiauswahl geöffnet (Vorschau).',
                      ),
                    ),
                  ],
                ),
              ],
              onStartCall: () => setState(() => _calling = true),
              voiceState: _state,
              onVoiceInput: () {
                if (_state == KDictationState.recording ||
                    _state == KDictationState.error) {
                  _finish(send: false);
                } else {
                  _startRecording();
                }
              },
              voiceCapture: KChatVoiceCapture(
                samples: _samples,
                error: 'Nicht erkannt. Erneut versuchen.',
                onCancel: () {
                  _samplesTimer?.cancel();
                  _pending?.cancel();
                  setState(() {
                    _state = KDictationState.ready;
                    _samples = const [];
                  });
                },
                onSend: () => _finish(send: true),
              ),
              labels: const KChatComposerLabels(
                input: 'Nachricht',
                placeholder: 'Nachricht …',
                attach: 'Datei hinzufügen',
                voice: 'Diktat starten',
                stopVoice: 'Aufnahme stoppen und Text prüfen',
                cancelVoice: 'Aufnahme verwerfen',
                sendVoice: 'Diktat direkt senden',
                processingVoice: 'Wird transkribiert …',
                errorVoice: 'Transkription erneut versuchen',
                call: 'Telefonat starten',
                send: 'Nachricht senden',
              ),
            ),
            if (_calling)
              KButton(
                label: 'Demo-Telefonat beenden',
                onPressed: () => setState(() => _calling = false),
              ),
            Text(
              _calling
                  ? 'Telefonat gestartet (Vorschau).'
                  : _result.isNotEmpty
                  ? 'Demo-Ergebnis: $_result'
                  : 'Mikrofon: aufnehmen · Stopp: Text prüfen · Pfeil: direkt senden',
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: KButton(
                label: _failNext
                    ? 'Nächste Transkription schlägt fehl'
                    : 'Fehlerfall ausprobieren',
                variant: KButtonVariant.ghost,
                onPressed: () => setState(() => _failNext = !_failNext),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
