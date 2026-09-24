import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../basic_components.dart';
import '../extended_components.dart';
import '../forms/k_checkbox.dart';
import '../primitives/k_button.dart';
import '../primitives/k_disclosure.dart';
import '../primitives/k_icon.dart';
import 'k_chat_types.dart';

typedef KAgentToolRenderer =
    Widget Function(BuildContext context, KAgentToolPart part);

class KAgentToolCall extends StatelessWidget {
  const KAgentToolCall({required this.part, this.renderer, super.key});
  final KAgentToolPart part;
  final KAgentToolRenderer? renderer;
  @override
  Widget build(BuildContext context) {
    if (renderer case final custom?) return custom(context, part);
    final complete = {
      KAgentToolState.succeeded,
      KAgentToolState.failed,
      KAgentToolState.cancelled,
    }.contains(part.state);
    return KDisclosure(
      title: part.title,
      defaultOpen: !complete,
      leadingIcon: _StateIcon(state: part.state),
      actions: KBadge(
        variant: KBadgeVariant.outline,
        child: Text(_enumLabel(part.state.name)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (part.description case final description?) Text(description),
          if (part.arguments != null)
            _AgentData(label: 'Arguments', value: part.arguments),
          if (part.result != null)
            _AgentData(label: 'Result', value: part.result),
          if (part.error case final error?) ...[
            SizedBox(height: _tokens(context).spaceControlGap),
            KAlert(tone: KStatusTone.error, title: Text(error)),
          ],
        ],
      ),
    );
  }
}

class KAgentApproval extends StatefulWidget {
  const KAgentApproval({
    required this.part,
    this.onResponse,
    this.reasonLabel = 'Optional reason',
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
        padding: EdgeInsets.all(t.spaceControlInsetInline),
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
                      Text(part.title, style: _labelStyle(t)),
                      if (part.description case final description?)
                        Text(description, style: _mutedStyle(t)),
                    ],
                  ),
                ),
              ],
            ),
            if (part.detail case final detail?)
              _AgentData(label: '', value: detail),
            if (part.state == KAgentResolutionState.pending) ...[
              SizedBox(height: t.spaceControlGap),
              TextField(
                controller: _reason,
                decoration: InputDecoration(labelText: widget.reasonLabel),
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
  const KAgentQuestion({required this.part, this.onResponse, super.key});
  final KAgentQuestionPart part;
  final ValueChanged<KAgentQuestionResponse>? onResponse;
  @override
  State<KAgentQuestion> createState() => _KAgentQuestionState();
}

class _KAgentQuestionState extends State<KAgentQuestion> {
  final _text = TextEditingController();
  final Set<String> _selected = {};
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _tokens(context);
    final part = widget.part;
    if (part.state != KAgentResolutionState.pending) {
      return Container(
        padding: EdgeInsets.all(t.spaceControlInsetInline),
        decoration: _cardDecoration(t),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const KIcon(KIconName.info),
            SizedBox(width: t.spaceControlGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(part.title, style: _labelStyle(t)),
                  Text(
                    part.answerSummary ?? _enumLabel(part.state.name),
                    style: _mutedStyle(t),
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
      padding: EdgeInsets.all(t.spaceControlInsetInline),
      decoration: _cardDecoration(t),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KIcon(KIconName.info),
              SizedBox(width: t.spaceControlGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(part.title, style: _labelStyle(t)),
                    if (part.description case final description?)
                      Text(description, style: _mutedStyle(t)),
                  ],
                ),
              ),
            ],
          ),
          if (isText) ...[
            SizedBox(height: t.spaceControlGap),
            TextField(
              controller: _text,
              decoration: InputDecoration(hintText: part.placeholder),
              onChanged: (_) => setState(() {}),
            ),
          ],
          for (final option in part.options)
            Padding(
              padding: EdgeInsets.only(top: t.spaceControlGap),
              child: KCheckbox(
                label: option.description == null
                    ? option.label
                    : '${option.label}\n${option.description}',
                value: _selected.contains(option.id),
                onChanged: (_) => setState(() {
                  if (part.kind != KAgentQuestionKind.multipleChoice) {
                    _selected.clear();
                  }
                  _selected.contains(option.id)
                      ? _selected.remove(option.id)
                      : _selected.add(option.id);
                }),
              ),
            ),
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
    defaultOpen: part.active,
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
                padding: EdgeInsets.all(t.spaceControlInsetInline),
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

class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.state});
  final KAgentToolState state;
  @override
  Widget build(BuildContext context) {
    if (state == KAgentToolState.running) {
      return SizedBox.square(
        dimension: _tokens(context).componentSpinnerDefaultSize,
        child: CircularProgressIndicator(
          strokeWidth: _tokens(context).componentSpinnerStrokeWidth,
        ),
      );
    }
    return KIcon(switch (state) {
      KAgentToolState.succeeded => KIconName.check,
      KAgentToolState.failed => KIconName.x,
      _ => KIconName.clock,
    });
  }
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
TextStyle _mutedStyle(KDesignTokens t) => TextStyle(
  color: t.colorTextMuted,
  fontFamily: t.fontFamily,
  fontSize: t.fontBodySmallSize,
  height: t.fontBodySmallLineHeight / t.fontBodySmallSize,
);
String _enumLabel(String value) => value.replaceAllMapped(
  RegExp(r'([A-Z])'),
  (match) => ' ${match.group(1)!.toLowerCase()}',
);
