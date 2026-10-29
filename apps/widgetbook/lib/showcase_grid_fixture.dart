import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:widgetbook/widgetbook.dart';

const _previews = [
  ('Studio Flora', 'Zeit für dich.', 'Haare & Styling', 'rose'),
  ('Grünraum', 'Mehr Leben im Garten.', 'Gartenpflege', 'green'),
  ('Balance', 'Ankommen. Durchatmen.', 'Massage & Bewegung', 'blue'),
  ('Pfotenfreund', 'Für deinen Lieblingsgast.', 'Fellpflege', 'amber'),
  ('Lichtblick', 'Dein Zuhause. Dein Stil.', 'Beratung & Einrichtung', 'blue'),
  ('Atelier Mia', 'Schön in deinem Alltag.', 'Kosmetik', 'rose'),
  ('Klar & Gut', 'Raum zum Wohlfühlen.', 'Reinigung', 'green'),
  ('Technik daheim', 'Einfach wieder verbunden.', 'IT-Hilfe', 'amber'),
  ('Gartenzeit', 'Draußen wird es schön.', 'Pflanzen & Pflege', 'green'),
  ('Salon Zuhause', 'Dein Moment. Dein Look.', 'Mobile Haarpflege', 'rose'),
  ('Freiraum', 'Bewegung, die gut tut.', 'Physiotherapie', 'blue'),
  ('Werk & Wert', 'Gut gemacht hält länger.', 'Handwerk', 'amber'),
];

class ShowcaseGridFixture extends StatefulWidget {
  const ShowcaseGridFixture({this.kind = 'hero', super.key});
  final String kind;
  @override
  State<ShowcaseGridFixture> createState() => _ShowcaseGridFixtureState();
}

class _ShowcaseGridFixtureState extends State<ShowcaseGridFixture> {
  bool _paused = false;
  int _revision = 0;
  @override
  Widget build(BuildContext context) {
    if (widget.kind == 'dark' &&
        Theme.of(context).brightness != Brightness.dark) {
      return Theme(
        data: kDesignTheme(brightness: Brightness.dark),
        child: Builder(builder: _gallery),
      );
    }
    return _gallery(context);
  }

