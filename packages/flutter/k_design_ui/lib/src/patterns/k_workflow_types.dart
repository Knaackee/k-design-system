import 'package:flutter/material.dart';

enum KWorkflowStatus {
  pending,
  running,
  paused,
  waiting,
  succeeded,
  failed,
  cancelled,
}

enum KWorkflowEventKind {
  status,
  log,
  progress,
  question,
  answer,
  result,
  approval,
  artifact,
  custom,
}

enum KWorkflowPresentation { auto, detailed, compact }

enum KWorkflowEventImportance { primary, secondary, technical }

class KWorkflowEvent {
  const KWorkflowEvent({
    required this.id,
    required this.kind,
    required this.title,
    this.description,
    this.timestamp,
    this.sequence,
    this.status,
    this.content,
    this.importance = KWorkflowEventImportance.primary,
    this.interactive = false,
  });

  final String id;
  final KWorkflowEventKind kind;
  final String title;
  final String? description;
  final String? timestamp;
  final int? sequence;
  final KWorkflowStatus? status;
  final Widget? content;
  final KWorkflowEventImportance importance;
  final bool interactive;
}

class KWorkflowPhase {
  const KWorkflowPhase({
    required this.id,
    required this.title,
    required this.status,
    required this.events,
    this.startedAt,
    this.endedAt,
    this.durationLabel,
    this.defaultOpen,
  });

  final String id;
  final String title;
  final KWorkflowStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? durationLabel;
  final List<KWorkflowEvent> events;
  final bool? defaultOpen;
}

class KWorkflowLabels {
  const KWorkflowLabels({
    this.timeline = 'Workflow',
    this.steps = 'Steps',
    this.duration = 'Duration',
    this.start = 'Start',
    this.end = 'End',
    this.notEnded = 'Not finished',
    this.running = 'Running',
    this.pending = 'Pending',
    this.paused = 'Paused',
    this.waiting = 'Waiting',
    this.succeeded = 'Completed',
    this.failed = 'Failed',
    this.cancelled = 'Cancelled',
  });

  final String timeline;
  final String steps;
  final String duration;
  final String start;
  final String end;
  final String notEnded;
  final String running;
  final String pending;
  final String paused;
  final String waiting;
  final String succeeded;
  final String failed;
  final String cancelled;

  String status(KWorkflowStatus value) => switch (value) {
    KWorkflowStatus.running => running,
    KWorkflowStatus.pending => pending,
    KWorkflowStatus.paused => paused,
    KWorkflowStatus.waiting => waiting,
    KWorkflowStatus.succeeded => succeeded,
    KWorkflowStatus.failed => failed,
    KWorkflowStatus.cancelled => cancelled,
  };
}

typedef KWorkflowEventBuilder =
    Widget? Function(
      BuildContext context,
      KWorkflowEvent event,
      KWorkflowPhase phase,
    );
typedef KWorkflowPhaseIconBuilder =
    Widget Function(BuildContext context, KWorkflowPhase phase);
typedef KWorkflowEventCallback =
    void Function(KWorkflowEvent event, KWorkflowPhase phase);
typedef KWorkflowPhaseOpenCallback =
    void Function(KWorkflowPhase phase, bool open);
typedef KWorkflowDurationFormatter =
    String Function(Duration duration, bool running);
typedef KWorkflowDateTimeFormatter = String Function(DateTime value);
