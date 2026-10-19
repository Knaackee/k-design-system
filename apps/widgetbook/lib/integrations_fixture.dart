import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'integration_icon_picker_stub.dart'
    if (dart.library.js_interop) 'integration_icon_picker_web.dart'
    as icon_picker;
import 'integration_brand_mark.dart';

const integrationFixtureIds = (
  marketplace: 'integrations-marketplace',
  chatConnection: 'integrations-chat-connection',
  connectionStates: 'integrations-connection-states',
  adminCatalog: 'integrations-admin-catalog',
);

const _categories = [
  KIntegrationCategory(id: 'all', label: 'Alle'),
  KIntegrationCategory(id: 'communication', label: 'Kommunikation'),
  KIntegrationCategory(id: 'development', label: 'Entwicklung'),
  KIntegrationCategory(id: 'planning', label: 'Planung'),
  KIntegrationCategory(id: 'knowledge', label: 'Wissen'),
];

Widget _brand(String brand, Color _) =>
    IntegrationBrandMark(brand.toLowerCase());

List<KIntegrationItem> _seedItems() => [
  KIntegrationItem(
    id: 'tasks',
    name: 'Tasks',
    category: 'planning',
    description:
        'Aufgaben und Projekte finden, planen und mit deinem Assistenten bearbeiten.',
    icon: Image.asset('assets/integrations/tasks-icon.png'),
    availabilityLabel: 'MCP-Server',
  ),
  KIntegrationItem(
    id: 'gmail',
    name: 'Gmail',
    category: 'communication',
    description:
        'E-Mails finden, lesen und als Kontext für Aufgaben verwenden.',
    icon: _brand('Gmail', const Color(0xffea4335)),
    state: KIntegrationConnectionState.connected,
    availabilityLabel: 'Developer Preview',
    accountLabel: 'arbeit@beispiel.de',
  ),
  KIntegrationItem(
    id: 'outlook',
    name: 'Outlook',
    category: 'communication',
    description: 'Postfach und Kalender für Termin- und Nachrichtenaufgaben.',
    icon: _brand('Outlook', const Color(0xff0078d4)),
  ),
  KIntegrationItem(
    id: 'github',
    name: 'GitHub',
    category: 'development',
    description: 'Issues, Pull Requests und Repositories als Arbeitskontext.',
    icon: _brand('GitHub', const Color(0xff6e7681)),
    state: KIntegrationConnectionState.error,
  ),
  KIntegrationItem(
    id: 'sentry',
    name: 'Sentry',
    category: 'development',
    description: 'Fehler, Releases und betroffene Dienste untersuchen.',
    icon: _brand('Sentry', const Color(0xffa68ac1)),
  ),
  KIntegrationItem(
    id: 'notion',
    name: 'Notion',
    category: 'knowledge',
    description:
        'Seiten und Datenbanken nach freigegebenem Wissen durchsuchen.',
    icon: _brand('Notion', const Color(0xff71717a)),
  ),
  KIntegrationItem(
    id: 'linear',
    name: 'Linear',
    category: 'planning',
    description: 'Projekte, Issues und Zyklen für Planung und Status nutzen.',
    icon: _brand('Linear', const Color(0xff8c8dff)),
  ),
  KIntegrationItem(
    id: 'slack',
    name: 'Slack',
    category: 'communication',
    description: 'Freigegebene Channels und Threads als Teamkontext verwenden.',
    icon: _brand('Slack', const Color(0xffce85d0)),
    state: KIntegrationConnectionState.unavailable,
    availabilityLabel: 'Workspace-Freigabe nötig',
  ),
];

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return ColoredBox(
      color: t.colorSurfaceCanvas,
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: t.spaceCardPadding),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.spaceControlInsetInline,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: KBadge(
                variant: KBadgeVariant.warning,
                child: const Text(
                  'Interaktive Vorschau · keine echte Anmeldung',
                ),
              ),
            ),
          ),
          SizedBox(height: t.spaceControlGap),
          child,
        ],
      ),
    );
  }
}

class IntegrationsMarketplaceFixture extends StatefulWidget {
  const IntegrationsMarketplaceFixture({super.key});
  @override
  State<IntegrationsMarketplaceFixture> createState() =>
      _IntegrationsMarketplaceFixtureState();
}

