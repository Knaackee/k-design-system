part of 'files_fixture.dart';

extension _FilesView on _FilesFixtureState {
  Widget panel(KFileNode node) {
    if (node.folder) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (node.children.isEmpty) const Text('Dieser Ordner ist leer.'),
          for (final child in node.children)
            Align(
              alignment: Alignment.centerLeft,
              child: KButton(
                label: child.name,
                variant: KButtonVariant.ghost,
                leading: KFileIcon(name: child.name),
                onPressed: () => select(child.id),
              ),
            ),
        ],
      );
    }
    if (node.id == 'photo') {
      return const Center(
        child: AspectRatio(aspectRatio: 1.5, child: _PhotoPreview()),
      );
    }
    if (node.id == 'video') {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KIcon(KIconName.fileVideoCamera, size: 48),
            SizedBox(height: 12),
            Text('Video-Vorschau'),
            Text('In diesem Beispiel ist keine Videodatei hinterlegt.'),
          ],
        ),
      );
    }
    if (documents.containsKey(node.id) &&
        (node.name.endsWith('.md') || node.name.endsWith('.markdown'))) {
      return KMarkdownEditor(
        key: markdownEditors.putIfAbsent(
          node.id,
          () => GlobalKey<KMarkdownEditorState>(),
        ),
        markdown: documents[node.id]!,
        minHeight: 0,
        showModeSwitcher: false,
        showSearchButton: false,
        contentMaxWidth: Theme.of(
          context,
        ).extension<KDesignTokens>()!.layoutContentWidth,
        showFloatingToolbar: false,
        dictationState: recording.contains(node.id)
            ? KDictationState.recording
            : KDictationState.ready,
        dictationLabel: recording.contains(node.id)
            ? 'Demo-Aufnahme beenden'
            : 'Spracheingabe ausprobieren (Demo)',
        onDictationPressed: () => mutate(() {
          if (recording.remove(node.id)) {
            markdownEditors[node.id]?.currentState?.insertDictation(
              'Hier steht der diktierte Beispieltext.',
            );
          } else {
            recording.add(node.id);
          }
        }),
        onChanged: (value, _) => documents[node.id] = value,
      );
    }
    if (documents.containsKey(node.id)) {
      return KCodeEditor(
        key: editors.putIfAbsent(node.id, () => GlobalKey<KCodeEditorState>()),
        value: documents[node.id]!,
        minHeight: 0,
        showSearchButton: false,
        contentMaxWidth: Theme.of(
          context,
        ).extension<KDesignTokens>()!.layoutContentWidth,
        embedded: true,
        lineWrapping: node.name.endsWith('.md') || node.name.endsWith('.txt'),
        semanticLabel: '${node.name} bearbeiten',
        language: node.name.endsWith('.ts')
            ? KCodeLanguage.typescript
            : node.name.endsWith('.js')
            ? KCodeLanguage.javascript
            : node.name.endsWith('.json')
            ? KCodeLanguage.json
            : node.name.endsWith('.md')
            ? KCodeLanguage.markdown
            : KCodeLanguage.plain,
        onChanged: (value, _) => documents[node.id] = value,
      );
    }
    final file = uploads[node.id];
    if (file != null && file.type.startsWith('image/')) {
      return Center(child: Image.memory(file.bytes, fit: BoxFit.contain));
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KFileIcon(name: node.name, size: 48),
          const SizedBox(height: 12),
          Text(node.name),
          if (file != null)
            Text('Lokal hinzugefügt · ${file.bytes.length} Bytes'),
          KButton(
            label: 'Herunterladen',
            variant: KButtonVariant.secondary,
            onPressed: () => download(node),
          ),
        ],
      ),
    );
  }

  Widget buildFiles(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final all = flatten(nodes);
    return DefaultTextStyle.merge(
      style: TextStyle(fontSize: t.fontControlSize),
      child: LayoutBuilder(
        builder: (context, bounds) => Stack(
          children: [
            KFilesWorkspace(
              constrainContentWidth: false,
              sidebarOpen: sidebarOpen,
              onSidebarOpenChange: (value) => mutate(() => sidebarOpen = value),
              tabs: KTabStrip(
                items: [
                  for (final id in tabs)
                    if (all.any((node) => node.id == id))
                      KTabStripItem(
                        id: id,
                        label: all.firstWhere((node) => node.id == id).name,
                        icon: KFileIcon(
                          name: all.firstWhere((node) => node.id == id).name,
                        ),
                      ),
                ],
                selectedId: selected,
                onSelect: select,
                onClose: (id) => close([id]),
                onReorder: (ids) => mutate(() => tabs = ids),
                menuActions: (item, mobile) => [
                  ...actions(all.firstWhere((node) => node.id == item.id)),
                  KMenuAction(
                    id: 'close',
                    label: 'Schließen',
                    separatorBefore: true,
                    onSelect: () => close([item.id]),
                  ),
                  KMenuAction(
                    id: 'others',
                    label: 'Andere schließen',
                    onSelect: () =>
                        close(tabs.where((id) => id != item.id).toList()),
                  ),
                  if (!mobile)
                    KMenuAction(
                      id: 'right',
                      label: 'Rechts schließen',
                      onSelect: () =>
                          close(tabs.sublist(tabs.indexOf(item.id) + 1)),
                    ),
                  KMenuAction(
                    id: 'all',
                    label: 'Alle schließen',
                    onSelect: () => close([...tabs]),
                  ),
                ],
              ),
              actions: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [
                  if (!mobile) ...[
                    KIconButton(
                      label: 'In Datei suchen',
                      icon: KIconName.search,
                      onPressed: documents.containsKey(selected)
                          ? searchFile
                          : null,
                    ),
                    KIconButton(
                      label: 'Freigeben',
                      icon: KIconName.share2,
                      onPressed: current == null
                          ? null
                          : () => dialog('share', current!),
                    ),
                    KIconButton(
                      label: 'Im Chat referenzieren',
                      icon: KIconName.messageCircle,
                      onPressed: current == null
                          ? null
                          : () => dialog('reference', current!),
                    ),
                  ],
                  KMenuButton(
                    label: 'Weitere Dateiaktionen',
                    overflow: true,
                    alignEnd: true,
                    actions: [
                      if (mobile) ...[
                        KMenuAction(
                          id: 'search-file',
                          label: 'In Datei suchen',
                          icon: KIconName.search,
                          onSelect: documents.containsKey(selected)
                              ? searchFile
                              : null,
                        ),
                        KMenuAction(
                          id: 'reference-file',
                          label: 'Im Chat referenzieren',
                          icon: KIconName.messageCircle,
                          onSelect: current == null
                              ? null
                              : () => dialog('reference', current!),
                        ),
                      ],
                      if (current != null) ...actions(current!),
                      KMenuAction(
                        id: 'transfers',
                        label: 'Übertragungen',
                        icon: KIconName.arrowDownUp,
                        onSelect: () => mutate(() {
                          transferVisible = true;
                          transferCollapsed = false;
                        }),
                      ),
                    ],
                  ),
                ],
              ),
              search: KSearchField(
                label: 'Dateien durchsuchen',
                placeholder: 'Dateien durchsuchen…',
                onChanged: (value) => mutate(() => query = value),
              ),
              sidebarHeader: KSidebarItem(
                label: 'Zurück zur App',
                leading: const KIcon(KIconName.arrowLeft),
                onPressed: () => mutate(() => notice = 'Demo: zurück zur App'),
              ),
              sidebarFooter: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KSidebarItem(
                    label: 'Mit mir geteilt',
                    leading: const KIcon(KIconName.users),
                    onPressed: () =>
                        mutate(() => notice = 'Demo: Mit mir geteilt'),
                  ),
                  KSidebarItem(
                    label: 'Papierkorb',
                    leading: const KIcon(KIconName.trash),
                    onPressed: () => mutate(() => notice = 'Demo: Papierkorb'),
                  ),
                  KSidebarItem(
                    label: 'Dateien hochladen',
                    leading: const KIcon(KIconName.upload),
                    disabled: !writable(uploadTarget),
                    onPressed: upload,
                  ),
                ],
              ),
              navigation: KFileTree(
                nodes: query.isEmpty ? nodes : filter(nodes),
                expandedIds: query.isEmpty
                    ? expanded
                    : {
                        ...expanded,
                        ...all
                            .where((node) => node.folder)
                            .map((node) => node.id),
                      },
                selectedId: selected,
                onSelect: select,
                onExpandedChange: (value) => mutate(() => expanded = value),
                emptyContent: const Text('Keine Dateien gefunden'),
                menuActions: (node) => actions(node, tree: true),
              ),
              child: Column(
                children: [
                  if (notice.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.all(t.spaceControlGap),
                      child: Text(notice),
                    ),
                  Expanded(
                    child: current == null
                        ? const Center(
                            child: Text('Öffne eine Datei in der Sidebar.'),
                          )
                        : Stack(
                            children: [
                              for (final node in all.where(
                                (node) =>
                                    tabs.contains(node.id) ||
                                    node.folder && node.id == selected,
                              ))
                                Positioned.fill(
                                  child: Offstage(
                                    offstage: node.id != selected,
                                    child: panel(node),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            if (transferVisible)
              Positioned(
                right: 16,
                bottom:
                    current != null &&
                        (current!.name.endsWith('.md') ||
                            current!.name.endsWith('.markdown'))
                    ? 16 +
                          t.spaceControlInsetInline +
                          t.sizeHitTarget +
                          4 * t.spaceControlGap +
                          t.spaceSmallInset
                    : 16,
                child: SizedBox(
                  width: math.min(360, math.max(0, bounds.maxWidth - 32)),
                  child: KFileTransferPanel(
                    items: transfers,
                    collapsed: transferCollapsed,
                    label: 'Übertragungen',
                    onCollapsedChange: (value) =>
                        mutate(() => transferCollapsed = value),
                    onClose: () => mutate(() => transferVisible = false),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _PhotoPainter());
}

class _PhotoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xff252830),
    );
    canvas.drawCircle(
      Offset(size.width * .35, size.height * .5),
      size.height * .2875,
      Paint()..color = const Color(0xffaeb8c9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .4667,
          size.height * .2125,
          size.width * .2917,
          size.height * .575,
        ),
        Radius.circular(size.width * .0267),
      ),
      Paint()..color = const Color(0xff64748b),
    );
  }

  @override
  bool shouldRepaint(_PhotoPainter oldDelegate) => false;
}
