import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

/// iOS page transition with the iOS 26 back gesture (Decision 0012).
///
/// Visually identical to [CupertinoPageTransitionsBuilder]. The back swipe
/// starts at the leading edge, as before, **and anywhere in the content
/// area**, as in iOS 26 system apps. Horizontal gestures inside the page
/// (carousels, sliders, maps, swipeable rows) still win: they sit deeper in
/// the hit test, pass the drag slop first and take the gesture, so a back
/// swipe only starts on content that does not move horizontally itself.
///
/// The gesture respects the route like the system one does:
/// [ModalRoute.popGestureEnabled] is false for the first route, full-screen
/// dialogs, routes with `PopScope(canPop: false)` and while a transition
/// runs.
///
/// [kDesignTheme] installs it for iOS (and macOS, which uses the same
/// navigation model); Android keeps the system's own back handling.
class KPageTransitionsBuilder extends PageTransitionsBuilder {
  const KPageTransitionsBuilder({this.contentSwipe = true});

  /// False restores the edge-only gesture (pre-iOS 26 behaviour).
  final bool contentSwipe;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.fullscreenDialog) {
      return CupertinoFullscreenDialogTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: route.popGestureInProgress,
        child: child,
      );
    }
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: route.popGestureInProgress,
      child: _KBackSwipe<T>(
        route: route,
        contentSwipe: contentSwipe,
        child: child,
      ),
    );
  }
}

/// Edge width that always starts a back swipe, as in UIKit / Flutter.
const double _kEdgeWidth = 20;

/// Fling velocity (screen widths per second) that decides the direction.
const double _kMinFlingVelocity = 1;

/// Settle duration after the finger lifts (UIKit value used by Flutter).
const Duration _kSettleDuration = Duration(milliseconds: 350);

class _KBackSwipe<T> extends StatefulWidget {
  const _KBackSwipe({
    required this.route,
    required this.contentSwipe,
    required this.child,
  });

  final PageRoute<T> route;
  final bool contentSwipe;
  final Widget child;

  @override
  State<_KBackSwipe<T>> createState() => _KBackSwipeState<T>();
}

class _KBackSwipeState<T> extends State<_KBackSwipe<T>> {
  late final HorizontalDragGestureRecognizer _recognizer =
      HorizontalDragGestureRecognizer(debugOwner: this)
        ..onStart = _start
        ..onUpdate = _update
        ..onEnd = _end
        ..onCancel = _cancel;
  _KBackSwipeController<T>? _controller;
  final _tracked = <int>{};

  @override
  void dispose() {
    _recognizer.dispose();
    if (_controller != null) {
      // The route was removed mid-gesture; release the navigator.
      if (widget.route.navigator?.mounted ?? false) {
        widget.route.navigator?.didStopUserGesture();
      }
      _controller = null;
    }
    super.dispose();
  }

  bool get _ltr => Directionality.of(context) == TextDirection.ltr;

  double _logical(double value) => _ltr ? value : -value;

  void _pointerDown(PointerDownEvent event, {required bool edge}) {
    if (!widget.route.popGestureEnabled) return;
    if (!edge && !widget.contentSwipe) return;
    // The edge strip and the content both see a pointer at the edge.
    if (!_tracked.add(event.pointer)) return;
    _recognizer.addPointer(event);
  }

  void _pointerEnd(PointerEvent event) => _tracked.remove(event.pointer);

  void _start(DragStartDetails details) {
    if (!widget.route.popGestureEnabled) return;
    _controller = _KBackSwipeController<T>(widget.route);
  }

  void _update(DragUpdateDetails details) {
    final controller = _controller;
    if (controller == null) return;
    final width = context.size?.width ?? 1;
    controller.dragUpdate(_logical(details.primaryDelta ?? 0) / width);
  }

  void _end(DragEndDetails details) {
    final controller = _controller;
    if (controller == null) return;
    final width = context.size?.width ?? 1;
    controller.dragEnd(
      _logical(details.velocity.pixelsPerSecond.dx) / math.max(width, 1),
    );
    _controller = null;
  }

  void _cancel() {
    _controller?.dragEnd(0);
    _controller = null;
  }

  @override
  Widget build(BuildContext context) {
    final edgeWidth = math.max(
      _kEdgeWidth,
      _ltr
          ? MediaQuery.paddingOf(context).left
          : MediaQuery.paddingOf(context).right,
    );
    return Stack(
      fit: StackFit.passthrough,
      children: [
        // Content area: a translucent listener that joins the gesture arena
        // after the page's own recognizers (they are deeper in the hit test
        // and win when they move horizontally themselves).
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) => _pointerDown(event, edge: false),
          onPointerUp: _pointerEnd,
          onPointerCancel: _pointerEnd,
          child: widget.child,
        ),
        // Leading edge: always a back swipe, above the content.
        PositionedDirectional(
          start: 0,
          width: edgeWidth,
          top: 0,
          bottom: 0,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) => _pointerDown(event, edge: true),
            onPointerUp: _pointerEnd,
            onPointerCancel: _pointerEnd,
          ),
        ),
      ],
    );
  }
}

/// Drives the route's transition while the finger moves, like UIKit.
class _KBackSwipeController<T> {
  _KBackSwipeController(this.route) {
    route.navigator!.didStartUserGesture();
  }

  final PageRoute<T> route;

  // The framework's own Cupertino gesture uses the same protected
  // controller; there is no public way to scrub a route transition.
  // ignore: invalid_use_of_protected_member
  AnimationController get _animation => route.controller!;

  void dragUpdate(double fraction) {
    _animation.value -= fraction;
  }

  void dragEnd(double velocity) {
    final navigator = route.navigator!;
    final bool stay;
    if (!route.isCurrent) {
      stay = route.isActive;
    } else if (velocity.abs() >= _kMinFlingVelocity) {
      stay = velocity <= 0;
    } else {
      stay = _animation.value > 0.5;
    }
    if (stay) {
      _animation.animateTo(
        1,
        duration: _kSettleDuration,
        curve: Curves.fastEaseInToSlowEaseOut,
      );
    } else {
      if (route.isCurrent) navigator.pop();
      if (_animation.isAnimating) {
        _animation.animateBack(
          0,
          duration: _kSettleDuration,
          curve: Curves.fastEaseInToSlowEaseOut,
        );
      }
    }
    if (_animation.isAnimating) {
      late AnimationStatusListener listener;
      listener = (status) {
        navigator.didStopUserGesture();
        _animation.removeStatusListener(listener);
      };
      _animation.addStatusListener(listener);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
