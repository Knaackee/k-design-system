import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class MobileAppBarFixture extends StatefulWidget {
  const MobileAppBarFixture({
    this.variant = KMobileAppBarVariant.floatingGlass,
    super.key,
  });
  final KMobileAppBarVariant variant;
  @override
  State<MobileAppBarFixture> createState() => _MobileAppBarFixtureState();
}

class _MobileAppBarFixtureState extends State<MobileAppBarFixture> {
  String selectedId = 'chat';
  String message = '';
  bool collapsed = false;
  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final action = widget.variant == KMobileAppBarVariant.action;
    final items = [
      KMobileAppBarItem(
        id: 'portfolios',
        label: 'Portfolios',
        icon: KIcon(
          KIconName.building,
          size: 24,
          strokeWidth: 1.5,
          color: selectedId == 'portfolios'
              ? tokens.colorTextPrimary
              : tokens.colorTextMuted,
        ),
      ),
      KMobileAppBarItem(
        id: 'chat',
        label: 'Chat',
        icon: _AppMark(color: tokens.colorTextPrimary),
      ),
      KMobileAppBarItem(
        id: 'settings',
        label: 'Settings',
        icon: KIcon(
          KIconName.settings,
          size: 24,
          strokeWidth: 1.5,
          color: selectedId == 'settings'
              ? tokens.colorTextPrimary
              : tokens.colorTextMuted,
        ),
      ),
    ];
    final title = switch (widget.variant) {
      KMobileAppBarVariant.floatingGlass => 'floating glass',
      KMobileAppBarVariant.floatingDock => 'floating dock',
      KMobileAppBarVariant.fixedLine => 'fixed line',
      _ => widget.variant.name,
    };
    return ColoredBox(
      color: tokens.colorSurfaceSubtle,
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: math.min(390, constraints.maxWidth),
            height: math.min(640, constraints.maxHeight),
            child: ColoredBox(
              color: tokens.colorSurfaceCanvas,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(tokens.spaceLayoutGutter),
                    child: KStack(
                      gap: KLayoutGap.control,
                      children: [
                        const KText(
                          'KMobileAppBar',
                          variant: KTextVariant.caption,
                        ),
                        KText(title, variant: KTextVariant.heading3),
                      ],
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(tokens.spaceLayoutGutter),
                      child: KStack(
                        gap: KLayoutGap.control,
                        align: KLayoutAlign.center,
                        children: [
                          KText(
                            items
                                .firstWhere((item) => item.id == selectedId)
                                .label,
                            variant: KTextVariant.heading2,
                          ),
                          KText(
                            message.isEmpty
                                ? 'Choose a destination below.'
                                : message,
                            variant: KTextVariant.bodySmall,
                          ),
                          if (widget.variant ==
                              KMobileAppBarVariant.collapsible)
                            KButton(
                              label: collapsed
                                  ? 'Show navigation'
                                  : 'Hide navigation',
                              variant: KButtonVariant.secondary,
                              onPressed: () =>
                                  setState(() => collapsed = !collapsed),
                            ),
                        ],
                      ),
                    ),
                  ),
                  KMobileAppBar(
                    items: action
                        ? items.where((item) => item.id != 'chat').toList()
                        : items,
                    selectedId: selectedId,
                    variant: widget.variant,
                    collapsed: collapsed,
                    quality:
                        widget.variant == KMobileAppBarVariant.floatingGlass
                        ? KGlassQuality.frosted
                        : KGlassQuality.solid,
                    visibility: KMobileAppBarVisibility.always,
                    onSelectionChanged: (id) => setState(() => selectedId = id),
                    primaryAction: action
                        ? Semantics(
                            selected: selectedId == 'chat',
                            child: KButton(
                              label: 'Chat',
                              variant: selectedId == 'chat'
                                  ? KButtonVariant.primary
                                  : KButtonVariant.secondary,
                              content: _AppMark(
                                color: selectedId == 'chat'
                                    ? tokens.colorActionPrimaryForeground
                                    : tokens.colorTextPrimary,
                              ),
                              onPressed: () =>
                                  setState(() => selectedId = 'chat'),
                            ),
                          )
                        : null,
                    contextualContent: Row(
                      children: [
                        const KText('3 selected', variant: KTextVariant.label),
                        KButton(
                          label: 'Move',
                          variant: KButtonVariant.ghost,
                          onPressed: () =>
                              setState(() => message = 'Move selected'),
                        ),
                        KButton(
                          label: 'Delete',
                          variant: KButtonVariant.ghost,
                          onPressed: () =>
                              setState(() => message = 'Delete selected'),
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
    );
  }
}

class _AppMark extends StatelessWidget {
  const _AppMark({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 32,
    child: SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="12 32 104 72"><path d="M14 102V90l24-14v26H14Z" fill="#EFA24C"/><path d="M44 102V74l26-18v46H44Z" fill="#A9A29A"/><path d="M76 102V50l19-14 19 14v52H76Z" fill="#${color.toARGB32().toRadixString(16).substring(2)}"/></svg>',
      width: 32,
      height: 32,
      excludeFromSemantics: true,
    ),
  );
}
