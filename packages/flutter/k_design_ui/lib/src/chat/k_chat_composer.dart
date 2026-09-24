import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/k_icon_button.dart';
import '../basic_components.dart';
import '../primitives/k_icon.dart';
import '../forms/k_select.dart';
import 'k_chat_types.dart';

class KChatComposerModel {
  const KChatComposerModel({
    required this.value,
    required this.label,
    this.icon,
    this.disabled = false,
  });
  final String value;
  final String label;
  final KIconName? icon;
  final bool disabled;
}

class KChatComposerLabels {
  const KChatComposerLabels({
    this.input = 'Message',
    this.placeholder = 'Ask anything…',
    this.send = 'Send message',
    this.stop = 'Stop response',
    this.removeAttachment = 'Remove attachment',
    this.attach = 'Attach files',
    this.voice = 'Start voice input',
    this.stopVoice = 'Stop voice input',
    this.model = 'Model',
  });
  final String input;
  final String placeholder;
  final String send;
  final String stop;
  final String removeAttachment;
  final String attach;
  final String voice;
  final String stopVoice;
  final String model;
}

class KChatComposer extends StatefulWidget {
  const KChatComposer({
    required this.value,
    required this.onValueChanged,
    required this.onSubmit,
    this.onStop,
    this.runState = KChatRunState.idle,
    this.disabled = false,
    this.maxLength,
    this.labels = const KChatComposerLabels(),
    this.leadingTools,
    this.trailingTools,
    this.attachments = const [],
    this.onAttachmentActivate,
    this.onAttachmentRemove,
    this.focusNode,
    this.onAttach,
    this.onVoiceInput,
    this.voiceActive = false,
    this.models = const [],
    this.model,
    this.onModelChanged,
    super.key,
  });
  final String value;
  final ValueChanged<String> onValueChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onStop;
  final KChatRunState runState;
  final bool disabled;
  final int? maxLength;
  final KChatComposerLabels labels;
  final List<Widget>? leadingTools;
  final List<Widget>? trailingTools;
  final List<KChatAttachmentPart> attachments;
  final ValueChanged<KChatAttachmentPart>? onAttachmentActivate;
  final ValueChanged<KChatAttachmentPart>? onAttachmentRemove;
  final FocusNode? focusNode;
  final VoidCallback? onAttach;
  final VoidCallback? onVoiceInput;
  final bool voiceActive;
  final List<KChatComposerModel> models;
  final String? model;
  final ValueChanged<String?>? onModelChanged;
  @override
  State<KChatComposer> createState() => _KChatComposerState();
}

class _KChatComposerState extends State<KChatComposer> {
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant KChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _controller.text) return;
    _controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _running =>
      widget.runState == KChatRunState.submitted ||
      widget.runState == KChatRunState.streaming;

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty || widget.disabled || _running) return;
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Material(
      color: t.colorSurfaceCanvas,
      child: Padding(
        padding: EdgeInsets.all(t.spaceControlInsetInline),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.attachments.isNotEmpty) ...[
              SizedBox(
                height:
                    t.componentAttachmentMediaSize +
                    t.spaceControlInsetInline * 2,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.attachments.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(width: t.spaceControlGap),
                  itemBuilder: (context, index) {
                    final attachment = widget.attachments[index];
                    return SizedBox(
                      width: t.componentAttachmentMediaSize * 4,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: KAttachment(
                              title: Text(attachment.title),
                              description: attachment.description == null
                                  ? null
                                  : Text(attachment.description!),
                              state: _attachmentState(attachment.state),
                              progress: attachment.progress,
                              onActivate: widget.onAttachmentActivate == null
                                  ? null
                                  : () => widget.onAttachmentActivate!(
                                      attachment,
                                    ),
                            ),
                          ),
                          if (widget.onAttachmentRemove != null)
                            PositionedDirectional(
                              top: 0,
                              end: 0,
                              child: KIconButton(
                                label:
                                    '${widget.labels.removeAttachment}: ${attachment.title}',
                                icon: KIconName.x,
                                onPressed: () =>
                                    widget.onAttachmentRemove!(attachment),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: t.spaceControlGap),
            ],
            DecoratedBox(
              decoration: BoxDecoration(
                color: t.colorSurfaceRaised,
                border: Border.all(color: t.colorBorderDefault),
                borderRadius: BorderRadius.circular(t.radiusCard),
                boxShadow: t.elevationLow,
              ),
              child: Padding(
                padding: EdgeInsets.all(t.spaceControlGap),
                child: Column(
                  children: [
                    CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.enter):
                            _submit,
                      },
                      child: TextField(
                        controller: _controller,
                        focusNode: widget.focusNode,
                        enabled: !widget.disabled,
                        minLines: 1,
                        maxLines: 6,
                        maxLength: widget.maxLength,
                        decoration: InputDecoration(
                          labelText: widget.labels.input,
                          hintText: widget.labels.placeholder,
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        onChanged: widget.onValueChanged,
                      ),
                    ),
                    Row(
                      children: [
                        if (widget.onAttach != null)
                          KIconButton(
                            label: widget.labels.attach,
                            icon: KIconName.paperclip,
                            onPressed: widget.onAttach,
                          ),
                        if (widget.onVoiceInput != null)
                          Semantics(
                            selected: widget.voiceActive,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: widget.voiceActive
                                    ? t.colorActionGhostHover
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  t.radiusControl,
                                ),
                              ),
                              child: KIconButton(
                                label: widget.voiceActive
                                    ? widget.labels.stopVoice
                                    : widget.labels.voice,
                                icon: KIconName.mic,
                                onPressed: widget.onVoiceInput,
                              ),
                            ),
                          ),
                        ...?widget.leadingTools,
                        const Spacer(),
                        ...?widget.trailingTools,
                        if (widget.models.isNotEmpty &&
                            widget.onModelChanged != null)
                          SizedBox(
                            width: t.layoutTableColumnWidth,
                            child: KSelect(
                              presentation: KSelectPresentation.inline,
                              options: [
                                for (final model in widget.models)
                                  KSelectOption(
                                    value: model.value,
                                    label: model.label,
                                    icon: model.icon,
                                    disabled: model.disabled,
                                  ),
                              ],
                              value: widget.model,
                              label: widget.labels.model,
                              placeholder: widget.labels.model,
                              onChanged: widget.onModelChanged,
                            ),
                          ),
                        KIconButton(
                          label: _running
                              ? widget.labels.stop
                              : widget.labels.send,
                          icon: _running ? KIconName.x : KIconName.arrowUp,
                          onPressed: _running
                              ? widget.onStop
                              : (_controller.text.trim().isEmpty ||
                                        widget.disabled
                                    ? null
                                    : _submit),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

KAttachmentState _attachmentState(KChatAttachmentPartState state) =>
    switch (state) {
      KChatAttachmentPartState.ready => KAttachmentState.ready,
      KChatAttachmentPartState.uploading => KAttachmentState.uploading,
      KChatAttachmentPartState.processing => KAttachmentState.processing,
      KChatAttachmentPartState.error => KAttachmentState.error,
      KChatAttachmentPartState.complete => KAttachmentState.complete,
    };
