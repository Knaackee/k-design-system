import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../basic_display.dart';
import '../extended_components.dart';
import '../actions/k_icon_button.dart';
import '../primitives/k_icon.dart';
import 'k_elapsed_time.dart';
import 'k_workflow_types.dart';

export 'k_elapsed_time.dart';
export 'k_workflow_types.dart';

class KWorkflow extends StatefulWidget {
  const KWorkflow({
    required this.title,
    required this.status,
    required this.phases,
    this.statusLabel,
    this.startedAt,
    this.endedAt,
    this.durationLabel,
    this.stepCountLabel,
    this.presentation = KWorkflowPresentation.auto,
    this.labels = const KWorkflowLabels(),
    this.expandedPhaseIds,
    this.defaultExpandedPhaseIds,
    this.onExpandedPhaseIdsChanged,
    this.onPhaseOpenChanged,
    this.onEventActivate,
    this.eventBuilder,
    this.phaseIconBuilder,
    this.showTechnicalEventsInCompact = false,
    this.now,
    this.durationFormatter,
    this.dateTimeFormatter,
    super.key,
  });

  final String title;
  final KWorkflowStatus status;
  final List<KWorkflowPhase> phases;
  final String? statusLabel;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? durationLabel;
  final String? stepCountLabel;
  final KWorkflowPresentation presentation;
  final KWorkflowLabels labels;
  final Set<String>? expandedPhaseIds;
  final Set<String>? defaultExpandedPhaseIds;
  final ValueChanged<Set<String>>? onExpandedPhaseIdsChanged;
  final KWorkflowPhaseOpenCallback? onPhaseOpenChanged;
  final KWorkflowEventCallback? onEventActivate;
  final KWorkflowEventBuilder? eventBuilder;
  final KWorkflowPhaseIconBuilder? phaseIconBuilder;
  final bool showTechnicalEventsInCompact;
  final DateTime? now;
  final KWorkflowDurationFormatter? durationFormatter;
  final KWorkflowDateTimeFormatter? dateTimeFormatter;

  @override
  State<KWorkflow> createState() => _KWorkflowState();
}

class _KWorkflowState extends State<KWorkflow> {
  String? _hoveredPhaseId;
  late Set<String> _expanded =
      widget.defaultExpandedPhaseIds ??
      widget.phases
          .where(
            (phase) =>
                phase.defaultOpen ?? phase.status != KWorkflowStatus.succeeded,
          )
          .map((phase) => phase.id)
          .toSet();

