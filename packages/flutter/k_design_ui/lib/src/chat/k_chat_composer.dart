import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/action_control.dart';
import '../actions/k_icon_button.dart';
import '../basic_components.dart';
import '../primitives/k_icon.dart';
import '../forms/k_select.dart';
import '../forms/k_dictation_action.dart';
import 'k_chat_types.dart';

part 'k_chat_composer_voice_capture.dart';
part 'k_chat_composer_types.dart';

class KChatComposer extends StatefulWidget {
  const KChatComposer({
    required this.value,
    required this.onValueChanged,
    required this.onSubmit,
    this.onStop,
    this.padding,
    this.backgroundColor,
    this.runState = KChatRunState.idle,
    this.disabled = false,
    this.submitEnabled = true,
    this.allowSubmitWhileRunning = false,
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
    this.voiceState,
    this.voiceAudioLevel,
    this.voiceCapture,
    this.onStartCall,
    this.models = const [],
    this.model,
    this.onModelChanged,
    super.key,
  });
  final String value;
  final ValueChanged<String> onValueChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onStop;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final KChatRunState runState;
  final bool disabled;

  /// Allows editing while independently preventing keyboard and button submission.
  final bool submitEnabled;

  /// Host accepts follow-up messages while a response is active.
  final bool allowSubmitWhileRunning;
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
  final KDictationState? voiceState;
  final double? voiceAudioLevel;
  final KChatVoiceCapture? voiceCapture;
  final VoidCallback? onStartCall;
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
    if (value.isEmpty ||
        widget.disabled ||
        !widget.submitEnabled ||
        (_running && !widget.allowSubmitWhileRunning)) {
      return;
    }
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final composerSpacing = math.min(
      t.spaceControlGap,
      KDesignTokenVariants.densityStandardSpaceControlGap,
    );
    final composerGap = composerSpacing / 2;
    final composerTarget = math.max(t.sizeControl, t.sizeHitTarget);
    final textInset = math.max(
      0.0,
      (composerTarget -
              MediaQuery.textScalerOf(context).scale(t.fontBodyLineHeight)) /
          2,
    );
    final composerVisualTarget = math.min(
      composerTarget,
      KDesignTokenVariants.densityStandardSpaceControlGap * 4.5,
    );
    final composerIconSize = math.min(
      composerVisualTarget,
      KDesignTokenVariants.densityStandardSpaceControlGap * 3 -
          t.borderWidthDefault * 2,
    );
    final composerTokens = t.copyWith(
      spaceControlGap: composerGap,
      sizeControl: composerVisualTarget,
      sizeHitTarget: composerTarget,
      radiusControl: composerVisualTarget / 2,
    );
    final dictationState =
        widget.voiceState ??
        (widget.voiceActive
            ? KDictationState.recording
            : KDictationState.ready);
    final recording = dictationState == KDictationState.recording;
    final capturing =
        widget.voiceCapture != null &&
        (recording ||
            dictationState == KDictationState.processing ||
            dictationState == KDictationState.error);
    final voiceLabel = switch (dictationState) {
      KDictationState.ready => widget.labels.voice,
      KDictationState.recording => widget.labels.stopVoice,
      KDictationState.processing => widget.labels.processingVoice,
      KDictationState.unavailable => widget.labels.unavailableVoice,
      KDictationState.error => widget.labels.errorVoice,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final inputMaxHeight =
            ((MediaQuery.sizeOf(context).height -
                        MediaQuery.viewInsetsOf(context).bottom) *
                    .25)
                .clamp(48.0, double.infinity);
        return Material(
          color: widget.backgroundColor ?? t.colorSurfaceCanvas,
          child: Padding(
            padding:
                widget.padding ??
                EdgeInsets.symmetric(
                  horizontal: t.spaceControlInsetInline,
                  vertical: composerTokens.spaceControlGap,
                ),
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
                                  onActivate:
                                      widget.onAttachmentActivate == null
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
                    borderRadius: BorderRadius.circular(
                      composerTokens.sizeHitTarget / 2 + composerGap,
                    ),
                    boxShadow: t.elevationLow,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(composerTokens.spaceControlGap),
                    child: Column(
                      children: [
                        if (!capturing &&
                            widget.models.isNotEmpty &&
                            widget.onModelChanged != null) ...[
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: t.layoutTableColumnWidth,
                              ),
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
                          ),
                          SizedBox(height: composerTokens.spaceControlGap),
                        ],
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(extensions: [composerTokens]),
                          child: KActionControlVisualScope(
                            child: KIconSizeScope(
                              size: composerIconSize,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                spacing: composerTokens.spaceControlGap,
                                children: [
                                  if (capturing)
                                    KIconButton(
                                      label: widget.labels.cancelVoice,
                                      icon: KIconName.x,
                                      onPressed: widget.voiceCapture!.onCancel,
                                    )
                                  else if (widget.onAttach != null)
                                    KIconButton(
                                      label: widget.labels.attach,
                                      icon: widget.voiceCapture == null
                                          ? KIconName.paperclip
                                          : KIconName.plus,
                                      onPressed: widget.onAttach,
                                    ),
                                  if (!capturing)
                                    for (final tool
                                        in widget.leadingTools ??
                                            const <Widget>[])
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: composerTarget,
                                        ),
                                        child: Center(
                                          widthFactor: 1,
                                          heightFactor: 1,
                                          child: tool,
                                        ),
                                      ),
                                  Expanded(
                                    child: capturing
                                        ? ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minHeight: composerTarget,
                                            ),
                                            child: Center(
                                              child: _KChatVoiceCaptureView(
                                                state: dictationState,
                                                samples: widget
                                                    .voiceCapture!
                                                    .samples,
                                                processingLabel: widget
                                                    .labels
                                                    .processingVoice,
                                                recordingLabel:
                                                    widget.labels.voice,
                                                errorLabel:
                                                    widget
                                                        .voiceCapture!
                                                        .error ??
                                                    widget.labels.errorVoice,
                                              ),
                                            ),
                                          )
                                        : CallbackShortcuts(
                                            bindings: {
                                              const SingleActivator(
                                                LogicalKeyboardKey.enter,
                                              ): _submit,
                                            },
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minHeight: math.max(
                                                  composerTokens.sizeControl,
                                                  composerTokens.sizeHitTarget,
                                                ),
                                                maxHeight: inputMaxHeight,
                                              ),
                                              child: TextField(
                                                controller: _controller,
                                                focusNode: widget.focusNode,
                                                enabled: !widget.disabled,
                                                textAlignVertical:
                                                    TextAlignVertical.center,
                                                style: TextStyle(
                                                  fontSize: composerTokens
                                                      .fontBodySize,
                                                  height:
                                                      composerTokens
                                                          .fontBodyLineHeight /
                                                      composerTokens
                                                          .fontBodySize,
                                                  leadingDistribution:
                                                      TextLeadingDistribution
                                                          .even,
                                                ),
                                                minLines: 1,
                                                maxLines: null,
                                                maxLength: widget.maxLength,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  filled: false,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        horizontal:
                                                            composerTokens
                                                                .spaceControlGap /
                                                            2,
                                                        vertical: textInset,
                                                      ),
                                                  labelText: null,
                                                  hintText:
                                                      widget.labels.placeholder,
                                                  hintMaxLines: 1,
                                                  border: InputBorder.none,
                                                  counterText: '',
                                                ),
                                                onChanged:
                                                    widget.onValueChanged,
                                              ),
                                            ),
                                          ),
                                  ),
                                  if (!capturing) ...?widget.trailingTools,
                                  if (!capturing &&
                                      _running &&
                                      widget.allowSubmitWhileRunning &&
                                      _controller.text.trim().isNotEmpty)
                                    KIconButton(
                                      label: widget.labels.send,
                                      icon: KIconName.arrowUp,
                                      selected: true,
                                      onPressed:
                                          widget.disabled ||
                                              !widget.submitEnabled
                                          ? null
                                          : _submit,
                                    ),
                                  if (capturing)
                                    KIconButton(
                                      label:
                                          dictationState ==
                                              KDictationState.error
                                          ? widget.labels.errorVoice
                                          : widget.labels.stopVoice,
                                      icon:
                                          dictationState ==
                                              KDictationState.error
                                          ? KIconName.rotateCw
                                          : KIconName.square,
                                      onPressed:
                                          dictationState ==
                                                  KDictationState.processing ||
                                              widget.onVoiceInput == null
                                          ? null
                                          : widget.onVoiceInput,
                                    )
                                  else if (widget.onVoiceInput != null)
                                    KDictationAction(
                                      state: dictationState,
                                      label: voiceLabel,
                                      audioLevel: widget.voiceAudioLevel,
                                      onPressed: widget.disabled && !recording
                                          ? null
                                          : widget.onVoiceInput,
                                    ),
                                  if (capturing)
                                    KIconButton(
                                      label: widget.labels.sendVoice,
                                      icon: KIconName.arrowUp,
                                      selected: true,
                                      onPressed:
                                          !recording ||
                                              widget.disabled ||
                                              !widget.submitEnabled ||
                                              _running
                                          ? null
                                          : widget.voiceCapture!.onSend,
                                    )
                                  else if (_running)
                                    KIconButton(
                                      label: widget.labels.stop,
                                      icon: KIconName.x,
                                      onPressed: widget.onStop,
                                    )
                                  else if (widget.onStartCall != null &&
                                      _controller.text.trim().isEmpty)
                                    KIconButton(
                                      label: widget.labels.call,
                                      icon: KIconName.phone,
                                      selected: true,
                                      onPressed: widget.disabled
                                          ? null
                                          : widget.onStartCall,
                                    )
                                  else
                                    KIconButton(
                                      label: widget.labels.send,
                                      icon: KIconName.arrowUp,
                                      selected: true,
                                      onPressed:
                                          _controller.text.trim().isEmpty ||
                                              widget.disabled ||
                                              !widget.submitEnabled
                                          ? null
                                          : _submit,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
