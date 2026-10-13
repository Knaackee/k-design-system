import 'package:card_stack_widget/card_stack_widget.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Upstream evaluation fixture: deliberately no gesture or animation overrides.
class ScreenSwitcherReferenceFixture extends StatefulWidget {
  const ScreenSwitcherReferenceFixture({super.key});
  @override
  State<ScreenSwitcherReferenceFixture> createState() => _ReferenceState();
}

class _ReferenceState extends State<ScreenSwitcherReferenceFixture> {
  int generation = 0;
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return ColoredBox(
      color: tokens.colorSurfaceCanvas,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLayoutGutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const KText('ScreenSwitcher · Bibliotheksreferenz'),
            SizedBox(height: tokens.spaceControlGap),
            const KText(
              '15 Karten · Originalgesten und Animationen. Wische nach oben oder unten, um die Karten durchzuwechseln.',
            ),
            SizedBox(height: tokens.spaceControlGap),
            KButton(
              label: 'Stapel zurücksetzen',
              onPressed: () => setState(() => generation++),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth.clamp(0.0, 480.0);
                  final height = (constraints.maxHeight * .6).clamp(0.0, 340.0);
                  return CardStackWidget(
                    key: ValueKey(generation),
                    // Upstream scales by count * index: defaults become negative
                    // for 15 cards. Bound the back card to 72% of the front.
                    scaleFactor: 28 / (15 * 14),
                    // Upstream applies its initial offset twice. Keep the
                    // complete stack within the available gallery height.
                    positionFactor: 0.25,
                    cardList: List.generate(
                      15,
                      (index) => CardModel(
                        key: ValueKey('screen-$index'),
                        backgroundColor: tokens.colorSurfaceRaised,
                        shadowColor: tokens.colorScrimModal,
                        radius: Radius.circular(tokens.radiusOverlay),
                        border: Border.all(color: tokens.colorBorderDefault),
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: Padding(
                            padding: EdgeInsets.all(tokens.spaceLayoutGutter),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                KText('Screen ${index + 1}'),
                                SizedBox(height: tokens.spaceLayoutGutter),
                                const KIcon(KIconName.fileText),
                                SizedBox(height: tokens.spaceLayoutGutter),
                                const Flexible(
                                  child: KText(
                                    'Projektideen und nächste Schritte. Ziehe diese Karte, um das unveränderte Verhalten der Bibliothek zu prüfen.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
