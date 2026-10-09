import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../basic_components.dart';
import '../extended_components.dart';
import '../primitives/k_button.dart';
import '../forms/k_input.dart';
import '../forms/k_textarea.dart';
import '../primitives/k_disclosure.dart';
import '../primitives/k_icon.dart';
import 'k_chat_types.dart';

typedef KAgentToolRenderer =
    Widget Function(BuildContext context, KAgentToolPart part);

class KAgentToolCall extends StatelessWidget {
  const KAgentToolCall({
    required this.part,
    this.renderer,
    this.showContentBorder = true,
    this.wrapTitle = false,
    super.key,
  });
  final KAgentToolPart part;
  final KAgentToolRenderer? renderer;
  final bool showContentBorder;
  final bool wrapTitle;
  @override
  Widget build(BuildContext context) {
    if (renderer case final custom?) return custom(context, part);
    final t = _tokens(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KDisclosure(
          title: part.title,
          titleLineHeight:
              KDesignTokenVariants.typeScaleCompactFontBodyLineHeight,
          titleWidget: _AgentDisclosureTitle(
            title: part.title,
            wrap: wrapTitle,
            running: part.state == KAgentToolState.running,
          ),
          presentation: KDisclosurePresentation.compact,
          showContentBorder: showContentBorder,
          leadingIcon: _StateIcon(state: part.state),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (part.description case final description?) Text(description),
              if (part.arguments != null)
                _AgentData(label: 'Arguments', value: part.arguments),
              if (part.result != null)
                _AgentData(label: 'Result', value: part.result),
            ],
          ),
        ),
        if (part.error case final error?) ...[
          SizedBox(height: t.spaceControlGap),
          KAlert(tone: KStatusTone.error, title: Text(error)),
        ],
      ],
    );
  }
}

class KAgentToolGroup extends StatelessWidget {
  const KAgentToolGroup({required this.parts, super.key});

  final List<KAgentToolPart> parts;

  @override
  Widget build(BuildContext context) {
    assert(parts.isNotEmpty, 'KAgentToolGroup requires at least one part.');
    final state = _groupState(parts);
    final title = '${parts.first.title} · ${parts.length}×';
    return KDisclosure(
      title: title,
      titleWidget: _AgentDisclosureTitle(
        title: title,
        running: state == KAgentToolState.running,
      ),
      presentation: KDisclosurePresentation.compact,
      leadingIcon: _StateIcon(state: state),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final part in parts) KAgentToolCall(part: part)],
      ),
    );
  }
}

class KAgentApproval extends StatefulWidget {
  const KAgentApproval({
    required this.part,
    this.onResponse,
    this.reasonLabel = 'Add a note (optional)',
    super.key,
  });
  final KAgentApprovalPart part;
  final ValueChanged<KAgentApprovalResponse>? onResponse;
  final String reasonLabel;
  @override
  State<KAgentApproval> createState() => _KAgentApprovalState();
}

