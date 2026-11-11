import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

void main() {
  test('all shared chat values resolve across densities and styles', () {
    for (final density in KDensity.values) {
      for (final style in KStyle.values) {
        final t = kDesignTokens(
          configuration: KDesignConfiguration(
            density: density,
            style: style,
            windowClass: KWindowClass.large,
            typeScale: KTypeScale.standard,
            inputMode: KInputMode.pointer,
          ),
        );
        expect(
          t.componentChatColumnMaxWidth,
          [720, 720, 720][density.index],
          reason: '$density $style ColumnMaxWidth',
        );
        expect(
          t.componentChatColumnGutter,
          [16, 24, 32][density.index],
          reason: '$density $style ColumnGutter',
        );
        expect(
          t.componentChatTurnGap,
          [16, 24, 32][density.index],
          reason: '$density $style TurnGap',
        );
        expect(
          t.componentChatBlockGap,
          [8, 12, 16][density.index],
          reason: '$density $style BlockGap',
        );
        expect(
          t.componentChatMetaGap,
          [4, 8, 12][density.index],
          reason: '$density $style MetaGap',
        );
        expect(
          t.componentChatBubblePaddingInline,
          [8, 12, 16][density.index],
          reason: '$density $style BubblePaddingInline',
        );
        expect(
          t.componentChatBubblePaddingBlock,
          [6, 10, 12][density.index],
          reason: '$density $style BubblePaddingBlock',
        );
        expect(
          t.componentChatBubbleMaxWidth,
          [0.8, 0.75, 0.7][density.index],
          reason: '$density $style BubbleMaxWidth',
        );
        expect(
          t.componentChatDisclosureMinHeight,
          [24, 28, 32][density.index],
          reason: '$density $style DisclosureMinHeight',
        );
        expect(
          t.componentChatCardPadding,
          [12, 16, 24][density.index],
          reason: '$density $style CardPadding',
        );
        expect(
          t.componentChatCardHeaderHeight,
          [32, 36, 44][density.index],
          reason: '$density $style CardHeaderHeight',
        );
        expect(
          t.componentChatCardActionGap,
          [8, 16, 24][density.index],
          reason: '$density $style CardActionGap',
        );
        expect(
          t.componentChatOptionMinHeight,
          [32, 36, 44][density.index],
          reason: '$density $style OptionMinHeight',
        );
        expect(
          t.componentChatOptionGap,
          [4, 8, 8][density.index],
          reason: '$density $style OptionGap',
        );
        expect(
          t.componentChatOptionPaddingInline,
          [8, 12, 16][density.index],
          reason: '$density $style OptionPaddingInline',
        );
        expect(
          t.componentChatAttachmentHeight,
          [32, 36, 44][density.index],
          reason: '$density $style AttachmentHeight',
        );
        expect(
          t.componentChatCodeHeaderHeight,
          [28, 32, 36][density.index],
          reason: '$density $style CodeHeaderHeight',
        );
        expect(
          t.componentChatCodePadding,
          [8, 12, 16][density.index],
          reason: '$density $style CodePadding',
        );
        expect(
          t.componentChatComposerPadding,
          [12, 16, 20][density.index],
          reason: '$density $style ComposerPadding',
        );
        expect(
          t.componentChatComposerOverhang,
          [12, 24, 32][density.index],
          reason: '$density $style ComposerOverhang',
        );
        expect(
          t.componentChatComposerMinHeight,
          [88, 112, 136][density.index],
          reason: '$density $style ComposerMinHeight',
        );
        expect(
          t.componentChatComposerBottomGap,
          [12, 16, 24][density.index],
          reason: '$density $style ComposerBottomGap',
        );
        expect(
          t.componentChatComposerRadius,
          [18, 18, 18][density.index],
          reason: '$density $style ComposerRadius',
        );
        expect(
          t.componentChatPanelWidth,
          [360, 400, 440][density.index],
          reason: '$density $style PanelWidth',
        );
        expect(
          t.componentChatPanelRowHeight,
          [32, 36, 44][density.index],
          reason: '$density $style PanelRowHeight',
        );
        expect(
          t.componentChatHomeSectionGap,
          [16, 32, 48][density.index],
          reason: '$density $style HomeSectionGap',
        );
        expect(
          t.componentChatHomeRowHeight,
          [32, 40, 48][density.index],
          reason: '$density $style HomeRowHeight',
        );
        expect(
          t.componentChatIconStroke,
          [1.25, 1.25, 1.25][density.index],
          reason: '$density $style IconStroke',
        );
      }
    }
  });
}
