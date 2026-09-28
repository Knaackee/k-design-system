import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'settings_page_fixtures.dart';
import 'dashboard_shell_content.dart';

// Fixture IDs: showcase-dashboard-shell, showcase-dashboard-shell-inspector,
// showcase-dashboard-shell-expanded.
class DashboardShellFixture extends StatefulWidget {
  const DashboardShellFixture({
    this.initialInspector = false,
    this.initialMode = KSidebarMode.rail,
    super.key,
  });
  final bool initialInspector;
  final KSidebarMode initialMode;
  @override
  State<DashboardShellFixture> createState() => _DashboardShellFixtureState();
}

class _DashboardShellFixtureState extends State<DashboardShellFixture> {
  final navigator = GlobalKey<NavigatorState>();
  ThemeMode themeMode = ThemeMode.system;
  @override
  Widget build(BuildContext context) {
    final inherited = Theme.of(context).extension<KDesignTokens>()!;
    final brightness = themeMode == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context)
        : themeMode == ThemeMode.dark
        ? Brightness.dark
        : Brightness.light;
    return Theme(
      data: kDesignTheme(
        brightness: brightness,
        tokenTransform: (base) => base.copyWith(
          sizeControl: inherited.sizeControl,
          sizeHitTarget: inherited.sizeHitTarget,
          spaceControlGap: inherited.spaceControlGap,
          spaceControlInsetInline: inherited.spaceControlInsetInline,
          spaceCardPadding: inherited.spaceCardPadding,
          spaceLayoutSectionGap: inherited.spaceLayoutSectionGap,
          fontControlSize: inherited.fontControlSize,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: constraints.biggest),
          child: NavigatorPopHandler(
            onPopWithResult: (_) => navigator.currentState!.pop(),
            child: Navigator(
              key: navigator,
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => _DashboardShell(
                  initialInspector: widget.initialInspector,
                  initialMode: widget.initialMode,
                  themeMode: () => themeMode,
                  onThemeChanged: (value) => setState(() => themeMode = value),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardShell extends StatefulWidget {
  const _DashboardShell({
    required this.initialInspector,
    required this.initialMode,
    required this.themeMode,
    required this.onThemeChanged,
  });
  final bool initialInspector;
  final KSidebarMode initialMode;
  final ThemeMode Function() themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  @override
  State<_DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<_DashboardShell> {
  late KSidebarMode mode = widget.initialMode;
  String page = 'Overview';
  String? project;
  String selectedProject = 'Website refresh';
  Future<void>? inspectorRoute;
  bool settings = false, overlayOpen = false;
  late bool inspectorOpen = widget.initialInspector;
  final detailsFocus = FocusNode(skipTraversal: true);
  BuildContext? navigationContext;
  final settingsPageFocus = FocusNode(skipTraversal: true);
  final navigationFocus = FocusNode(skipTraversal: true);
  final settingsFocus = FocusNode(skipTraversal: true);
  void focusChild(FocusNode node) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && node.traversalDescendants.isNotEmpty) {
          node.traversalDescendants.first.requestFocus();
        }
      });
  int? layout;
  BuildContext? overlayContext;
  final noteControllers = <String, TextEditingController>{};
  TextEditingController get notes =>
      noteControllers.putIfAbsent(selectedProject, TextEditingController.new);
  @override
  void dispose() {
    for (final controller in noteControllers.values) {
      controller.dispose();
    }
    detailsFocus.dispose();
    settingsFocus.dispose();
    navigationFocus.dispose();
    settingsPageFocus.dispose();
    super.dispose();
  }

  void navigate(String next) => setState(() {
    settings = false;
    page = next;
    project = null;
  });
  Widget navigation({bool mobile = false}) => KSidebar(
    mode: mobile ? KSidebarMode.expanded : mode,
    expandedWidth: 248,
    railWidth: 56,
    onModeChanged: (value) => setState(() => mode = value),
    child: Column(
      children: [
        if (!mobile)
          KSidebarHeader(
            child: SizedBox(
              height: 47,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (mobile || mode == KSidebarMode.expanded)
                    const Expanded(
                      child: Row(
                        children: [
                          KIcon(KIconName.orbit, size: 24),
                          SizedBox(width: 8),
                          KText('Orbit', variant: KTextVariant.heading5),
                        ],
                      ),
                    ),
                  if (!mobile)
                    SizedBox(
                      width: mode == KSidebarMode.rail ? 39 : 40,
                      child: const KSidebarToggle(
                        key: ValueKey('brand-toggle'),
                        railContent: KIcon(KIconName.orbit, size: 24),
                      ),
                    ),
                ],
              ),
            ),
          ),
        KSidebarBody(
          children: [
            KSidebarGroup(
              label: 'Workspace',
              children: [
                for (final item in [
                  ('Overview', KIconName.house),
                  ('Projects', KIconName.folder),
                ])
                  KSidebarItem(
                    label: item.$1,
                    leading: KIcon(item.$2),
                    active: page == item.$1,
                    onPressed: () {
                      navigate(item.$1);
                      if (mobile) Navigator.of(navigationContext!).pop();
                    },
                  ),
              ],
            ),
          ],
        ),
        KSidebarFooter(
          child: Focus(
            focusNode: settingsFocus,
            child: KSidebarItem(
              label: 'Settings',
              leading: const KIcon(KIconName.settings),
              onPressed: () {
                setState(() {
                  settings = true;
                });
                if (mobile) Navigator.of(navigationContext!).pop();
              },
            ),
          ),
        ),
      ],
    ),
  );
  Widget inspectorBody() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      KText(selectedProject, variant: KTextVariant.heading5),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: KBadge(
          variant: KBadgeVariant.secondary,
          child: Text(
            shellProjects.firstWhere((row) => row.$1 == selectedProject).$2,
          ),
        ),
      ),
      const SizedBox(height: 16),
      KField(
        label: 'Notes',
        helperText: 'Demo data stays in this showcase.',
        child: KInput(controller: notes),
      ),
    ],
  );
  Future<void> showInspector() async {
    if (overlayOpen || !mounted) return;
    overlayOpen = true;
    await KResponsiveDrawer.show<void>(
      useRootNavigator: false,
      context: context,
      title: const Text('Project details'),
      child: Builder(
        builder: (context) {
          overlayContext = context;
          return inspectorBody();
        },
      ),
    );
    overlayOpen = false;
    overlayContext = null;
    if (mounted) {
      setState(() => inspectorOpen = false);
      focusChild(detailsFocus);
    }
  }

  void openInspector() {
    if (inspectorOpen) {
      setState(() => inspectorOpen = false);
      focusChild(detailsFocus);
      return;
    }
    setState(() => inspectorOpen = true);
    inspectorRoute = showInspector();
  }

  void changeLayout(int next) {
    if (layout == next) return;
    layout = next;
    if (inspectorOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (overlayOpen && overlayContext != null) {
          Navigator.of(overlayContext!).pop();
          await inspectorRoute;
        }
        if (!mounted) return;
        setState(() => inspectorOpen = true);
        inspectorRoute = showInspector();
      });
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 600;
      changeLayout(mobile ? 0 : 1);
      if (settings) {
        return Focus(
          focusNode: settingsPageFocus,
          child: SettingsPageFixture(
            onBackToApp: () {
              setState(() => settings = false);
              focusChild(layout == 0 ? navigationFocus : settingsFocus);
            },
          ),
        );
      }
      final t = Theme.of(context).extension<KDesignTokens>()!;
      return ColoredBox(
        color: t.colorSurfaceCanvas,
        child: Row(
          children: [
            if (!mobile) navigation(),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 64,
                    padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 24),
                    decoration: BoxDecoration(
                      color: t.colorSurfaceRaised,
                      border: Border(
                        bottom: BorderSide(color: t.colorBorderDefault),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (mobile)
                          Focus(
                            focusNode: navigationFocus,
                            child: KIconButton(
                              label: 'Open navigation',
                              icon: KIconName.menu,
                              onPressed: () async {
                                await KResponsiveDrawer.show<void>(
                                  useRootNavigator: false,
                                  context: context,
                                  title: const Row(
                                    key: ValueKey('navigation-brand'),
                                    children: [
                                      KIcon(KIconName.orbit, size: 24),
                                      SizedBox(width: 8),
                                      Text('Orbit'),
                                    ],
                                  ),
                                  left: true,
                                  breakpoint: 0,
                                  sideWidth: 248,
                                  sideContentInset: false,
                                  sideScrollable: false,
                                  sideShowCloseButton: false,
                                  child: Builder(
                                    builder: (context) {
                                      navigationContext = context;
                                      return navigation(mobile: true);
                                    },
                                  ),
                                );
                                navigationContext = null;
                                if (mounted) {
                                  focusChild(
                                    settings
                                        ? settingsPageFocus
                                        : navigationFocus,
                                  );
                                }
                              },
                            ),
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: KBreadcrumb(
                              items: [
                                KBreadcrumbItem(
                                  id: 'home',
                                  label: 'Orbit',
                                  onSelect: () => navigate('Overview'),
                                ),
                                KBreadcrumbItem(
                                  id: 'page',
                                  label: page,
                                  onSelect: project != null
                                      ? () => navigate('Projects')
                                      : null,
                                ),
                                if (project != null)
                                  KBreadcrumbItem(
                                    id: 'project',
                                    label: project!,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        KThemeSwitcher(
                          value: widget.themeMode(),
                          onChanged: widget.onThemeChanged,
                        ),
                        Focus(
                          focusNode: detailsFocus,
                          child: KIconButton(
                            label: 'Project details',
                            icon: KIconName.panelRight,
                            onPressed: openInspector,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: DashboardShellContent(
                            page: page,
                            project: project,
                            mobile: mobile,
                            onSelect: (value) => setState(() {
                              page = 'Projects';
                              project = value;
                              selectedProject = value;
                            }),
                            onBack: () => navigate('Projects'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
