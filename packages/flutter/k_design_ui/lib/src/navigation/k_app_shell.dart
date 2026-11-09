import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../basic_display.dart';
import '../feedback/k_haptics.dart';
import '../primitives/k_icon.dart';
import 'k_mobile_app_bar.dart';
import 'k_scroll_top_bar.dart';
import 'k_sidebar.dart';

/// A top-level destination of a [KAppShell].
class KAppDestination {
  const KAppDestination({
    required this.id,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.mobileIconBuilder,
    this.badge,
  });
  final String id;
  final String label;
  final KIconName icon;
  final KIconName? selectedIcon;

  /// Decorative compact-navigation visual. The shell owns its 24 px fitted
  /// slot and destination semantics; rail/sidebar keep [icon]/[selectedIcon].
  final Widget Function(BuildContext context, bool selected)? mobileIconBuilder;

  /// Short count or marker ("2", "99+"); a tab bar badge and a sidebar
  /// [KBadge].
  final String? badge;
}

/// Adaptive app frame for the top-level destinations (Decision 0012):
///
/// | Width       | Navigation                                  |
/// | ----------- | ------------------------------------------- |
/// | < 600       | tab bar at the bottom (2–5 destinations)    |
/// | 600 – 839   | sidebar rail                                |
/// | ≥ 840       | expanded sidebar with header and footer     |
///
/// The width is the shell's own width, so the same rule holds in a split
/// view or a resizable window. The shell holds no routes: [onSelected]
/// reports the destination and the app's router shows [child]. Destination
/// changes keep each screen's own navigation stack in the app.
class KAppShell extends StatelessWidget {
  const KAppShell({
    required this.destinations,
    required this.selectedId,
    required this.onSelected,
    required this.child,
    this.sidebarHeader,
    this.sidebarFooter,
    this.semanticLabel = 'Primary navigation',
    this.primaryActionPlacement = KPrimaryActionPlacement.auto,
    this.mobileLabelVisibility = KMobileAppBarLabelVisibility.always,
    super.key,
  });

  final List<KAppDestination> destinations;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final Widget child;

  /// Shown above the destinations in the expanded sidebar (app name,
  /// account switcher).
  final Widget? sidebarHeader;

  /// Shown below the destinations in the expanded sidebar (settings, help).
  final Widget? sidebarFooter;
  final String semanticLabel;
  final KMobileAppBarLabelVisibility mobileLabelVisibility;

  /// Phones: where a page's primary action goes. `auto` uses the extended
  /// floating action button for Material and the top bar for Apple.
  final KPrimaryActionPlacement primaryActionPlacement;

  void _select(BuildContext context, String id) {
    if (id == selectedId) return;
    kHaptic(context, KHapticCue.selection);
    onSelected(id);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      destinations.length >= 2 && destinations.length <= 5,
      'A tab bar holds 2 to 5 destinations (Apple HIG); group the rest '
      'inside an existing tab (no "More" tab).',
    );
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final windowClass = kWindowClassForWidth(constraints.maxWidth);
        if (windowClass == KWindowClass.compact) {
          final style = KAdaptive.maybeOf(context)?.style;
          final bar = KMobileAppBar(
            // Apple style: the iOS 26 floating glass tab bar.
            variant: switch (KAdaptive.maybeOf(context)?.style) {
              KStyle.apple => KMobileAppBarVariant.floatingGlass,
              // Material 3 navigation bar with pill indicator.
              KStyle.material => KMobileAppBarVariant.labeled,
              _ => KMobileAppBarVariant.fixed,
            },
            labelVisibility: mobileLabelVisibility,
            visibility: KMobileAppBarVisibility.always,
            semanticLabel: semanticLabel,
            selectedId: selectedId,
            onSelectionChanged: (id) => _select(context, id),
            items: [
              for (final destination in destinations)
                KMobileAppBarItem(
                  id: destination.id,
                  label: destination.label,
                  icon: destination.mobileIconBuilder != null
                      ? ExcludeSemantics(
                          child: SizedBox.square(
                            dimension:
                                t.componentMobileAppBarDestinationIconSize,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: destination.mobileIconBuilder!(
                                context,
                                destination.id == selectedId,
                              ),
                            ),
                          ),
                        )
                      : KIcon(
                          destination.id == selectedId
                              ? destination.selectedIcon ?? destination.icon
                              : destination.icon,
                          size: 24,
                          color: destination.id == selectedId
                              ? t.colorTextPrimary
                              : t.colorTextMuted,
                        ),
                  badge: destination.badge == null
                      ? null
                      : Text(destination.badge!),
                ),
            ],
          );
          // Content scrolls under a bar that covers the status bar and
          // takes the page title (Decision 0015).
          final page = KScrollTopBar(
            placement: primaryActionPlacement,
            child: child,
          );
          if (style != KStyle.apple) {
            return Column(
              children: [
                Expanded(child: page),
                bar,
              ],
            );
          }
          // iOS 26: content scrolls under the floating glass tab bar; the
          // bar's height is reported as bottom padding so lists end above it.
          final media = MediaQuery.of(context);
          final reserve =
              t.componentMobileAppBarContainerMinHeight +
              2 * t.componentMobileAppBarContainerBottomInset;
          return Stack(
            children: [
              Positioned.fill(
                child: MediaQuery(
                  data: media.copyWith(
                    padding: media.padding.copyWith(
                      bottom: media.padding.bottom + reserve,
                    ),
                  ),
                  child: page,
                ),
              ),
              Align(alignment: Alignment.bottomCenter, child: bar),
            ],
          );
        }
        // iPadOS and Android tablets show labelled destinations; the
        // icon-only rail stays for the productivity style (Decision 0015).
        final rail =
            windowClass == KWindowClass.medium &&
            (KAdaptive.maybeOf(context)?.style ?? KStyle.linear) ==
                KStyle.linear;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KSidebar(
              mode: rail ? KSidebarMode.rail : KSidebarMode.expanded,
              semanticLabel: semanticLabel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sidebarHeader case final header? when !rail)
                    KSidebarHeader(child: header),
                  KSidebarBody(
                    children: [
                      for (final destination in destinations)
                        Padding(
                          padding: EdgeInsets.only(bottom: t.spaceMicro),
                          child: KSidebarItem(
                            label: destination.label,
                            leading: KIcon(
                              destination.id == selectedId
                                  ? destination.selectedIcon ?? destination.icon
                                  : destination.icon,
                              size: 20,
                            ),
                            badge: destination.badge == null
                                ? null
                                : KBadge(
                                    variant: KBadgeVariant.secondary,
                                    child: Text(destination.badge!),
                                  ),
                            active: destination.id == selectedId,
                            onPressed: () => _select(context, destination.id),
                          ),
                        ),
                    ],
                  ),
                  if (sidebarFooter case final footer? when !rail)
                    Padding(
                      padding: EdgeInsets.all(t.spaceControlGap),
                      child: footer,
                    ),
                ],
              ),
            ),
            // Wide windows: the page keeps a readable width (Decision 0014).
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: t.layoutPageWidth),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
