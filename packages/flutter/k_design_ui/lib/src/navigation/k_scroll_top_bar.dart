import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show RenderIndexedStack, RenderOffstage, ScrollDirection;
import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/k_icon_button.dart';
import '../actions/k_menu_button.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../localization/k_localization.dart';
import '../primitives/k_text.dart';

/// Lets a [KPageHeader] hand its title to the bar of the surrounding
/// [KScrollTopBar].
class KTopBarTitleScope extends InheritedWidget {
  const KTopBarTitleScope({
    required this.controller,
    required super.child,
    this.barControls = false,
    super.key,
  });

  final KTopBarTitleController controller;

  /// Whether the bar row holds controls (back, leading or actions). The
  /// row then separates the large title from the status bar, so the
  /// header drops its own top padding.
  final bool barControls;

  static bool barControlsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<KTopBarTitleScope>()
          ?.barControls ??
      false;

  static KTopBarTitleController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<KTopBarTitleScope>()
      ?.controller;

  @override
  bool updateShouldNotify(KTopBarTitleScope oldWidget) =>
      controller != oldWidget.controller ||
      barControls != oldWidget.barControls;
}

/// The page title and where it is on screen.
/// One page header's entry in the top bar.
class KTopBarEntry {
  KTopBarEntry({
    required this.title,
    required this.anchor,
    this.back,
    this.leading,
    this.actions = const [],
    required this.order,
  });
  final String title;
  final GlobalKey anchor;
  final Widget? back;
  final Widget? leading;
  final List<Widget> actions;

  /// Registration order; among visible headers the newest wins.
  final int order;
}

/// The page headers below a [KScrollTopBar]. Only the header that is on
/// screen fills the bar: pages kept alive in other tabs (`IndexedStack`,
/// `Offstage`) or under another route never leak their actions (0015).
class KTopBarTitleController extends ChangeNotifier {
  final _entries = <GlobalKey, KTopBarEntry>{};
  int _order = 0;
  KTopBarEntry? _active;

  KTopBarEntry? get active => _active;
  String? get title => _active?.title;
  GlobalKey? get anchor => _active?.anchor;

  /// The header's back control, or its [leading] navigation button.
  Widget? get back => _active?.back ?? _active?.leading;
  List<Widget> get actions => _active?.actions ?? const [];

  void register(
    String title,
    GlobalKey anchor, {
    Widget? back,
    Widget? leading,
    List<Widget> actions = const [],
  }) {
    _entries[anchor] = KTopBarEntry(
      title: title,
      anchor: anchor,
      back: back,
      leading: leading,
      actions: actions,
      order: _entries[anchor]?.order ?? _order++,
    );
    resolve();
  }

  void unregister(GlobalKey anchor) {
    if (_entries.remove(anchor) == null) return;
    // Unregistering happens while the tree is finalized; resolve after it.
    if (_resolveScheduled) return;
    _resolveScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveScheduled = false;
      if (!_disposed) resolve();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  bool _resolveScheduled = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Picks the newest header that is actually shown; call after layout.
  void resolve() {
    KTopBarEntry? next;
    for (final entry in _entries.values) {
      final box = entry.anchor.currentContext?.findRenderObject();
      if (box == null || !box.attached || !_shown(box)) continue;
      if (next == null || entry.order > next.order) next = entry;
    }
    if (next == _active) return;
    _active = next;
    notifyListeners();
  }

  /// False when an IndexedStack shows another child or an Offstage hides it.
  static bool _shown(RenderObject node) {
    RenderObject child = node;
    var parent = node.parent;
    while (parent != null) {
      if (parent is RenderOffstage && parent.offstage) return false;
      if (parent is RenderIndexedStack) {
        var index = 0;
        var current = parent.firstChild;
        while (current != null && current != child) {
          index++;
          current = parent.childAfter(current);
        }
        if (index != parent.index) return false;
      }
      child = parent;
      parent = parent.parent;
    }
    return true;
  }
}

/// Reports the page title of a [KPageHeader] to the nearest bar.
class KTopBarTitleAnchor extends StatefulWidget {
  const KTopBarTitleAnchor({
    required this.title,
    required this.child,
    this.back,
    this.leading,
    this.actions = const [],
    super.key,
  });
  final String title;
  final Widget child;
  final Widget? back;
  final Widget? leading;
  final List<Widget> actions;

