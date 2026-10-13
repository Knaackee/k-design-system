import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:coverflow_carousel/coverflow_carousel.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Prototype contract: the consumer owns content and navigation.
class ScreenSwitcherItem {
  const ScreenSwitcherItem({
    required this.id,
    required this.title,
    required this.preview,
  });
  final String id;
  final String title;
  final Widget preview;
}

class ScreenSwitcherPrototypeDemo extends StatefulWidget {
  const ScreenSwitcherPrototypeDemo({super.key});
  @override
  State<ScreenSwitcherPrototypeDemo> createState() => _DemoState();
}

class _DemoState extends State<ScreenSwitcherPrototypeDemo> {
  String? lastSelection;
  final switcher = GlobalKey<_PrototypeState>();
  @override
  Widget build(BuildContext context) => ScreenSwitcherPrototype(
    key: switcher,
    initiallyExpanded: true,
    onOpenRequested: (id) => setState(() => lastSelection = id),
    items: List.generate(
      8,
      (i) => ScreenSwitcherItem(
        id: 'screen-${i + 1}',
        title: 'Entwurf ${i + 1}',
        preview: _DemoScreen(
          index: i,
          onShowStack: () => switcher.currentState?.showStack(),
        ),
      ),
    ),
    onScreenSelected: (id) => setState(() => lastSelection = id),
    status: lastSelection == null
        ? 'Nach oben oder unten wischen'
        : 'Auswahl-Event: $lastSelection',
  );
}

class ScreenSwitcherPrototype extends StatefulWidget {
  const ScreenSwitcherPrototype({
    required this.items,
    required this.onScreenSelected,
    this.onOpenRequested,
    this.initiallyExpanded = false,
    this.maximizeOnOpen = true,
    this.status = '',
    super.key,
  });
  final List<ScreenSwitcherItem> items;
  final ValueChanged<String> onScreenSelected;
  final ValueChanged<String>? onOpenRequested;
  final bool initiallyExpanded;
  final bool maximizeOnOpen;
  final String status;

  @override
  State<ScreenSwitcherPrototype> createState() => _PrototypeState();
}

