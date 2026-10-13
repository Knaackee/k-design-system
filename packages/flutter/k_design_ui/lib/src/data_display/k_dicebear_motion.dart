// This implementation is package-internal; public names let focused tests
// exercise the normalized motion model without exporting it from k_design_ui.
// ignore_for_file: library_private_types_in_public_api

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

/// A parsed DiceBear SVG whose CSS animation rules are evaluated by Flutter.
///
/// DiceBear emits CSS animation in otherwise ordinary SVG. `flutter_svg` paints
/// the SVG but intentionally does not run that CSS, so animated elements are
/// split into stable pictures and their transform/opacity is applied natively.
class KDiceBearMotionScene {
  KDiceBearMotionScene._({
    required this.svg,
    required this.viewBox,
    required this.root,
    required this.animations,
  });

  final String svg;
  final Rect viewBox;
  final _SceneNode root;
  final List<KDiceBearAnimation> animations;

  bool get isAnimated => animations.isNotEmpty;

  static KDiceBearMotionScene parse(String svg) {
    final document = XmlDocument.parse(svg);
    final root = document.rootElement;
    if (root.name.local != 'svg') {
      throw const FormatException('DiceBear output must have an SVG root');
    }
    final viewBox = _parseViewBox(root);
    final css = root.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'style')
        .map((element) => element.innerText)
        .join('\n');
    final stylesheet = _Stylesheet.parse(css);
    if (stylesheet.animations.isEmpty) {
      return KDiceBearMotionScene._(
        svg: svg,
        viewBox: viewBox,
        root: _PictureNode(svg),
        animations: const [],
      );
    }

    final definitions = root.childElements
        .where((element) => element.name.local == 'defs')
        .map(_serializeSvgNode)
        .join();
    final compiler = _SceneCompiler(
      svgRoot: root,
      definitions: definitions,
      stylesheet: stylesheet,
    );
    final scene = compiler.compile();
    return KDiceBearMotionScene._(
      svg: svg,
      viewBox: viewBox,
      root: scene,
      animations: compiler.usedAnimations.toList(growable: false),
    );
  }
}

/// One normalized CSS animation. Public for deterministic evaluator tests.
@immutable
class KDiceBearAnimation {
  const KDiceBearAnimation({
    required this.name,
    required this.durationSeconds,
    required this.delaySeconds,
    required this.timing,
    required this.keyframes,
    required this.origin,
  });

  final String name;
  final double durationSeconds;
  final double delaySeconds;
  final _Timing timing;
  final List<KDiceBearKeyframe> keyframes;
  final _TransformOrigin origin;

  KDiceBearAnimationValue evaluate(
    double elapsedSeconds, {
    double baseOpacity = 1,
  }) {
    if (elapsedSeconds < delaySeconds) {
      return KDiceBearAnimationValue(
        transform: _CssTransform.identity,
        opacity: baseOpacity,
      );
    }
    final local = ((elapsedSeconds - delaySeconds) / durationSeconds) % 1;
    final progress = local < 0 ? local + 1 : local;
    final transformFrames = keyframes
        .where((frame) => frame.transform != null)
        .toList(growable: false);
    final opacityFrames = keyframes
        .where((frame) => frame.opacity != null)
        .toList(growable: false);
    return KDiceBearAnimationValue(
      transform: _evaluateTransform(transformFrames, progress, timing),
      opacity: _evaluateOpacity(opacityFrames, progress, timing, baseOpacity),
    );
  }
}

@immutable
class KDiceBearKeyframe {
  const KDiceBearKeyframe({
    required this.offset,
    this.transform,
    this.opacity,
    this.timing,
  });

  final double offset;
  final _CssTransform? transform;
  final double? opacity;
  final _Timing? timing;
}

@immutable
class KDiceBearAnimationValue {
  const KDiceBearAnimationValue({
    required this.transform,
    required this.opacity,
  });

  final _CssTransform transform;
  final double opacity;
}

class KDiceBearMotion extends StatefulWidget {
  const KDiceBearMotion({required this.scene, required this.paused, super.key});

  final KDiceBearMotionScene scene;
  final bool paused;

  @override
  State<KDiceBearMotion> createState() => _KDiceBearMotionState();
}

