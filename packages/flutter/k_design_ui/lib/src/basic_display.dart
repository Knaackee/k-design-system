import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'primitives/k_icon.dart';

enum KAttachmentState { ready, uploading, processing, error, complete }

enum KAttachmentSize { standard, small, compact }

class KAttachment extends StatelessWidget {
  const KAttachment({
    required this.title,
    this.description,
    this.media,
    this.actions,
    this.state = KAttachmentState.ready,
    this.progress,
    this.size = KAttachmentSize.standard,
    this.showLoadingIndicator = false,
    this.loadingIndicator,
    this.loadingLabel = 'Uploading attachment',
    this.onActivate,
    this.activateLabel = 'Open attachment',
    super.key,
  });
  final Widget title;
  final Widget? description;
  final Widget? media;
  final Widget? actions;
  final KAttachmentState state;
  final double? progress;
  final KAttachmentSize size;
  final bool showLoadingIndicator;
  final Widget? loadingIndicator;
  final String loadingLabel;
  final VoidCallback? onActivate;
  final String activateLabel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final error = state == KAttachmentState.error;
    final loading =
        showLoadingIndicator &&
        (state == KAttachmentState.uploading ||
            state == KAttachmentState.processing);
    final padding = switch (size) {
      KAttachmentSize.standard => t.spaceControlGap,
      KAttachmentSize.small => t.spaceControlGap * .75,
      KAttachmentSize.compact => 2.0,
    };
    return Semantics(
      button: onActivate != null,
      label: onActivate == null ? null : activateLabel,
      child: InkWell(
        onTap: onActivate,
        borderRadius: BorderRadius.circular(t.radiusCard),
        child: Container(
          constraints: BoxConstraints(minHeight: t.sizeHitTarget),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: error ? t.colorStatusErrorBackground : t.colorSurfaceRaised,
            border: Border.all(
              color: error ? t.colorStatusErrorBorder : t.colorBorderDefault,
            ),
            borderRadius: BorderRadius.circular(t.radiusCard),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: t.colorSurfaceSubtle,
                  borderRadius: BorderRadius.circular(t.radiusControl),
                ),
                alignment: Alignment.center,
                child: loading
                    ? Semantics(
                        label: loadingLabel,
                        child:
                            loadingIndicator ??
                            SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                value: MediaQuery.disableAnimationsOf(context)
                                    ? .72
                                    : null,
                                strokeWidth: 2,
                                color: t.colorActionPrimaryBackground,
                                backgroundColor: t.colorBorderDefault,
                              ),
                            ),
                      )
                    : media ?? const KIcon(KIconName.file),
              ),
              SizedBox(width: t.spaceControlGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DefaultTextStyle(
                      style: _textStyle(
                        t,
                        t.fontLabelSize,
                        t.fontLabelWeight,
                        error
                            ? t.colorStatusErrorForeground
                            : t.colorTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: title,
                    ),
                    if (description != null)
                      DefaultTextStyle(
                        style: _textStyle(
                          t,
                          t.fontBodySmallSize,
                          t.fontBodyWeight,
                          error
                              ? t.colorStatusErrorForeground
                              : t.colorTextMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: description!,
                      ),
                    if (progress != null) ...[
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress!.clamp(0, 1),
                        minHeight: 3,
                        backgroundColor: t.colorBorderDefault,
                        color: t.colorActionPrimaryBackground,
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...[
                SizedBox(width: t.spaceControlGap),
                actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum KAvatarSize { small, standard, large }

class KAvatar extends StatelessWidget {
  const KAvatar({
    required this.alt,
    this.image,
    this.fallback,
    this.badge,
    this.size = KAvatarSize.standard,
    super.key,
  });
  final String alt;
  final Widget? fallback;
  final ImageProvider<Object>? image;
  final Widget? badge;
  final KAvatarSize size;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final dimension = switch (size) {
      KAvatarSize.small => 28.0,
      KAvatarSize.standard => 36.0,
      KAvatarSize.large => 48.0,
    };
    final fallbackWidget = Center(
      child: DefaultTextStyle(
        style: _textStyle(
          t,
          size == KAvatarSize.large
              ? 16
              : size == KAvatarSize.small
              ? 11
              : t.fontControlSize,
          t.fontControlWeight,
          t.colorTextPrimary,
        ),
        child: fallback ?? Text(_avatarInitials(alt)),
      ),
    );
    return Semantics(
      image: image != null,
      label: alt,
      child: SizedBox.square(
        dimension: dimension,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipOval(
                child: ColoredBox(
                  color: t.colorSurfaceSubtle,
                  child: image == null
                      ? fallbackWidget
                      : Image(
                          image: image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => fallbackWidget,
                        ),
                ),
              ),
            ),
            if (badge != null)
              PositionedDirectional(
                end: -2,
                bottom: -2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: t.colorStatusSuccessAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: t.colorSurfaceCanvas, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: DefaultTextStyle(
                    style: _textStyle(t, 8, FontWeight.w600, Colors.white),
                    child: badge!,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _avatarInitials(String label) => label
    .trim()
    .split(RegExp(r'\s+'))
    .take(2)
    .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
    .join();

class KAvatarGroup extends StatelessWidget {
  const KAvatarGroup({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Stack(
      children: [
        for (final (index, child) in children.indexed)
          PositionedDirectional(start: index * 30, child: child),
      ],
    ),
  );
}

enum KBadgeVariant { primary, secondary, outline, ghost, destructive }

class KBadge extends StatelessWidget {
  const KBadge({
    required this.child,
    this.leading,
    this.trailing,
    this.variant = KBadgeVariant.primary,
    super.key,
  });
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final KBadgeVariant variant;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final (background, foreground, border) = switch (variant) {
      KBadgeVariant.primary => (
        t.colorActionPrimaryBackground,
        t.colorActionPrimaryForeground,
        Colors.transparent,
      ),
      KBadgeVariant.secondary => (
        t.colorSurfaceSubtle,
        t.colorTextPrimary,
        Colors.transparent,
      ),
      KBadgeVariant.outline => (
        Colors.transparent,
        t.colorTextPrimary,
        t.colorBorderDefault,
      ),
      KBadgeVariant.ghost => (
        Colors.transparent,
        t.colorTextMuted,
        Colors.transparent,
      ),
      KBadgeVariant.destructive => (
        t.colorStatusErrorBackground,
        t.colorStatusErrorForeground,
        t.colorStatusErrorBorder,
      ),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(t.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            IconTheme(
              data: IconThemeData(size: 12, color: foreground),
              child: leading!,
            ),
            const SizedBox(width: 4),
          ],
          DefaultTextStyle(
            style: _textStyle(
              t,
              t.fontCaptionSize,
              t.fontControlWeight,
              foreground,
            ),
            child: child,
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            IconTheme(
              data: IconThemeData(size: 12, color: foreground),
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}

TextStyle _textStyle(
  KDesignTokens t,
  double size,
  FontWeight weight,
  Color color,
) => TextStyle(
  color: color,
  fontFamily: t.fontFamily,
  fontSize: size,
  fontWeight: weight,
  height: 1.2,
  leadingDistribution: TextLeadingDistribution.even,
  fontVariations: [
    FontVariation.weight(weight.value.toDouble()),
    FontVariation.opticalSize(size.clamp(14, 32)),
  ],
);
