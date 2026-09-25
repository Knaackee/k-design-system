import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../basic_display.dart';
import 'k_menu_button.dart';

/// Avatar-triggered actions. The consumer owns navigation and authentication.
class KUserMenu extends StatelessWidget {
  const KUserMenu({
    required this.userName,
    required this.actions,
    this.description,
    this.avatarImage,
    this.avatarFallback,
    this.avatar,
    this.label = 'User menu',
    this.disabled = false,
    this.header,
    this.showHeader = true,
    this.onOpenChange,
    super.key,
  });
  final String userName;
  final Widget? description;
  final ImageProvider<Object>? avatarImage;
  final Widget? avatarFallback, avatar, header;
  final List<KMenuAction> actions;
  final String label;
  final bool disabled, showHeader;
  final ValueChanged<bool>? onOpenChange;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final image =
        avatar ??
        KAvatar(alt: userName, image: avatarImage, fallback: avatarFallback);
    return KMenuButton(
      label: label,
      actions: actions,
      disabled: disabled,
      alignEnd: true,
      onOpenChange: onOpenChange,
      triggerRadius: BorderRadius.circular(t.radiusFull),
      triggerContent: SizedBox.square(
        dimension: math.max(t.sizeControl, t.sizeHitTarget),
        child: Center(
          child: ExcludeSemantics(
            child: SizedBox.square(dimension: t.sizeControl, child: image),
          ),
        ),
      ),
      header: !showHeader
          ? null
          : header ??
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(child: image),
                    SizedBox(width: t.spaceControlInsetInline),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontFamily: t.fontFamily,
                              fontSize: t.fontBodySmallSize,
                              height:
                                  t.fontBodySmallLineHeight /
                                  t.fontBodySmallSize,
                              fontWeight: t.fontLabelWeight,
                              color: t.colorTextPrimary,
                            ),
                          ),
                          if (description != null) ...[
                            SizedBox(height: t.spaceMicro),
                            DefaultTextStyle(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: TextStyle(
                                fontFamily: t.fontFamily,
                                fontSize: t.fontBodySmallSize,
                                height:
                                    t.fontBodySmallLineHeight /
                                    t.fontBodySmallSize,
                                color: t.colorTextMuted,
                              ),
                              child: description!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