class _KDiceBearMotionState extends State<KDiceBearMotion>
    with SingleTickerProviderStateMixin {
  static const _clockDuration = Duration(hours: 24);
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: _clockDuration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncClock();
  }

  @override
  void didUpdateWidget(covariant KDiceBearMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.scene, widget.scene)) {
      _clock.stop();
      _clock.value = 0;
    }
    _syncClock();
  }

  void _syncClock() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldRun =
        widget.scene.isAnimated &&
        !widget.paused &&
        !reduceMotion &&
        TickerMode.valuesOf(context).enabled;
    if (shouldRun && !_clock.isAnimating) {
      _clock.repeat();
    } else if (!shouldRun && _clock.isAnimating) {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.scene.isAnimated) {
      return _buildScene(context, widget.scene.root, 0);
    }
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return SvgPicture.string(
        widget.scene.svg,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      );
    }
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, _) => _buildScene(
        context,
        widget.scene.root,
        _clock.value *
            _clockDuration.inMicroseconds /
            Duration.microsecondsPerSecond,
      ),
    );
  }

  Widget _buildScene(BuildContext context, _SceneNode node, double seconds) {
    if (node is _PictureNode) {
      return SvgPicture.string(
        node.svg,
        allowDrawingOutsideViewBox: true,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      );
    }
    if (node is _GroupNode) {
      return Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          for (final child in node.children)
            _buildScene(context, child, seconds),
        ],
      );
    }
    final animated = node as _AnimatedNode;
    final value = animated.animation.evaluate(
      seconds,
      baseOpacity: animated.baseOpacity,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewBox = widget.scene.viewBox;
        final scaleX = constraints.maxWidth / viewBox.width;
        final scaleY = constraints.maxHeight / viewBox.height;
        final local = value.transform.toAffine();
        final aroundOrigin = _aroundOrigin(local, animated.origin);
        final rootMatrix = animated.parentTransform
            .multiply(aroundOrigin)
            .multiply(animated.parentTransform.inverse());
        final matrix = Matrix4.identity()
          ..setEntry(0, 0, rootMatrix.a)
          ..setEntry(0, 1, rootMatrix.c * scaleX / scaleY)
          ..setEntry(1, 0, rootMatrix.b * scaleY / scaleX)
          ..setEntry(1, 1, rootMatrix.d)
          ..setEntry(0, 3, rootMatrix.e * scaleX)
          ..setEntry(1, 3, rootMatrix.f * scaleY);
        return Opacity(
          opacity: value.opacity.clamp(0, 1),
          child: Transform(
            transform: matrix,
            alignment: Alignment.topLeft,
            child: _buildScene(context, animated.child, seconds),
          ),
        );
      },
    );
  }
}

sealed class _SceneNode {
  const _SceneNode();
}

class _PictureNode extends _SceneNode {
  const _PictureNode(this.svg);
  final String svg;
}

class _GroupNode extends _SceneNode {
  const _GroupNode(this.children);
  final List<_SceneNode> children;
}

class _AnimatedNode extends _SceneNode {
  const _AnimatedNode({
    required this.animation,
    required this.origin,
    required this.parentTransform,
    required this.baseOpacity,
    required this.child,
  });

  final KDiceBearAnimation animation;
  final math.Point<double> origin;
  final _Affine parentTransform;
  final double baseOpacity;
  final _SceneNode child;
}

class _SceneCompiler {
  _SceneCompiler({
    required this.svgRoot,
    required this.definitions,
    required this.stylesheet,
  });

  final XmlElement svgRoot;
  final String definitions;
  final _Stylesheet stylesheet;
  final Set<KDiceBearAnimation> usedAnimations = {};
  late final Map<String, XmlElement> _elementsById = {
    for (final element in svgRoot.descendants.whereType<XmlElement>())
      // ignore: use_null_aware_elements
      if (element.getAttribute('id') case final id?) id: element,
  };

  _SceneNode compile() {
    final children = <_SceneNode>[];
    for (final element in svgRoot.childElements) {
      if (element.name.local == 'style' || element.name.local == 'defs') {
        continue;
      }
      children.add(_compileElement(element, const [], _Affine.identity));
    }
    return _GroupNode(children);
  }

