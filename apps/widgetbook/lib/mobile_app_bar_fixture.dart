import 'package:flutter/material.dart';
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
  final ScrollController _scrollController = ScrollController();
  String selectedId = 'home';
  String message = 'Home selected';
  KGlassQuality quality = KGlassQuality.auto;
  bool collapsed = false;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (widget.variant != KMobileAppBarVariant.collapsible) return;
    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;
    final nextCollapsed = offset <= 24
        ? false
        : delta >= 6
        ? true
        : delta <= -6
        ? false
        : collapsed;
    if (offset <= 24 || delta.abs() >= 6) _lastScrollOffset = offset;
    if (nextCollapsed != collapsed && mounted) {
      setState(() => collapsed = nextCollapsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final items = [
      const KMobileAppBarItem(
        id: 'home',
        label: 'Home',
        icon: KIcon(KIconName.house, size: 24),
      ),
      const KMobileAppBarItem(
        id: 'inbox',
        label: 'Inbox',
        icon: KIcon(KIconName.mail, size: 24),
        badge: Text('13'),
      ),
      const KMobileAppBarItem(
        id: 'search',
        label: 'Search',
        icon: KIcon(KIconName.search, size: 24),
      ),
      const KMobileAppBarItem(
        id: 'settings',
        label: 'Settings',
        icon: KIcon(KIconName.settings, size: 24),
      ),
    ];

    return Scaffold(
      backgroundColor: tokens.colorSurfaceCanvas,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(.8, -.65),
                  radius: 1.2,
                  colors: [
                    tokens.colorBrandPrimaryAccent.withValues(alpha: .24),
                    tokens.colorSurfaceCanvas,
                  ],
                ),
              ),
            ),
          ),
          ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 132),
            children: [
              Text(
                'MOBILE WORKSPACE',
                style: TextStyle(
                  color: tokens.colorBrandPrimaryAccent,
                  fontFamily: tokens.fontFamily,
                  fontSize: tokens.fontCaptionSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              KText(widget.variant.name, variant: KTextVariant.heading2),
              const SizedBox(height: 4),
              KText(message, variant: KTextVariant.body),
              if (widget.variant == KMobileAppBarVariant.collapsible) ...[
                const SizedBox(height: 8),
                const KText(
                  'Scroll down to hide the navigation and up to reveal it.',
                  variant: KTextVariant.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final entry in KGlassQuality.values)
                    ChoiceChip(
                      label: Text(entry.name),
                      selected: quality == entry,
                      onSelected: (_) => setState(() => quality = entry),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < 8; index++) ...[
                KCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KText(
                        'Project update ${index + 1}',
                        variant: KTextVariant.label,
                      ),
                      const SizedBox(height: 4),
                      const KText(
                        'Content remains visible beneath the glass surface.',
                        variant: KTextVariant.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: KMobileAppBar(
                items: items,
                selectedId: selectedId,
                variant: widget.variant,
                collapsed: collapsed,
                contextualContent: Row(
                  children: [
                    const Expanded(
                      child: KText('3 selected', variant: KTextVariant.label),
                    ),
                    KIconButton(
                      icon: KIconName.folder,
                      label: 'Move selected items',
                      onPressed: () =>
                          setState(() => message = 'Moved 3 items'),
                    ),
                    const SizedBox(width: 4),
                    KIconButton(
                      icon: KIconName.trash,
                      label: 'Delete selected items',
                      onPressed: () =>
                          setState(() => message = 'Deleted 3 items'),
                    ),
                  ],
                ),
                quality: quality,
                visibility: KMobileAppBarVisibility.always,
                onSelectionChanged: (id) {
                  setState(() {
                    selectedId = id;
                    message =
                        '${items.firstWhere((item) => item.id == id).label} selected';
                  });
                },
                primaryAction:
                    widget.variant == KMobileAppBarVariant.floatingGlass ||
                        widget.variant == KMobileAppBarVariant.action
                    ? Semantics(
                        button: true,
                        label: 'Create issue',
                        child: Material(
                          color: tokens.colorActionPrimaryBackground,
                          borderRadius: BorderRadius.circular(18),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () =>
                                setState(() => message = 'Create issue action'),
                            child: const SizedBox.square(
                              dimension: 56,
                              child: Center(
                                child: KIcon(KIconName.plus, size: 26),
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
