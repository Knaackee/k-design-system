part of 'files_fixture.dart';

extension _FilesDialogs on _FilesFixtureState {
  Future<void> dialog(String kind, KFileNode node) async {
    mutate(() => sidebarOpen = false);
    final name = TextEditingController(text: node.name);
    await KAdaptiveDialog.show<void>(
      context: context,
      useRootNavigator: false,
      maxWidth: 460,
      builder: (route) => StatefulBuilder(
        builder: (route, refresh) {
          final title = switch (kind) {
            'rename' => 'Umbenennen',
            'share' => 'Freigeben',
            'reference' => 'Im Chat referenzieren',
            _ => 'Datei-Info',
          };
          return KAdaptiveDialog(
            maxWidth: 460,
            expandBody: false,
            title: Text(title),
            description: kind == 'share' ? Text(node.name) : null,
            onClose: () => Navigator.pop(route),
            actions: kind == 'rename'
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      KButton(
                        label: 'Abbrechen',
                        variant: KButtonVariant.ghost,
                        onPressed: () => Navigator.pop(route),
                      ),
                      const SizedBox(width: 8),
                      KButton(
                        label: 'Speichern',
                        onPressed: () {
                          if (name.text.trim().isEmpty) return;
                          mutate(
                            () => nodes = update(
                              nodes,
                              node.id,
                              (item) => copy(item, name: name.text.trim()),
                            ),
                          );
                          Navigator.pop(route);
                        },
                      ),
                    ],
                  )
                : null,
            child: kind == 'rename'
                ? KInput(
                    controller: name,
                    label: 'Name',
                    autofocus: true,
                    onSubmitted: (_) {
                      if (name.text.trim().isEmpty) return;
                      mutate(
                        () => nodes = update(
                          nodes,
                          node.id,
                          (item) => copy(item, name: name.text.trim()),
                        ),
                      );
                      Navigator.pop(route);
                    },
                  )
                : kind == 'share'
                ? KFileShare(
                    recipients: recipients,
                    hasLink: true,
                    onInvite: (email, permission) {
                      mutate(
                        () => recipients.add(
                          KFileRecipient(
                            id: email,
                            name: email,
                            permission: permission == 'edit'
                                ? 'Kann bearbeiten'
                                : 'Kann ansehen',
                          ),
                        ),
                      );
                      refresh(() {});
                    },
                    onRevoke: (id) {
                      mutate(
                        () => recipients.removeWhere((item) => item.id == id),
                      );
                      refresh(() {});
                    },
                    onCopyLink: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: 'https://example.com/files/${node.id}',
                        ),
                      );
                      mutate(() => notice = 'Demo-Link kopiert');
                      Navigator.pop(route);
                    },
                  )
                : kind == 'reference'
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('${node.name} in einem Chat referenzieren'),
                      const SizedBox(height: 12),
                      for (final agent in [
                        'Arbeitsassistent',
                        'Recherche',
                        'Programmierung',
                      ])
                        KButton(
                          label: agent,
                          variant: KButtonVariant.ghost,
                          leading: const KIcon(KIconName.messageCircle),
                          onPressed: () {
                            mutate(
                              () => notice =
                                  'Demo: ${node.name} in $agent referenzieren',
                            );
                            Navigator.pop(route);
                          },
                        ),
                    ],
                  )
                : KFileInfo(
                    name: node.name,
                    properties: {
                      'Typ': node.folder
                          ? 'Ordner'
                          : node.name.split('.').last.toUpperCase(),
                      'Größe': uploads[node.id] != null
                          ? '${uploads[node.id]!.bytes.length} Bytes'
                          : const {
                                  'welcome': '2 KB',
                                  'project': '8 KB',
                                  'photo': '1,8 KB',
                                  'video': '24 MB',
                                }[node.id] ??
                                '2 KB',
                      'Speicherort': parent(node.id) == null
                          ? 'Dateien'
                          : 'Dateien / ${parent(node.id)!.name}',
                      'Geändert': '10. Oktober 2026, 14:00',
                    },
                  ),
          );
        },
      ),
    );
    name.dispose();
  }
}
