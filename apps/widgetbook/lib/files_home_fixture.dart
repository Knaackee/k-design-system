import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

const _entries = [
  KFilesHomeEntry(
    id: 'welcome',
    name: 'Willkommen.md',
    parentLabel: 'Notizen',
    updatedLabel: '19. Okt., 10:30',
  ),
  KFilesHomeEntry(
    id: 'photo',
    name: 'Entwurf.png',
    parentLabel: 'Medien',
    updatedLabel: '18. Okt., 16:45',
  ),
  KFilesHomeEntry(
    id: 'code',
    name: 'example.ts',
    parentLabel: 'Notizen',
    updatedLabel: '17. Okt., 09:00',
  ),
];

/// Deterministic dashboard and complete workspace with host-owned state.
class FilesHomeFixture extends StatefulWidget {
  const FilesHomeFixture({
    this.empty = false,
    this.workspace = false,
    super.key,
  });
  final bool empty, workspace;
  @override
  State<FilesHomeFixture> createState() => _FilesHomeFixtureState();
}

class _FilesHomeFixtureState extends State<FilesHomeFixture> {
  KFilesHomeCategory filter = KFilesHomeCategory.all;
  String selected = 'home', notice = '';
  bool sidebarOpen = false;
  Set<String> expanded = {'notes', 'media'};
  List<String> tabs = [];
  String markdown =
      '# Willkommen\n\nEin gemeinsamer Platz für Notizen, Dokumente und Medien.\n\nDiese Datei kannst du hier direkt bearbeiten.';
  String code = 'export const greeting = "Hallo Welt";';
  late List<KFilesHomeEntry> entries = widget.empty ? [] : [..._entries];
  void open(String id) => setState(() {
    selected = id;
    if (id != 'home' && !tabs.contains(id)) {
      tabs.add(id);
    }
    if (MediaQuery.sizeOf(context).width < 600) sidebarOpen = false;
  });
  void create() => setState(() {
    final id = 'note-${entries.length}';
    entries.add(
      KFilesHomeEntry(
        id: id,
        name: 'Neue Datei.md',
        parentLabel: 'Dateien',
        updatedLabel: '19. Okt., 10:30',
      ),
    );
    notice = 'Neue Datei erstellt';
  });
  Widget addMenu(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return KMenuButton(
      label: 'Datei hinzufügen',
      fullWidth: true,
      triggerContent: Padding(
        padding: EdgeInsets.symmetric(horizontal: t.spaceHairline * 8),
        child: Row(
          children: [
            SizedBox(
              width: t.componentSidebarLeadingWidth,
              child: const Center(child: KIcon(KIconName.filePlus)),
            ),
            SizedBox(width: t.spaceControlGap),
            const Expanded(child: KText('Datei hinzufügen')),
            SizedBox(width: t.spaceControlGap),
            const KIcon(KIconName.chevronDown),
          ],
        ),
      ),
      actions: [
        KMenuAction(
          id: 'create-file',
          label: 'Neue Datei',
          icon: KIconName.filePlus,
          onSelect: create,
        ),
        KMenuAction(
          id: 'create-folder',
          label: 'Neuer Ordner',
          icon: KIconName.folderPlus,
          onSelect: () => setState(() => notice = 'Neuer Ordner erstellt'),
        ),
        KMenuAction(
          id: 'upload',
          label: 'Hochladen',
          icon: KIconName.upload,
          onSelect: () => setState(() => notice = 'Dateiauswahl angefordert'),
        ),
      ],
    );
  }

  Widget home() => KFilesHome(
    files: entries,
    filter: filter,
    onFilterChange: (value) => setState(() => filter = value),
    onOpen: widget.workspace
        ? open
        : (id) => setState(
            () => notice =
                'Geöffnet: ${entries.firstWhere((entry) => entry.id == id).name}',
          ),
    onCreateFile: create,
    onCreateFolder: () => setState(() => notice = 'Neuer Ordner erstellt'),
    onUpload: () => setState(() => notice = 'Dateiauswahl angefordert'),
  );
  Widget content() {
    if (selected == 'home') return home();
    if (selected == 'photo') {
      return Center(
        child: InteractiveViewer(
          child: SvgPicture.string(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 400"><rect width="600" height="400" fill="#252830"/><circle cx="210" cy="200" r="115" fill="#aeb8c9"/><rect x="280" y="85" width="175" height="230" rx="16" fill="#64748b"/></svg>',
            width: 600,
            height: 400,
            semanticsLabel: 'Entwurf.png – deterministische Bildvorschau',
          ),
        ),
      );
    }
    if (selected == 'code') {
      return KCodeEditor(
        value: code,
        minHeight: 0,
        embedded: true,
        language: KCodeLanguage.typescript,
        onChanged: (value, _) => code = value,
      );
    }
    return KMarkdownEditor(
      key: ValueKey(selected),
      markdown: markdown,
      minHeight: 0,
      onChanged: (value, _) => markdown = value,
    );
  }

  @override
  Widget build(BuildContext context) => Material(
    child: Column(
      children: [
        if (notice.isNotEmpty)
          Padding(padding: const EdgeInsets.all(8), child: KText(notice)),
        Expanded(
          child: widget.workspace
              ? KFilesWorkspace(
                  constrainContentWidth: false,
                  sidebarOpen: sidebarOpen,
                  onSidebarOpenChange: (value) =>
                      setState(() => sidebarOpen = value),
                  sidebarHeader: const KText('Dateien'),
                  sidebarFooter: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      addMenu(context),
                      KSidebarItem(
                        label: 'Papierkorb',
                        leading: const KIcon(KIconName.trash),
                        onPressed: () =>
                            setState(() => notice = 'Papierkorb geöffnet'),
                      ),
                    ],
                  ),
                  header: SizedBox(
                    height: 56,
                    child: Center(
                      child: KButton(
                        label: 'Dateien',
                        variant: KButtonVariant.ghost,
                        onPressed: () => open('home'),
                      ),
                    ),
                  ),
                  navigation: KFileTree(
                    nodes: [
                      for (final folder in ['Notizen', 'Medien'])
                        KFileNode(
                          id: folder == 'Notizen' ? 'notes' : 'media',
                          name: folder,
                          folder: true,
                          children: [
                            for (final entry in entries.where(
                              (entry) => entry.parentLabel == folder,
                            ))
                              KFileNode(id: entry.id, name: entry.name),
                          ],
                        ),
                      for (final entry in entries.where(
                        (entry) => entry.parentLabel == 'Dateien',
                      ))
                        KFileNode(id: entry.id, name: entry.name),
                    ],
                    expandedIds: expanded,
                    onExpandedChange: (value) =>
                        setState(() => expanded = value),
                    selectedId: selected,
                    onSelect: open,
                  ),
                  tabs: tabs.isEmpty
                      ? null
                      : KTabStrip(
                          items: [
                            for (final id in tabs)
                              KTabStripItem(
                                id: id,
                                label: entries
                                    .firstWhere((entry) => entry.id == id)
                                    .name,
                                icon: KFileIcon(
                                  name: entries
                                      .firstWhere((entry) => entry.id == id)
                                      .name,
                                ),
                              ),
                          ],
                          selectedId: selected,
                          onSelect: open,
                          onReorder: (ids) => setState(() => tabs = ids),
                          onClose: (id) => setState(() {
                            tabs.remove(id);
                            if (selected == id) {
                              selected = tabs.lastOrNull ?? 'home';
                            }
                          }),
                        ),
                  child: content(),
                )
              : home(),
        ),
      ],
    ),
  );
}