  Widget _gallery(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final mobile = widget.kind == 'mobile';
    final hero = widget.kind != 'grid-only';
    final loop = context.knobs.boolean(label: 'loop', initialValue: true);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: mobile ? 390 : double.infinity),
          child: ColoredBox(
            color: tokens.colorSurfaceCanvas,
            child: Column(
              children: [
                SizedBox(
                  height: mobile ? 672 : 640,
                  child: KShowcaseGrid(
                    key: ValueKey(_revision),
                    items: [
                      for (var i = 0; i < _previews.length; i++)
                        KShowcaseGridItem(
                          id: 'preview-$i',
                          content: _PreviewCard(index: i),
                        ),
                    ],
                    loop: loop,
                    animate:
                        context.knobs.boolean(
                          label: 'animate',
                          initialValue: widget.kind != 'reduced-motion',
                        ) &&
                        !_paused,
                    columns: context.knobs.double
                        .slider(
                          label: 'columns',
                          initialValue: 4,
                          min: 1,
                          max: 8,
                          divisions: 7,
                        )
                        .round(),
                    compactColumns: context.knobs.double
                        .slider(
                          label: 'compactColumns',
                          initialValue: 2,
                          min: 1,
                          max: 4,
                          divisions: 3,
                        )
                        .round(),
                    tilt: context.knobs.double.slider(
                      label: 'tilt',
                      initialValue: -8,
                      min: -15,
                      max: 15,
                      divisions: 30,
                    ),
                    gap: context.knobs.double.slider(
                      label: 'gap',
                      initialValue: tokens.spaceLayoutSectionGap,
                      min: 0,
                      max: 64,
                    ),
                    edgeFade: context.knobs.boolean(
                      label: 'edgeFade',
                      initialValue: true,
                    ),
                    durationMs: context.knobs.double
                        .slider(
                          label: 'durationMs',
                          initialValue: 900,
                          min: 0,
                          max: 3000,
                        )
                        .round(),
                    staggerMs: context.knobs.double
                        .slider(
                          label: 'staggerMs',
                          initialValue: 90,
                          min: 0,
                          max: 500,
                        )
                        .round(),
                    loopDurationMs: context.knobs.double
                        .slider(
                          label: 'loopDurationMs',
                          initialValue: 45000,
                          min: 1000,
                          max: 90000,
                        )
                        .round(),
                    child: hero
                        ? ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 608),
                            child: CustomPaint(
                              painter: _QuietPainter(tokens.colorSurfaceCanvas),
                              child: Padding(
                                padding: EdgeInsets.all(
                                  tokens.spaceLayoutSectionGap,
                                ),
                                child: KStack(
                                  gap: KLayoutGap.section,
                                  align: KLayoutAlign.center,
                                  children: [
                                    const KText(
                                      'DEINE SEITE. DEIN STIL.',
                                      variant: KTextVariant.caption,
                                    ),
                                    const KText(
                                      'So vielfältig wie dein Arbeitsalltag.',
                                      variant: KTextVariant.heading1,
                                      textWrap: KTextWrap.balance,
                                      align: TextAlign.center,
                                    ),
                                    const KText(
                                      'Eine Buchungsseite, die zu dir passt. Und mehr Zeit für das, was du liebst.',
                                      textWrap: KTextWrap.balance,
                                      align: TextAlign.center,
                                    ),
                                    KButton(
                                      label: !loop
                                          ? 'Animation erneut ansehen'
                                          : _paused
                                          ? 'Animation fortsetzen'
                                          : 'Animation pausieren',
                                      onPressed: () => setState(() {
                                        if (loop) {
                                          _paused = !_paused;
                                        } else {
                                          _revision++;
                                        }
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                if (!hero)
                  KButton(
                    label: 'Animation erneut ansehen',
                    variant: KButtonVariant.ghost,
                    onPressed: () => setState(() => _revision++),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final (name, headline, service, tone) = _previews[index];
    final accent = switch (tone) {
      'rose' => t.colorStatusErrorAccent,
      'green' => t.colorStatusSuccessAccent,
      'blue' => t.colorStatusInfoAccent,
      _ => t.colorStatusWarningAccent,
    };
    Color mix(double value) => Color.lerp(t.colorSurfaceRaised, accent, value)!;
    return KSurface(
      radius: KSurfaceRadius.card,
      elevation: KSurfaceElevation.low,
      child: Padding(
        padding: EdgeInsets.all(t.spaceCardPadding),
        child: KStack(
          gap: KLayoutGap.control,
          align: KLayoutAlign.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: t.sizeControl,
                  height: t.sizeControl,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: mix(.15),
                  ),
                  child: KText(name[0], style: TextStyle(color: accent)),
                ),
                SizedBox(width: t.spaceControlGap),
                Expanded(child: KText(name, variant: KTextVariant.label)),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(t.radiusControl),
              child: SizedBox(
                height: 144,
                child: CustomPaint(
                  painter: _ArtPainter(accent, t.colorSurfaceRaised),
                ),
              ),
            ),
            KText(
              headline,
              variant: KTextVariant.heading4,
              textWrap: KTextWrap.balance,
            ),
            KText(service, variant: KTextVariant.bodySmall),
            FractionallySizedBox(
              widthFactor: .9,
              alignment: Alignment.centerLeft,
              child: Container(
                height: t.spaceControlGap,
                decoration: BoxDecoration(
                  color: t.colorSurfaceSubtle,
                  borderRadius: BorderRadius.circular(t.radiusControl),
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: .6,
              alignment: Alignment.centerLeft,
              child: Container(
                height: t.spaceControlGap,
                decoration: BoxDecoration(
                  color: t.colorSurfaceSubtle,
                  borderRadius: BorderRadius.circular(t.radiusControl),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(t.spaceControlGap),
              decoration: BoxDecoration(
                color: mix(.12),
                borderRadius: BorderRadius.circular(t.radiusControl),
              ),
              child: KText(
                'Termin auswählen',
                variant: KTextVariant.label,
                align: TextAlign.center,
                style: TextStyle(color: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuietPainter extends CustomPainter {
  const _QuietPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale((size.width + 224) / 2, (size.height + 288) / 2);
    canvas.drawRect(
      const Rect.fromLTWH(-1, -1, 2, 2),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          1,
          [color, color.withValues(alpha: .94), color.withValues(alpha: 0)],
          [.3, .48, .74],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_QuietPainter old) => color != old.color;
}

class _ArtPainter extends CustomPainter {
  const _ArtPainter(this.accent, this.surface);
  final Color accent, surface;
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint(double value) =>
        Paint()..color = Color.lerp(surface, accent, value)!;
    canvas.drawRect(Offset.zero & size, paint(.18));
    canvas.drawCircle(
      Offset(size.width * .68, size.height * .4),
      40,
      paint(.58),
    );
    canvas.save();
    canvas.translate(size.width * .28, size.height * .9);
    canvas.rotate(-.38);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * .65,
          height: size.height * .85,
        ),
        topLeft: const Radius.circular(80),
        topRight: const Radius.circular(80),
      ),
      paint(.78),
    );
    canvas.restore();
    canvas.save();
    canvas.translate(size.width * .7, size.height * .9);
    canvas.rotate(.49);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * .35,
        height: size.height * .75,
      ),
      paint(.36),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArtPainter old) =>
      old.accent != accent || old.surface != surface;
}
