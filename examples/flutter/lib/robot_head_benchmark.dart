// Run: flutter run --profile -d <device> -t lib/robot_head_benchmark.dart
// ROBOT_BENCH JSON lines contain steady-state FrameTiming measurements.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'theme/consumer_theme.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: consumerTheme(Brightness.dark),
    builder: consumerAdaptive,
    home: const RobotBenchmark(),
  ),
);

class RobotBenchmark extends StatefulWidget {
  const RobotBenchmark({super.key});

  @override
  State<RobotBenchmark> createState() => _RobotBenchmarkState();
}

class _RobotBenchmarkState extends State<RobotBenchmark> {
  static const _phases = [
    'idle',
    'thinking',
    'speaking',
    'tracking',
    'hexagon',
    'four',
    'paused',
    'reduced',
  ];
  final _clock = Stopwatch()..start();
  final _frames = <FrameTiming>[];
  final _target = ValueNotifier<Offset?>(null);
  final _controller = KRobotHeadController();
  Timer? _phaseTimer, _trackingTimer;
  int _index = -1;
  int _since = 0;
  bool _complete = false;
  String _lastResult = '3 s warm-up + 12 s measurement per scenario';

  String get _phase => _phases[_index.clamp(0, _phases.length - 1)];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_timings);
    WidgetsBinding.instance.addPostFrameCallback((_) => _next());
  }

  void _timings(List<FrameTiming> timings) {
    if (!_complete && _clock.elapsedMilliseconds - _since >= 3000) {
      _frames.addAll(timings);
    }
  }

  double _percentile(List<double> values, double p) {
    if (values.isEmpty) return 0;
    values.sort();
    return values[((values.length - 1) * p).round()];
  }

  void _report() {
    final build = _frames
        .map((f) => f.buildDuration.inMicroseconds / 1000)
        .toList();
    final raster = _frames
        .map((f) => f.rasterDuration.inMicroseconds / 1000)
        .toList();
    final refresh = View.of(context).display.refreshRate;
    final budget = 1000 / refresh;
    final result = <String, Object>{
      'phase': _phase,
      'mode': kProfileMode
          ? 'profile'
          : kReleaseMode
          ? 'release'
          : 'debug',
      'refreshHz': refresh,
      'frames': _frames.length,
      'approxFps': _frames.length / 12,
      'buildP50ms': _percentile(build, .5),
      'buildP95ms': _percentile(build, .95),
      'rasterP50ms': _percentile(raster, .5),
      'rasterP95ms': _percentile(raster, .95),
      'rasterMaxMs': _percentile(raster, 1),
      'overBudget': _frames
          .where(
            (f) =>
                f.buildDuration.inMicroseconds / 1000 > budget ||
                f.rasterDuration.inMicroseconds / 1000 > budget,
          )
          .length,
      'over16ms': _frames
          .where(
            (f) =>
                f.buildDuration.inMicroseconds > 16667 ||
                f.rasterDuration.inMicroseconds > 16667,
          )
          .length,
    };
    // One summary per phase: never log from the per-frame callback.
    debugPrint('ROBOT_BENCH ${jsonEncode(result)}');
    _lastResult =
        '$_phase: ${(_frames.length / 12).toStringAsFixed(1)} fps; '
        'UI p95 ${result['buildP95ms']} ms; raster p95 ${result['rasterP95ms']} ms';
  }

  void _next() {
    if (!mounted) return;
    if (_index >= 0) _report();
    _trackingTimer?.cancel();
    if (_index == _phases.length - 1) {
      setState(() => _complete = true);
      debugPrint('ROBOT_BENCH COMPLETE');
      return;
    }
    setState(() => _index++);
    _target.value = null;
    _frames.clear();
    _since = _clock.elapsedMilliseconds;
    debugPrint('ROBOT_BENCH START $_phase');
    if (_phase == 'tracking') {
      _trackingTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
        final t = (_clock.elapsedMilliseconds - _since) / 1000;
        _target.value = Offset(math.sin(t * 2), math.cos(t * 1.3));
        if (t > 5 && t < 5.04) _controller.react();
      });
    }
    _phaseTimer = Timer(const Duration(seconds: 15), _next);
  }

  KRobotHeadAudioFrame _audio() {
    final t = _clock.elapsedMilliseconds / 1000;
    return KRobotHeadAudioFrame(
      level: (math.sin(t * 4) + 1) / 2,
      bands: List.generate(12, (i) => (math.sin(t * 3 + i) + 1) / 2),
    );
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_timings);
    _phaseTimer?.cancel();
    _trackingTimer?.cancel();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(
          Theme.of(context).extension<KDesignTokens>()!.spaceLayoutGutter,
        ),
        child: Column(
          children: [
            const KText(
              'KRobotHead · device benchmark',
              variant: KTextVariant.heading2,
            ),
            KText(_complete ? 'Complete — ready for touch testing' : _phase),
            Expanded(
              child: Center(
                child: _phase == 'four'
                    ? Wrap(
                        children: List.generate(
                          4,
                          (i) => KRobotHead(
                            size: 140,
                            state: KRobotHeadState.values[i],
                            seed: .42 + i * .1,
                          ),
                        ),
                      )
                    : ValueListenableBuilder<Offset?>(
                        valueListenable: _target,
                        builder: (context, target, _) => KRobotHead(
                          size: 240,
                          controller: _controller,
                          target: target,
                          paused: !_complete && _phase == 'paused',
                          reducedMotion: !_complete && _phase == 'reduced',
                          shape: _phase == 'hexagon'
                              ? KRobotHeadShape.hexagon
                              : KRobotHeadShape.rectangle,
                          state: _phase == 'thinking'
                              ? KRobotHeadState.thinking
                              : _phase == 'speaking'
                              ? KRobotHeadState.speaking
                              : KRobotHeadState.idle,
                          audioSource: _phase == 'speaking' ? _audio : null,
                        ),
                      ),
              ),
            ),
            KText(_lastResult, variant: KTextVariant.bodySmall),
          ],
        ),
      ),
    ),
  );
}
