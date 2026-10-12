import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

enum BrowserPermissionAskState { request, onceOnly, manual, submitted }

class BrowserPermissionAskFixture extends StatefulWidget {
  const BrowserPermissionAskFixture({
    this.state = BrowserPermissionAskState.request,
    super.key,
  });
  final BrowserPermissionAskState state;
  @override
  State<BrowserPermissionAskFixture> createState() =>
      _BrowserPermissionAskFixtureState();
}

class _BrowserPermissionAskFixtureState
    extends State<BrowserPermissionAskFixture> {
  String answer = '', notice = '';
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final manual = widget.state == BrowserPermissionAskState.manual;
    final summary = widget.state == BrowserPermissionAskState.submitted
        ? 'Einmal erlauben'
        : answer;
    final options = manual
        ? const [
            KAgentQuestionOption(
              id: 'takeover',
              label: 'Browser übernehmen',
              description:
                  'Pausiert den Agenten. Du führst die Aktion selbst aus.',
            ),
            KAgentQuestionOption(id: 'block', label: 'Blockieren'),
          ]
        : [
            const KAgentQuestionOption(
              id: 'allow-once',
              label: 'Einmal erlauben',
              description: 'Führt nur diese angefragte Aktion aus.',
            ),
            if (widget.state != BrowserPermissionAskState.onceOnly)
              const KAgentQuestionOption(
                id: 'allow',
                label: 'Erlauben und merken',
                description:
                    'Speichert die Freigabe für diese Adresse und Aktion.',
              ),
            const KAgentQuestionOption(
              id: 'ask',
              label: 'Immer fragen',
              description:
                  'Speichert die Rückfrage. Diese Aktion wartet weiterhin auf deine Entscheidung.',
            ),
            const KAgentQuestionOption(
              id: 'block',
              label: 'Blockieren',
              description: 'Speichert die Sperre für diese Adresse und Aktion.',
            ),
            const KAgentQuestionOption(
              id: 'takeover',
              label: 'Browser übernehmen',
              description:
                  'Pausiert den Agenten. Du führst die Aktion selbst aus.',
            ),
          ];
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 672 + t.spaceLayoutGutter * 2),
          child: Padding(
            padding: EdgeInsets.all(t.spaceLayoutGutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KAgentQuestion(
                  part: KAgentQuestionPart(
                    id: 'browser-permission',
                    title: manual
                        ? 'Bestellung selbst abschließen'
                        : 'Hotelsuche erlauben?',
                    description: manual
                        ? 'shop.example · /checkout · Käufe, Zahlungen und Nachrichten schließt du selbst ab. Dein Agent wartet.'
                        : 'stay.example · /hotels/search · Nur diese Aktion auf diesem Pfad für Nova.',
                    kind: KAgentQuestionKind.singleChoice,
                    state: summary.isEmpty
                        ? KAgentResolutionState.pending
                        : KAgentResolutionState.answered,
                    options: options,
                    submitLabel: 'Entscheidung senden',
                    answerSummary: summary.isEmpty ? null : summary,
                  ),
                  onResponse: (response) => setState(() {
                    if (response.optionIds.firstOrNull == 'ask') {
                      notice =
                          'Diese Aktion wartet weiterhin auf deine Entscheidung.';
                    } else {
                      notice = '';
                      answer = options
                          .firstWhere(
                            (option) => option.id == response.optionIds.first,
                          )
                          .label;
                    }
                  }),
                ),
                if (notice.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: t.spaceControlGap * 2),
                    child: Semantics(
                      liveRegion: true,
                      child: KText(notice, variant: KTextVariant.caption),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
