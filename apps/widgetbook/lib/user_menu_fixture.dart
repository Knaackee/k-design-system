import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class UserMenuFixture extends StatefulWidget {
  const UserMenuFixture({this.longIdentity = false, super.key});
  final bool longIdentity;
  @override
  State<UserMenuFixture> createState() => _UserMenuFixtureState();
}

class _UserMenuFixtureState extends State<UserMenuFixture> {
  String _result = 'No action selected';
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final email = widget.longIdentity
        ? 'alexandra.morgan@international-workspace.example'
        : 'alex@workspace.example';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(t.spaceCardPadding),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: t.colorBorderDefault,
                width: t.borderWidthDefault,
              ),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: KText('Workspace', variant: KTextVariant.heading4),
              ),
              KUserMenu(
                userName: widget.longIdentity
                    ? 'Alexandra Morgan-Hernández'
                    : 'Alex Morgan',
                description: Tooltip(message: email, child: Text(email)),
                actions: [
                  KMenuAction(
                    id: 'profile',
                    label: 'Profile',
                    icon: KIconName.user,
                    onSelect: () =>
                        setState(() => _result = 'Profile selected'),
                  ),
                  KMenuAction(
                    id: 'settings',
                    label: 'Settings',
                    icon: KIconName.settings,
                    onSelect: () =>
                        setState(() => _result = 'Settings selected'),
                  ),
                  KMenuAction(
                    id: 'help',
                    label: 'Help & support',
                    icon: KIconName.circleQuestionMark,
                    separatorBefore: true,
                    onSelect: () => setState(() => _result = 'Help selected'),
                  ),
                  KMenuAction(
                    id: 'sign-out',
                    label: 'Sign out',
                    icon: KIconName.logOut,
                    separatorBefore: true,
                    destructive: true,
                    onSelect: () => setState(
                      () => _result = 'Sign out requested — demo only',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(t.spaceCardPadding),
          child: Semantics(
            liveRegion: true,
            child: KText(_result, variant: KTextVariant.bodySmall),
          ),
        ),
      ],
    );
  }
}