class _KAgentApprovalState extends State<KAgentApproval> {
  final _reason = TextEditingController();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _tokens(context);
    final part = widget.part;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.all(t.spaceControlGap),
        decoration: _cardDecoration(t),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KIcon(KIconName.lock),
                SizedBox(width: t.spaceControlGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(part.title, style: _heading5Style(t)),
                      if (part.description case final description?)
                        Padding(
                          padding: EdgeInsets.only(top: t.spaceControlGap),
                          child: Text(description, style: _bodyStyle(t)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (part.detail case final detail?)
              _AgentData(label: '', value: detail),
            if (part.state == KAgentResolutionState.pending) ...[
              SizedBox(height: t.spaceControlInsetInline),
              KDisclosure(
                title: widget.reasonLabel,
                presentation: KDisclosurePresentation.compact,
                titleWidget: Text(widget.reasonLabel, style: _captionStyle(t)),
                child: KTextarea(
                  controller: _reason,
                  label: widget.reasonLabel,
                  rows: 2,
                ),
              ),
              SizedBox(height: t.spaceContentActionGap),
              Wrap(
                spacing: t.spaceControlGap,
                runSpacing: t.spaceControlGap,
                children: [
                  for (final option in part.options)
                    KButton(
                      label: option.label,
                      variant: option.primary
                          ? KButtonVariant.primary
                          : KButtonVariant.secondary,
                      onPressed: () => widget.onResponse?.call(
                        KAgentApprovalResponse(
                          approvalId: part.id,
                          optionId: option.id,
                          reason: _reason.text.trim().isEmpty
                              ? null
                              : _reason.text.trim(),
                        ),
                      ),
                    ),
                ],
              ),
            ] else ...[
              SizedBox(height: t.spaceControlGap),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: KBadge(
                  variant: part.state == KAgentResolutionState.rejected
                      ? KBadgeVariant.destructive
                      : KBadgeVariant.outline,
                  child: Text(
                    part.responseSummary ?? _enumLabel(part.state.name),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class KAgentQuestion extends StatefulWidget {
  const KAgentQuestion({
    required this.part,
    this.onResponse,
    this.inputBuilder,
    super.key,
  });
  final KAgentQuestionPart part;
  final ValueChanged<KAgentQuestionResponse>? onResponse;

  /// Builds the consumer-owned text input, using the question controller.
  ///
  /// The default is the design-system single-line [KInput]. Consumers can
  /// provide a [KTextarea] or a decorated input with dictation actions.
  final Widget Function(TextEditingController controller)? inputBuilder;
  @override
  State<KAgentQuestion> createState() => _KAgentQuestionState();
}

class _KAgentQuestionState extends State<KAgentQuestion> {
  final _text = TextEditingController();
  late final Set<String> _selected = {...widget.part.selectedOptionIds};
  @override
  void dispose() {
    _text.removeListener(_textChanged);
    _text.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _text.addListener(_textChanged);
  }

  void _textChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final t = _tokens(context);
    final part = widget.part;
    final headingStyle = _heading5Style(t);
    final questionIcon = SizedBox(
      height:
          MediaQuery.textScalerOf(context).scale(headingStyle.fontSize!) *
          headingStyle.height!,
      child: const Center(child: KIcon(KIconName.circleQuestionMark)),
    );
    if (part.state != KAgentResolutionState.pending) {
      return Container(
        padding: EdgeInsets.all(t.spaceControlGap),
        decoration: _cardDecoration(t),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            questionIcon,
            SizedBox(width: t.spaceControlGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(part.title, style: _heading5Style(t)),
                  Text(
                    part.answerSummary ?? _enumLabel(part.state.name),
                    style: _bodyStyle(t),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final isText = part.kind == KAgentQuestionKind.text;
    return Container(
      padding: EdgeInsets.all(t.spaceControlGap),
      decoration: _cardDecoration(t),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              questionIcon,
              SizedBox(width: t.spaceControlGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(part.title, style: _heading5Style(t)),
                    if (part.description case final description?)
                      Padding(
                        padding: EdgeInsets.only(top: t.spaceControlGap),
                        child: Text(description, style: _bodyStyle(t)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isText) ...[
            SizedBox(height: t.spaceControlGap),
            widget.inputBuilder?.call(_text) ??
                KInput(controller: _text, placeholder: part.placeholder),
          ],
          if (part.options.isNotEmpty) ...[
            SizedBox(height: t.spaceControlInsetInline),
            for (var index = 0; index < part.options.length; index++) ...[
              if (index > 0) SizedBox(height: t.spaceControlGap),
              _QuestionOptionRow(
                option: part.options[index],
                selected: _selected.contains(part.options[index].id),
                multiple: part.kind == KAgentQuestionKind.multipleChoice,
                onActivate: () => _toggle(part.options[index].id),
              ),
            ],
          ],
          SizedBox(height: t.spaceContentActionGap),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: KButton(
              label: part.submitLabel ?? 'Continue',
              onPressed: isText
                  ? (_text.text.trim().isEmpty ? null : _submit)
                  : (_selected.isEmpty ? null : _submit),
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(String id) => setState(() {
    if (widget.part.kind != KAgentQuestionKind.multipleChoice) {
      _selected
        ..clear()
        ..add(id);
      return;
    }
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
  });

  void _submit() => widget.onResponse?.call(
    KAgentQuestionResponse(
      questionId: widget.part.id,
      optionIds: _selected.toList(growable: false),
      text: _text.text.trim().isEmpty ? null : _text.text.trim(),
    ),
  );
}

class KAgentTaskGroup extends StatelessWidget {
  const KAgentTaskGroup({required this.part, super.key});
  final KAgentTaskPart part;
  @override
  Widget build(BuildContext context) {
    final t = _tokens(context);
    final completed = part.items
        .where((item) => item.state == KAgentTaskState.completed)
        .length;
    return KDisclosure(
      title: part.title,
      defaultOpen: true,
      actions: KBadge(
        variant: KBadgeVariant.outline,
        child: Text('$completed/${part.items.length}'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KProgress(
            value: completed.toDouble(),
            max: part.items.length.toDouble(),
            label: Text(part.title),
          ),
          SizedBox(height: t.spaceControlGap),
          for (final item in part.items)
            Padding(
              padding: EdgeInsets.only(top: t.spaceControlGap),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StateIcon(state: _toolState(item.state)),
                  SizedBox(width: t.spaceControlGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: _labelStyle(t)),
                        if (item.description case final description?)
                          Text(description, style: _mutedStyle(t)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class KAgentActivity extends StatelessWidget {
  const KAgentActivity({required this.part, super.key});
  final KAgentActivityPart part;
  @override
  Widget build(BuildContext context) => KDisclosure(
    title: part.title,
    titleWidget: _AgentDisclosureTitle(title: part.title, running: part.active),
    presentation: KDisclosurePresentation.compact,
    leadingIcon: _StateIcon(
      state: part.active ? KAgentToolState.running : KAgentToolState.succeeded,
    ),
    child: Text(part.summary),
  );
}

class KAgentStatus extends StatelessWidget {
  const KAgentStatus({required this.part, super.key});

  final KAgentStatusPart part;

  @override
  Widget build(BuildContext context) => KAlert(
    title: Text(part.title),
    description: part.description == null ? null : Text(part.description!),
    tone: switch (part.tone) {
      KAgentStatusTone.neutral => KStatusTone.neutral,
      KAgentStatusTone.info => KStatusTone.info,
      KAgentStatusTone.success => KStatusTone.success,
      KAgentStatusTone.warning => KStatusTone.warning,
      KAgentStatusTone.error => KStatusTone.error,
    },
  );
}

class KAgentReference extends StatelessWidget {
  const KAgentReference({
    required this.title,
    this.description,
    this.artifact = false,
    this.onActivate,
    super.key,
  });
  final String title;
  final String? description;
  final bool artifact;
  final VoidCallback? onActivate;
  @override
  Widget build(BuildContext context) {
    final t = _tokens(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onActivate,
        borderRadius: BorderRadius.circular(t.radiusControl),
        child: Container(
          constraints: BoxConstraints(minHeight: t.sizeHitTarget),
          padding: EdgeInsets.all(t.spaceControlGap),
          decoration: _cardDecoration(t),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KIcon(artifact ? KIconName.file : KIconName.externalLink),
              SizedBox(width: t.spaceControlGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _labelStyle(t)),
                    if (description case final value?)
                      Text(value, style: _mutedStyle(t)),
                  ],
                ),
              ),
              const KIcon(KIconName.chevronRight),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentData extends StatelessWidget {
  const _AgentData({required this.label, required this.value});
  final String label;
  final Object? value;
  @override
  Widget build(BuildContext context) {
    final t = _tokens(context);
    final formatted = value is String
        ? value as String
        : const JsonEncoder.withIndent('  ').convert(value);
    return Padding(
      padding: EdgeInsets.only(top: t.spaceControlGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) Text(label, style: _labelStyle(t)),
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.colorSurfaceSubtle,
              border: Border.all(color: t.colorBorderDefault),
              borderRadius: BorderRadius.circular(t.radiusControl),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.all(t.spaceControlGap),
                child: SelectableText(
                  formatted,
                  style: _mutedStyle(t).copyWith(fontFamily: t.fontFamily),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionOptionRow extends StatefulWidget {
  const _QuestionOptionRow({
    required this.option,
    required this.selected,
    required this.multiple,
    required this.onActivate,
  });

  final KAgentQuestionOption option;
  final bool selected;
  final bool multiple;
  final VoidCallback onActivate;

  @override
  State<_QuestionOptionRow> createState() => _QuestionOptionRowState();
}

class _QuestionOptionRowState extends State<_QuestionOptionRow> {
  final _focusNode = FocusNode();
  bool _focused = false;
  bool _hovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _activate() {
    _focusNode.requestFocus();
    widget.onActivate();
  }

  @override
  Widget build(BuildContext context) {
    final t = _tokens(context);
    final label = widget.option.description == null
        ? widget.option.label
        : '${widget.option.label}, ${widget.option.description}';
    return Semantics(
      label: label,
      checked: widget.selected,
      inMutuallyExclusiveGroup: !widget.multiple,
      focusable: true,
      focused: _focused,
      onTap: _activate,
      excludeSemantics: true,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        mouseCursor: SystemMouseCursors.click,
        onFocusChange: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onActivate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _activate,
          child: AnimatedContainer(
            duration: t.motionStandard,
            constraints: BoxConstraints(minHeight: t.sizeHitTarget),
            padding: EdgeInsets.all(t.spaceControlGap),
            decoration: BoxDecoration(
              color: widget.selected || _hovered
                  ? t.colorActionGhostHover
                  : Colors.transparent,
              border: Border.all(
                color: widget.selected || _focused
                    ? t.colorBorderFocus
                    : t.colorBorderDefault,
                width: t.borderWidthDefault,
              ),
              borderRadius: BorderRadius.circular(t.radiusControl),
            ),
            child: Row(
              children: [
                _QuestionSelectionIndicator(
                  selected: widget.selected,
                  multiple: widget.multiple,
                ),
                SizedBox(width: t.spaceControlInsetInline),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.option.label, style: _bodyStyle(t)),
                      if (widget.option.description
                          case final description?) ...[
                        SizedBox(height: t.spaceControlGap),
                        Text(description, style: _captionStyle(t)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionSelectionIndicator extends StatelessWidget {
  const _QuestionSelectionIndicator({
    required this.selected,
    required this.multiple,
  });

  final bool selected;
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    final t = _tokens(context);
    if (multiple) {
      return Container(
        width: t.sizeContent,
        height: t.sizeContent,
        decoration: BoxDecoration(
          color: selected
              ? t.componentSelectionSelectedBackground
              : t.componentSelectionBackground,
          border: Border.all(
            color: selected
                ? t.componentSelectionSelectedBorder
                : t.componentSelectionBorder,
          ),
          borderRadius: BorderRadius.circular(t.radiusSmall),
        ),
        child: selected
            ? KIcon(
                KIconName.check,
                size: 12,
                color: t.componentSelectionSelectedForeground,
              )
            : null,
      );
    }
    return Container(
      width: t.componentRadioSize,
      height: t.componentRadioSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? t.componentSelectionSelectedBackground
            : t.componentSelectionBackground,
        border: Border.all(
          color: selected
              ? t.componentSelectionSelectedBorder
              : t.componentSelectionBorder,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: t.componentRadioDotSize,
                height: t.componentRadioDotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.componentSelectionSelectedForeground,
                ),
              ),
            )
          : null,
    );
  }
}

class _AgentDisclosureTitle extends StatefulWidget {
  const _AgentDisclosureTitle({
    required this.title,
    required this.running,
    this.wrap = false,
  });

  final String title;
  final bool running;
  final bool wrap;

  @override
  State<_AgentDisclosureTitle> createState() => _AgentDisclosureTitleState();
}

class _AgentDisclosureTitleState extends State<_AgentDisclosureTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _AgentDisclosureTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final t = _tokens(context);
    _controller.duration = Duration(
      milliseconds: t.motionProgress.inMilliseconds * 5,
    );
    if (widget.running && !MediaQuery.disableAnimationsOf(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _tokens(context);
    final text = Text(
      widget.title,
      maxLines: widget.wrap ? null : 1,
      overflow: widget.wrap ? TextOverflow.visible : TextOverflow.ellipsis,
      style: _bodyStyle(t).copyWith(color: t.colorTextMuted),
    );
    if (!widget.running || MediaQuery.disableAnimationsOf(context)) return text;
    return AnimatedBuilder(
      animation: _controller,
      child: text,
      builder: (context, child) {
        final center = (_controller.value * 4) - 2;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(center - 1, 0),
            end: Alignment(center + 1, 0),
            colors: [t.colorTextMuted, t.colorTextPrimary, t.colorTextMuted],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.state});
  final KAgentToolState state;
  @override
  Widget build(BuildContext context) => Semantics(
    label: _enumLabel(state.name),
    child: ExcludeSemantics(
      child: KIcon(switch (state) {
        KAgentToolState.running => KIconName.refreshCw,
        KAgentToolState.succeeded => KIconName.check,
        KAgentToolState.failed => KIconName.x,
        _ => KIconName.clock,
      }),
    ),
  );
}

KAgentToolState _groupState(List<KAgentToolPart> parts) {
  if (parts.any((part) => part.state == KAgentToolState.failed)) {
    return KAgentToolState.failed;
  }
  if (parts.any((part) => part.state == KAgentToolState.running)) {
    return KAgentToolState.running;
  }
  if (parts.any((part) => part.state == KAgentToolState.approvalRequired)) {
    return KAgentToolState.approvalRequired;
  }
  if (parts.any((part) => part.state == KAgentToolState.pending)) {
    return KAgentToolState.pending;
  }
  if (parts.every((part) => part.state == KAgentToolState.cancelled)) {
    return KAgentToolState.cancelled;
  }
  return KAgentToolState.succeeded;
}

KAgentToolState _toolState(KAgentTaskState state) => switch (state) {
  KAgentTaskState.active => KAgentToolState.running,
  KAgentTaskState.completed => KAgentToolState.succeeded,
  KAgentTaskState.failed => KAgentToolState.failed,
  _ => KAgentToolState.pending,
};
KDesignTokens _tokens(BuildContext context) =>
    Theme.of(context).extension<KDesignTokens>()!;
BoxDecoration _cardDecoration(KDesignTokens t) => BoxDecoration(
  color: t.colorSurfaceRaised,
  border: Border.all(color: t.colorBorderDefault),
  borderRadius: BorderRadius.circular(t.radiusCard),
);
TextStyle _labelStyle(KDesignTokens t) => TextStyle(
  color: t.colorTextPrimary,
  fontFamily: t.fontFamily,
  fontSize: t.fontLabelSize,
  fontWeight: t.fontLabelWeight,
);
TextStyle _heading5Style(KDesignTokens t) => TextStyle(
  color: t.colorTextPrimary,
  fontFamily: t.fontFamily,
  fontSize: KDesignTokenVariants.typeScaleCompactFontHeading5Size,
  fontWeight: t.fontLabelWeight,
  height:
      KDesignTokenVariants.typeScaleCompactFontHeading5LineHeight /
      KDesignTokenVariants.typeScaleCompactFontHeading5Size,
  letterSpacing: t.fontHeading5LetterSpacing,
);
TextStyle _bodyStyle(KDesignTokens t) => TextStyle(
  color: t.colorTextPrimary,
  fontFamily: t.fontFamily,
  fontSize: KDesignTokenVariants.typeScaleCompactFontBodySize,
  fontWeight: t.fontBodyWeight,
  height:
      KDesignTokenVariants.typeScaleCompactFontBodyLineHeight /
      KDesignTokenVariants.typeScaleCompactFontBodySize,
  letterSpacing: t.fontBodyLetterSpacing,
);
TextStyle _captionStyle(KDesignTokens t) => TextStyle(
  color: t.colorTextMuted,
  fontFamily: t.fontFamily,
  fontSize: t.fontCaptionSize,
  fontWeight: t.fontBodyWeight,
  height: t.fontCaptionLineHeight / t.fontCaptionSize,
  letterSpacing: t.fontCaptionLetterSpacing,
);
TextStyle _mutedStyle(KDesignTokens t) => TextStyle(
  color: t.colorTextMuted,
  fontFamily: t.fontFamily,
  fontSize: KDesignTokenVariants.typeScaleCompactFontBodySmallSize,
  height:
      KDesignTokenVariants.typeScaleCompactFontBodySmallLineHeight /
      KDesignTokenVariants.typeScaleCompactFontBodySmallSize,
);
String _enumLabel(String value) => value.replaceAllMapped(
  RegExp(r'([A-Z])'),
  (match) => ' ${match.group(1)!.toLowerCase()}',
);
