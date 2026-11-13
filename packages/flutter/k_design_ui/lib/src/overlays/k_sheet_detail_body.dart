import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/k_icon_button.dart';
import '../primitives/k_icon.dart';

/// Shared full-bleed media, one content inset and a fixed safe-area footer.
class KSheetDetailBody extends StatelessWidget {
  const KSheetDetailBody({
    required this.hero,
    required this.child,
    this.floatingActions,
    this.heroOverlays,
    this.footer,
    this.onClose,
    this.closeLabel,
    this.showGrip = false,
    super.key,
  });

  final Widget hero;
  final Widget child;
  final Widget? floatingActions;
  final Widget? heroOverlays;
  final Widget? footer;
  final VoidCallback? onClose;
  final String? closeLabel;
  final bool showGrip;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: t.layoutMenuWidth,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        hero,
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: t.spaceCardPadding * 3,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    t.colorSurfaceRaised.withValues(alpha: 0),
                                    t.colorSurfaceRaised,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (heroOverlays != null)
                          Positioned(
                            left: t.spaceControlInsetInline,
                            right: t.spaceControlInsetInline,
                            bottom: t.spaceContentActionGap,
                            child: heroOverlays!,
                          ),
                        Positioned(
                          top: t.spaceControlInsetInline,
                          right: t.spaceControlInsetInline,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (floatingActions != null) ...[
                                _FloatingSurface(child: floatingActions!),
                                SizedBox(width: t.spaceControlGap),
                              ],
                              if (onClose != null)
                                _FloatingSurface(
                                  child: KIconButton(
                                    label:
                                        closeLabel ??
                                        MaterialLocalizations.of(
                                          context,
                                        ).closeButtonTooltip,
                                    icon: KIconName.x,
                                    onPressed: onClose,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (showGrip)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: t.spaceSmallInset,
                            child: IgnorePointer(
                              child: Center(
                                child: Container(
                                  width: t.componentBottomSheetGripWidth,
                                  height: t.componentBottomSheetGripHeight,
                                  decoration: BoxDecoration(
                                    color: t.colorBorderStrong,
                                    borderRadius: BorderRadius.circular(
                                      t.radiusExtraSmall,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      t.spaceCardPadding,
                      t.spaceTight,
                      t.spaceCardPadding,
                      t.spaceCardPadding,
                    ),
                    child: child,
                  ),
                ],
              ),
            ),
          ),
          if (footer != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight / 2),
              child: SingleChildScrollView(
                primary: false,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: t.colorBorderDefault,
                        width: t.borderWidthDefault,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: t.spaceCardPadding,
                        vertical: t.spaceControlInsetInline,
                      ),
                      child: footer!,
                    ),
                  ),
                ),
              ),
            )
          else
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}

class _FloatingSurface extends StatelessWidget {
  const _FloatingSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.colorSurfaceRaised.withValues(alpha: 1 - t.opacityFaint),
        borderRadius: BorderRadius.circular(t.radiusFull),
      ),
      child: child,
    );
  }
}
