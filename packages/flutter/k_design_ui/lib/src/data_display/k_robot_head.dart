import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'robot_head/geometry.dart' as geometry;
import 'robot_head/light.dart' as lighting;
import 'robot_head/render.dart' as engine;
import 'robot_head/sim.dart';
import 'robot_head/types.dart';

export 'robot_head/types.dart';

// Upstream artwork palette, not application chrome. All three are overridable
// per head, matching the Web renderer's scoped color properties.
const _shellArgb = 0xff2b49a3;
const _trimArgb = 0xff93a6c8;
const _screenArgb = 0xffe8f2ff;

/// A consumer-owned audio measurement. No playback or microphone is started.
class KRobotHeadAudioFrame {
  const KRobotHeadAudioFrame({required this.level, this.bands});
  final double level;
  final List<double>? bands;
}

/// Imperative reactions complement the controlled widget properties.
class KRobotHeadController {
  _KRobotHeadState? _owner;
  bool react() => _owner?._react() ?? false;
  void reset() => _owner?._reset();
}

/// Native rendering of the same robot geometry, lighting and simulation as Web.
/// The resting square participates in layout; hops and glow paint outside it.
class KRobotHead extends StatefulWidget {
  const KRobotHead({
    super.key,
    this.shape = KRobotHeadShape.rectangle,
    this.state = KRobotHeadState.idle,
    this.size = 160,
    this.color = const Color(_shellArgb),
    this.trimColor = const Color(_trimArgb),
    this.screenColor = const Color(_screenArgb),
    this.speed = 1,
    this.paused = false,
    this.reducedMotion = false,
    this.interactive = true,
    this.antenna = true,
    this.floorShadow = true,
    this.seed = .42,
    this.target,
    this.trackPointer = true,
    this.audio,
    this.audioSource,
    this.controller,
    this.onActivate,
    this.onReactionStart,
    this.onReactionEnd,
    this.semanticsLabel = 'Robot',
  });

  final KRobotHeadShape shape;
  final KRobotHeadState state;
  final double size, speed, seed;
  final Color color, trimColor, screenColor;
  final bool paused, reducedMotion, interactive, antenna, floorShadow;

  /// Normalized -1…1 coordinates. Overrides automatic pointer tracking.
  final Offset? target;

  /// Set false with a null target to disable tracking entirely.
  final bool trackPointer;
  final KRobotHeadAudioFrame? audio;

  /// Sampled without widget rebuilds. Null returned by a source means silence.
  final KRobotHeadAudioFrame? Function()? audioSource;
  final KRobotHeadController? controller;
  final VoidCallback? onActivate, onReactionStart, onReactionEnd;
  final String semanticsLabel;

  @override
  State<KRobotHead> createState() => _KRobotHeadState();
}

double _unit(double v) => v.isFinite ? v.clamp(0.0, 1.0) : 0;

class _Repaint extends ChangeNotifier {
  void paint() => notifyListeners();
}

