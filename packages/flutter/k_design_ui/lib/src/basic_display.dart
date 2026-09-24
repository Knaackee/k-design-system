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
      KAttachmentSize.compact => t.componentAttachmentCompactPaddingBlock,
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
                width: t.componentAttachmentMediaSize,
                height: t.componentAttachmentMediaSize,
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
                              dimension: t.componentSpinnerDefaultSize,
                              child: CircularProgressIndicator(
                                value: MediaQuery.disableAnimationsOf(context)
                                    ? .72
                                    : null,
                                strokeWidth: t.componentSpinnerStrokeWidth,
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
                      SizedBox(height: t.componentAttachmentProgressGap),
                      LinearProgressIndicator(
                        value: progress!.clamp(0, 1),
                        minHeight: t.componentAttachmentProgressHeight,
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
      KAvatarSize.small => t.componentAvatarSizeSmall,
      KAvatarSize.standard => t.componentAvatarSizeMedium,
      KAvatarSize.large => t.componentAvatarSizeLarge,
    };
    final fallbackWidget = Center(
      child: DefaultTextStyle(
        style: _textStyle(
          t,
          size == KAvatarSize.large
              ? t.componentAvatarFallbackFontSizeLarge
              : size == KAvatarSize.small
              ? t.componentAvatarFallbackFontSizeSmall
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
                end: -t.componentAvatarBadgeInset,
                bottom: -t.componentAvatarBadgeInset,
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: t.componentAvatarBadgeSize,
                    minHeight: t.componentAvatarBadgeSize,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: t.componentAvatarBadgeInset,
                  ),
                  decoration: BoxDecoration(
                    color: t.colorStatusSuccessAccent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: t.colorSurfaceCanvas,
                      width: t.componentAvatarBadgeStrokeWidth,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: DefaultTextStyle(
                    style: _textStyle(
                      t,
                      t.componentAvatarBadgeFontSize,
                      FontWeight.w600,
                      t.colorActionPrimaryForeground,
                    ),
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
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return SizedBox(
      height: t.componentAvatarSizeLarge,
      child: Stack(
        children: [
          for (final (index, child) in children.indexed)
            PositionedDirectional(
              start: index * t.componentAvatarGroupStep,
              child: child,
            ),
        ],
      ),
    );
  }
}

enum KBadgeVariant {
  primary,
  secondary,
  outline,
  ghost,
  info,
  success,
  warning,
  destructive,
}

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
      KBadgeVariant.info => (
        t.colorStatusInfoBackground,
        t.colorStatusInfoForeground,
        t.colorStatusInfoBorder,
      ),
      KBadgeVariant.success => (
        t.colorStatusSuccessBackground,
        t.colorStatusSuccessForeground,
        t.colorStatusSuccessBorder,
      ),
      KBadgeVariant.warning => (
        t.colorStatusWarningBackground,
        t.colorStatusWarningForeground,
        t.colorStatusWarningBorder,
      ),
      KBadgeVariant.destructive => (
        t.colorStatusErrorBackground,
        t.colorStatusErrorForeground,
        t.colorStatusErrorBorder,
      ),
    };
    return Container(
      constraints: BoxConstraints(minHeight: t.componentBadgeMinHeight),
      padding: EdgeInsets.symmetric(horizontal: t.componentBadgePaddingInline),
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
              data: IconThemeData(
                size: t.componentBadgeIconSize,
                color: foreground,
              ),
              child: leading!,
            ),
            SizedBox(width: t.componentBadgeContentGap),
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
            SizedBox(width: t.componentBadgeContentGap),
            IconTheme(
              data: IconThemeData(
                size: t.componentBadgeIconSize,
                color: foreground,
              ),
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
  height: t.fontRelaxedHeight,
  leadingDistribution: TextLeadingDistribution.even,
  fontVariations: [
    FontVariation.weight(weight.value.toDouble()),
    FontVariation.opticalSize(size.clamp(14, 32)),
  ],
);
