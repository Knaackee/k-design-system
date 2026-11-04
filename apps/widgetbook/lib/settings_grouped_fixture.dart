import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'settings_grouped_parts.dart';
import 'settings_grouped_extra.dart';
import 'settings_grouped_admin.dart';
import 'settings_grouped_payments.dart';
import 'avatar_editor_fixture.dart';
import 'settings_overhaul_dialogs.dart';

const _pages = <(String, String, KIconName, Color)>[
  ('profile', 'Profil & Konto', KIconName.user, Color(0xff0c679f)),
  ('appearance', 'Darstellung', KIconName.sun, Color(0xff8b5cf6)),
  ('language', 'Sprache', KIconName.languages, Color(0xff14b8a6)),
  ('payments', 'Zahlungen', KIconName.creditCard, Color(0xff635bff)),
  ('integrations', 'Integrationen', KIconName.plug, Color(0xfff97316)),
  ('about', 'Über Onzeit', KIconName.info, Color(0xff71717a)),
  ('access', 'Zugang & Einladungen', KIconName.mail, Color(0xffe11d48)),
  ('assistant', 'KI-Assistent', KIconName.sparkles, Color(0xff7c3aed)),
  ('server', 'Server', KIconName.server, Color(0xff52525b)),
];

class SettingsGroupedFixture extends StatefulWidget {
  const SettingsGroupedFixture({
    this.initialPage = 'profile',
    this.admin = true,
    this.emptyAccess = false,
    this.overview = false,
    this.overhaul = false,
    this.emptyPayments = false,
    this.initialDialog,
    super.key,
  });
  final String initialPage;
  final bool admin, overview, emptyAccess, overhaul, emptyPayments;
  final String? initialDialog;
  @override
  State<SettingsGroupedFixture> createState() => _SettingsGroupedFixtureState();
}

class _SettingsGroupedFixtureState extends State<SettingsGroupedFixture> {
  late String page = widget.initialPage;
  late bool detail = !widget.overview;
  String name = 'Denis Knaack',
      scheme = 'Automatisch',
      density = 'Standard',
      language = 'Deutsch';
  String email = 'denis@example.com', notice = '';
  double fontSize = 100;