  _SceneNode _compileElement(
    XmlElement element,
    List<_Wrapper> ancestors,
    _Affine parentTransform,
  ) {
    if (element.name.local == 'use') {
      if (_animationFor(element) != null) {
        throw UnsupportedError(
          'CSS animation directly on <use> is unsupported',
        );
      }
      final referenced = _referencedElement(element);
      if (referenced == null) {
        throw UnsupportedError('External SVG use references are not supported');
      }
      return _compileElement(referenced, [
        ...ancestors,
        _Wrapper.forUse(element),
      ], parentTransform.multiply(_useTransform(element)));
    }
    final animation = _animationFor(element);
    final descendantsAnimate = element.childElements.any(_containsAnimation);
    final ownTransform = _parseSvgTransform(element.getAttribute('transform'));
    final nextParent = parentTransform.multiply(ownTransform);
    final removesTransform =
        animation != null &&
        animation.keyframes.any((f) => f.transform != null);
    final removesOpacity =
        animation != null && animation.keyframes.any((f) => f.opacity != null);
    final wrapper = _Wrapper(
      element,
      removeTransform: removesTransform,
      removeOpacity: removesOpacity,
      removeClipPath: _isCoreViewportClip(element),
    );

    late final _SceneNode content;
    if (!descendantsAnimate) {
      content = _PictureNode(_layerSvg(ancestors, wrapper));
    } else {
      final nested = <_SceneNode>[];
      for (final child in element.childElements) {
        if (child.name.local == 'style') continue;
        nested.add(
          _compileElement(child, [
            ...ancestors,
            wrapper,
          ], removesTransform ? parentTransform : nextParent),
        );
      }
      content = _GroupNode(nested);
    }

    if (animation == null) return content;
    usedAnimations.add(animation);
    final bounds = _elementBounds(
      element,
      elementsById: _elementsById,
      ignoreOwnTransform: true,
    );
    final origin = animation.origin.resolve(bounds);
    return _AnimatedNode(
      animation: animation,
      origin: origin,
      parentTransform: parentTransform,
      baseOpacity: double.tryParse(element.getAttribute('opacity') ?? '') ?? 1,
      child: content,
    );
  }

  bool _containsAnimation(XmlElement element) {
    if (_animationFor(element) != null) return true;
    if (element.name.local == 'use') {
      final referenced = _referencedElement(element);
      return referenced != null && _containsAnimation(referenced);
    }
    return element.childElements.any(_containsAnimation);
  }

  // KAvatar clips the composed scene after motion. Clipping this viewport inside
  // each cached layer would cut off geometry before it can move into view.
  bool _isCoreViewportClip(XmlElement element) {
    if (!identical(element.parent, svgRoot)) return false;
    final match = RegExp(
      r'^url\(#(clip-[\w-]+)\)$',
    ).firstMatch(element.getAttribute('clip-path') ?? '');
    if (match == null) return false;
    final clip = _elementsById[match.group(1)];
    if (clip == null ||
        clip.name.local != 'clipPath' ||
        clip.childElements.length != 1) {
      return false;
    }
    final rect = clip.childElements.single;
    final box = _parseViewBox(svgRoot);
    return rect.name.local == 'rect' &&
        _number(rect, 'x') == box.left &&
        _number(rect, 'y') == box.top &&
        _number(rect, 'width') == box.width &&
        _number(rect, 'height') == box.height;
  }

  XmlElement? _referencedElement(XmlElement use) {
    String? href;
    for (final attribute in use.attributes) {
      if (attribute.name.local == 'href') href = attribute.value;
    }
    if (href == null || !href.startsWith('#')) return null;
    return _elementsById[href.substring(1)];
  }

  _Affine _useTransform(XmlElement use) => _parseSvgTransform(
    use.getAttribute('transform'),
  ).multiply(_Affine.translation(_number(use, 'x'), _number(use, 'y')));

  KDiceBearAnimation? _animationFor(XmlElement element) {
    final classes = (element.getAttribute('class') ?? '').split(RegExp(r'\s+'));
    for (final className in classes) {
      final animation = stylesheet.animations[className];
      if (animation != null) return animation;
    }
    return null;
  }

  String _layerSvg(List<_Wrapper> ancestors, _Wrapper element) {
    final rootAttributes = svgRoot.attributes
        .map((a) => a.toXmlString())
        .join(' ');
    final buffer = StringBuffer('<svg $rootAttributes>')..write(definitions);
    for (final ancestor in ancestors) {
      buffer.write(ancestor.openTag);
    }
    buffer.write(element.fullElement);
    for (var i = ancestors.length - 1; i >= 0; i--) {
      buffer.write('</${ancestors[i].name}>');
    }
    return (buffer..write('</svg>')).toString();
  }
}

