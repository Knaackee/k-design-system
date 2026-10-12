import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class BrowserPermissionsFixture extends StatefulWidget {
  const BrowserPermissionsFixture({
    this.empty = false,
    this.mobile = false,
    super.key,
  });
  final bool empty, mobile;
  @override
  State<BrowserPermissionsFixture> createState() =>
      _BrowserPermissionsFixtureState();
}

class _BrowserPermissionsFixtureState extends State<BrowserPermissionsFixture> {
  final decisions = <String, KBrowserRuleDecision>{};
  final revoked = <String>{};
  String outcome = '';
  static const labels = {
    'agent': 'Persönlicher Agent',
    'rules': 'Browserberechtigungen',
    'rulesDescription':
        'Du bestimmst, was Nova auf einer Website ausführen darf.',
    'searchNote':
        'Häufige Suchen sind bereits erlaubt. Suchergebnisse erlauben keine weiteren Websiteaktionen.',
    'baseline': 'Mitgelieferte Suchregel',
    'custom': 'Deine Regel',
    'active': 'Aktiv',
    'revoked': 'Widerrufen',
    'allowed': 'Erlaubt',
    'blocked': 'Blockiert',
    'ask': 'Immer fragen',
    'block': 'Blockieren',
    'ruleDecision': 'Berechtigung',
    'revoke': 'Widerrufen',
    'reset': 'Basisregel wiederherstellen',
    'empty': 'Noch keine Browserberechtigungen',
    'emptyDescription':
        'Braucht dein Agent eine Websiteaktion, entscheidest du. Gespeicherte Regeln erscheinen hier.',
    'details': 'Details zur Aktion',
  };
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final data = [
      (
        'google-search',
        'www.google.com',
        '/search',
        'Google-Suche ausführen',
        'G',
        'Nur die Suchaktion. Keine Anmeldung, Nachrichten oder anderen Formulare.',
      ),
      (
        'amazon-search',
        'www.amazon.de',
        '/s',
        'Amazon-Produkte suchen',
        'a',
        'Nur Produktsuche auf diesem Host. Warenkorb und Bestellung sind nicht freigegeben.',
      ),
      (
        'hotel-filter',
        'stay.example',
        '/hotels/search',
        'Hotelsuche mit Reisedaten',
        's',
        '',
      ),
      (
        'newsletter',
        'shop.example',
        '/newsletter',
        'Newsletter abonnieren',
        '',
        '',
      ),
    ];
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (widget.mobile ? 352 : 672) + t.spaceLayoutGutter * 2,
          ),
          child: Padding(
            padding: EdgeInsets.all(t.spaceLayoutGutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: KText('Nova', variant: KTextVariant.caption),
                    ),
                    KText(
                      'Einstellungen / Browser',
                      variant: KTextVariant.caption,
                      style: TextStyle(color: t.colorTextMuted),
                    ),
                  ],
                ),
                SizedBox(height: t.spaceControlGap * 2),
                KBrowserPermissionList(
                  agent: 'Nova',
                  labels: labels,
                  rules: widget.empty
                      ? []
                      : [
                          for (var i = 0; i < data.length; i++)
                            KBrowserPermissionRule(
                              id: data[i].$1,
                              host: data[i].$2,
                              origin: 'https://${data[i].$2}',
                              path: data[i].$3,
                              action: data[i].$4,
                              source: i < 2
                                  ? KBrowserRuleSource.baseline
                                  : KBrowserRuleSource.custom,
                              decision:
                                  decisions[data[i].$1] ??
                                  (i < 2
                                      ? KBrowserRuleDecision.allow
                                      : i == 2
                                      ? KBrowserRuleDecision.ask
                                      : KBrowserRuleDecision.block),
                              status: revoked.contains(data[i].$1)
                                  ? KBrowserRuleStatus.revoked
                                  : KBrowserRuleStatus.active,
                              favicon: data[i].$5.isEmpty
                                  ? null
                                  : Text(
                                      data[i].$5,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                              details: data[i].$6.isEmpty
                                  ? null
                                  : KText(data[i].$6),
                            ),
                        ],
                  onDecisionChange: (id, decision) => setState(() {
                    decisions[id] = decision;
                    outcome =
                        'Berechtigung geändert. Gilt nur für diese Regel.';
                  }),
                  onRevoke: (id) => setState(() {
                    revoked.add(id);
                    outcome = 'Freigabe widerrufen.';
                  }),
                  onReset: (id) => setState(() {
                    decisions[id] = KBrowserRuleDecision.allow;
                    revoked.remove(id);
                    outcome = 'Mitgelieferte Suchregel wiederhergestellt.';
                  }),
                ),
                SizedBox(height: t.spaceControlGap * 2),
                Semantics(
                  liveRegion: true,
                  child: KText(
                    outcome.isEmpty
                        ? 'Designvorschau · Aktionen ändern nur diese lokale Story.'
                        : outcome,
                    variant: KTextVariant.caption,
                    style: TextStyle(color: t.colorTextMuted),
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