class _PrototypeState extends State<ScreenSwitcherPrototype>
    with SingleTickerProviderStateMixin {
  late final AnimationController expansion;
  final surfaceKey = GlobalKey();
  Rect? sourceRect;
  double fittedScale = 1;
  bool busy = false;
  String? pendingId;

  @override
  void initState() {
    super.initState();
    expansion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: widget.initiallyExpanded ? 1 : 0,
    );
    carousel.pageListenable.addListener(checkSelection);
  }

  void checkSelection() {
    final id = pendingId;
    if (id == null) return;
    final index = widget.items.indexWhere((item) => item.id == id);
    final target = (-index) % widget.items.length;
    if ((carousel.page - target).abs() < .0001) {
      pendingId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) finishSelection(id);
      });
    }
  }

  Rect cardRect(int index) {
    final box =
        cardKeys[widget.items[index].id]?.currentContext?.findRenderObject()
            as RenderBox?;
    final surface = surfaceKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || surface == null) {
      return const Rect.fromLTWH(8, 210, 374, 1000);
    }
    final top = surface.globalToLocal(box.localToGlobal(Offset.zero));
    return Rect.fromLTWH(0, top.dy, box.size.width, box.size.height);
  }

  Future<void> showStack() async {
    if (busy || expansion.value == 0) return;
    sourceRect = cardRect(selected);
    busy = true;
    await expansion.reverse();
    if (mounted) setState(() => busy = false);
  }

  Future<void> finishSelection(String id) async {
    if (!mounted) return;
    final index = widget.items.indexWhere((item) => item.id == id);
    if (index < 0) {
      setState(() => busy = false);
      return;
    }
    selected = index;
    sourceRect = cardRect(index);
    widget.onOpenRequested?.call(id);
    if (widget.maximizeOnOpen) await expansion.forward();
    if (mounted) setState(() => busy = false);
  }

  final carousel = CoverflowCarouselController();
  int selected = 0;
  final cardKeys = <String, GlobalKey>{};
  final previewKeys = <String, GlobalKey>{};
  Widget preview(int index) => KeyedSubtree(
    key: previewKeys.putIfAbsent(widget.items[index].id, GlobalKey.new),
    child: widget.items[index].preview,
  );
  Offset? tapStart;
  String? tappedId;
  int? tapPointer;

  void startTap(PointerDownEvent event) {
    if (busy || expansion.value > 0) return;
    if (tapPointer != null) {
      tappedId = null;
      return;
    }
    tapPointer = event.pointer;
    tapStart = event.position;
    tappedId = null;
    final pages = List.generate(widget.items.length, (i) => i);
    double depth(int i) =>
        (((-i - carousel.page + widget.items.length / 2) %
                    widget.items.length) -
                widget.items.length / 2)
            .abs();
    pages.sort((a, b) => depth(a).compareTo(depth(b)));
    for (final i in pages) {
      final item = widget.items[i];
      final box = cardKeys[item.id]?.currentContext?.findRenderObject();
      if (box is RenderBox &&
          box.hasSize &&
          (Offset.zero & box.size).contains(
            box.globalToLocal(event.position),
          )) {
        tappedId = item.id;
        break;
      }
    }
  }

  void endTap(PointerUpEvent event) {
    if (event.pointer != tapPointer) return;
    final id = tappedId;
    tapPointer = null;
    tapStart = null;
    tappedId = null;
    if (id != null && !busy) {
      setState(() => busy = true);
      pendingId = id;
      carousel.animateTo(
        (-widget.items.indexWhere((item) => item.id == id)) %
            widget.items.length,
      );
      checkSelection();
    }
  }

  @override
  void dispose() {
    carousel.pageListenable.removeListener(checkSelection);
    expansion.dispose();
    carousel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      child: LayoutBuilder(
        builder: (context, size) {
          final peeks = math.min(
            widget.items.length - 1,
            size.maxHeight < 500 ? 2 : 3,
          );
          final stepHeight = math.min(32.0, size.maxHeight * .06);
          final cardTop = 54 + peeks * stepHeight;
          const angle = -12 * math.pi / 180;
          final available = math.max(1.0, size.maxHeight - cardTop - 16);
          fittedScale = math.max(
            .05,
            math.min(
              (size.maxWidth - 32) / size.maxWidth,
              available /
                  math.max(
                    1,
                    size.maxHeight *
                        (math.cos(angle) + available * math.sin(angle) / 1000),
                  ),
            ),
          );
          return AnimatedBuilder(
            animation: expansion,
            builder: (context, _) {
              final progress = Curves.easeInOutCubic.transform(expansion.value);
              return Material(
                color: t.colorSurfaceCanvas,
                child: Stack(
                  key: surfaceKey,
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: busy || progress > 0,
                        child: Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: startTap,
                          onPointerMove: (event) {
                            if (event.pointer == tapPointer &&
                                tapStart != null &&
                                (event.position - tapStart!).distance > 8) {
                              tappedId = null;
                            }
                          },
                          onPointerUp: endTap,
                          onPointerCancel: (_) {
                            tapPointer = null;
                            tappedId = null;
                            tapStart = null;
                          },
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              // Keep the package's drag physics and cyclic page controller.
                              Opacity(
                                opacity: 0,
                                child: CoverflowCarousel.builder(
                                  controller: carousel,
                                  initialPage:
                                      (-selected) % widget.items.length,
                                  isInfinite: true,
                                  itemCount: widget.items.length,
                                  scrollDirection: Axis.vertical,
                                  width: size.maxWidth,
                                  height: size.maxHeight,
                                  itemWidth: size.maxWidth,
                                  itemHeight: size.maxHeight,
                                  viewportFraction: 160 / size.maxHeight,
                                  visibleItems: 0,
                                  enableShadow: false,
                                  enableHoverTilt: false,
                                  onPageChanged: (index) {
                                    setState(
                                      () => selected =
                                          (-index) % widget.items.length,
                                    );
                                    widget.onScreenSelected(
                                      widget.items[selected].id,
                                    );
                                  },
                                  itemBuilder: (_, _) =>
                                      const SizedBox.expand(),
                                ),
                              ),
                              IgnorePointer(
                                child: ValueListenableBuilder<double>(
                                  valueListenable: carousel.pageListenable,
                                  builder: (context, page, _) {
                                    double offset(int i) =>
                                        (i + page + widget.items.length * 1.5) %
                                            widget.items.length -
                                        widget.items.length / 2;
                                    final order =
                                        List.generate(
                                          widget.items.length,
                                          (i) => i,
                                        )..sort(
                                          (a, b) => offset(
                                            b,
                                          ).abs().compareTo(offset(a).abs()),
                                        );
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        for (final i in order)
                                          if (offset(i) >= -.01 &&
                                              offset(i) <= peeks + .5)
                                            Positioned(
                                              left: 0,
                                              top:
                                                  cardTop -
                                                  math.max(0, offset(i)) *
                                                      stepHeight,
                                              width: size.maxWidth,
                                              height: size.maxHeight,
                                              child: Transform(
                                                alignment: Alignment.topCenter,
                                                transform: Matrix4.identity()
                                                  ..setEntry(3, 2, -1 / 1000)
                                                  ..rotateX(angle)
                                                  ..multiply(
                                                    Matrix4.diagonal3Values(
                                                      math.max(
                                                        .05,
                                                        fittedScale -
                                                            offset(i).abs() *
                                                                32 /
                                                                size.maxWidth,
                                                      ),
                                                      math.max(
                                                        .05,
                                                        fittedScale -
                                                            offset(i).abs() *
                                                                32 /
                                                                size.maxWidth,
                                                      ),
                                                      1,
                                                    ),
                                                  ),
                                                child: Material(
                                                  key: cardKeys.putIfAbsent(
                                                    widget.items[i].id,
                                                    GlobalKey.new,
                                                  ),
                                                  elevation: 8,
                                                  color: t.colorSurfaceRaised,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        t.radiusOverlay,
                                                      ),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      Padding(
                                                        padding: EdgeInsets.all(
                                                          t.spaceLayoutGutter,
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .stretch,
                                                          children: [
                                                            KText(
                                                              widget
                                                                  .items[i]
                                                                  .title,
                                                            ),
                                                            const Divider(),
                                                            Expanded(
                                                              child:
                                                                  progress >
                                                                          0 &&
                                                                      i ==
                                                                          selected
                                                                  ? const SizedBox()
                                                                  : preview(i),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      ColoredBox(
                                                        color: t
                                                            .colorTextPrimary
                                                            .withValues(
                                                              alpha:
                                                                  (offset(
                                                                            i,
                                                                          ).abs() *
                                                                          .08)
                                                                      .clamp(
                                                                        0,
                                                                        .4,
                                                                      ),
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: t.spaceLayoutGutter,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: KText(
                                    'Entw\u00fcrfe · ${selected + 1} / ${widget.items.length}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (progress > 0 && widget.items.isNotEmpty)
                      Positioned.fill(
                        child: ClipRect(
                          child: LayoutBuilder(
                            builder: (context, bounds) {
                              final start =
                                  sourceRect ?? (Offset.zero & bounds.biggest);
                              final rect = Rect.lerp(
                                start,
                                Offset.zero & bounds.biggest,
                                progress,
                              )!;
                              return Stack(
                                children: [
                                  Positioned.fromRect(
                                    rect: rect,
                                    child: Transform(
                                      alignment: Alignment.topCenter,
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, -(1 - progress) / 1000)
                                        ..rotateX(
                                          -12 *
                                              3.141592653589793 /
                                              180 *
                                              (1 - progress),
                                        )
                                        ..multiply(
                                          Matrix4.diagonal3Values(
                                            lerpDouble(
                                              fittedScale,
                                              1,
                                              progress,
                                            )!,
                                            lerpDouble(
                                              fittedScale,
                                              1,
                                              progress,
                                            )!,
                                            1,
                                          ),
                                        ),
                                      child: Material(
                                        color: t.colorSurfaceRaised,
                                        clipBehavior: Clip.antiAlias,
                                        borderRadius: BorderRadius.circular(
                                          lerpDouble(
                                            t.radiusOverlay,
                                            0,
                                            progress,
                                          )!,
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(
                                            t.spaceLayoutGutter,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              KText(
                                                widget.items[selected].title,
                                              ),
                                              const Divider(),
                                              Expanded(
                                                child: preview(selected),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DemoScreen extends StatelessWidget {
  const _DemoScreen({required this.index, required this.onShowStack});
  final int index;
  final VoidCallback onShowStack;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        KButton(label: 'Geöffnete Screens', onPressed: onShowStack),
        SizedBox(height: t.spaceLayoutGutter),
        AspectRatio(
          aspectRatio: 1.8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.colorActionPrimaryBackground,
              borderRadius: BorderRadius.circular(t.radiusOverlay),
            ),
            child: Center(
              child: Icon(
                Icons.landscape_outlined,
                size: 72,
                color: t.colorActionPrimaryForeground,
              ),
            ),
          ),
        ),
        SizedBox(height: t.spaceLayoutGutter),
        KText('Projekt ${index + 1} · Übersicht'),
        const KText(
          'Dieser vollständige Test-Screen wird als Karte im Stapel dargestellt. Der Inhalt kommt von außen.',
        ),
        for (var row = 0; row < 5; row++) ...[
          SizedBox(height: t.spaceLayoutGutter),
          KText('${row + 1}. Arbeitspaket · Projekt ${index + 1}'),
          const KText('Konzept, Gestaltung und Umsetzung im Team abstimmen.'),
          const Divider(),
        ],
      ],
    );
  }
}