class _IntegrationsMarketplaceFixtureState
    extends State<IntegrationsMarketplaceFixture> {
  late List<KIntegrationItem> items = _seedItems();
  String category = 'all', query = '';
  String? activeId;

  void update(String id, KIntegrationConnectionState state, [String? account]) {
    setState(() {
      items = [
        for (final item in items)
          if (item.id == id)
            KIntegrationItem(
              id: item.id,
              name: item.name,
              category: item.category,
              description: item.description,
              icon: item.icon,
              state: state,
              availabilityLabel: item.availabilityLabel,
              accountLabel: state == KIntegrationConnectionState.connected
                  ? account
                  : null,
            )
          else
            item,
      ];
    });
  }

  @override
  Widget build(BuildContext context) => _PreviewFrame(
    child: KIntegrationMarketplace(
      integrations: items,
      categories: _categories,
      activeCategory: category,
      searchValue: query,
      activeIntegrationId: activeId,
      onCategoryChanged: (value) => setState(() => category = value),
      onSearchChanged: (value) => setState(() => query = value),
      onConnect: (item) => setState(() => activeId = item.id),
      onDisconnect: (item) =>
          update(item.id, KIntegrationConnectionState.disconnected),
      panelBuilder: (context, item) => KIntegrationConnectionCard(
        name: item.name,
        icon: item.icon,
        description:
            'Anmeldung und Kontoauswahl erfolgen beim jeweiligen Dienst. Hier simulieren wir nur die erfolgreiche Rückkehr.',
        permissions: const [
          'Freigegebene Inhalte lesen',
          'Verbindung jederzeit trennen',
        ],
        stateLabel: 'Nicht verbunden',
        connectLabel: 'OAuth-Rückkehr simulieren',
        onConnect: () {
          update(
            item.id,
            KIntegrationConnectionState.connected,
            'demo@beispiel.de',
          );
          setState(() => activeId = null);
        },
      ),
    ),
  );
}

class IntegrationChatConnectionFixture extends StatefulWidget {
  const IntegrationChatConnectionFixture({super.key});
  @override
  State<IntegrationChatConnectionFixture> createState() =>
      _IntegrationChatConnectionFixtureState();
}

