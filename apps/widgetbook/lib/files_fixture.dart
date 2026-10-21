import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'files_demo_io.dart';

import 'files_demo_stub.dart'
    if (dart.library.js_interop) 'files_demo_web.dart'
    as io;

part 'files_fixture_dialogs.dart';
part 'files_fixture_view.dart';

class FilesFixture extends StatelessWidget {
  const FilesFixture({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => MediaQuery(
      data: MediaQuery.of(context).copyWith(size: bounds.biggest),
      child: Navigator(
        initialRoute: '/',
        onGenerateRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => const _FilesCanvas()),
      ),
    ),
  );
}

class _FilesCanvas extends StatefulWidget {
  const _FilesCanvas();
  @override
  State<_FilesCanvas> createState() => _FilesFixtureState();
}

class _FilesFixtureState extends State<_FilesCanvas> {
  bool sidebarOpen = false, transferVisible = true, transferCollapsed = false;
  bool sidebarInitialized = false;
  String selected = 'welcome', query = '', notice = '';
  Set<String> expanded = {'notes', 'media'};
  List<String> tabs = ['welcome', 'project', 'code'];
  List<KFileNode> nodes = const [
    KFileNode(
      id: 'notes',
      name: 'Notizen',
      folder: true,
      children: [
        KFileNode(id: 'welcome', name: 'Willkommen.md'),
        KFileNode(id: 'project', name: 'Projektplan.md'),
        KFileNode(id: 'code', name: 'example.ts'),
        KFileNode(
          id: 'archive',
          name: 'Archiv',
          folder: true,
          children: [KFileNode(id: 'archived', name: 'Notiz.md')],
        ),
      ],
    ),
    KFileNode(
      id: 'media',
      name: 'Medien',
      folder: true,
      children: [
        KFileNode(id: 'photo', name: 'Entwurf.svg'),
        KFileNode(id: 'video', name: 'Präsentation.mp4'),
      ],
    ),
  ];
  final documents = <String, String>{
    'welcome':
        '# Willkommen\n\nEin gemeinsamer Platz für Notizen, Dokumente und Medien.\n\nDiese Datei kannst du hier direkt bearbeiten.',
    'project':
        '# Projektplan\n\n## Nächste Schritte\n\n- Entwürfe abstimmen\n- Gemeinsam Inhalte bearbeiten\n- Ergebnisse freigeben',
    'code':
        '// Beispiel mit Syntax-Highlighting\nexport const greet = (name: string): string => {\n  return `Hallo \${name}`;\n};\n',
  };
  final uploads = <String, DemoFile>{};
  final editors = <String, GlobalKey<KCodeEditorState>>{};
  final markdownEditors = <String, GlobalKey<KMarkdownEditorState>>{};
  final recording = <String>{};
  void searchFile() {
    markdownEditors[selected]?.currentState?.openSearch();
    editors[selected]?.currentState?.openSearch();
  }