class _Wrapper {
  const _Wrapper(
    this.element, {
    this.removeTransform = false,
    this.removeOpacity = false,
    this.removeClipPath = false,
  }) : _useTransform = null;

  _Wrapper.forUse(this.element)
    : removeTransform = false,
      removeOpacity = false,
      removeClipPath = false,
      _useTransform = _parseSvgTransform(element.getAttribute('transform'))
          .multiply(
            _Affine.translation(_number(element, 'x'), _number(element, 'y')),
          );

  final XmlElement element;
  final bool removeTransform;
  final bool removeOpacity;
  final bool removeClipPath;
  final _Affine? _useTransform;

  String get name => _useTransform != null || element.name.local == 'symbol'
      ? 'g'
      : element.name.qualified;

  Iterable<XmlAttribute> get _attributes =>
      element.attributes.where((attribute) {
        if (_useTransform != null &&
            {'href', 'x', 'y', 'transform'}.contains(attribute.name.local)) {
          return false;
        }
        return !(removeTransform && attribute.name.local == 'transform') &&
            !(removeOpacity && attribute.name.local == 'opacity') &&
            !(removeClipPath && attribute.name.local == 'clip-path');
      });

  String get openTag {
    final attributes = _attributes.map((a) => a.toXmlString()).join(' ');
    final useTransform = _useTransform;
    final transform = useTransform == null
        ? ''
        : ' transform="matrix(${useTransform.a} ${useTransform.b} ${useTransform.c} ${useTransform.d} ${useTransform.e} ${useTransform.f})"';
    return '<$name${attributes.isEmpty ? '' : ' $attributes'}$transform>';
  }

  String get fullElement =>
      '$openTag${element.children.map(_serializeSvgNode).join()}</$name>';
}

String _serializeSvgNode(XmlNode node) {
  if (node is! XmlElement) return node.toXmlString();
  if (node.name.local == 'style') return '';
  final attributes = node.attributes.map((a) => a.toXmlString()).join(' ');
  final open =
      '<${node.name.qualified}${attributes.isEmpty ? '' : ' $attributes'}>';
  return '$open${node.children.map(_serializeSvgNode).join()}</${node.name.qualified}>';
}

class _Stylesheet {
  const _Stylesheet(this.animations);
  final Map<String, KDiceBearAnimation> animations;

  static _Stylesheet parse(String css) {
    if (css.trim().isEmpty) return const _Stylesheet({});
    final keyframeBodies = <String, String>{};
    final ranges = <(int, int)>[];
    final keyframeStart = RegExp(r'@keyframes\s+([\w-]+)\s*\{');
    for (final match in keyframeStart.allMatches(css)) {
      final end = _matchingBrace(css, match.end - 1);
      keyframeBodies[match.group(1)!] = css.substring(match.end, end);
      ranges.add((match.start, end + 1));
    }
    var rulesCss = css;
    for (final range in ranges.reversed) {
      rulesCss = rulesCss.replaceRange(range.$1, range.$2, '');
    }
    final speed =
        double.tryParse(
          RegExp(r'--[\w-]+-t\s*:\s*([\d.]+)').firstMatch(css)?.group(1) ?? '',
        ) ??
        1;
    final keyframes = <String, List<KDiceBearKeyframe>>{
      for (final entry in keyframeBodies.entries)
        entry.key: _parseKeyframes(entry.value),
    };
    final origins = <String, _TransformOrigin>{};
    final pending = <String, _AnimationRule>{};
    final rulePattern = RegExp(r'([^{}]+)\{([^{}]*)\}');
    for (final match in rulePattern.allMatches(rulesCss)) {
      final selectors = match.group(1)!;
      if (!selectors.contains('.')) continue;
      final declarations = _declarations(match.group(2)!);
      final origin = declarations['transform-origin'];
      final shorthand = declarations['animation'];
      for (final selector in selectors.split(',')) {
        final classMatch = RegExp(r'\.([\w-]+)').firstMatch(selector);
        if (classMatch == null) continue;
        final className = classMatch.group(1)!;
        if (origin != null) {
          origins[className] = _TransformOrigin.parse(origin);
        }
        if (shorthand != null) {
          pending[className] = _AnimationRule.parse(shorthand, speed);
        }
      }
    }
    final animations = <String, KDiceBearAnimation>{};
    for (final entry in pending.entries) {
      final frames = keyframes[entry.value.name];
      if (frames == null || frames.isEmpty) {
        throw UnsupportedError(
          'Animation ${entry.value.name} has no keyframes',
        );
      }
      animations[entry.key] = KDiceBearAnimation(
        name: entry.value.name,
        durationSeconds: entry.value.duration,
        delaySeconds: entry.value.delay,
        timing: entry.value.timing,
        keyframes: frames,
        origin: origins[entry.key] ?? _TransformOrigin.center,
      );
    }
    return _Stylesheet(animations);
  }
}

