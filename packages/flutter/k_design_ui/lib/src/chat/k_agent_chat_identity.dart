part of 'k_agent_chat_workspace.dart';

extension _KAgentChatIdentity on _KAgentChatWorkspaceState {
  Widget _floatingIdentity(
    BuildContext context,
    double size,
    Widget avatar,
    Duration duration,
  ) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    // Fade/blur spans the stage width and only the identity's vertical band.
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: -tokens.spaceLayoutGutter,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: widget.conversationEmpty ? 0 : 1),
                duration: duration,
                builder: (context, visibility, _) => LayoutBuilder(
                  builder: (context, bounds) => Stack(
                    children: [
                      // Filter the actual conversation directly. A ShaderMask or
                      // opacity saveLayer isolates it from the backdrop on Flutter.
                      for (var band = 0; band < 16; band++)
                        Positioned(
                          top: bounds.maxHeight * band / 16,
                          height: bounds.maxHeight / 16,
                          left: 0,
                          right: 0,
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX:
                                    widget.avatarBackdropBlur *
                                    visibility *
                                    (1 - ((band + .5) / 16 - .25) / .75).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                sigmaY:
                                    widget.avatarBackdropBlur *
                                    visibility *
                                    (1 - ((band + .5) / 16 - .25) / .75).clamp(
                                      0.0,
                                      1.0,
                                    ),
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      for (final edge in [band, band + 1])
                                        tokens.colorSurfaceCanvas.withValues(
                                          alpha:
                                              .68 *
                                              visibility *
                                              (1 - (edge / 16 - .25) / .75)
                                                  .clamp(0.0, 1.0),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: _avatarTrigger(context, size, avatar)),
              if (widget.showTitle) ...[
                SizedBox(height: tokens.spaceTight),
                Semantics(
                  header: true,
                  child: DefaultTextStyle.merge(
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tokens.colorTextPrimary,
                      fontFamily: tokens.fontFamily,
                      fontSize: tokens.fontHeading3Size,
                      fontWeight: tokens.fontHeadingWeight,
                    ),
                    child: widget.title,
                  ),
                ),
              ],
              if (widget.status case final status?) ...[
                SizedBox(height: tokens.spaceTight),
                DefaultTextStyle.merge(
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: tokens.colorTextMuted,
                    fontFamily: tokens.fontFamily,
                    fontSize: tokens.fontBodySmallSize,
                  ),
                  child: status,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarTrigger(BuildContext context, double size, Widget avatar) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final trigger = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          key: const ValueKey('k-agent-chat-workspace-avatar'),
          dimension: size,
          child: SizedBox.expand(
            key: _avatarPopoverAnchor,
            child: FittedBox(child: avatar),
          ),
        ),
        if (widget.avatarLabel case final label?) ...[
          SizedBox(height: tokens.spaceTight),
          Transform.translate(
            offset: Offset(0, -tokens.spaceControlGap),
            child: DefaultTextStyle.merge(
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.colorTextPrimary,
                fontWeight: tokens.fontHeadingWeight,
                fontFamily: tokens.fontFamily,
                fontSize: tokens.fontBodySmallSize,
              ),
              child: label,
            ),
          ),
        ],
      ],
    );
    return widget.avatarPopover == null
        ? IgnorePointer(child: trigger)
        : KPopover(
            label: widget.avatarPopoverLabel,
            openOnLongPress:
                widget.avatarPopoverActivation ==
                KAgentAvatarPopoverActivation.longPress,
            onOpenChanged: _changeAvatarInfoOpen,
            belowAnchor: true,
            showArrow: true,
            anchorKey: _avatarPopoverAnchor,
            anchorTransitionDuration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : widget.avatarTransitionDuration ?? tokens.motionLong,
            trigger: trigger,
            content: widget.avatarPopover!,
          );
  }
}