  List<KFileTransfer> transfers = [
    const KFileTransfer(
      id: 'demo-done',
      name: 'Willkommen.md',
      progress: 1,
      status: 'Abgeschlossen',
    ),
  ];
  Timer? timer;
  void mutate(VoidCallback change) => setState(change);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (sidebarInitialized) return;
    sidebarInitialized = true;
    sidebarOpen = MediaQuery.sizeOf(context).width >= 600;
  }

  @override
  Widget build(BuildContext context) => buildFiles(context);
  List<KFileRecipient> recipients = [
    const KFileRecipient(
      id: 'alex',
      name: 'Alex · alex@example.com',
      permission: 'Kann bearbeiten',
      expires: 'Bis 31. Oktober 2026',
    ),
  ];
  List<KFileNode> flatten(List<KFileNode> items) => [
    for (final node in items) ...[node, ...flatten(node.children)],
  ];
  KFileNode? get current =>
      flatten(nodes).where((node) => node.id == selected).firstOrNull;
  KFileNode? parent(String id) => flatten(
    nodes,
  ).where((node) => node.children.any((child) => child.id == id)).firstOrNull;
  bool writable(KFileNode? node) =>
      node != null && node.folder && !['shared', 'trash'].contains(node.id);
  KFileNode? get uploadTarget =>
      current?.folder == true ? current : parent(selected);
  List<KFileNode> filter(List<KFileNode> items) => [
    for (final node in items)
      if (node.name.toLowerCase().contains(query.toLowerCase()))
        node
      else if (filter(node.children).isNotEmpty)
        copy(node, children: filter(node.children)),
  ];
  KFileNode copy(KFileNode node, {String? name, List<KFileNode>? children}) =>
      KFileNode(
        id: node.id,
        name: name ?? node.name,
        folder: node.folder,
        icon: node.icon,
        detail: node.detail,
        children: children ?? node.children,
      );
  List<KFileNode> update(
    List<KFileNode> items,
    String id,
    KFileNode Function(KFileNode) change,
  ) => [
    for (final node in items)
      node.id == id
          ? change(node)
          : copy(node, children: update(node.children, id, change)),
  ];
  void select(String id) => setState(() {
    selected = id;
    if (flatten(nodes).any((node) => node.id == id && !node.folder) &&
        !tabs.contains(id)) {
      tabs.add(id);
    }
    if (MediaQuery.sizeOf(context).width < 600) sidebarOpen = false;
  });
  void close(List<String> ids) => setState(() {
    final index = tabs.indexOf(selected);
    tabs = tabs.where((id) => !ids.contains(id)).toList();
    if (ids.contains(selected)) {
      selected = tabs.isEmpty ? '' : tabs[index.clamp(0, tabs.length - 1)];
    }
  });
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> upload([KFileNode? target]) async {
    final folder = target ?? uploadTarget;
    if (!writable(folder)) return;
    if (!kIsWeb) {
      setState(
        () => notice =
            'Der lokale Dateidialog ist in diesem Web-Beispiel verfügbar.',
      );
      return;
    }
    try {
      final files = await io.pickFiles();
      if (!mounted || files.isEmpty) return;
      setState(() {
        final additions = <KFileNode>[];
        for (final file in files) {
          final id =
              'upload-${DateTime.now().microsecondsSinceEpoch}-${additions.length}';
          additions.add(KFileNode(id: id, name: file.name));
          uploads[id] = file;
          if (file.type.startsWith('text/') ||
              RegExp(
                r'\.(txt|md|markdown|js|jsx|ts|tsx|json|html|css|xml|csv|yaml|yml|py|rs|go|java|sh|sql)$',
                caseSensitive: false,
              ).hasMatch(file.name)) {
            documents[id] = utf8.decode(file.bytes, allowMalformed: true);
          }
          transfers.add(
            KFileTransfer(
              id: id,
              name: file.name,
              progress: 0,
              status: 'Wird hochgeladen · Demo',
            ),
          );
        }
        nodes = update(
          nodes,
          folder!.id,
          (node) => copy(node, children: [...node.children, ...additions]),
        );
        expanded.add(folder.id);
        transferVisible = true;
        transferCollapsed = false;
        notice = '';
      });
      timer?.cancel();
      timer = Timer.periodic(const Duration(milliseconds: 400), (tick) {
        if (!mounted) {
          tick.cancel();
          return;
        }
        setState(
          () => transfers = transfers.map((item) {
            final progress = math.min(1.0, item.progress + .08);
            return KFileTransfer(
              id: item.id,
              name: item.name,
              progress: progress,
              status: progress >= 1
                  ? 'Abgeschlossen · Demo'
                  : 'Wird hochgeladen · Demo',
            );
          }).toList(),
        );
        if (transfers.every((item) => item.progress >= 1)) tick.cancel();
      });
    } catch (_) {
      if (mounted) {
        setState(() => notice = 'Die Datei konnte nicht gelesen werden.');
      }
    }
  }

  void download(KFileNode node) {
    final text = documents[node.id];
    final file = text != null
        ? DemoFile(
            node.name,
            Uint8List.fromList(utf8.encode(text)),
            'text/plain;charset=utf-8',
          )
        : uploads[node.id];
    if (file == null) {
      setState(
        () => notice =
            'Für diese Beispieldatei ist kein Download-Inhalt hinterlegt.',
      );
      return;
    }
    if (!io.downloadFile(DemoFile(node.name, file.bytes, file.type))) {
      setState(
        () => notice = 'Downloads sind in diesem Web-Beispiel verfügbar.',
      );
    }
  }

  List<KMenuAction> actions(KFileNode node, {bool tree = false}) => [
    if (tree && writable(node))
      KMenuAction(
        id: 'upload',
        label: 'Dateien hochladen',
        icon: KIconName.upload,
        onSelect: () => upload(node),
      ),
    if (!node.folder)
      KMenuAction(
        id: 'download',
        label: 'Herunterladen',
        icon: KIconName.download,
        onSelect: () => download(node),
      ),
    KMenuAction(
      id: 'info',
      label: 'Datei-Info',
      icon: KIconName.info,
      onSelect: () => dialog('info', node),
    ),
    KMenuAction(
      id: 'rename',
      label: 'Umbenennen',
      icon: KIconName.pencil,
      onSelect: () => dialog('rename', node),
    ),
    KMenuAction(
      id: 'share',
      label: 'Freigeben',
      icon: KIconName.share2,
      onSelect: () => dialog('share', node),
    ),
    if (tree)
      KMenuAction(
        id: 'trash',
        label: 'In Papierkorb',
        icon: KIconName.trash,
        destructive: true,
        separatorBefore: true,
        onSelect: () => setState(
          () => notice = 'Demo: ${node.name} in den Papierkorb verschieben',
        ),
      ),
  ];
}