class _AnimationRule {
  const _AnimationRule(this.name, this.duration, this.delay, this.timing);
  final String name;
  final double duration;
  final double delay;
  final _Timing timing;

  static _AnimationRule parse(String value, double speed) {
    final name = RegExp(r'^\s*([\w-]+)').firstMatch(value)?.group(1);
    final times = RegExp(r'(?:\*\s*)?([\d.]+)s').allMatches(value).toList();
    if (name == null || times.isEmpty) {
      throw UnsupportedError('Unsupported CSS animation shorthand: $value');
    }
    final timingMatch = RegExp(
      r'\b(ease-in-out|ease-in|ease-out|linear|step-end)\b',
    ).firstMatch(value);
    return _AnimationRule(
      name,
      double.parse(times.first.group(1)!) * speed,
      times.length > 1 ? double.parse(times.last.group(1)!) * speed : 0,
      _Timing.parse(timingMatch?.group(1) ?? 'linear'),
    );
  }
}

List<KDiceBearKeyframe> _parseKeyframes(String body) {
  final frames = <KDiceBearKeyframe>[];
  for (final match in RegExp(r'([^{}]+)\{([^{}]*)\}').allMatches(body)) {
    final declarations = _declarations(match.group(2)!);
    for (final selector in match.group(1)!.split(',')) {
      final token = selector.trim();
      final transform = declarations['transform'];
      final frameTiming = declarations['animation-timing-function'];
      final offset = switch (token) {
        'from' => 0.0,
        'to' => 1.0,
        _ => double.parse(token.replaceAll('%', '')) / 100,
      };
      frames.add(
        KDiceBearKeyframe(
          offset: offset,
          transform: transform == null ? null : _CssTransform.parse(transform),
          opacity: double.tryParse(declarations['opacity'] ?? ''),
          timing: frameTiming == null ? null : _Timing.parse(frameTiming),
        ),
      );
    }
  }
  frames.sort((a, b) => a.offset.compareTo(b.offset));
  return frames;
}

Map<String, String> _declarations(String value) => {
  for (final declaration in value.split(';'))
    if (declaration.contains(':'))
      declaration.substring(0, declaration.indexOf(':')).trim(): declaration
          .substring(declaration.indexOf(':') + 1)
          .trim(),
};

int _matchingBrace(String value, int opening) {
  var depth = 0;
  for (var index = opening; index < value.length; index++) {
    if (value[index] == '{') depth++;
    if (value[index] == '}' && --depth == 0) return index;
  }
  throw const FormatException('Unbalanced CSS braces');
}

enum _Timing {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  stepEnd;

  static _Timing parse(String value) => switch (value.trim()) {
    'linear' => linear,
    'ease-in' => easeIn,
    'ease-out' => easeOut,
    'ease-in-out' => easeInOut,
    'step-end' => stepEnd,
    _ => throw UnsupportedError('Unsupported animation timing: $value'),
  };

  double transform(double value) => switch (this) {
    linear => value,
    easeIn => Curves.easeIn.transform(value),
    easeOut => Curves.easeOut.transform(value),
    easeInOut => Curves.easeInOut.transform(value),
    stepEnd => value < 1 ? 0 : 1,
  };
}

class _TransformOrigin {
  const _TransformOrigin(this.x, this.y, this.relativeX, this.relativeY);
  static const center = _TransformOrigin(.5, .5, true, true);

  final double x;
  final double y;
  final bool relativeX;
  final bool relativeY;

