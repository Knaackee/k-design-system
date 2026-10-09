part of 'k_workflow.dart';

extension _WorkflowParts on _KWorkflowState {
  Widget _summary(BuildContext context, bool compact) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final identity = Wrap(
      spacing: t.spaceControlGap,
      runSpacing: t.spaceControlGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Semantics(
          key: const ValueKey('workflow-heading'),
          header: true,
          headingLevel: 3,
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: t.fontHeading5Size,
              fontWeight: t.fontHeadingWeight,
            ),
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
    final metrics = Wrap(
      spacing: t.spaceLayoutSectionGap,
      runSpacing: t.spaceControlGap,
      children: [
        _metric(
          context,
          widget.labels.steps,
          widget.stepCountLabel ?? '${widget.phases.length}',
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.labels.duration,
              style: TextStyle(
                color: t.colorTextMuted,
                fontSize: t.fontCaptionSize,
              ),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: t.spaceControlGap,
            runSpacing: t.spaceControlGap,
            children: [
              identity,
              if (widget.summaryActions != null) widget.summaryActions!,
            ],
          ),
          SizedBox(height: t.spaceControlInsetInline),
          metrics,
        ] else
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: t.spaceLayoutSectionGap,
            runSpacing: t.spaceControlInsetInline,
            children: [
              identity,
              metrics,
              if (widget.summaryActions != null) widget.summaryActions!,
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

  Widget _date(BuildContext context, String label, String value) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
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

  Widget _event(
    BuildContext context,
    KWorkflowEvent event,
    KWorkflowPhase phase,
    bool compact,
  ) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final custom = widget.eventBuilder?.call(context, event, phase);
    if (custom != null) return custom;
    final child = Column(
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
              height: t.fontBodySmallLineHeight / t.fontBodySmallSize,
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
