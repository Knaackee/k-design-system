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

part 'k_workflow_parts.dart';

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
    this.toolbarActions,
    this.summaryActions,
    this.scrollable = true,
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

  /// Consumer-controlled actions beside the timeline heading.
  final Widget? toolbarActions;
  final Widget? summaryActions;

  /// Disable when the consumer provides the scroll controller (for a sheet).
  final bool scrollable;
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

  @override
  void didUpdateWidget(covariant KWorkflow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expandedPhaseIds != null) return;
    final previousIds = oldWidget.phases.map((phase) => phase.id).toSet();
    _expanded = {
      ..._expanded,
      for (final phase in widget.phases)
        if (!previousIds.contains(phase.id) &&
            (phase.defaultOpen ?? phase.status != KWorkflowStatus.succeeded))
          phase.id,
    };
  }

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
          child: _scrollBody(
            child: Padding(
              padding: EdgeInsets.all(
                compact ? t.spaceControlGap : t.spaceLayoutGutter,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _summary(context, compact),
                  Divider(
                    height: t.spaceControlInsetInline * 2,
                    color: t.colorBorderDefault,
                    thickness: t.borderWidthDefault,
                  ),
                  Row(
                    children: [
                      if (!compact) ...[
                        const KIcon(KIconName.slidersHorizontal),
                        SizedBox(width: t.spaceControlGap),
                      ],
                      Text(
                        widget.labels.timeline,
                        style: TextStyle(
                          fontSize: t.fontLabelSize,
                          fontWeight: t.fontLabelWeight,
                        ),
                      ),
                      if (widget.toolbarActions != null) ...[
                        SizedBox(width: t.spaceControlGap),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: widget.toolbarActions!,
                          ),
                        ),
                      ],
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

  Widget _scrollBody({required Widget child}) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return DefaultTextStyle.merge(
      style: TextStyle(
        fontFamily: t.fontFamily,
        fontSize: t.fontBodySmallSize,
        fontWeight: t.fontBodyWeight,
        color: t.colorTextPrimary,
        height: t.fontBodySmallLineHeight / t.fontBodySmallSize,
      ),
      child: widget.scrollable
          ? SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: child,
            )
          : child,
    );
  }

  Widget _phase(
    BuildContext context,
    KWorkflowPhase phase,
    int index,
    bool compact,
  ) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final railWidth = compact ? t.sizeIconDefault : t.sizeHitTarget;
    final firstLineHeight = MediaQuery.textScalerOf(
      context,
    ).scale(t.fontBodySmallLineHeight);
    final headerInset = ((t.sizeHitTarget - firstLineHeight) / 2)
        .clamp(0.0, double.infinity)
        .toDouble();
    final expanded = (widget.expandedPhaseIds ?? _expanded).contains(phase.id);
    final events = compact && !widget.showTechnicalEventsInCompact
        ? phase.events.where(
            (event) => event.importance != KWorkflowEventImportance.technical,
          )
        : phase.events;
    return Stack(
      children: [
        if (index < widget.phases.length - 1)
          PositionedDirectional(
            start: railWidth / 2,
            top: t.sizeHitTarget / 2,
            bottom: 0,
            child: Container(
              width: t.borderWidthDefault,
              color: t.colorBorderDefault,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: railWidth,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: railWidth,
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
                padding: EdgeInsets.only(bottom: t.spaceControlGap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Semantics(
                            button: true,
                            label:
                                '${phase.title}, ${widget.labels.status(phase.status)}',
                            expanded: expanded,
                            excludeSemantics: true,
                            onTap: () => _toggle(phase),
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
                                  key: ValueKey('workflow-phase-${phase.id}'),
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
                                      padding: EdgeInsets.symmetric(
                                        horizontal: compact
                                            ? 0
                                            : t.spaceControlGap,
                                        vertical: headerInset,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AnimatedRotation(
                                            turns: expanded ? .25 : 0,
                                            duration:
                                                MediaQuery.disableAnimationsOf(
                                                  context,
                                                )
                                                ? Duration.zero
                                                : t.motionEntry,
                                            child: SizedBox(
                                              height:
                                                  MediaQuery.textScalerOf(
                                                    context,
                                                  ).scale(
                                                    t.fontBodySmallLineHeight,
                                                  ),
                                              child: const Center(
                                                child: KIcon(
                                                  KIconName.chevronRight,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: compact
                                                ? t.spaceControlGap / 2
                                                : t.spaceControlGap,
                                          ),
                                          Expanded(
                                            child: Text(
                                              phase.title,
                                              style: TextStyle(
                                                fontSize: t.fontBodySmallSize,
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
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top:
                                  headerInset +
                                  (firstLineHeight -
                                          MediaQuery.textScalerOf(
                                            context,
                                          ).scale(
                                            t.fontCaptionSize *
                                                t.fontBodySmallLineHeight /
                                                t.fontBodySmallSize,
                                          )) /
                                      2,
                            ),
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: KElapsedTime(
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
                            ),
                          ),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : t.motionEntry,
                      alignment: Alignment.topCenter,
                      child: Visibility(
                        visible: expanded,
                        maintainState: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final event in events)
                              _event(context, event, phase, compact),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
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