class _IntegrationChatConnectionFixtureState
    extends State<IntegrationChatConnectionFixture> {
  var state = KIntegrationConnectionState.disconnected;
  @override
  Widget build(BuildContext context) {
    const labels = {
      KIntegrationConnectionState.disconnected: 'Nicht verbunden',
      KIntegrationConnectionState.pending: 'Simulierter Verbindungstest läuft',
      KIntegrationConnectionState.connected: 'Arbeit · dennis@unternehmen.de',
      KIntegrationConnectionState.error: 'Simulation fehlgeschlagen',
      KIntegrationConnectionState.unavailable: 'Voraussetzungen fehlen',
    };
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return _PreviewFrame(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(t.spaceControlInsetInline),
          child: Column(
            children: [
              KIntegrationConnectionCard(
                name: 'Gmail',
                icon: _brand('Gmail', const Color(0xffea4335)),
                availability: 'Developer Preview',
                description:
                    'Lass Assist E-Mails finden und relevante Inhalte in deiner Unterhaltung zusammenfassen.',
                permissions: const [
                  'Betreff und Inhalt freigegebener E-Mails lesen',
                  'Anhänge nur nach Auswahl öffnen',
                  'Keine E-Mail ohne Bestätigung senden',
                ],
                state: state,
                stateLabel: labels[state]!,
                connectLabel: 'Verbindung simulieren',
                onConnect: () =>
                    setState(() => state = KIntegrationConnectionState.pending),
                onRetry: () =>
                    setState(() => state = KIntegrationConnectionState.pending),
                onDisconnect: () => setState(
                  () => state = KIntegrationConnectionState.disconnected,
                ),
              ),
              if (state == KIntegrationConnectionState.pending) ...[
                SizedBox(height: t.spaceControlGap),
                Wrap(
                  spacing: t.spaceControlGap,
                  runSpacing: t.spaceControlGap,
                  children: [
                    KButton(
                      label: 'Erfolg simulieren',
                      onPressed: () => setState(
                        () => state = KIntegrationConnectionState.connected,
                      ),
                    ),
                    KButton(
                      label: 'Fehler simulieren',
                      variant: KButtonVariant.secondary,
                      onPressed: () => setState(
                        () => state = KIntegrationConnectionState.error,
                      ),
                    ),
                    KButton(
                      label: 'Abbrechen',
                      variant: KButtonVariant.ghost,
                      onPressed: () => setState(
                        () => state = KIntegrationConnectionState.disconnected,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class IntegrationConnectionStatesFixture extends StatelessWidget {
  const IntegrationConnectionStatesFixture({super.key});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final labels = [
      'Nicht verbunden',
      'Verbindung wird simuliert',
      'Arbeit · verbunden',
      'Test fehlgeschlagen',
      'Workspace-Freigabe nötig',
    ];
    return _PreviewFrame(
      child: Padding(
        padding: EdgeInsets.all(t.spaceControlInsetInline),
        child: Wrap(
          spacing: t.spaceControlInsetInline,
          runSpacing: t.spaceControlInsetInline,
          children: [
            for (
              var index = 0;
              index < KIntegrationConnectionState.values.length;
              index++
            )
              SizedBox(
                width: 340,
                child: KIntegrationConnectionCard(
                  name:
                      'Linear · ${KIntegrationConnectionState.values[index].name}',
                  icon: _brand('Linear', const Color(0xff8c8dff)),
                  description:
                      'Fest definierter Zustand für Review und Barrierefreiheitsprüfung.',
                  permissions: const [
                    'Ausgewählte Projekte lesen',
                    'Issues als Kontext verwenden',
                  ],
                  state: KIntegrationConnectionState.values[index],
                  stateLabel: labels[index],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class IntegrationAdminCatalogFixture extends StatelessWidget {
  const IntegrationAdminCatalogFixture({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => MediaQuery(
      data: MediaQuery.of(context).copyWith(size: bounds.biggest),
      child: Navigator(
        initialRoute: '/',
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const _IntegrationAdminCatalogCanvas(),
        ),
      ),
    ),
  );
}

class _IntegrationAdminCatalogCanvas extends StatefulWidget {
  const _IntegrationAdminCatalogCanvas();

  @override
  State<_IntegrationAdminCatalogCanvas> createState() =>
      _IntegrationAdminCatalogCanvasState();
}

class _IntegrationAdminCatalogCanvasState
    extends State<_IntegrationAdminCatalogCanvas> {
  late List<KIntegrationCatalogItem> items = [
    for (var index = 0; index < _seedItems().length; index++)
      _catalogFromItem(
        _seedItems()[index],
        index < 2
            ? KIntegrationCatalogState.published
            : index < 5
            ? KIntegrationCatalogState.tested
            : KIntegrationCatalogState.draft,
      ),
  ];
  final drafts = <String, KIntegrationDraft>{};

  static KIntegrationCatalogItem _catalogFromItem(
    KIntegrationItem item,
    KIntegrationCatalogState state,
  ) => KIntegrationCatalogItem(
    id: item.id,
    name: item.name,
    category: _categories
        .where((category) => category.id == item.category)
        .first
        .label,
    description: item.description,
    icon: item.icon,
    endpoint: 'https://mcp.example.test/${item.id}',
    catalogState: state,
  );

  void openEditor([KIntegrationCatalogItem? item]) {
    final id = item?.id ?? 'custom-${DateTime.now().microsecondsSinceEpoch}';
    final initial =
        drafts[id] ??
        (item == null
            ? const KIntegrationDraft.empty()
            : KIntegrationDraft(
                name: item.name,
                description: item.description,
                category: item.category,
                endpoint: item.endpoint,
              ));
    var testFails = false;
    KAdaptiveDialog.show<void>(
      context: context,
      useRootNavigator: false,
      builder: (routeContext) => StatefulBuilder(
        builder: (context, setRouteState) => KIntegrationEditor(
          value: initial,
          initialStatus: item?.catalogState ?? KIntegrationCatalogState.draft,
          existingIcon: item?.icon,
          onPickIcon: icon_picker.pickIntegrationIcon,
          testControls: KButton(
            label: testFails
                ? 'Testausgang: Fehler (ändern)'
                : 'Testausgang: Erfolg (ändern)',
            variant: KButtonVariant.ghost,
            onPressed: () => setRouteState(() => testFails = !testFails),
          ),
          onTest: (_) async => !testFails,
          onCancel: () => Navigator.of(routeContext).pop(),
          onSave: (draft, status) {
            _store(id, draft, status, item?.icon);
            Navigator.of(routeContext).pop();
          },
          onPublish: (draft) {
            _store(id, draft, KIntegrationCatalogState.published, item?.icon);
            Navigator.of(routeContext).pop();
          },
        ),
      ),
    );
  }

  void _store(
    String id,
    KIntegrationDraft draft,
    KIntegrationCatalogState status,
    Widget? previousIcon,
  ) {
    final icon = draft.icon == null
        ? previousIcon ?? Text(draft.name.characters.first.toUpperCase())
        : Image.memory(draft.icon!.bytes, fit: BoxFit.contain);
    final next = KIntegrationCatalogItem(
      id: id,
      name: draft.name,
      description: draft.description,
      category: draft.category,
      endpoint: draft.endpoint,
      icon: icon,
      catalogState: status,
    );
    setState(() {
      drafts[id] = draft;
      items = items.any((entry) => entry.id == id)
          ? [
              for (final entry in items)
                if (entry.id == id) next else entry,
            ]
          : [...items, next];
    });
  }

  @override
  Widget build(BuildContext context) => _PreviewFrame(
    child: KIntegrationAdminCatalog(
      integrations: items,
      onCreate: openEditor,
      onEdit: openEditor,
    ),
  );
}
