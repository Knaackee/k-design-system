part of 'k_agent_switcher.dart';

double _switcherContentHeight(BuildContext context, KDesignTokens tokens) {
  final scaler = MediaQuery.textScalerOf(context);
  return tokens.componentAvatarSizeLarge +
      tokens.spaceTight * 4 +
      scaler.scale(tokens.fontCaptionLineHeight) +
      scaler.scale(tokens.fontCaption2Size) * tokens.fontRelaxedHeight +
      tokens.borderWidthDefault;
}

class _AgentReorderDragStartListener extends ReorderableDragStartListener {
  const _AgentReorderDragStartListener({
    required super.index,
    required super.child,
    super.key,
  });

  @override
  MultiDragGestureRecognizer createRecognizer() =>
      DelayedMultiDragGestureRecognizer(
        delay: _agentReorderLongPressDelay,
        debugOwner: this,
      );
}

final _agentReorderLongPressDelay = Duration(
  microseconds: kLongPressTimeout.inMicroseconds * 9 ~/ 10,
);

class _AgentBubble extends StatelessWidget {
  const _AgentBubble({
    required this.item,
    required this.index,
    required this.selected,
    required this.labels,
    required this.itemCount,
    required this.orientation,
    required this.reorderable,
    required this.onSelect,
    this.onLongPress,
    this.onMovePrevious,
    this.onMoveNext,
  });

  final KAgentSwitcherItem item;
  final int index;
  final bool selected;
  final KAgentSwitcherLabels labels;
  final int itemCount;
  final Axis orientation;
  final bool reorderable;
  final VoidCallback onSelect;
  final VoidCallback? onLongPress;
  final VoidCallback? onMovePrevious;
  final VoidCallback? onMoveNext;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final shortcuts = <ShortcutActivator, VoidCallback>{};
    final previousKey = orientation == Axis.horizontal
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowUp;
    final nextKey = orientation == Axis.horizontal
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowDown;
    if (onMovePrevious case final action?) {
      shortcuts[SingleActivator(previousKey, alt: true)] = action;
    }
    if (onMoveNext case final action?) {
      shortcuts[SingleActivator(nextKey, alt: true)] = action;
    }
    return CallbackShortcuts(
      bindings: shortcuts,
      child: Semantics(
        key: ValueKey('k-agent-switcher-${item.id}'),
        container: true,
        excludeSemantics: true,
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        sortKey: OrdinalSortKey(index.toDouble()),
        label: item.semanticLabel ?? _semanticLabel(item, labels),
        hint: reorderable ? labels.reorderInstruction : null,
        value: reorderable
            ? labels.reorderAnnouncement(item.name, index + 1, itemCount)
            : null,
        onTap: onSelect,
        onLongPress: onLongPress,
        onDecrease: onMovePrevious,
        onIncrease: onMoveNext,
        decreasedValue: onMovePrevious == null
            ? null
            : labels.reorderAnnouncement(item.name, index, itemCount),
        increasedValue: onMoveNext == null
            ? null
            : labels.reorderAnnouncement(item.name, index + 2, itemCount),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          child: InkWell(
            excludeFromSemantics: true,
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            onTap: onSelect,
            onLongPress: onLongPress,
            child: SizedBox(
              width: orientation == Axis.horizontal
                  ? tokens.componentAvatarSizeLarge +
                        tokens.spaceControlInsetInline * 2
                  : double.infinity,
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceTight),
                child: orientation == Axis.horizontal
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: tokens.spaceTight,
                        children: [
                          _AvatarShell(item: item, selected: selected),
                          if (item.showName)
                            _NameContent(item: item, selected: selected),
                          if (item.statusContent != null ||
                              item.activity != null)
                            _StatusContent(item: item, labels: labels),
                        ],
                      )
                    : Row(
                        children: [
                          _AvatarShell(item: item, selected: selected),
                          SizedBox(width: tokens.spaceControlGap),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: tokens.spaceTight,
                              children: [
                                if (item.showName)
                                  _NameContent(
                                    item: item,
                                    selected: selected,
                                    textAlign: TextAlign.start,
                                  ),
                                if (item.statusContent != null ||
                                    item.activity != null)
                                  _StatusContent(
                                    item: item,
                                    labels: labels,
                                    textAlign: TextAlign.start,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarShell extends StatelessWidget {
  const _AvatarShell({required this.item, required this.selected});
  final KAgentSwitcherItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final size = tokens.componentAvatarSizeLarge;
    final selectedColor = item.selectedColor ?? tokens.colorBrandPrimaryAccent;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: selectedColor,
                          spreadRadius: tokens.borderWidthStrong * 2,
                        ),
                        BoxShadow(
                          color: tokens.colorSurfaceRaised,
                          spreadRadius: tokens.borderWidthStrong,
                        ),
                      ]
                    : null,
              ),
              child: ExcludeSemantics(
                child:
                    item.avatar ??
                    KAvatar(alt: item.name, size: KAvatarSize.large),
              ),
            ),
          ),
          if (item.connection != null)
            PositionedDirectional(
              start: 0,
              bottom: 0,
              child: _ConnectionIndicator(
                connection: item.connection!,
                color: item.connectionColor,
              ),
            ),
          if (item.badgeContent != null || (item.unread ?? 0) > 0)
            PositionedDirectional(
              end: -tokens.spaceTight,
              top: -tokens.spaceTight,
              child: _BadgeIndicator(item: item),
            ),
        ],
      ),
    );
  }
}

