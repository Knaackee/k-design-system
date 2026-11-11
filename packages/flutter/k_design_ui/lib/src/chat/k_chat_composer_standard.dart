part of 'k_chat_composer.dart';

extension on _KChatComposerState {
  Widget _standardComposer(
    BuildContext context,
    KDesignTokens t,
    KDictationState dictationState,
    String voiceLabel,
  ) {
    final target = math.max(t.sizeControl, t.sizeHitTarget);
    final toolsTokens = t.copyWith(
      sizeControl: math.min(target, t.spaceControlGap * 4.5),
      sizeHitTarget: target,
      componentButtonRadius: t.radiusFull,
      fontControlWeight: t.fontLabelWeight,
      sizeIconStroke: t.componentChatIconStroke,
    );
    return Material(
      color: widget.backgroundColor ?? t.colorSurfaceCanvas,
      child: Padding(
        padding: widget.padding ?? EdgeInsets.all(t.spaceControlInsetInline),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.attachments.isNotEmpty) ...[
              Wrap(
                spacing: t.componentChatBlockGap,
                runSpacing: t.componentChatBlockGap,
                children: [
                  for (final attachment in widget.attachments)
                    SizedBox(
                      width: t.componentAttachmentMediaSize * 4,
                      child: Stack(
                        children: [
                          KAttachment(
                            title: Text(attachment.title),
                            description: attachment.description == null
                                ? null
                                : Text(attachment.description!),
                            state: _attachmentState(attachment.state),
                            progress: attachment.progress,
                            onActivate: widget.onAttachmentActivate == null
                                ? null
                                : () =>
                                      widget.onAttachmentActivate!(attachment),
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
                    ),
                ],
              ),
              SizedBox(height: t.componentChatBlockGap),
            ],
            Container(
              constraints: BoxConstraints(
                minHeight: t.componentChatComposerMinHeight,
              ),
              padding: EdgeInsets.all(t.componentChatComposerPadding),
              decoration: BoxDecoration(
                color: t.colorSurfaceRaised,
                border: Border.all(
                  color: t.colorBorderDefault,
                  width: t.borderWidthDefault,
                ),
                borderRadius: BorderRadius.circular(
                  t.componentChatComposerRadius,
                ),
                boxShadow: t.elevationLow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.enter): _submit,
                    },
                    child: TextField(
                      controller: _controller,
                      focusNode: widget.focusNode,
                      enabled: !widget.disabled,
                      minLines: 2,
                      maxLines: 8,
                      maxLength: widget.maxLength,
                      style: TextStyle(
                        fontFamily: t.fontFamily,
                        fontSize: t.fontBodySmallSize,
                        fontWeight: t.fontBodyWeight,
                        height: t.fontBodySmallLineHeight / t.fontBodySmallSize,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        hintText: widget.labels.placeholder,
                        hintMaxLines: 1,
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: widget.onValueChanged,
                    ),
                  ),
                  SizedBox(height: t.componentChatBlockGap),
                  Theme(
                    data: Theme.of(context).copyWith(extensions: [toolsTokens]),
                    child: KActionControlVisualScope(
                      child: KIconSizeScope(
                        size: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: t.spaceControlGap / 2,
                          children: [
                            if (widget.onAttach != null)
                              KIconButton(
                                label: widget.labels.attach,
                                icon: widget.voiceCapture == null
                                    ? KIconName.paperclip
                                    : KIconName.plus,
                                onPressed: widget.onAttach,
                              ),
                            ...?widget.leadingTools,
                            Expanded(
                              child:
                                  widget.models.isNotEmpty &&
                                      widget.onModelChanged != null
                                  ? KSelect(
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
                                      onChanged: widget.onModelChanged,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            ...?widget.trailingTools,
                            if (_running &&
                                widget.allowSubmitWhileRunning &&
                                _controller.text.trim().isNotEmpty)
                              KIconButton(
                                label: widget.labels.send,
                                icon: KIconName.arrowUp,
                                selected: true,
                                onPressed:
                                    widget.disabled || !widget.submitEnabled
                                    ? null
                                    : _submit,
                              ),
                            if (widget.onVoiceInput != null)
                              KDictationAction(
                                state: dictationState,
                                label: voiceLabel,
                                audioLevel: widget.voiceAudioLevel,
                                onPressed:
                                    widget.disabled &&
                                        dictationState !=
                                            KDictationState.recording
                                    ? null
                                    : widget.onVoiceInput,
                              ),
                            if (_running)
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
          ],
        ),
      ),
    );
  }
}