  @override
  void initState() {
    super.initState();
    if (widget.initialDialog case final title?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _profileDialog(context, title);
      });
    }
  }

  Uint8List? avatar;
  final avatarEditor = AvatarEditorFixtureData();
  final nameDraft = TextEditingController();
  @override
  void dispose() {
    nameDraft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = settingsGroupedTokens(
      theme.extension<KDesignTokens>()!,
      theme.brightness == Brightness.dark,
    );
    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where((e) => e is! KDesignTokens),
          t,
        ],
      ),
      child: Builder(
        builder: (context) {
          if (widget.overhaul && !detail) {
            return Material(
              color: t.colorSurfaceCanvas,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 2 * t.layoutPanelWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          t.spaceLayoutGutter,
                          t.spaceLayoutGutter,
                          t.spaceLayoutGutter,
                          0,
                        ),
                        child: const KStack(
                          gap: KLayoutGap.control,
                          children: [
                            KText(
                              'Einstellungen',
                              variant: KTextVariant.heading2,
                            ),
                            SgMuted('Dein Konto, deine App und dein Business.'),
                          ],
                        ),
                      ),
                      Expanded(child: _navigation(context)),
                    ],
                  ),
                ),
              ),
            );
          }
          return KSettingsPage(
            contentPadding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width < KSettingsPage.breakpoint
                  ? t.spaceControlInsetInline + t.spaceSmallInset
                  : t.spaceLayoutSectionGap + t.spaceContentActionGap,
              MediaQuery.sizeOf(context).width < KSettingsPage.breakpoint
                  ? t.spaceControlInsetInline
                  : t.spaceLayoutSectionGap,
              MediaQuery.sizeOf(context).width < KSettingsPage.breakpoint
                  ? t.spaceControlInsetInline + t.spaceSmallInset
                  : t.spaceLayoutSectionGap + t.spaceContentActionGap,
              t.spaceLayoutSectionGap + t.spaceContentActionGap,
            ),
            breadcrumb: Padding(
              padding: EdgeInsets.only(bottom: t.spaceContentActionGap),
              child: KBreadcrumb(
                label: 'Brotkrümelnavigation',
                items: [
                  KBreadcrumbItem(
                    id: 'settings',
                    label: 'Einstellungen',
                    onSelect: () => setState(() => detail = false),
                  ),
                  KBreadcrumbItem(
                    id: page,
                    label: _pages.firstWhere((p) => p.$1 == page).$2,
                  ),
                ],
              ),
            ),
            title: ['assistant', 'server'].contains(page)
                ? null
                : _pages.firstWhere((p) => p.$1 == page).$2,
            description: ['appearance', 'language'].contains(page)
                ? 'Gilt nur für dieses Gerät.'
                : null,
            navigation: _navigation(context),
            detailVisible: detail,
            backLabel: 'Einstellungen',
            onBack: () => setState(() => detail = false),
            content: switch (page) {
              'profile' => _profile(context),
              'appearance' => _appearance(context),
              'language' => SgGroup(
                title: 'App-Sprache',
                children: [
                  for (final label in [
                    'Deutsch',
                    'English',
                    'Français',
                    'Español',
                    'Italiano',
                  ])
                    SgRow(
                      label,
                      selected: language == label,
                      onTap: () => setState(() => language = label),
                    ),
                ],
              ),
              'payments' => SgPayments(
                empty: widget.emptyPayments,
                overhaul: widget.overhaul,
              ),
              'access' => SgAccess(empty: widget.emptyAccess),
              'assistant' => const SgAssistant(),
              _ => SgExtra(
                key: ValueKey(page),
                page: page,
                overhaul: widget.overhaul,
              ),
            },
          );
        },
      ),
    );
  }

  Widget _navigation(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final desktop = MediaQuery.sizeOf(context).width >= 700;
    return ColoredBox(
      color: t.colorSurfaceCanvas,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: t.spaceContentActionGap,
          vertical: t.spaceLayoutSectionGap,
        ),
        child: KStack(
          gap: KLayoutGap.action,
          align: KLayoutAlign.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: KButton(
                label: 'Zurück zu Onzeit',
                leading: const KIcon(KIconName.arrowLeft, size: 20),
                variant: KButtonVariant.ghost,
                onPressed: () => setState(() => detail = false),
              ),
            ),
            KInline(
              gap: KLayoutGap.control,
              children: [
                KAvatar(
                  alt: name,
                  size: KAvatarSize.large,
                  image: avatar == null ? null : MemoryImage(avatar!),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [KText(name), SgMuted(email)],
                  ),
                ),
              ],
            ),
            for (final group in <(String, List<String>)>[
              ('Konto', ['profile']),
              ('Business', ['payments']),
              ('App', ['appearance', 'language', 'about']),
              ('Erweitert', ['integrations']),
              if (widget.admin)
                ('Plattform', ['access', 'assistant', 'server']),
            ])
              SgGroup(
                title: group.$1,
                plain: desktop && (!widget.overhaul || detail),
                children: [
                  for (final id in group.$2)
                    Builder(
                      builder: (context) {
                        final p = _pages.firstWhere((p) => p.$1 == id);
                        return SgRow(
                          p.$2,
                          icon: p.$3,
                          color: p.$4,
                          navigation: true,
                          selected: detail && page == id,
                          value: id == 'language'
                              ? language
                              : id == 'appearance'
                              ? scheme
                              : null,
                          onTap: () => setState(() {
                            page = id;
                            detail = true;
                          }),
                        );
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _profile(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return KStack(
      gap: KLayoutGap.section,
      align: KLayoutAlign.stretch,
      children: [
        if (notice.isNotEmpty) SgMuted(notice),
        Column(
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                extensions: [
                  t.copyWith(
                    componentAvatarSizeLarge: 104,
                    componentAvatarFallbackFontSizeLarge: 32,
                    colorStatusSuccessAccent: t.colorActionPrimaryBackground,
                    componentAvatarBadgeSize: 32,
                    componentAvatarBadgeStrokeWidth: 3,
                  ),
                ],
              ),
              child: KButton(
                label: 'Foto ändern',
                variant: KButtonVariant.ghost,
                onPressed: () => showAvatarEditorFixture(
                  context,
                  data: avatarEditor,
                  onAvatarChange: (value) => setState(() => avatar = value),
                ),
                content: KAvatar(
                  alt: name,
                  size: KAvatarSize.large,
                  image: avatar == null ? null : MemoryImage(avatar!),
                  fallback: SgProfileAvatarFallback(name),
                  badge: KIcon(
                    KIconName.pencil,
                    size: 16,
                    color: t.colorActionPrimaryForeground,
                  ),
                ),
              ),
            ),
            SizedBox(height: t.spaceContentActionGap),
            KText(name, variant: KTextVariant.heading3),
            SgMuted(email),
            if (widget.admin)
              Padding(
                padding: EdgeInsets.only(top: t.spaceControlGap),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: t.spaceControlInsetInline,
                    vertical: t.spaceSmallInset,
                  ),
                  decoration: BoxDecoration(
                    color: t.colorBrandPrimaryBackground,
                    borderRadius: BorderRadius.circular(t.radiusCard),
                  ),
                  child: KText(
                    'Plattform-Admin',
                    variant: KTextVariant.caption,
                    style: TextStyle(
                      color: t.colorBrandPrimaryForeground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SgGroup(
          title: 'Persönliche Daten',
          children: [
            SgRow('Name', value: name, onTap: () => _editName(context)),
            SgRow(
              'E-Mail',
              value: email,
              onTap: () => _profileDialog(context, 'E-Mail ändern'),
            ),
          ],
        ),
        SgGroup(
          title: 'Sicherheit',
          footer: 'Abmelden betrifft nur dieses Gerät.',
          children: [
            SgRow(
              'Passwort ändern',
              description: 'Sichere deinen Zugang mit einem Passwort.',
              onTap: () => _profileDialog(context, 'Passwort ändern'),
            ),
            SgRow(
              'Abmelden',
              icon: KIconName.logOut,
              danger: true,
              onTap: () => _profileDialog(context, 'Abmelden?'),
            ),
          ],
        ),
        SgGroup(
          title: 'Konto verwalten',
          children: [
            SgRow(
              'Konto löschen',
              danger: true,
              onTap: () => _profileDialog(context, 'Konto löschen?'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _editName(BuildContext context) async {
    final controller = nameDraft..text = name;
    await KAdaptiveDialog.show<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => KAdaptiveDialog(
          title: const KText('Name bearbeiten', variant: KTextVariant.heading3),
          description: const SgMuted(
            'Änderungen gelten nur für diese Vorschau.',
          ),
          closeLabel: 'Schließen',
          onClose: () => Navigator.of(c).pop(),
          child: KStack(
            gap: KLayoutGap.control,
            children: [
              KField(
                label: 'Name',
                child: KInput(
                  controller: controller,
                  onChanged: (_) => update(() {}),
                ),
              ),
              KButton(
                label: 'Speichern',
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : () {
                        setState(() => name = controller.text.trim());
                        Navigator.of(c).pop();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _profileDialog(BuildContext context, String title) async {
    if (!widget.overhaul) {
      await sgDialog(
        context,
        title,
        const KText('Designvorschau – es werden keine Kontodaten geändert.'),
      );
      return;
    }
    final result = await showSettingsReviewDialog(
      context,
      title,
      name: name,
      email: email,
    );
    if (!mounted || result == null) return;
    setState(() {
      if (title == 'Name bearbeiten') {
        name = result;
      } else if (title == 'E-Mail ändern') {
        email = result;
      } else {
        notice = result;
      }
    });
  }

  Widget _appearance(BuildContext context) => KStack(
    gap: KLayoutGap.section,
    align: KLayoutAlign.stretch,
    children: [
      if (widget.overhaul)
        SgGroup(
          title: 'Dialogdarstellung',
          children: [
            SgInset(
              child: ValueListenableBuilder<bool>(
                valueListenable: reviewPageSheetPreference,
                builder: (context, pageSheet, _) => KSelect(
                  label: 'Dialogdarstellung',
                  value: pageSheet ? 'page' : 'adaptive',
                  options: const [
                    KSelectOption(
                      value: 'adaptive',
                      label: 'Dialog / Bottom Sheet',
                    ),
                    KSelectOption(value: 'page', label: 'Page Sheet'),
                  ],
                  onChanged: (value) =>
                      reviewPageSheetPreference.value = value == 'page',
                ),
              ),
            ),
          ],
        ),

      SgGroup(
        title: 'Vorschau',
        children: [
          SgInset(
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(fontSize / 100)),
              child: KInline(
                gap: density == 'Kompakt'
                    ? KLayoutGap.control
                    : KLayoutGap.action,
                children: [
                  const KAvatar(alt: 'Elisa Ferrari'),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KText('Elisa Ferrari'),
                        SgMuted('Einzeltraining · 16 Min Fahrt'),
                      ],
                    ),
                  ),
                  const KText('11:50'),
                ],
              ),
            ),
          ),
        ],
      ),
      SgGroup(
        title: 'Farbschema',
        children: [
          SgInset(
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: KButton(
                      label: ['Hell', 'Dunkel', 'Automatisch'][i],
                      variant: scheme == ['Hell', 'Dunkel', 'Automatisch'][i]
                          ? KButtonVariant.secondary
                          : KButtonVariant.ghost,
                      onPressed: () => setState(
                        () => scheme = ['Hell', 'Dunkel', 'Automatisch'][i],
                      ),
                      content: Column(
                        children: [
                          Container(
                            height: 70,
                            margin: EdgeInsets.symmetric(
                              vertical: Theme.of(
                                context,
                              ).extension<KDesignTokens>()!.spaceControlGap,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: i == 2
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xfffafafa),
                                        Color(0xff18181b),
                                      ],
                                    )
                                  : null,
                              color: i == 2
                                  ? null
                                  : i == 0
                                  ? const Color(0xfffafafa)
                                  : const Color(0xff18181b),
                            ),
                            child: const Center(
                              child: KIcon(
                                KIconName.menu,
                                color: Color(0xffa1a1aa),
                              ),
                            ),
                          ),
                          KText(
                            ['Hell', 'Dunkel', 'Automatisch'][i],
                            variant: KTextVariant.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      SgGroup(
        title: 'Dichte',
        children: [
          SgInset(
            child: SgChoices(
              items: const ['Kompakt', 'Standard', 'Groß'],
              value: density,
              onChanged: (v) => setState(() => density = v),
            ),
          ),
        ],
      ),
      SgGroup(
        title: 'Schriftgröße · ${fontSize.round()}%',
        footer:
            'Die Systemschrift deines Geräts wird zusätzlich berücksichtigt.',
        children: [
          SgInset(
            child: KSlider(
              label: 'Schriftgröße',
              value: fontSize,
              min: 85,
              max: 130,
              divisions: 9,
              onChanged: (v) => setState(() => fontSize = v),
            ),
          ),
        ],
      ),
      KButton(
        label: 'Auf Standard zurücksetzen',
        variant: KButtonVariant.ghost,
        onPressed: () => setState(() {
          fontSize = 100;
          density = 'Standard';
          scheme = 'Automatisch';
        }),
      ),
    ],
  );
}
