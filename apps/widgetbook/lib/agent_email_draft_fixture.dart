import 'dart:async';
import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class AgentEmailDraftFixture extends StatefulWidget {
  const AgentEmailDraftFixture({this.scenario = 'pending', super.key});
  final String scenario;
  @override
  State<AgentEmailDraftFixture> createState() => _AgentEmailDraftFixtureState();
}

class _AgentEmailDraftFixtureState extends State<AgentEmailDraftFixture> {
  final subject = TextEditingController();
  final editor = GlobalKey<KMarkdownEditorState>();
  KDictationState subjectState = KDictationState.ready;
  KDictationState bodyState = KDictationState.ready;
  TextSelection subjectRange = const TextSelection.collapsed(offset: 0);
  Timer? timer;
  @override
  void dispose() {
    timer?.cancel();
    subject.dispose();
    super.dispose();
  }

  void subjectPressed() {
    if (subjectState == KDictationState.recording) {
      setState(() => subjectState = KDictationState.processing);
      timer = Timer(const Duration(milliseconds: 800), () {
        if (!mounted || status != KAgentEmailDraftStatus.pending) return;
        const text = ' – aktualisiert';
        final start = subjectRange.start.clamp(0, subject.text.length);
        final end = subjectRange.end.clamp(start, subject.text.length);
        subject.value = TextEditingValue(
          text: subject.text.replaceRange(start, end, text),
          selection: TextSelection.collapsed(offset: start + text.length),
        );
        setState(() {
          value = value.copyWith(subject: subject.text);
          subjectState = KDictationState.ready;
        });
      });
    } else {
      subjectRange = subject.selection.isValid
          ? subject.selection
          : TextSelection.collapsed(offset: subject.text.length);
      setState(() => subjectState = KDictationState.recording);
    }
  }

  void bodyPressed() {
    if (bodyState == KDictationState.recording) {
      setState(() => bodyState = KDictationState.processing);
      timer = Timer(const Duration(milliseconds: 800), () {
        if (!mounted || status != KAgentEmailDraftStatus.pending) return;
        editor.currentState?.insertDictation(' Ergänzung aus dem Demo-Diktat.');
        setState(() => bodyState = KDictationState.ready);
      });
    } else {
      if (subjectState != KDictationState.ready) return;
      setState(() => bodyState = KDictationState.recording);
    }
  }