class _KRobotHeadState extends State<KRobotHead>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  late final engine.RobotRenderer _renderer;
  late RobotSim _sim;
  final _repaint = _Repaint();
  final _boundsKey = GlobalKey();
  Duration? _last;
  Offset? _pointer;
  double _level = 0;
  double? _reactionEnd;
  bool _reduced = false, _foreground = true, _focus = false;
  late engine.Palette _palette;
  final List<double> _bands = [];

  double get _size => widget.size.isFinite ? widget.size.clamp(16, 1024) : 160;
  bool get _running => !widget.paused && widget.speed > 0 && !_reduced;
  bool get _actionable => widget.interactive || widget.onActivate != null;

  @override
  void initState() {
    super.initState();
    _sim = RobotSim(_unit(widget.seed), widget.state);
    _renderer = engine.RobotRenderer(
      onInvalidate: () {
        if (mounted) _repaint.paint();
      },
    );
    _ticker = createTicker(_tick);
    _attachController();
    WidgetsBinding.instance.addObserver(this);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_routePointer);
    _updatePalette();
  }

  void _attachController() {
    assert(
      widget.controller?._owner == null || widget.controller?._owner == this,
      'A KRobotHeadController can control only one mounted robot.',
    );
    widget.controller?._owner = this;
  }

  void _updatePalette() {
    List<double> rgb(Color c) => [c.r * 255, c.g * 255, c.b * 255];
    _palette = engine.Palette(
      shell: lighting.Material(
        albedo: lighting.linear(rgb(widget.color)),
        f0: .05,
        metal: .15,
        spec: .55,
        shininess: 70,
        rim: .9,
      ),
      trim: lighting.Material(
        albedo: lighting.linear(rgb(widget.trimColor)),
        f0: .2,
        metal: .65,
        spec: .8,
        shininess: 45,
        rim: .7,
      ),
      led: rgb(widget.screenColor),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
  }

  @override
  void didUpdateWidget(KRobotHead oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._owner == this) {
        oldWidget.controller?._owner = null;
      }
      _attachController();
    }
    if (oldWidget.seed != widget.seed) _reset();
    if (oldWidget.color != widget.color ||
        oldWidget.trimColor != widget.trimColor ||
        oldWidget.screenColor != widget.screenColor) {
      _updatePalette();
    }
    _sim.setState(widget.state);
    _configure();
  }

  void _configure() {
    _reduced = widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    final run = _running && _foreground && TickerMode.valuesOf(context).enabled;
    if (run && !_ticker.isActive) {
      _last = null;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
      _last = null;
    }
    _repaint.paint();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _pointer = null;
    _configure();
  }

  void _routePointer(PointerEvent event) {
    if (event is PointerCancelEvent ||
        event is PointerRemovedEvent ||
        (event is PointerUpEvent && event.kind != PointerDeviceKind.mouse)) {
      _pointer = null;
    } else if (event is PointerHoverEvent ||
        event is PointerMoveEvent ||
        event is PointerDownEvent) {
      _pointer = event.position;
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == null
        ? 0.0
        : ((elapsed - _last!).inMicroseconds / 1000000).clamp(0.0, .1);
    _last = elapsed;
    final box = _boundsKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    // Avoid expensive rendering and time catch-up outside the visible window.
    final visible = (origin & box.size).overlaps(
      Offset.zero & MediaQuery.sizeOf(context),
    );
    if (!visible) return;
    final target = widget.target;
    if (target != null && target.dx.isFinite && target.dy.isFinite) {
      _sim.pointer = Offset(
        target.dx.clamp(-1, 1) * 260,
        target.dy.clamp(-1, 1) * 260,
      );
    } else if (widget.interactive && widget.trackPointer && _pointer != null) {
      final frame = engine.frameFor(
        geometry.getShape(widget.shape),
        widget.antenna,
        _size,
      );
      final p = _pointer! - origin - Offset(_size / 2, frame.cy - frame.padTop);
      _sim.pointer = p.distance < 700 ? p : null;
    } else {
      _sim.pointer = null;
    }
    if (widget.audioSource != null || widget.audio != null) {
      final sample = widget.audioSource != null
          ? widget.audioSource!()
          : widget.audio;
      final next = _unit(sample?.level ?? 0);
      _level +=
          (next - _level) * (1 - math.exp(-dt / (next > _level ? .035 : .09)));
      _sim.face.audioLevel = _level;
      _bands.clear();
      for (final value in (sample?.bands ?? const <double>[]).take(32)) {
        _bands.add(_unit(value));
      }
      _sim.face.audioBands = _bands;
    } else {
      _sim.face.audioLevel = null;
      _sim.face.audioBands = null;
    }
    _sim.setState(widget.state);
    _sim.update(dt * (widget.speed.isFinite ? widget.speed.clamp(0, 4) : 1));
    if (_reactionEnd != null && _sim.time >= _reactionEnd!) {
      _reactionEnd = null;
      widget.onReactionEnd?.call();
    }
    _repaint.paint();
  }

  bool _react() {
    if (!_running) return false;
    _sim.poke();
    final first = _reactionEnd == null;
    _reactionEnd = _sim.time + 1.6;
    if (first) widget.onReactionStart?.call();
    return true;
  }

  void _reset() {
    _sim = RobotSim(_unit(widget.seed), widget.state);
    _reactionEnd = null;
    _level = 0;
    _last = null;
    _repaint.paint();
  }

  void _activate() {
    if (widget.interactive) _react();
    widget.onActivate?.call();
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_routePointer);
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller?._owner == this) widget.controller?._owner = null;
    _ticker.dispose();
    _renderer.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    return Semantics(
      label: widget.semanticsLabel,
      button: _actionable,
      image: !_actionable,
      onTap: _actionable ? _activate : null,
      child: FocusableActionDetector(
        enabled: _actionable,
        mouseCursor: _actionable ? SystemMouseCursors.click : MouseCursor.defer,
        onShowFocusHighlight: (value) => setState(() => _focus = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTap: _actionable ? _activate : null,
          child: SizedBox(
            key: _boundsKey,
            width: _size,
            height: _size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(tokens.radiusControl),
                border: _focus
                    ? Border.all(color: tokens.colorBorderFocus)
                    : null,
              ),
              child: RepaintBoundary(
                child: CustomPaint(painter: _RobotPainter(this, _repaint)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RobotPainter extends CustomPainter {
  _RobotPainter(this.owner, Listenable repaint) : super(repaint: repaint);
  final _KRobotHeadState owner;
  @override
  void paint(Canvas canvas, Size size) {
    final w = owner.widget;
    final shape = geometry.getShape(w.shape);
    final frame = engine.frameFor(shape, w.antenna, owner._size);
    final still = owner._reduced || owner._sim.age == 0;
    // RobotRenderer owns the isolated glow layer. A second offscreen surface
    // here duplicates its GPU compositing work without changing the image.
    canvas.save();
    canvas.translate(-frame.padSide, -frame.padTop);
    owner._renderer.draw(
      canvas,
      frame,
      MediaQuery.devicePixelRatioOf(owner.context).clamp(1, 2),
      still ? restPose(w.state) : owner._sim.pose,
      still ? null : owner._sim,
      w.state,
      shape,
      owner._palette,
      engine.RenderOptions(antenna: w.antenna, floorShadow: w.floorShadow),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RobotPainter oldDelegate) => true;
}
