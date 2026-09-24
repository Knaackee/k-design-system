import 'dart:async';

import 'package:flutter/material.dart';

import 'k_workflow_types.dart';

class KElapsedTime extends StatefulWidget {
  const KElapsedTime({
    this.startedAt,
    this.endedAt,
    this.now,
    this.label,
    this.formatter,
    this.style,
    super.key,
  });

  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? now;
  final String? label;
  final KWorkflowDurationFormatter? formatter;
  final TextStyle? style;

  @override
  State<KElapsedTime> createState() => _KElapsedTimeState();
}

class _KElapsedTimeState extends State<KElapsedTime> {
  Timer? _timer;
  DateTime _clock = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.startedAt != null &&
        widget.endedAt == null &&
        widget.now == null &&
        widget.label == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _clock = DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.label != null) {
      return Text(widget.label!, style: widget.style);
    }
    if (widget.startedAt == null) {
      return Text('–', style: widget.style);
    }
    final running = widget.endedAt == null;
    final end = widget.endedAt ?? widget.now ?? _clock;
    final duration = end.difference(widget.startedAt!);
    return ExcludeSemantics(
      child: Text(
        (widget.formatter ?? _formatDuration)(
          duration.isNegative ? Duration.zero : duration,
          running,
        ),
        style: widget.style,
      ),
    );
  }
}

String _formatDuration(Duration duration, bool running) {
  if (duration.inSeconds < 60) {
    return running ? '${duration.inSeconds} sec.' : '<1 min.';
  }
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return running ? '$minutes:$seconds' : '$minutes min.';
}