  late KAgentEmailDraftValue value;
  late KAgentEmailDraftStatus status;
  late bool validation;
  List<KAgentEmailDraftAttachment> attachments = const [
    KAgentEmailDraftAttachment(
      id: 'agenda',
      name: 'Projektübersicht.pdf',
      description: 'PDF · 248 KB',
    ),
  ];
  @override
  void initState() {
    super.initState();
    validation = widget.scenario == 'validation';
    status = KAgentEmailDraftStatus.values.firstWhere(
      (item) => item.name == widget.scenario,
      orElse: () => KAgentEmailDraftStatus.pending,
    );
    value = KAgentEmailDraftValue(
      to: validation ? '' : 'Mara Hoffmann <mara.hoffmann@example.com>',
      subject: 'Unterlagen für unseren Termin am Donnerstag',
      markdown:
          'Hallo Mara,\n\nanbei die besprochene Übersicht für unseren Termin am Donnerstag. Passt es für dich weiterhin um 10 Uhr?\n\nViele Grüße\nDennis',
    );
    subject.text = value.subject;
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: KContainer(
      child: KStack(
        align: KLayoutAlign.stretch,
        gap: KLayoutGap.control,
        children: [
          const KText(
            'Diktat-Demo: simuliert, ohne Mikrofonaufnahme. Starten, stoppen, Text prüfen.',
            variant: KTextVariant.caption,
          ),
          KAgentEmailDraft(
            draftId: 'demo-project-mail',
            subjectController: subject,
            subjectDictationState: subjectState,
            subjectDictationOffset: subjectRange.start,
            subjectDictationLabel: subjectState == KDictationState.recording
                ? 'Betreff-Diktat stoppen'
                : 'Betreff diktieren (Demo)',
            onSubjectDictationPressed: bodyState == KDictationState.ready
                ? subjectPressed
                : null,
            editorKey: editor,
            dictationState: bodyState,
            onDictationPressed: bodyPressed,
            showExpandButton: true,
            title: 'Mail',
            from: 'Dennis Knaack <dennis@example.com>',
            value: value,
            onChanged: (next) => setState(() {
              if (subjectState != KDictationState.ready &&
                  next.subject != value.subject) {
                var prefix = 0;
                while (prefix < value.subject.length &&
                    prefix < next.subject.length &&
                    value.subject[prefix] == next.subject[prefix]) {
                  prefix++;
                }
                var oldEnd = value.subject.length, newEnd = next.subject.length;
                while (oldEnd > prefix &&
                    newEnd > prefix &&
                    value.subject[oldEnd - 1] == next.subject[newEnd - 1]) {
                  oldEnd--;
                  newEnd--;
                }
                int map(int offset) => offset <= prefix
                    ? offset
                    : offset >= oldEnd
                    ? offset + newEnd - oldEnd
                    : newEnd;
                subjectRange = TextSelection(
                  baseOffset: map(subjectRange.start),
                  extentOffset: map(subjectRange.end),
                );
              }
              value = next;
              validation = validation && next.to.trim().isEmpty;
            }),
            attachments: attachments,
            onAddAttachment: () => setState(() {
              if (!attachments.any((file) => file.id == 'notes')) {
                attachments = [
                  ...attachments,
                  const KAgentEmailDraftAttachment(
                    id: 'notes',
                    name: 'Gesprächsnotizen.txt',
                    description: 'Text · 2 KB',
                  ),
                ];
              }
            }),
            onRemoveAttachment: (id) => setState(
              () => attachments = attachments
                  .where((file) => file.id != id)
                  .toList(),
            ),
            status: status,
            border: status == KAgentEmailDraftStatus.pending
                ? KCardBorder.aurora
                : KCardBorder.none,
            errors: validation
                ? {
                    KAgentEmailDraftField.to:
                        'Bitte gib mindestens einen Empfänger an.',
                  }
                : const {},
            labels: KAgentEmailDraftLabels(
              from: 'Von',
              to: 'An',
              subject: 'Betreff',
              message: 'Nachricht',
              showBcc: 'Bcc hinzufügen',
              attachments: 'Anhänge',
              addAttachment: 'Anhang hinzufügen',
              removeAttachment: (name) => '$name entfernen',
              send: 'Senden',
              discard: 'Verwerfen',
              expand: 'Nachricht vergrößern',
              collapse: 'Zurück zum Entwurf',
            ),
            onSend: () => setState(() {
              if (value.to.trim().isEmpty) {
                validation = true;
              } else {
                status = KAgentEmailDraftStatus.submitting;
                timer = Timer(const Duration(milliseconds: 800), () {
                  if (mounted) {
                    setState(() => status = KAgentEmailDraftStatus.sent);
                  }
                });
              }
            }),
            onDiscard: () =>
                setState(() => status = KAgentEmailDraftStatus.discarded),
          ),
          if (status != KAgentEmailDraftStatus.pending)
            Semantics(
              liveRegion: true,
              child: KInline(
                gap: KLayoutGap.control,
                align: KLayoutAlign.start,
                children: [
                  if (status == KAgentEmailDraftStatus.submitting)
                    const KSpinner(label: 'Wird gesendet …'),
                  if (status == KAgentEmailDraftStatus.sent)
                    const KIcon(KIconName.check),
                  Expanded(
                    child: KText(switch (status) {
                      KAgentEmailDraftStatus.submitting => 'Wird gesendet …',
                      KAgentEmailDraftStatus.sent => 'Versendet',
                      KAgentEmailDraftStatus.discarded => 'Verworfen',
                      _ => '',
                    }, variant: KTextVariant.caption),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
