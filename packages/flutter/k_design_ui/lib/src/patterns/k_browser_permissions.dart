import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../basic_display.dart';
import '../forms/k_select.dart';
import '../primitives/k_button.dart';
import '../primitives/k_surface.dart';
import '../primitives/k_disclosure.dart';
import '../primitives/k_text.dart';

class KWebsiteIdentity extends StatelessWidget {
  const KWebsiteIdentity({required this.host, this.favicon, super.key});
  final String host;

  /// Decorative consumer-supplied asset; no network request is made here.
  final Widget? favicon;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: t.sizeControl,
            height: t.sizeControl,
            decoration: BoxDecoration(
              color: t.colorSurfaceRaised,
              border: Border.all(
                color: t.colorBorderDefault,
                width: t.borderWidthDefault,
              ),
              borderRadius: BorderRadius.circular(t.radiusControl),
            ),
            child: Center(
              child: favicon == null
                  ? const Text('↗')
                  : SizedBox(
                      width: t.sizeControl * .6,
                      height: t.sizeControl * .6,
                      child: FittedBox(child: favicon!),
                    ),
            ),
          ),
        ),
        SizedBox(width: t.spaceControlGap),
        Flexible(
          child: KText(host, style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

enum KBrowserRuleDecision { allow, ask, block }

enum KBrowserRuleSource { baseline, custom }

enum KBrowserRuleStatus { active, revoked }

class KBrowserPermissionRule {
  const KBrowserPermissionRule({
    required this.id,
    required this.host,
    required this.origin,
    required this.path,
    required this.action,
    required this.source,
    required this.decision,
    required this.status,
    this.favicon,
    this.websiteWide = false,
    this.details,
  });
  final String id, host, origin, path, action;
  final KBrowserRuleSource source;
  final KBrowserRuleDecision decision;
  final KBrowserRuleStatus status;
  final Widget? favicon, details;
  final bool websiteWide;
}

/// Presentation only. The consumer persists rules and enforces permission policy.
class KBrowserPermissionList extends StatelessWidget {
  const KBrowserPermissionList({
    required this.agent,
    required this.rules,
    required this.onDecisionChange,
    required this.onRevoke,
    required this.onReset,
    this.labels = const {},
    super.key,
  });
  final String agent;
  final List<KBrowserPermissionRule> rules;
  final void Function(String id, KBrowserRuleDecision decision)
  onDecisionChange;
  final ValueChanged<String> onRevoke, onReset;
  final Map<String, String> labels;
  static const defaultLabels = {
    'agent': 'Personal agent',
    'rules': 'Browser permissions',
    'rulesDescription':
        'Manage what your personal agent can do on each website.',
    'searchNote':
        'Common searches are already allowed. Search results do not grant permission for other website actions.',
    'baseline': 'Included search rule',
    'custom': 'Your rule',
    'active': 'Active',
    'revoked': 'Revoked',
    'allowed': 'Allowed',
    'blocked': 'Blocked',
    'ask': 'Always ask',
    'block': 'Block',
    'ruleDecision': 'Permission',
    'revoke': 'Revoke',
    'reset': 'Reset to included rule',
    'empty': 'No browser permissions yet',
    'emptyDescription':
        'When your agent needs a website action, you decide. Saved permissions will appear here.',
    'details': 'Action details',
    'origin': 'Origin',
    'path': 'Path',
    'action': 'Action',
    'websiteScope':
        'Applies to all forms at this exact website address for this personal agent. Other hosts are separate. You can revoke it in permissions.',
    'manualLimit':
        'Purchases, payments and messages still require your manual action.',
  };
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final text = {...defaultLabels, ...labels};
    final gap = t.spaceControlGap;
    Widget muted(String value) =>
        KText(value, style: TextStyle(color: t.colorTextMuted));
    Widget caption(String value) => KText(
      value,
      variant: KTextVariant.caption,
      style: TextStyle(color: t.colorTextMuted),
    );
    Widget notice(String value) => Container(
      padding: EdgeInsets.all(gap * 2),
      decoration: BoxDecoration(
        color: t.colorSurfaceSubtle,
        border: Border.all(
          color: t.colorBorderDefault,
          width: t.borderWidthDefault,
        ),
        borderRadius: BorderRadius.circular(t.radiusControl),
      ),
      child: muted(value),
    );
    return KSurface(
      tone: KSurfaceTone.raised,
      radius: KSurfaceRadius.card,
      child: Padding(
        padding: EdgeInsets.all(gap * 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            caption('${text['agent']} · $agent'),
            SizedBox(height: gap),
            KText(text['rules']!, variant: KTextVariant.heading4),
            SizedBox(height: gap),
            muted(text['rulesDescription']!),
            SizedBox(height: gap * 2),
            notice(text['searchNote']!),
            SizedBox(height: gap * 2),
            if (rules.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: gap * 4),
                child: Column(
                  children: [
                    KText(
                      text['empty']!,
                      align: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: gap),
                    KText(
                      text['emptyDescription']!,
                      align: TextAlign.center,
                      style: TextStyle(color: t.colorTextMuted),
                    ),
                  ],
                ),
              ),
            for (final rule in rules) ...[
              Divider(
                height: t.borderWidthDefault,
                thickness: t.borderWidthDefault,
                color: t.colorBorderDefault,
              ),
              SizedBox(height: gap * 2),
              LayoutBuilder(
                builder: (context, bounds) {
                  final badge = KBadge(
                    variant: rule.status == KBrowserRuleStatus.revoked
                        ? KBadgeVariant.outline
                        : switch (rule.decision) {
                            KBrowserRuleDecision.allow => KBadgeVariant.success,
                            KBrowserRuleDecision.ask => KBadgeVariant.warning,
                            KBrowserRuleDecision.block =>
                              KBadgeVariant.destructive,
                          },
                    child: Text(
                      text[rule.status == KBrowserRuleStatus.revoked
                          ? 'revoked'
                          : switch (rule.decision) {
                              KBrowserRuleDecision.allow => 'allowed',
                              KBrowserRuleDecision.ask => 'ask',
                              KBrowserRuleDecision.block => 'blocked',
                            }]!,
                    ),
                  );
                  final identity = KWebsiteIdentity(
                    host: rule.host,
                    favicon: rule.favicon,
                  );
                  return bounds.maxWidth < 340
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            identity,
                            SizedBox(height: gap),
                            badge,
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: identity),
                            SizedBox(width: gap),
                            badge,
                          ],
                        );
                },
              ),
              SizedBox(height: gap * 1.5),
              KText(
                rule.action,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: gap),
              KText(
                rule.path,
                variant: KTextVariant.caption,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              SizedBox(height: gap),
              caption('${text[rule.source.name]} · ${text[rule.status.name]}'),
              if (rule.websiteWide) ...[
                SizedBox(height: gap),
                notice('${text['websiteScope']} ${text['manualLimit']}'),
              ],
              SizedBox(height: gap * 1.5),
              LayoutBuilder(
                builder: (context, bounds) {
                  final select = KSelect(
                    label:
                        '${text['ruleDecision']} · ${rule.host} · ${rule.action}',
                    value: rule.decision.name,
                    options: [
                      KSelectOption(value: 'allow', label: text['allowed']!),
                      KSelectOption(value: 'ask', label: text['ask']!),
                      KSelectOption(value: 'block', label: text['block']!),
                    ],
                    onChanged: rule.status == KBrowserRuleStatus.revoked
                        ? null
                        : (value) {
                            if (value != null) {
                              onDecisionChange(
                                rule.id,
                                KBrowserRuleDecision.values.byName(value),
                              );
                            }
                          },
                  );
                  final action = KButton(
                    variant: KButtonVariant.ghost,
                    label:
                        text[rule.source == KBrowserRuleSource.baseline
                            ? 'reset'
                            : 'revoke']!,
                    onPressed: rule.source == KBrowserRuleSource.baseline
                        ? () => onReset(rule.id)
                        : rule.status == KBrowserRuleStatus.revoked
                        ? null
                        : () => onRevoke(rule.id),
                  );
                  return bounds.maxWidth < 480
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            select,
                            SizedBox(height: gap),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: action,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: select),
                            SizedBox(width: gap),
                            action,
                          ],
                        );
                },
              ),
              SizedBox(height: gap * 1.5),
              KDisclosure(
                title: text['details']!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KText(
                      rule.origin,
                      variant: KTextVariant.caption,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    if (rule.details != null) rule.details!,
                  ],
                ),
              ),
              SizedBox(height: gap * 2),
            ],
          ],
        ),
      ),
    );
  }
}