class FilesStorageFixture extends StatelessWidget {
  const FilesStorageFixture({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: KStorageBreakdown(
      title: 'Gesamtverbrauch',
      formatBytes: (bytes) => '${(bytes / 1048576).toStringAsFixed(1)} MB',
      checkedAt: const Text('Demo · zuletzt geprüft: gerade eben'),
      entries: const [
        KStorageEntry(id: 'issues', label: 'Issue-Anhänge', bytes: 12582912),
        KStorageEntry(id: 'files', label: 'Dateien', bytes: 27053260),
        KStorageEntry(id: 'artifacts', label: 'Chat-Artefakte', bytes: 1048576),
        KStorageEntry(id: 'trash', label: 'Papierkorb', bytes: 2097152),
        KStorageEntry(id: 'versions', label: 'Alte Versionen', bytes: 524288),
        KStorageEntry(
          id: 'parts',
          label: 'Unvollständige Uploads',
          bytes: 8388608,
        ),
      ],
    ),
  );
}

class TabStripFixture extends StatefulWidget {
  const TabStripFixture({super.key});
  @override
  State<TabStripFixture> createState() => _TabStripFixtureState();
}

class _TabStripFixtureState extends State<TabStripFixture> {
  List<String> files = [
    'Willkommen.md',
    'Projektplan.md',
    'example.ts',
    'Entwurf.svg',
    'Präsentation.mp4',
  ];
  String selected = 'Willkommen.md';
  void close(List<String> removed) => setState(() {
    files = files.where((file) => !removed.contains(file)).toList();
    if (!files.contains(selected)) selected = files.firstOrNull ?? '';
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      KTabStrip(
        items: [
          for (final name in files)
            KTabStripItem(
              id: name,
              label: name,
              icon: KFileIcon(name: name),
            ),
        ],
        selectedId: selected,
        onSelect: (id) => setState(() => selected = id),
        onClose: (id) => close([id]),
        onReorder: (ids) => setState(() => files = ids),
        menuActions: (item, mobile) => [
          KMenuAction(
            id: 'close',
            label: 'Schließen',
            onSelect: () => close([item.id]),
          ),
          KMenuAction(
            id: 'others',
            label: 'Andere schließen',
            onSelect: () => close(files.where((id) => id != item.id).toList()),
          ),
          if (!mobile)
            KMenuAction(
              id: 'right',
              label: 'Rechts schließen',
              onSelect: () => close(files.sublist(files.indexOf(item.id) + 1)),
            ),
          KMenuAction(
            id: 'all',
            label: 'Alle schließen',
            onSelect: () => close([...files]),
          ),
        ],
      ),
      Expanded(
        child: Center(
          child: Text(selected.isEmpty ? 'Keine Dateien geöffnet' : selected),
        ),
      ),
    ],
  );
}