  static _TransformOrigin parse(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    final normalized = parts.length == 1 ? [parts.first, parts.first] : parts;
    (double, bool) coordinate(String token, bool horizontal) {
      if (token == 'center') return (.5, true);
      if (token == 'left' || token == 'top') return (0, true);
      if (token == 'right' || token == 'bottom') return (1, true);
      if (token.endsWith('%')) {
        return (double.parse(token.substring(0, token.length - 1)) / 100, true);
      }
      if (token.endsWith('px')) {
        return (double.parse(token.substring(0, token.length - 2)), false);
      }
      if (token == '0') return (0, false);
      throw UnsupportedError('Unsupported transform-origin coordinate: $token');
    }

    final x = coordinate(normalized[0], true);
    final y = coordinate(normalized[1], false);
    return _TransformOrigin(x.$1, y.$1, x.$2, y.$2);
  }

  math.Point<double> resolve(Rect bounds) => math.Point(
    relativeX ? bounds.left + bounds.width * x : x,
    relativeY ? bounds.top + bounds.height * y : y,
  );
}

class _CssTransform {
  const _CssTransform(this.operations);
  static const identity = _CssTransform([]);
  final List<_TransformOperation> operations;

  static _CssTransform parse(String value) {
    final operations = <_TransformOperation>[];
    final matches = RegExp(
      r'(translate|translateX|translateY|rotate|scale|scaleX|scaleY)\(([^)]+)\)',
    ).allMatches(value);
    for (final match in matches) {
      final name = match.group(1)!;
      final values = match
          .group(2)!
          .split(RegExp(r'[,\s]+'))
          .where((v) => v.isNotEmpty)
          .map(_cssNumber)
          .toList();
      operations.add(_TransformOperation(name, values));
    }
    if (operations.isEmpty && value.trim() != 'none') {
      throw UnsupportedError('Unsupported SVG animation transform: $value');
    }
    return _CssTransform(operations);
  }

  _Affine toAffine() {
    var result = _Affine.identity;
    for (final operation in operations) {
      result = result.multiply(operation.toAffine());
    }
    return result;
  }

  static _CssTransform interpolate(_CssTransform a, _CssTransform b, double t) {
    if (a.operations.isEmpty && b.operations.isNotEmpty) a = b.identityLike();
    if (b.operations.isEmpty && a.operations.isNotEmpty) b = a.identityLike();
    if (a.operations.length != b.operations.length) {
      throw UnsupportedError('Keyframe transform operation lists do not match');
    }
    return _CssTransform([
      for (var i = 0; i < a.operations.length; i++)
        _TransformOperation.interpolate(a.operations[i], b.operations[i], t),
    ]);
  }

  _CssTransform identityLike() =>
      _CssTransform([for (final operation in operations) operation.identity]);
}

class _TransformOperation {
  const _TransformOperation(this.name, this.values);
  final String name;
  final List<double> values;

  _TransformOperation get identity => _TransformOperation(
    name,
    name.startsWith('scale')
        ? List.filled(values.length, 1)
        : List.filled(values.length, 0),
  );

  static _TransformOperation interpolate(
    _TransformOperation a,
    _TransformOperation b,
    double t,
  ) {
    if (a.name != b.name || a.values.length != b.values.length) {
      throw UnsupportedError('Keyframe transform operations do not match');
    }
    return _TransformOperation(a.name, [
      for (var i = 0; i < a.values.length; i++)
        a.values[i] + (b.values[i] - a.values[i]) * t,
    ]);
  }

  _Affine toAffine() => switch (name) {
    'translate' => _Affine.translation(
      values[0],
      values.length > 1 ? values[1] : 0,
    ),
    'translateX' => _Affine.translation(values[0], 0),
    'translateY' => _Affine.translation(0, values[0]),
    'rotate' => _Affine.rotation(values[0] * math.pi / 180),
    'scale' => _Affine.scale(
      values[0],
      values.length > 1 ? values[1] : values[0],
    ),
    'scaleX' => _Affine.scale(values[0], 1),
    'scaleY' => _Affine.scale(1, values[0]),
    _ => throw UnsupportedError('Unsupported transform operation: $name'),
  };
}

double _cssNumber(String value) =>
    double.parse(value.trim().replaceAll('px', '').replaceAll('deg', ''));

