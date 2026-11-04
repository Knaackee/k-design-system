import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class DisclosureFixture extends StatefulWidget {
  const DisclosureFixture({this.accordion = false, super.key});

  final bool accordion;

  @override
  State<DisclosureFixture> createState() => _DisclosureFixtureState();
}

class _DisclosureFixtureState extends State<DisclosureFixture> {
  String _message = 'No action selected';

  Widget _actions(String section) => KOverflowMenu(
    label: 'More actions for $section',
    actions: [
      KMenuAction(
        id: 'rename',
        label: 'Rename',
        icon: KIconName.pen,
        onSelect: () => setState(() => _message = 'Rename $section'),
      ),
      KMenuAction(
        id: 'copy',
        label: 'Copy link',
        icon: KIconName.link,
        onSelect: () => setState(() => _message = 'Copy link for $section'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: t.spaceLayoutGutter),
      child: KContainer(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: KStack(
            gap: KLayoutGap.section,
            align: KLayoutAlign.stretch,
            children: [
              KText(
                widget.accordion ? 'Accordion' : 'Disclosure',
                variant: KTextVariant.heading4,
              ),
              if (widget.accordion)
                KAccordion(
                  defaultValue: const ['overview'],
                  items: [
                    KAccordionItem(
                      id: 'overview',
                      title: 'Overview',
                      leadingIcon: const KIcon(KIconName.folder, size: 20),
                      titleIcon: const KIcon(KIconName.star, size: 20),
                      actions: _actions('Overview'),
                      child: const KText('Project details and ownership.'),
                    ),
                    KAccordionItem(
                      id: 'activity',
                      title: 'Activity',
                      leadingIcon: const KIcon(KIconName.clock, size: 20),
                      actions: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const KText('3 items', variant: KTextVariant.caption),
                          SizedBox(width: t.spaceControlGap),
                          _actions('Activity'),
                        ],
                      ),
                      child: const KText('Recent updates and decisions.'),
                    ),
                  ],
                )
              else
                KDisclosure(
                  title: 'Project settings',
                  leadingIcon: const KIcon(KIconName.settings, size: 20),
                  titleIcon: const KIcon(KIconName.star, size: 20),
                  actions: _actions('Project settings'),
                  defaultOpen: true,
                  child: const KText(
                    'Configure the shared project defaults here.',
                  ),
                ),
              Semantics(
                liveRegion: true,
                child: KText(_message, variant: KTextVariant.bodySmall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