  void _toggle(KWorkflowPhase phase) {
    final current = widget.expandedPhaseIds ?? _expanded;
    final next = {...current};
    final open = !next.contains(phase.id);
    open ? next.add(phase.id) : next.remove(phase.id);
    if (widget.expandedPhaseIds == null) {
      setState(() => _expanded = next);
    }
    widget.onExpandedPhaseIdsChanged?.call(next);
    widget.onPhaseOpenChanged?.call(phase, open);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            widget.presentation == KWorkflowPresentation.compact ||
            (widget.presentation == KWorkflowPresentation.auto &&
                constraints.maxWidth < 600);
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: const {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.stylus,
              PointerDeviceKind.invertedStylus,
              PointerDeviceKind.trackpad,
            },
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(t.spaceLayoutGutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _summary(context, compact),
                  Divider(height: t.spaceLayoutSectionGap * 2),
                  Row(
                    children: [
                      if (!compact) ...[
                        const KIcon(KIconName.slidersHorizontal),
                        SizedBox(width: t.spaceControlGap),
                      ],
                      Text(
                        widget.labels.timeline,
                        style: TextStyle(fontWeight: t.fontLabelWeight),
                      ),
                    ],
                  ),
                  SizedBox(height: t.spaceControlInsetInline),
                  for (var index = 0; index < widget.phases.length; index++)
                    _phase(context, widget.phases[index], index, compact),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summary(BuildContext context, bool compact) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final identity = Wrap(
      spacing: t.spaceControlGap,
      runSpacing: t.spaceControlGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: t.fontHeading5Size,
            fontWeight: t.fontHeadingWeight,
          ),
        ),
        KBadge(
          variant: _badgeVariant(widget.status),
          child: Text(
            widget.statusLabel ?? widget.labels.status(widget.status),
          ),
        ),
      ],
    );
    final metrics = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _metric(
          context,
          widget.labels.steps,
          widget.stepCountLabel ?? '${widget.phases.length}',
        ),
        SizedBox(width: t.spaceLayoutSectionGap),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.labels.duration,
              style: TextStyle(color: t.colorTextMuted),
            ),
            KElapsedTime(
              startedAt: widget.startedAt,
              endedAt: widget.endedAt,
              now: widget.now,
              label: widget.durationLabel,
              formatter: widget.durationFormatter,
            ),
          ],
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact) ...[
          identity,
          SizedBox(height: t.spaceControlInsetInline),
          metrics,
        ] else
          Row(
            children: [
              Expanded(child: identity),
              metrics,
            ],
          ),
        if (widget.startedAt != null || widget.endedAt != null) ...[
          SizedBox(height: t.spaceControlInsetInline),
          Wrap(
            spacing: t.spaceLayoutSectionGap,
            runSpacing: t.spaceControlGap,
            children: [
              _date(
                context,
                widget.labels.start,
                widget.startedAt == null
                    ? '–'
                    : _formatDateTime(widget.startedAt!),
              ),
              _date(
                context,
                widget.labels.end,
                widget.endedAt == null
                    ? widget.labels.notEnded
                    : _formatDateTime(widget.endedAt!),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: t.colorTextMuted,
            fontSize: t.fontCaptionSize,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: t.fontBodySmallSize,
            fontWeight: t.fontLabelWeight,
          ),
        ),
      ],
    );
  }

  Widget _date(BuildContext context, String label, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$label  ',
        style: TextStyle(
          color: Theme.of(context).extension<KDesignTokens>()!.colorTextMuted,
          fontSize: Theme.of(
            context,
          ).extension<KDesignTokens>()!.fontCaptionSize,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: Theme.of(
            context,
          ).extension<KDesignTokens>()!.fontBodySmallSize,
          fontWeight: Theme.of(
            context,
          ).extension<KDesignTokens>()!.fontLabelWeight,
        ),
      ),
    ],
  );

  Widget _phase(
    BuildContext context,
    KWorkflowPhase phase,
    int index,
    bool compact,
  ) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final expanded = (widget.expandedPhaseIds ?? _expanded).contains(phase.id);
    final events = compact && !widget.showTechnicalEventsInCompact
        ? phase.events.where(
            (event) => event.importance != KWorkflowEventImportance.technical,
          )
        : phase.events;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: t.sizeHitTarget,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (index < widget.phases.length - 1)
                  Positioned(
                    top: t.sizeHitTarget / 2,
                    bottom: 0,
                    child: Container(
                      width: t.borderWidthDefault,
                      color: t.colorBorderDefault,
                    ),
                  ),
                Container(
                  width: t.sizeHitTarget,
                  height: t.sizeHitTarget,
                  alignment: Alignment.center,
                  color: t.colorSurfaceCanvas,
                  child:
                      widget.phaseIconBuilder?.call(context, phase) ??
                      _stateIcon(context, phase.status),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: t.spaceLayoutSectionGap),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Transform.translate(
                    offset: Offset(0, -t.borderWidthStrong),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            button: true,
                            expanded: expanded,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              onEnter: (_) =>
                                  setState(() => _hoveredPhaseId = phase.id),
                              onExit: (_) => setState(() {
                                if (_hoveredPhaseId == phase.id) {
                                  _hoveredPhaseId = null;
                                }
                              }),
                              child: AnimatedContainer(
                                duration: t.motionFast,
                                decoration: BoxDecoration(
                                  color: _hoveredPhaseId == phase.id
                                      ? t.colorSurfaceRaised
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    t.radiusControl,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => _toggle(phase),
                                  hoverColor: Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    t.radiusControl,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: t.sizeHitTarget,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        t.spaceControlGap,
                                      ),
                                      child: Row(
                                        children: [
                                          KIcon(
                                            expanded
                                                ? KIconName.chevronDown
                                                : KIconName.chevronRight,
                                          ),
                                          SizedBox(width: t.spaceControlGap),
                                          Expanded(
                                            child: Text(
                                              phase.title,
                                              style: TextStyle(
                                                fontSize: t.fontLabelSize,
                                                fontWeight: t.fontLabelWeight,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        KElapsedTime(
                          startedAt: phase.startedAt,
                          endedAt: phase.endedAt,
                          now: widget.now,
                          label: phase.durationLabel,
                          formatter: widget.durationFormatter,
                          style: TextStyle(
                            color: t.colorTextMuted,
                            fontSize: t.fontCaptionSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (expanded)
                    for (final event in events)
                      _event(context, event, phase, compact),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _event(
    BuildContext context,
    KWorkflowEvent event,
    KWorkflowPhase phase,
    bool compact,
  ) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final custom = widget.eventBuilder?.call(context, event, phase);
    final child =
        custom ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                KIcon(_eventIcon(event), size: 16, color: t.colorTextMuted),
                SizedBox(width: t.spaceControlGap),
                Expanded(
                  child: Text(
                    event.title.toUpperCase(),
                    style: TextStyle(
                      color: t.colorTextMuted,
                      fontSize: t.fontCaptionSize,
                      fontWeight: t.fontLabelWeight,
                    ),
                  ),
                ),
                Text(
                  '${event.sequence == null ? '' : '#${event.sequence} · '}${event.timestamp ?? ''}',
                  style: TextStyle(
                    color: t.colorTextMuted,
                    fontSize: t.fontCaptionSize,
                  ),
                ),
              ],
            ),
            if (event.description != null) ...[
              SizedBox(height: t.spaceControlGap),
              Text(
                event.description!,
                style: TextStyle(
                  fontSize: t.fontBodySmallSize,
                  fontWeight: t.fontBodyWeight,
                  height:
                      t.fontBodySmallLineHeight / t.fontBodySmallSize,
                ),
              ),
            ],
            if (event.content != null) ...[
              SizedBox(height: t.spaceControlGap),
              event.content!,
            ],
          ],
        );
    final decoration = BoxDecoration(
      color: event.kind == KWorkflowEventKind.result
          ? t.colorStatusSuccessBackground
          : event.kind == KWorkflowEventKind.log
          ? t.colorSurfaceRaised
          : Colors.transparent,
      border: event.kind == KWorkflowEventKind.result
          ? Border.all(color: t.colorStatusSuccessBorder)
          : null,
      borderRadius: BorderRadius.circular(t.radiusCard),
    );
    final interactive = event.interactive && widget.onEventActivate != null;
    return Padding(
      padding: EdgeInsets.only(top: t.spaceControlGap),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? t.spaceControlGap : t.spaceControlInsetInline,
          vertical: t.spaceControlInsetInline,
        ),
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            child,
            if (interactive)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: KIconButton(
                  label: event.title,
                  icon: KIconName.chevronRight,
                  onPressed: () => widget.onEventActivate?.call(event, phase),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) =>
      widget.dateTimeFormatter?.call(value) ?? _dateTime(value);
}

Widget _stateIcon(BuildContext context, KWorkflowStatus status) {
  final t = Theme.of(context).extension<KDesignTokens>()!;
  if (status == KWorkflowStatus.running) {
    return KSpinner(label: 'Running', size: 16);
  }
  return KIcon(
    _statusIcon(status),
    color: status == KWorkflowStatus.succeeded
        ? t.colorStatusSuccessForeground
        : t.colorTextMuted,
  );
}

KIconName _statusIcon(KWorkflowStatus status) => switch (status) {
  KWorkflowStatus.succeeded => KIconName.circleCheck,
  KWorkflowStatus.failed => KIconName.circleAlert,
  KWorkflowStatus.cancelled => KIconName.x,
  KWorkflowStatus.paused || KWorkflowStatus.waiting => KIconName.clock,
  _ => KIconName.info,
};

KIconName _eventIcon(KWorkflowEvent event) => switch (event.kind) {
  KWorkflowEventKind.artifact => KIconName.paperclip,
  KWorkflowEventKind.result ||
  KWorkflowEventKind.approval => KIconName.circleCheck,
  KWorkflowEventKind.question => KIconName.info,
  KWorkflowEventKind.log => KIconName.fileText,
  _ => _statusIcon(event.status ?? KWorkflowStatus.pending),
};

KBadgeVariant _badgeVariant(KWorkflowStatus status) => switch (status) {
  KWorkflowStatus.failed => KBadgeVariant.destructive,
  KWorkflowStatus.succeeded => KBadgeVariant.success,
  KWorkflowStatus.running => KBadgeVariant.info,
  KWorkflowStatus.paused || KWorkflowStatus.waiting => KBadgeVariant.warning,
  KWorkflowStatus.cancelled => KBadgeVariant.secondary,
  KWorkflowStatus.pending => KBadgeVariant.outline,
};

String _dateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}, '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