_CssTransform _evaluateTransform(
  List<KDiceBearKeyframe> frames,
  double progress,
  _Timing timing,
) {
  if (frames.isEmpty) return _CssTransform.identity;
  final normalized = [...frames];
  if (normalized.first.offset > 0) {
    normalized.insert(
      0,
      KDiceBearKeyframe(
        offset: 0,
        transform: normalized.first.transform!.identityLike(),
      ),
    );
  }
  if (normalized.last.offset < 1) {
    normalized.add(
      KDiceBearKeyframe(
        offset: 1,
        transform: normalized.last.transform!.identityLike(),
      ),
    );
  }
  final pair = _surrounding(normalized, progress);
  final span = pair.$2.offset - pair.$1.offset;
  final raw = span == 0 ? 0.0 : (progress - pair.$1.offset) / span;
  final eased = (pair.$1.timing ?? timing).transform(raw.clamp(0, 1));
  return _CssTransform.interpolate(
    pair.$1.transform!,
    pair.$2.transform!,
    eased,
  );
}

double _evaluateOpacity(
  List<KDiceBearKeyframe> frames,
  double progress,
  _Timing timing,
  double base,
) {
  if (frames.isEmpty) return base;
  final normalized = [...frames];
  if (normalized.first.offset > 0) {
    normalized.insert(0, KDiceBearKeyframe(offset: 0, opacity: base));
  }
  if (normalized.last.offset < 1) {
    normalized.add(KDiceBearKeyframe(offset: 1, opacity: base));
  }
  final pair = _surrounding(normalized, progress);
  final span = pair.$2.offset - pair.$1.offset;
  final raw = span == 0 ? 0.0 : (progress - pair.$1.offset) / span;
  final eased = (pair.$1.timing ?? timing).transform(raw.clamp(0, 1));
  return pair.$1.opacity! + (pair.$2.opacity! - pair.$1.opacity!) * eased;
}

(KDiceBearKeyframe, KDiceBearKeyframe) _surrounding(
  List<KDiceBearKeyframe> frames,
  double progress,
) {
  for (var i = 1; i < frames.length; i++) {
    if (progress <= frames[i].offset) return (frames[i - 1], frames[i]);
  }
  return (frames.last, frames.last);
}

Rect _parseViewBox(XmlElement root) {
  final parts = (root.getAttribute('viewBox') ?? '')
      .split(RegExp(r'[,\s]+'))
      .where((v) => v.isNotEmpty)
      .map(double.parse)
      .toList();
  if (parts.length != 4 || parts[2] <= 0 || parts[3] <= 0) {
    throw const FormatException('SVG viewBox must contain four finite values');
  }
  return Rect.fromLTWH(parts[0], parts[1], parts[2], parts[3]);
}

Rect _elementBounds(
  XmlElement element, {
  required Map<String, XmlElement> elementsById,
  bool ignoreOwnTransform = false,
}) {
  Rect? result;
  void include(Rect bounds) =>
      result = result == null ? bounds : result!.expandToInclude(bounds);
  final name = element.name.local;
  switch (name) {
    case 'path':
      final data = element.getAttribute('d');
      if (data != null && data.isNotEmpty) {
        include(parseSvgPathData(data).getBounds());
      }
    case 'rect':
      include(
        Rect.fromLTWH(
          _number(element, 'x'),
          _number(element, 'y'),
          _number(element, 'width'),
          _number(element, 'height'),
        ),
      );
    case 'circle':
      final r = _number(element, 'r');
      include(
        Rect.fromCircle(
          center: Offset(_number(element, 'cx'), _number(element, 'cy')),
          radius: r,
        ),
      );
    case 'ellipse':
      final rx = _number(element, 'rx');
      final ry = _number(element, 'ry');
      include(
        Rect.fromCenter(
          center: Offset(_number(element, 'cx'), _number(element, 'cy')),
          width: rx * 2,
          height: ry * 2,
        ),
      );
    case 'line':
      include(
        Rect.fromPoints(
          Offset(_number(element, 'x1'), _number(element, 'y1')),
          Offset(_number(element, 'x2'), _number(element, 'y2')),
        ),
      );
    case 'polygon':
    case 'polyline':
      final values = (element.getAttribute('points') ?? '')
          .split(RegExp(r'[,\s]+'))
          .where((v) => v.isNotEmpty)
          .map(double.parse)
          .toList();
      for (var i = 0; i + 1 < values.length; i += 2) {
        include(Rect.fromLTWH(values[i], values[i + 1], 0, 0));
      }
    case 'use':
      String? href;
      for (final attribute in element.attributes) {
        if (attribute.name.local == 'href') href = attribute.value;
      }
      if (href != null && href.startsWith('#')) {
        final referenced = elementsById[href.substring(1)];
        if (referenced != null) {
          include(
            _transformRect(
              _elementBounds(referenced, elementsById: elementsById),
              _Affine.translation(_number(element, 'x'), _number(element, 'y')),
            ),
          );
        }
      }
  }
  for (final child in element.childElements) {
    if (child.name.local == 'defs' || child.name.local == 'style') continue;
    include(_elementBounds(child, elementsById: elementsById));
  }
  final bounds = result ?? Rect.zero;
  return ignoreOwnTransform
      ? bounds
      : _transformRect(
          bounds,
          _parseSvgTransform(element.getAttribute('transform')),
        );
}