  @override
  State<KTopBarTitleAnchor> createState() => _KTopBarTitleAnchorState();
}

class _KTopBarTitleAnchorState extends State<KTopBarTitleAnchor>
    with AutomaticKeepAliveClientMixin {
  final _anchor = GlobalKey();

  // In a lazy list the header leaves the tree once it scrolls far away;
  // the bar still needs its title, back control and actions.
  @override
  bool get wantKeepAlive => true;
  KTopBarTitleController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = KTopBarTitleScope.maybeOf(context);
    if (controller != _controller) {
      _controller?.unregister(_anchor);
      _controller = controller;
    }
    _register();
  }

  @override
  void didUpdateWidget(KTopBarTitleAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.back != widget.back ||
        oldWidget.leading != widget.leading ||
        oldWidget.actions != widget.actions) {
      _register();
    }
  }

  void _register() {
    final controller = _controller;
    if (controller == null) return;
    // Hidden routes and tabs pause their tickers; they leave the bar.
    final visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (visible) {
        controller.register(
          widget.title,
          _anchor,
          back: widget.back,
          leading: widget.leading,
          actions: widget.actions,
        );
      } else {
        controller.unregister(_anchor);
      }
    });
  }

  @override
  void dispose() {
    _controller?.unregister(_anchor);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return KeyedSubtree(key: _anchor, child: widget.child);
  }
}

/// Where a page's primary action goes on phones (Decision 0015).
enum KPrimaryActionPlacement {
  /// Material: extended floating action button; Apple and linear: an icon
  /// in the top bar.
  auto,

  /// An icon in the top bar (iOS navigation bar).
  bar,

  /// An extended floating action button above the tab bar (Material 3).
  fab,
}

/// The top bar of phone screens (Decision 0015), as the iOS navigation bar
/// and the Material 3 top app bar work:
///
/// - It always holds the page header's back control and actions, so they
///   never scroll away and never appear twice. The page header then shows
///   only the large title.
/// - At the top it is transparent; once content scrolls under it, it gets
///   glass (Apple) or a tonal surface, and the inline title fades in when
///   the large title has scrolled away.
/// - The page's primary action becomes an icon in the bar or an extended
///   floating action button ([placement]).
///
/// [KAppShell] places it on phones; screens outside the shell can wrap
/// their scroll view in it.
class KScrollTopBar extends StatefulWidget {
  const KScrollTopBar({
    required this.child,
    this.placement = KPrimaryActionPlacement.auto,
    this.enabled = true,
    super.key,
  });
  final Widget child;
  final KPrimaryActionPlacement placement;

  /// Hide the header and its insets while preserving the page subtree.
  final bool enabled;

  @override
  State<KScrollTopBar> createState() => _KScrollTopBarState();
}

