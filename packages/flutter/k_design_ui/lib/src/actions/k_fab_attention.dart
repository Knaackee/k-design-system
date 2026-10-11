import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../chat/k_chat_bubble.dart';
import 'k_fab.dart' show KFabItem;

/// A request to draw attention to one of a [KFab]'s items.
///
/// Append new notices last. The consumer owns acknowledgement and removes
/// notices when they are no longer relevant.
class KFabAttention {
  const KFabAttention({required this.id, required this.itemId});

  final String id;
  final String itemId;
}

class KFabAttentionBubble extends StatefulWidget {
  const KFabAttentionBubble({
    required this.notices,
    required this.items,
    required this.size,
    required this.active,
    required this.showDuration,
    required this.pauseDuration,
    required this.peekFraction,
    required this.holdDuration,
    this.onSelect,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  final List<KFabAttention> notices;
  final List<KFabItem> items;
  final double size;
  final Clip clipBehavior;
  final bool active;
  final Duration showDuration;
  final Duration pauseDuration;
  final double peekFraction;
  final Duration holdDuration;
  final ValueChanged<KFabAttention>? onSelect;

  @override
  State<KFabAttentionBubble> createState() => _KFabAttentionBubbleState();
}

class _KFabAttentionBubbleState extends State<KFabAttentionBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)
    ..addStatusListener(_handleStatus);
  Animation<double> _height = const AlwaysStoppedAnimation(0);
  Timer? _pauseTimer;
  int _index = 0;
  bool _hovered = false;
  bool _focused = false;
  bool _reducedMotion = false;
  bool _dependenciesReady = false;
  final FocusNode _focusNode = FocusNode();
  late String _queueSignature;

  List<KFabAttention> get _eligible => widget.notices
      .where(
        (notice) => widget.items.any(
          (item) => item.id == notice.itemId && item.onSelected != null,
        ),
      )
      .toList(growable: false);

  Duration get _holdDuration =>
      Duration(microseconds: math.max(0, widget.holdDuration.inMicroseconds));

  Duration get _showDuration {
    final requested = widget.showDuration.inMicroseconds;
    final minimum =
        _holdDuration.inMicroseconds +
        const Duration(milliseconds: 600).inMicroseconds;
    return Duration(microseconds: math.max(requested, minimum));
  }

  Duration get _pauseDuration =>
      Duration(microseconds: math.max(0, widget.pauseDuration.inMicroseconds));

  bool get _held => _hovered || _focused || _reducedMotion;

  @override
  void initState() {
    super.initState();
    _index = math.max(0, _eligible.length - 1);
    _queueSignature = _eligibleQueueKey(widget.notices, widget.items);
    _configureAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (_dependenciesReady && _reducedMotion == reduced) return;
    _dependenciesReady = true;
    _reducedMotion = reduced;
    _syncPlayback(restart: true);
  }

  @override
  void didUpdateWidget(covariant KFabAttentionBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextQueueSignature = _eligibleQueueKey(widget.notices, widget.items);
    final queueChanged = _queueSignature != nextQueueSignature;
    _queueSignature = nextQueueSignature;
    final timingChanged =
        oldWidget.showDuration != widget.showDuration ||
        oldWidget.holdDuration != widget.holdDuration;
    final playbackChanged =
        oldWidget.active != widget.active ||
        oldWidget.pauseDuration != widget.pauseDuration;
    final reactivated = !oldWidget.active && widget.active;
    if (queueChanged || reactivated) {
      if (_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.unfocus();
        });
      }
      _focused = false;
      _hovered = false;
      _index = math.max(0, _eligible.length - 1);
    }
    if (timingChanged) _configureAnimation();
    if (queueChanged || timingChanged || playbackChanged) {
      _syncPlayback(restart: queueChanged || timingChanged || reactivated);
    }
  }

  String _eligibleQueueKey(List<KFabAttention> notices, List<KFabItem> items) =>
      notices
          .where(
            (notice) => items.any(
              (item) => item.id == notice.itemId && item.onSelected != null,
            ),
          )
          .map((notice) => '${notice.id}\u0000${notice.itemId}')
          .join('\u0001');

  void _configureAnimation() {
    final holdUs = _holdDuration.inMicroseconds.toDouble();
    final motionUs = (_showDuration - _holdDuration).inMicroseconds.toDouble();
    double motion(double originalMs) => motionUs * originalMs / 1476;
    _controller.duration = _showDuration;
    final sequence = <TweenSequenceItem<double>>[
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: motion(432),
      ),
      if (holdUs > 0)
        TweenSequenceItem(tween: ConstantTween<double>(1), weight: holdUs),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: motion(360),
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: .36,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: motion(180),
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: .36,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: motion(180),
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: .14,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: motion(108),
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: .14,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: motion(108),
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: .04,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: motion(54),
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: .04,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: motion(54),
      ),
    ];
    _height = TweenSequence<double>(sequence).animate(_controller);
  }

  void _syncPlayback({bool restart = false}) {
    _pauseTimer?.cancel();
    if (!widget.active || _eligible.isEmpty) {
      _controller.stop();
      return;
    }
    if (_held) {
      _controller.stop();
      return;
    }
    if (restart || _controller.isCompleted) {
      _controller.forward(from: 0);
    } else if (!_controller.isAnimating) {
      _controller.forward();
    }
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !widget.active || _held) return;
    _pauseTimer?.cancel();
    _pauseTimer = Timer(_pauseDuration, () {
      if (!mounted || !widget.active || _held || _eligible.isEmpty) return;
      setState(() => _index = (_index + 1) % _eligible.length);
      _controller.forward(from: 0);
    });
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
    _syncPlayback(restart: !value);
  }

  void _setFocused(bool value) {
    if (_focused == value) return;
    setState(() => _focused = value);
    _syncPlayback(restart: !value);
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eligible = _eligible;
    if (!widget.active || eligible.isEmpty) return const SizedBox.shrink();
    final notice = eligible[_index % eligible.length];
    final item = widget.items.firstWhere((item) => item.id == notice.itemId);
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final dimension = math.max(widget.size, tokens.sizeHitTarget);
    final peek = widget.peekFraction.isFinite
        ? widget.peekFraction.clamp(0.0, 1.0)
        : 0.5;

    return SizedBox(
      width: dimension,
      height: dimension * (1 + peek),
      child: AnimatedBuilder(
        animation: _height,
        builder: (context, child) => Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: 0,
              bottom: dimension * peek * (_held ? 1 : _height.value),
              child: child!,
            ),
          ],
        ),
        child: MouseRegion(
          onEnter: (_) => _setHovered(true),
          onExit: (_) => _setHovered(false),
          child: Focus(
            focusNode: _focusNode,
            onFocusChange: _setFocused,
            child: KChatBubble(
              key: ValueKey('k-fab-attention-${notice.id}'),
              label: item.label,
              size: widget.size,
              clipBehavior: widget.clipBehavior,
              onPressed: () {
                widget.onSelect?.call(notice);
                item.onSelected!();
              },
              child: item.child,
            ),
          ),
        ),
      ),
    );
  }
}