double _number(XmlElement element, String name) =>
    double.tryParse(element.getAttribute(name) ?? '') ?? 0;

_Affine _parseSvgTransform(String? value) {
  if (value == null || value.trim().isEmpty) return _Affine.identity;
  var result = _Affine.identity;
  for (final match in RegExp(
    r'(matrix|translate|scale|rotate)\(([^)]+)\)',
  ).allMatches(value)) {
    final values = match
        .group(2)!
        .split(RegExp(r'[,\s]+'))
        .where((v) => v.isNotEmpty)
        .map(double.parse)
        .toList();
    final operation = switch (match.group(1)) {
      'matrix' when values.length == 6 => _Affine(
        values[0],
        values[1],
        values[2],
        values[3],
        values[4],
        values[5],
      ),
      'translate' => _Affine.translation(
        values[0],
        values.length > 1 ? values[1] : 0,
      ),
      'scale' => _Affine.scale(
        values[0],
        values.length > 1 ? values[1] : values[0],
      ),
      'rotate' when values.length == 1 => _Affine.rotation(
        values[0] * math.pi / 180,
      ),
      'rotate' when values.length == 3 => _aroundOrigin(
        _Affine.rotation(values[0] * math.pi / 180),
        math.Point(values[1], values[2]),
      ),
      _ => throw UnsupportedError('Unsupported SVG transform: $value'),
    };
    result = result.multiply(operation);
  }
  return result;
}

Rect _transformRect(Rect rect, _Affine matrix) {
  final points = [
    matrix.transform(rect.topLeft),
    matrix.transform(rect.topRight),
    matrix.transform(rect.bottomLeft),
    matrix.transform(rect.bottomRight),
  ];
  return Rect.fromLTRB(
    points.map((p) => p.dx).reduce(math.min),
    points.map((p) => p.dy).reduce(math.min),
    points.map((p) => p.dx).reduce(math.max),
    points.map((p) => p.dy).reduce(math.max),
  );
}

_Affine _aroundOrigin(_Affine value, math.Point<double> origin) =>
    _Affine.translation(
      origin.x,
      origin.y,
    ).multiply(value).multiply(_Affine.translation(-origin.x, -origin.y));

class _Affine {
  const _Affine(this.a, this.b, this.c, this.d, this.e, this.f);
  static const identity = _Affine(1, 0, 0, 1, 0, 0);
  final double a, b, c, d, e, f;

  factory _Affine.translation(double x, double y) => _Affine(1, 0, 0, 1, x, y);
  factory _Affine.scale(double x, double y) => _Affine(x, 0, 0, y, 0, 0);
  factory _Affine.rotation(double radians) => _Affine(
    math.cos(radians),
    math.sin(radians),
    -math.sin(radians),
    math.cos(radians),
    0,
    0,
  );

  _Affine multiply(_Affine other) => _Affine(
    a * other.a + c * other.b,
    b * other.a + d * other.b,
    a * other.c + c * other.d,
    b * other.c + d * other.d,
    a * other.e + c * other.f + e,
    b * other.e + d * other.f + f,
  );

  _Affine inverse() {
    final determinant = a * d - b * c;
    if (determinant.abs() < 1e-12) return identity;
    return _Affine(
      d / determinant,
      -b / determinant,
      -c / determinant,
      a / determinant,
      (c * f - d * e) / determinant,
      (b * e - a * f) / determinant,
    );
  }

  Offset transform(Offset point) =>
      Offset(a * point.dx + c * point.dy + e, b * point.dx + d * point.dy + f);
}
