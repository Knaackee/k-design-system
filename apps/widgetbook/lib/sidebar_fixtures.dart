import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class SidebarFixture extends StatefulWidget {
  const SidebarFixture({
    this.initialMode = KSidebarMode.expanded,
    this.settings = false,
    this.drawer = false,
    super.key,
  });
  final KSidebarMode initialMode;
  final bool settings;
  final bool drawer;

  @override
  State<SidebarFixture> createState() => _SidebarFixtureState();
}

class _SidebarFixtureState extends State<SidebarFixture> {
  late KSidebarMode mode = widget.initialMode;
  String active = 'All issues';

  List<KMenuAction> actions(String label) => [
    KMenuAction(
      id: 'open-$label',
      label: 'Open in new tab',
      icon: KIconName.externalLink,
    ),
    KMenuAction(id: 'copy-$label', label: 'Copy link', icon: KIconName.copy),
    KMenuAction(
      id: 'unpin-$label',
      label: 'Unpin',
      icon: KIconName.x,
      separatorBefore: true,
    ),
  ];

  Widget action(String label) =>
      KOverflowMenu(label: '$label actions', actions: actions(label));

  Widget item(
    String label,
    KIconName icon, {
    Widget? badge,
    int depth = 0,
    bool withAction = false,
  }) => KSidebarItem(
    label: label,
    leading: KIcon(icon),
    badge: badge,
    action: withAction ? action(label) : null,
    depth: depth,
    active: active == label,
    onPressed: () => setState(() => active = label),
  );

  Widget get sidebar => KSidebar(
    mode: mode,
    onModeChanged: (value) => setState(() => mode = value),
    expandedWidth: widget.drawer ? 420 : 248,
    semanticLabel: widget.settings
        ? 'Settings navigation'
        : 'Workspace navigation',
    child: Column(
      children: [
        KSidebarHeader(
          child: KSidebarModeContent(
            expanded: Row(
              children: [
                Expanded(child: _WorkspaceButton(actions: actions('Orbit'))),
                const KSidebarToggle(),
              ],
            ),
            rail: const KSidebarToggle(railContent: _OrbitAvatar()),
          ),
        ),
        if (widget.settings)
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: KSidebarModeContent(
              expanded: KSearchField(placeholder: 'Search settings'),
            ),
          ),
        KSidebarBody(
          children: widget.settings ? settingsItems : workspaceItems,
        ),
        KSidebarFooter(child: item('Help and feedback', KIconName.circleAlert)),
      ],
    ),
  );

  List<Widget> get settingsItems => [
    KSidebarGroup(
      label: 'Workspace',
      children: [
        item('General', KIconName.settings),
        item(
          'Members',
          KIconName.users,
          badge: const KBadge(child: Text('99+')),
        ),
        item('Integrations', KIconName.link),
      ],
    ),
    KSidebarGroup(
      label: 'Account',
      children: [
        item('Profile', KIconName.user),
        item('Notifications', KIconName.bell),
        item('Security', KIconName.lock),
      ],
    ),
  ];

  List<Widget> get workspaceItems => [
    KSidebarGroup(
      children: [
        item(
          'Inbox',
          KIconName.mail,
          badge: const KBadge(child: Text('9')),
          withAction: true,
        ),
        item('My issues', KIconName.user),
        item('Calendar', KIconName.calendar),
        item('All issues', KIconName.checkCheck),
      ],
    ),
    KSidebarGroup(
      label: 'Workspace',
      action: KIconButton(
        label: 'Add workspace item',
        icon: KIconName.plus,
        onPressed: () {},
      ),
      children: [
        item(
          'Projects',
          KIconName.folder,
          badge: const KBadge(child: Text('99+')),
          withAction: true,
        ),
        item('Views', KIconName.slidersHorizontal),
      ],
    ),
    KSidebarGroup(
      label: 'Teams',
      action: KIconButton(
        label: 'Add team',
        icon: KIconName.plus,
        onPressed: () {},
      ),
      children: [
        KSidebarSubgroup(
          label: 'Knaack',
          leading: const KIcon(KIconName.users),
          action: action('Knaack'),
          children: [
            item('Issues', KIconName.checkCheck, depth: 1),
            item('Cycles', KIconName.refreshCw, depth: 1),
            item(
              'Members',
              KIconName.users,
              depth: 1,
              badge: const KBadge(child: Text('99')),
              withAction: true,
            ),
          ],
        ),
        KSidebarSubgroup(
          label: 'Product lab',
          leading: const KIcon(KIconName.users),
          action: action('Product lab'),
          initiallyExpanded: false,
          children: [
            item('Roadmap', KIconName.calendar, depth: 1),
            item('Research notes', KIconName.fileText, depth: 1),
          ],
        ),
      ],
    ),
    KSidebarGroup(
      label: 'Pinned',
      collapsible: true,
      children: [
        item('KNAACK.IT', KIconName.folder, withAction: true),
        item('Design system', KIconName.star, withAction: true),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    if (widget.drawer) {
      return Center(
        child: KButton(
          label: 'Open navigation drawer',
          onPressed: () => KResponsiveDrawer.show<void>(
            context: context,
            title: const Text('Navigation'),
            left: true,
            child: SizedBox.expand(child: sidebar),
          ),
        ),
      );
    }
    return Center(
      child: Container(
        width: 920,
        height: 660,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: t.colorSurfaceCanvas,
          border: Border.all(color: t.colorBorderDefault),
          borderRadius: BorderRadius.circular(t.radiusCard),
        ),
        child: Row(
          children: [
            sidebar,
            Expanded(
              child: Center(
                child: Text(
                  active,
                  style: TextStyle(
                    color: t.colorTextMuted,
                    fontFamily: t.fontFamily,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitAvatar extends StatelessWidget {
  const _OrbitAvatar();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Center(
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.colorActionPrimaryBackground,
          borderRadius: BorderRadius.circular(t.radiusControl),
        ),
        child: Text(
          'O',
          style: TextStyle(
            color: t.colorActionPrimaryForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _WorkspaceButton extends StatelessWidget {
  const _WorkspaceButton({required this.actions});
  final List<KMenuAction> actions;
  @override
  Widget build(BuildContext context) => KMenuButton(
    label: 'Orbit workspace',
    actions: actions,
    fullWidth: true,
    triggerContent: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          _OrbitAvatar(),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orbit',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Design workspace',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          KIcon(KIconName.chevronDown, size: 16),
        ],
      ),
    ),
  );
}