class _NameContent extends StatelessWidget {
  const _NameContent({
    required this.item,
    required this.selected,
    this.textAlign = TextAlign.center,
  });
  final KAgentSwitcherItem item;
  final bool selected;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return SizedBox(
      width: double.infinity,
      child: ExcludeSemantics(
        child: DefaultTextStyle(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: TextStyle(
            color: tokens.colorTextPrimary,
            fontFamily: tokens.fontFamily,
            fontSize: tokens.fontCaptionSize,
            height: tokens.fontCaptionLineHeight / tokens.fontCaptionSize,
            fontWeight: selected
                ? tokens.fontLabelWeight
                : tokens.fontBodyWeight,
          ),
          child: item.nameContent ?? Text(item.name),
        ),
      ),
    );
  }
}

class _StatusContent extends StatelessWidget {
  const _StatusContent({
    required this.item,
    required this.labels,
    this.textAlign = TextAlign.center,
  });
  final KAgentSwitcherItem item;
  final KAgentSwitcherLabels labels;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final color =
        item.statusColor ??
        switch (item.activity) {
          KAgentActivityState.working => tokens.colorStatusInfoForeground,
          KAgentActivityState.needsInput => tokens.colorStatusWarningForeground,
          _ => tokens.colorTextMuted,
        };
    return SizedBox(
      width: double.infinity,
      child: ExcludeSemantics(
        child: IconTheme(
          data: IconThemeData(color: color, size: tokens.sizeIconDefault),
          child: DefaultTextStyle(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: TextStyle(
              color: color,
              fontFamily: tokens.fontFamily,
              fontSize: tokens.fontCaption2Size,
              height: tokens.fontRelaxedHeight,
              fontWeight: tokens.fontLabelWeight,
            ),
            child:
                item.statusContent ??
                Text(labels.activityLabel(item.activity!)),
          ),
        ),
      ),
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.connection, this.color});
  final KAgentConnection connection;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final accent =
        color ??
        switch (connection) {
          KAgentConnection.online => tokens.colorStatusSuccessAccent,
          KAgentConnection.offline => tokens.colorBorderStrong,
          KAgentConnection.unknown => tokens.colorBorderStrong,
          KAgentConnection.sleeping => tokens.colorStatusInfoAccent,
        };
    final filled =
        connection == KAgentConnection.online ||
        connection == KAgentConnection.sleeping;
    return Container(
      width: tokens.sizeIndicatorTiny,
      height: tokens.sizeIndicatorTiny,
      decoration: BoxDecoration(
        color: filled ? accent : tokens.colorSurfaceRaised,
        borderRadius: BorderRadius.circular(
          connection == KAgentConnection.sleeping
              ? tokens.radiusExtraSmall
              : tokens.radiusFull,
        ),
        border: Border.all(color: accent, width: tokens.borderWidthDefault),
      ),
    );
  }
}

class _BadgeIndicator extends StatelessWidget {
  const _BadgeIndicator({required this.item});
  final KAgentSwitcherItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final foreground =
        item.badgeForeground ?? tokens.colorActionPrimaryForeground;
    final count = item.unread ?? 0;
    return Container(
      constraints: BoxConstraints(
        minWidth: tokens.sizeIndicatorMedium,
        minHeight: tokens.sizeIndicatorMedium,
      ),
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceMicro),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: item.badgeColor ?? tokens.colorStatusErrorAccent,
        borderRadius: BorderRadius.circular(tokens.radiusFull),
        border: Border.all(
          color: tokens.colorSurfaceRaised,
          width: tokens.borderWidthDefault,
        ),
      ),
      child: IconTheme(
        data: IconThemeData(color: foreground, size: tokens.sizeIndicatorSmall),
        child: DefaultTextStyle(
          style: TextStyle(
            color: foreground,
            fontFamily: tokens.fontFamily,
            fontSize: tokens.fontCaption2Size,
            fontWeight: tokens.fontControlWeight,
          ),
          child: item.badgeContent ?? Text(count > 99 ? '99+' : '$count'),
        ),
      ),
    );
  }
}

class _ManageBubble extends StatelessWidget {
  const _ManageBubble({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      button: true,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        child: InkWell(
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          onTap: onPressed,
          child: SizedBox(
            width:
                tokens.componentAvatarSizeLarge +
                tokens.spaceControlInsetInline * 2,
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceTight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: tokens.spaceTight,
                children: [
                  CustomPaint(
                    painter: _DashedCirclePainter(
                      color: tokens.colorBorderStrong,
                      width: tokens.borderWidthDefault,
                    ),
                    child: SizedBox.square(
                      dimension: tokens.componentAvatarSizeLarge,
                      child: Center(
                        child: KIcon(
                          KIconName.userRoundPlus,
                          size: tokens.sizeIconDefault,
                          color: tokens.colorTextMuted,
                        ),
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tokens.colorTextMuted,
                        fontFamily: tokens.fontFamily,
                        fontSize: tokens.fontCaptionSize,
                        height:
                            tokens.fontCaptionLineHeight /
                            tokens.fontCaptionSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color, required this.width});
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final rect = Offset.zero & size;
    const segments = 12;
    const gapFraction = 0.45;
    final sweep = 2 * 3.141592653589793 / segments;
    for (var index = 0; index < segments; index++) {
      canvas.drawArc(
        rect.deflate(width / 2),
        index * sweep,
        sweep * (1 - gapFraction),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      color != oldDelegate.color || width != oldDelegate.width;
}

String _semanticLabel(KAgentSwitcherItem item, KAgentSwitcherLabels labels) {
  final parts = <String>[item.name];
  if (item.connection != null) {
    parts.add(
      '${labels.connectionPrefix}: '
      '${labels.connectionLabel(item.connection!)}',
    );
  }
  if (item.activity != null) {
    parts.add(
      '${labels.activityPrefix}: ${labels.activityLabel(item.activity!)}',
    );
  }
  if ((item.unread ?? 0) > 0) parts.add(labels.unreadLabel(item.unread!));
  return parts.join(', ');
}