class _KScrollTopBarState extends State<KScrollTopBar> {
  final _controller = KTopBarTitleController();
  final _bar = GlobalKey();
  bool _scrolled = false;
  bool _titleShown = false;
  bool _fabExtended = true;
  bool _updateScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Titles register while the tree builds or unmounts; measure after it.
  void _onTitleChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
      _update();
    });
  }

  bool _onScroll(ScrollNotification notification) {
    if (!widget.enabled) return false;
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      final scrolled =
          notification.metrics.pixels > notification.metrics.minScrollExtent;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
      // Material: the extended FAB shrinks to its icon while scrolling down.
      if (notification is UserScrollNotification) {
        final extended =
            notification.direction != ScrollDirection.reverse || !scrolled;
        if (extended != _fabExtended) {
          setState(() => _fabExtended = extended);
        }
      }
      // Positions settle after this frame's layout.
      if (!_updateScheduled) {
        _updateScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateScheduled = false;
          _update();
        });
      }
    }
    return false;
  }

  void _update() {
    if (!mounted) return;
    final anchor = _controller.anchor?.currentContext?.findRenderObject();
    final bar = _bar.currentContext?.findRenderObject();
    // Each tab keeps its own scroll position: after a tab switch the bar
    // follows the page now shown, not the one scrolled before.
    final anchorContext = _controller.anchor?.currentContext;
    final position = anchorContext == null
        ? null
        : Scrollable.maybeOf(anchorContext)?.position;
    if (position != null && position.hasPixels) {
      final scrolled = position.pixels > position.minScrollExtent;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    }
    var shown = false;
    if (_scrolled &&
        anchor is RenderBox &&
        anchor.attached &&
        bar is RenderBox &&
        bar.attached) {
      final titleBottom = anchor
          .localToGlobal(Offset(0, anchor.size.height))
          .dy;
      final barBottom = bar.localToGlobal(Offset(0, bar.size.height)).dy;
      // A header kept alive far outside a lazy list has no position.
      shown = !titleBottom.isFinite || titleBottom <= barBottom;
    }
    if (shown != _titleShown && mounted) setState(() => _titleShown = shown);
  }

  @override
  Widget build(BuildContext context) {
    // A tab switch changes which header is shown only after layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.resolve();
    });
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final style = KAdaptive.maybeOf(context)?.style ?? KStyle.linear;
    final apple = style == KStyle.apple;
    final motion = t.motion(KMotionRole.control);
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    final title = _controller.title;
    final back = _controller.back;
    final placement = switch (widget.placement) {
      KPrimaryActionPlacement.auto =>
        style == KStyle.material
            ? KPrimaryActionPlacement.fab
            : KPrimaryActionPlacement.bar,
      final other => other,
    };
    final split = _splitActions(
      _controller.actions,
      KLocalization.of(context).text('moreActions'),
      fab: placement == KPrimaryActionPlacement.fab,
    );
    // The bar row takes space only when it holds controls; a top-level
    // screen keeps its large title right under the status bar.
    final hasControls =
        widget.enabled && (back != null || split.bar.isNotEmpty);
    final barHeight = t.componentTopBarHeight;
    final fab = widget.enabled ? split.primary : null;
    final fabReserve = fab == null
        ? 0.0
        : t.componentFabHeight + t.spaceLayoutGutter;

    final row = SizedBox(
      height: barHeight,
      child: Row(
        children: [
          if (back case final control?) ...[
            control,
            SizedBox(width: t.spaceTight),
          ],
          Expanded(
            child: ExcludeSemantics(
              child: AnimatedOpacity(
                opacity: _titleShown && title != null ? 1 : 0,
                duration: motion.settle,
                curve: motion.curve,
                child: Align(
                  // iOS centres the inline title; Material starts it.
                  alignment: apple
                      ? Alignment.center
                      : AlignmentDirectional.centerStart,
                  child: KText(
                    title ?? '',
                    variant: KTextVariant.heading5,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          ...split.bar,
        ],
      ),
    );
    Widget background = AnimatedOpacity(
      opacity: _scrolled ? 1 : 0,
      duration: motion.settle,
      curve: motion.curve,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Same glass as the tab bar.
          color: apple
              ? t.colorSurfaceRaised.withValues(
                  alpha: t.componentMobileAppBarOpacitySurface,
                )
              : t.colorSurfaceRaised,
          border: Border(
            bottom: BorderSide(
              color: t.colorBorderDefault,
              width: t.spaceHairline,
            ),
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
    if (apple) {
      background = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _scrolled ? t.componentMobileAppBarGlassNativeBlur : 0,
            sigmaY: _scrolled ? t.componentMobileAppBarGlassNativeBlur : 0,
          ),
          child: background,
        ),
      );
    }
    final bar = KeyedSubtree(
      key: _bar,
      child: SizedBox(
        height: top + barHeight,
        child: Stack(
          children: [
            Positioned.fill(child: IgnorePointer(child: background)),
            Padding(
              padding: EdgeInsets.only(
                top: top,
                left: t.spaceLayoutGutter + media.padding.left,
                right: t.spaceLayoutGutter + media.padding.right,
              ),
              child: row,
            ),
          ],
        ),
      ),
    );
    return KTopBarTitleScope(
      controller: _controller,
      barControls: hasControls,
      child: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
              // Content starts below the bar's controls and ends above the
              // floating action button.
              data: media.copyWith(
                padding: media.padding.copyWith(
                  top: top + (hasControls ? barHeight : 0),
                  bottom: media.padding.bottom + fabReserve,
                ),
              ),
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: widget.child,
              ),
            ),
          ),
          if (widget.enabled) Positioned(top: 0, left: 0, right: 0, child: bar),
          if (fab case final action?)
            PositionedDirectional(
              end: t.spaceLayoutGutter + media.padding.right,
              bottom: t.spaceLayoutGutter + media.padding.bottom,
              child: _KExtendedFab(action: action, extended: _fabExtended),
            ),
        ],
      ),
    );
  }
}

