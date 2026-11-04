import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'admin_workspace_data.dart';
import 'admin_workspace_parts.dart';
import 'settings_grouped_parts.dart' show settingsGroupedTokens;
part 'admin_workspace_pages.dart';
part 'admin_workspace_growth.dart';
part 'admin_workspace_details.dart';

/// Admin gallery only. No production accounts, mail, payments or permissions.
class AdminWorkspaceFixture extends StatefulWidget {
  const AdminWorkspaceFixture({this.initialPage = 'overview', super.key});
  final String initialPage;
  @override
  State<AdminWorkspaceFixture> createState() => _AdminWorkspaceState();
}

class _AdminWorkspaceState extends State<AdminWorkspaceFixture> {
  final data = adminWorkspaceData();
  late String page = widget.initialPage;
  final search = TextEditingController();
  String filter = 'Alle',
      notice = '',
      provider = 'OpenRouter',
      model = 'Demo-Modell',
      fallback = 'Kein Ausweichmodell';
  int days = 30;
  bool registration = true, inviteOnly = true;
  KDesignTokens get t => Theme.of(context).extension<KDesignTokens>()!;
  List<List<String>> rows(String key) =>
      (data[key] as List).map((r) => (r as List).cast<String>()).toList();
  Map<String, dynamic> get pages => data['adminPages'] as Map<String, dynamic>;
  void updateState(VoidCallback change) => setState(change);
  void go(String next) => setState(() {
    page = next;
    filter = 'Alle';
    search.clear();
    notice = '';
  });
  void feedback(String text) =>
      setState(() => notice = '$text · nur Designvorschau');
  void change(String key, int index, int column, String value) =>
      setState(() => (data[key] as List)[index][column] = value);
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens =
        settingsGroupedTokens(
          theme.extension<KDesignTokens>()!,
          theme.brightness == Brightness.dark,
        ).copyWith(
          spaceCardPadding: 16,
          fontBodySize: 16,
          fontBodyLineHeight: 24,
          fontBodySmallSize: 14,
          fontBodySmallLineHeight: 21,
          fontHeading2LineHeight: 38,
          fontHeading3Size: 22,
          fontHeading3LineHeight: 27.5,
          radiusControl: 12,
          colorActionSecondaryBackground: theme.brightness == Brightness.dark
              ? const Color(0xff27272a)
              : const Color(0xfff4f4f5),
          colorActionSecondaryForeground: theme.brightness == Brightness.dark
              ? const Color(0xfffafafa)
              : const Color(0xff18181b),
        );
    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where((e) => e is! KDesignTokens),
          tokens,
        ],
      ),
      child: Builder(
        builder: (context) => LayoutBuilder(
          builder: (context, box) {
            final desktop = box.maxWidth >= 1000;
            return ColoredBox(
              color: tokens.colorSurfaceCanvas,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (desktop) ...[
                    SizedBox(width: 170, child: _primary(context)),
                    SizedBox(
                      width: 238,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(tokens.spaceCardPadding),
                        child: _navigation(context, sidebar: true),
                      ),
                    ),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      key: ValueKey(page),
                      padding: EdgeInsets.all(
                        desktop
                            ? tokens.spaceLayoutGutter * 2
                            : tokens.spaceCardPadding,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: KStack(
                            gap: KLayoutGap.section,
                            align: KLayoutAlign.stretch,
                            children: [
                              if (!desktop && page != 'navigation')
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: KButton(
                                    label: 'Admin',
                                    leading: const KIcon(KIconName.chevronLeft),
                                    variant: KButtonVariant.ghost,
                                    onPressed: () => go('navigation'),
                                  ),
                                ),
                              KStack(
                                gap: KLayoutGap.control,
                                align: KLayoutAlign.stretch,
                                children: [
                                  KText(
                                    page == 'navigation'
                                        ? 'Admin'
                                        : pages[page][0] as String,
                                    variant: KTextVariant.heading2,
                                  ),
                                  KText(
                                    page == 'navigation'
                                        ? 'Plattform, Betriebe und Wachstum.'
                                        : pages[page][2] as String,
                                    style: TextStyle(
                                      color: tokens.colorTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                              ..._content(context),
                              if (notice.isNotEmpty)
                                Semantics(
                                  liveRegion: true,
                                  child: KText(
                                    notice,
                                    variant: KTextVariant.caption,
                                    style: TextStyle(
                                      color:
                                          tokens.colorActionPrimaryBackground,
                                    ),
                                  ),
                                ),
                              KText(
                                'Designvorschau · Beispieldaten, keine echten Aktionen.',
                                variant: KTextVariant.caption,
                                style: TextStyle(color: tokens.colorTextMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _primary(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: t.colorBorderDefault)),
      ),
      padding: EdgeInsets.all(t.spaceCardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const KText('onzeit.', variant: KTextVariant.heading3),
          SizedBox(height: t.spaceLayoutSectionGap),
          for (final x in const [
            ('Heute', KIconName.house),
            ('Kalender', KIconName.calendar),
            ('Eingang', KIconName.inbox),
            ('Admin', KIconName.shield),
            ('Mehr', KIconName.settings),
          ])
            Padding(
              padding: EdgeInsets.only(bottom: t.spaceControlGap),
              child: KButton(
                label: x.$1,
                leading: KIcon(x.$2),
                variant: x.$1 == 'Admin'
                    ? KButtonVariant.secondary
                    : KButtonVariant.ghost,
                onPressed: () => x.$1 == 'Admin'
                    ? go('overview')
                    : feedback('App-Navigation ist außerhalb dieser Galerie'),
              ),
            ),
          const Spacer(),
          const Align(
            alignment: Alignment.centerLeft,
            child: KAvatar(alt: 'Denis Knaack'),
          ),
          SizedBox(height: t.spaceControlGap),
          const KText('Denis Knaack', variant: KTextVariant.label),
          const KText('Owner', variant: KTextVariant.caption),
        ],
      ),
    );
  }

  Widget _navigation(BuildContext context, {bool sidebar = false}) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return KStack(
      gap: KLayoutGap.section,
      align: KLayoutAlign.stretch,
      children: [
        for (final group in data['adminGroups'] as List)
          AwGroup(
            group[0] as String,
            child: AwCard(
              children: [
                for (final key in group[1] as List)
                  KButton(
                    label: pages[key][0] as String,
                    variant: page == key
                        ? KButtonVariant.secondary
                        : KButtonVariant.ghost,
                    fullWidth: true,
                    onPressed: () => go(key as String),
                    content: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: t.spaceControlGap,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(t.spaceControlGap / 2),
                            decoration: BoxDecoration(
                              color: _navColor(key),
                              borderRadius: BorderRadius.circular(
                                t.radiusControl,
                              ),
                            ),
                            child: KIcon(
                              _navIcon(key),
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: t.spaceControlGap),
                          Expanded(
                            child: KText(
                              pages[key][0] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              variant: KTextVariant.bodySmall,
                            ),
                          ),
                          if (!sidebar)
                            const KIcon(KIconName.chevronRight, size: 16),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  KIconName _navIcon(String key) => switch (key) {
    'customers' => KIconName.users,
    'access' => KIconName.keyRound,
    'growth' => KIconName.trendingUp,
    'subscriptions' => KIconName.creditCard,
    'waitlist' => KIconName.list,
    'invitations' => KIconName.mail,
    'applications' => KIconName.star,
    'partners' => KIconName.link,
    'operations' => KIconName.server,
    'assistant' => KIconName.sparkles,
    'audit' => KIconName.clock,
    _ => KIconName.chartNoAxesCombined,
  };
  Color _navColor(String key) => const [
    Color(0xff0c679f),
    Color(0xff7c3aed),
    Color(0xffe11d48),
    Color(0xff16a34a),
    Color(0xff635bff),
    Color(0xff0891b2),
    Color(0xffea580c),
    Color(0xffdb2777),
    Color(0xffca8a04),
    Color(0xff52525b),
    Color(0xff7c3aed),
    Color(0xff71717a),
  ][pages.keys.toList().indexOf(key)];
  Widget _filters(List<String> options) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: KInline(
      gap: KLayoutGap.control,
      children: [
        for (final f in options)
          KButton(
            label: f,
            variant: filter == f
                ? KButtonVariant.primary
                : KButtonVariant.ghost,
            onPressed: () => setState(() => filter = f),
          ),
      ],
    ),
  );
  Widget _search(String placeholder) => KSearchField(
    label: 'Suchen',
    placeholder: placeholder,
    controller: search,
    clearable: true,
    onChanged: (_) => setState(() {}),
  );
  bool _matches(List<String> row, String status) =>
      (filter == 'Alle' || filter == status) &&
      row.join(' ').toLowerCase().contains(search.text.toLowerCase());
  Widget _list(
    String key,
    int statusIndex,
    Widget Function(List<String>, int) render,
  ) {
    final entries = rows(key);
    final widgets = [
      for (var i = 0; i < entries.length; i++)
        if (_matches(entries[i], entries[i][statusIndex]))
          render(entries[i], i),
    ];
    return AwCard(
      children: widgets.isEmpty
          ? [
              AwRow(
                'Keine Einträge',
                subtitle: 'Suche oder Filter ändern.',
                action: KButton(
                  label: 'Zurücksetzen',
                  variant: KButtonVariant.ghost,
                  onPressed: () => setState(() {
                    filter = 'Alle';
                    search.clear();
                  }),
                ),
              ),
            ]
          : widgets,
    );
  }
}