/// A page action converted for the bar or the FAB.
class _BarAction {
  const _BarAction({required this.label, required this.onPressed, this.icon});
  final String label;
  final KIconName? icon;
  final VoidCallback? onPressed;
}

class _SplitActions {
  const _SplitActions(this.bar, this.primary);
  final List<Widget> bar;
  final _BarAction? primary;
}

/// Distributes the page header's actions (Decision 0015):
///
/// - the first primary [KButton] is the primary action: an extended FAB
///   when [fab], else an icon in the bar (its label becomes the tooltip);
/// - icon buttons stay in the bar, at most two;
/// - text buttons, further actions and the entries of a page's own overflow
///   menu share one More menu, so the bar never shows two of them.
_SplitActions _splitActions(
  List<Widget> actions,
  String moreLabel, {
  required bool fab,
}) {
  if (actions.isEmpty) return const _SplitActions([], null);
  final visible = <Widget>[];
  final menu = <KMenuAction>[];
  _BarAction? primary;
  KIconName? iconOf(KButton button) =>
      button.leading is KIcon ? (button.leading! as KIcon).name : null;
  for (final (index, action) in actions.indexed) {
    if (action is KButton &&
        primary == null &&
        action.variant == KButtonVariant.primary) {
      final icon = iconOf(action);
      if (fab) {
        primary = _BarAction(
          label: action.label,
          icon: icon,
          onPressed: action.onPressed,
        );
        continue;
      }
      if (icon != null && visible.length < 2) {
        visible.add(
          KIconButton(
            label: action.label,
            icon: icon,
            onPressed: action.onPressed,
          ),
        );
        continue;
      }
    }
    if (action is KIconButton && visible.length < 2) {
      visible.add(action);
    } else if (action is KIconButton) {
      menu.add(
        KMenuAction(
          id: '$index',
          label: action.label,
          icon: action.icon,
          onSelect: action.onPressed,
          disabled: action.onPressed == null,
        ),
      );
    } else if (action is KButton) {
      menu.add(
        KMenuAction(
          id: '$index',
          label: action.label,
          icon: iconOf(action),
          onSelect: action.onPressed,
          disabled: action.onPressed == null,
        ),
      );
    } else if (action is KMenuButton && action.overflow) {
      // The page's own More menu merges into the bar's.
      menu.addAll(action.actions);
    } else if (action is KOverflowMenu) {
      menu.addAll(action.actions);
    } else if (visible.length < 2) {
      visible.add(action);
    }
  }
  return _SplitActions([
    ...visible,
    if (menu.isNotEmpty)
      KMenuButton(label: moreLabel, overflow: true, actions: menu),
  ], primary);
}

/// Material 3 extended FAB; it shrinks to its icon while content scrolls
/// down and extends again on the way up.
class _KExtendedFab extends StatelessWidget {
  const _KExtendedFab({required this.action, required this.extended});
  final _BarAction action;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final motion = t.motion(KMotionRole.control);
    final showLabel = extended || action.icon == null;
    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.componentFabRadius),
          boxShadow: t.elevationMedium,
        ),
        child: Material(
          color: t.componentFabBackground,
          borderRadius: BorderRadius.circular(t.componentFabRadius),
          child: InkWell(
            onTap: action.onPressed,
            borderRadius: BorderRadius.circular(t.componentFabRadius),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: t.componentFabHeight,
                minWidth: t.componentFabHeight,
              ),
              child: AnimatedSize(
                duration: motion.settle,
                curve: motion.curve,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: showLabel ? t.spaceLayoutGutter : 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (action.icon case final icon?)
                        KIcon(icon, color: t.componentFabForeground),
                      if (showLabel) ...[
                        if (action.icon != null) SizedBox(width: t.spaceTight),
                        KText(
                          action.label,
                          variant: KTextVariant.label,
                          maxLines: 1,
                          style: TextStyle(color: t.componentFabForeground),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
