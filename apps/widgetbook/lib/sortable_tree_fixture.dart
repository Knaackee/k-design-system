import 'sortable_tree_name_editor.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

typedef Offer = ({String kind, String detail, String price});
typedef Node = KSortableTreeNode<Offer>;
const _initial = <Node>[
  Node(
    id: 'hair',
    label: 'Schnitt & Styling',
    children: [
      Node(
        id: 'cut',
        label: 'Haarschnitt',
        data: (kind: 'service', detail: '45 Min.', price: '48 €'),
      ),
      Node(
        id: 'styling',
        label: 'Styling',
        data: (kind: 'service', detail: '30 Min.', price: '32 €'),
      ),
    ],
  ),
  Node(
    id: 'care',
    label: 'Farbe & Pflege',
    children: [
      Node(
        id: 'color',
        label: 'Farbe & Pflege',
        data: (kind: 'service', detail: '90 Min.', price: 'ab 85 €'),
      ),
      Node(
        id: 'shampoo',
        label: 'Pflegeshampoo',
        data: (kind: 'product', detail: '250 ml', price: '18 €'),
      ),
      Node(
        id: 'conditioner',
        label: 'Conditioner',
        data: (kind: 'product', detail: '200 ml', price: '22 €'),
      ),
    ],
  ),
  Node(id: 'new', label: 'Neue Kategorie', children: []),
];

class SortableTreeFixture extends StatefulWidget {
  const SortableTreeFixture({this.kind = 'categories', super.key});
  final String kind;
  @override
  State<SortableTreeFixture> createState() => _SortableTreeFixtureState();
}

class _SortableTreeFixtureState extends State<SortableTreeFixture> {
  late List<Node> nodes = widget.kind == 'empty'
      ? []
      : widget.kind == 'flat'
      ? [
          for (final e in flattenKSortableTree(_initial))
            if (e.node.children == null) e.node,
        ]
      : widget.kind == 'ungrouped'
      ? [
          for (final n in _initial)
            n.children == null
                ? n
                : n.copyWith(
                    children: n.children!
                        .where((c) => c.data?.kind != 'product')
                        .toList(),
                  ),
          for (final e in flattenKSortableTree(_initial))
            if (e.node.data?.kind == 'product') e.node,
        ]
      : widget.kind == 'deep'
      ? [
          const Node(
            id: 'catalog',
            label: 'Mein Angebot',
            children: [
              Node(id: 'beauty', label: 'Beauty & Pflege', children: _initial),
            ],
          ),
        ]
      : _initial;
  late Set<String> expanded = {
    for (final e in flattenKSortableTree(nodes))
      if (e.node.children != null) e.node.id,
  };
  late String mode = widget.kind == 'flat' ? 'flat' : 'categories';
  ({List<Node> nodes, Set<String> expanded, String mode})? previous;
  KToastController? toast;
  @override
  void dispose() {
    toast?.dismiss();
    super.dispose();
  }

  void change(List<Node> next, String message, {String? nextMode}) {
    previous = (nodes: nodes, expanded: {...expanded}, mode: mode);
    setState(() {
      nodes = next;
      mode = nextMode ?? mode;
    });
    toast?.dismiss();
    toast = KToast.show(
      context: context,
      title: KText(message, variant: KTextVariant.bodySmall),
      tone: KToastTone.success,
      position: KNotificationPosition.bottomCenter,
      duration: const Duration(seconds: 8),
      action: KButton(
        label: 'Rückgängig',
        variant: KButtonVariant.ghost,
        onPressed: undo,
      ),
    );
  }

  void undo() {
    final old = previous;
    if (old == null) return;
    setState(() {
      nodes = old.nodes;
      expanded = old.expanded;
      mode = old.mode;
      previous = null;
    });
    toast?.dismiss();
  }

  List<Node> mapNodes(List<Node> values, String id, Node? replacement) => [
    for (final n in values)
      if (n.id == id) ...[
        ?replacement,
      ] else if (n.children != null)
        n.copyWith(children: mapNodes(n.children!, id, replacement))
      else
        n,
  ];
  String kindLabel(Node node) => node.children != null
      ? 'Kategorie'
      : node.data?.kind == 'product'
      ? 'Produkt'
      : 'Leistung';

  Future<void> edit(Node node, {bool fresh = false}) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SortableTreeNameEditor(name: node.label, fresh: fresh),
    );
    if (!mounted || result == null) return;
    final item = node.copyWith(label: result);
    change(
      fresh ? [...nodes, item] : mapNodes(nodes, node.id, item),
      '${kindLabel(item)} „${item.label}“ ${fresh ? 'hinzugefügt' : 'umbenannt'}',
    );
  }

  Future<void> remove(Node node) async {
    final accepted = await KAlertDialog.show(
      context: context,
      title: KText(
        node.children == null ? 'Eintrag entfernen?' : 'Kategorie entfernen?',
      ),
      description: KText(
        '„${node.label}“ wird entfernt.${node.children?.isNotEmpty == true ? ' Alle enthaltenen Kategorien und Angebote werden ebenfalls entfernt.' : ''}',
      ),
      destructive: true,
      cancelLabel: 'Abbrechen',
      actionLabel: 'Entfernen',
    );
    if (!mounted || accepted != true) return;
    change(
      mapNodes(nodes, node.id, null),
      '${kindLabel(node)} „${node.label}“ entfernt',
    );
  }

  void regroup(String value) {
    final leaves = [
      for (final e in flattenKSortableTree(nodes))
        if (e.node.children == null) e.node,
    ];
    final next = value == 'flat'
        ? leaves
        : value == 'kind'
        ? <Node>[
            Node(
              id: 'services',
              label: 'Dienstleistungen',
              children: leaves.where((n) => n.data?.kind == 'service').toList(),
            ),
            Node(
              id: 'products',
              label: 'Produkte',
              children: leaves.where((n) => n.data?.kind == 'product').toList(),
            ),
          ]
        : <Node>[
            Node(
              id: 'hair',
              label: 'Schnitt & Styling',
              children: leaves
                  .where((n) => ['cut', 'styling'].contains(n.id))
                  .toList(),
            ),
            Node(
              id: 'care',
              label: 'Farbe & Pflege',
              children: leaves
                  .where((n) => !['cut', 'styling'].contains(n.id))
                  .toList(),
            ),
            const Node(id: 'new', label: 'Neue Kategorie', children: []),
          ];
    change(next, 'Anordnung geändert', nextMode: value);
    setState(
      () => expanded = {
        for (final e in flattenKSortableTree(next))
          if (e.node.children != null) e.node.id,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final large = MediaQuery.textScalerOf(context).scale(1) >= 2;
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ['mobile', 'ungrouped'].contains(widget.kind) ? 390 : 768,
          ),
          child: Padding(
            padding: EdgeInsets.all(t.spaceCardPadding),
            child: KStack(
              gap: KLayoutGap.control,
              align: KLayoutAlign.stretch,
              children: [
                KStack(
                  gap: KLayoutGap.control,
                  align: KLayoutAlign.stretch,
                  children: [
                    const KText(
                      'Angebote ordnen',
                      variant: KTextVariant.heading3,
                    ),
                    KText(
                      'Ziehe am Griff, um deine Angebote zu ordnen.',
                      variant: KTextVariant.bodySmall,
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (widget.kind != 'deep')
                      Expanded(
                        child: KSelect(
                          value: mode,
                          selectionLabel: 'Anordnung',
                          onChanged: (value) {
                            if (value != null) regroup(value);
                          },
                          options: const [
                            KSelectOption(
                              value: 'categories',
                              label: 'Nach Themen',
                              icon: KIconName.folders,
                            ),
                            KSelectOption(
                              value: 'kind',
                              label: 'Leistungen & Produkte',
                              icon: KIconName.listTree,
                            ),
                            KSelectOption(
                              value: 'flat',
                              label: 'Ohne Kategorien',
                              icon: KIconName.list,
                            ),
                          ],
                        ),
                      ),
                    SizedBox(width: t.spaceControlGap),
                    KIconButton(
                      label: 'Rückgängig',
                      icon: KIconName.undo2,
                      iconContent: const KIcon(
                        KIconName.undo2),
                      onPressed: previous == null ? null : undo,
                    ),
                  ],
                ),
                KSortableTree<Offer>(
                  nodes: nodes,
                  // Large text: the price takes its own line (numbers never
                  // truncate), so rows reserve three scaled lines.
                  minRowHeight: large
                      ? MediaQuery.textScalerOf(context).scale(
                              t.fontBodySmallLineHeight * 2 +
                                  t.fontCaptionLineHeight,
                            ) +
                            t.spaceControlGap * 2 +
                            t.borderWidthDefault * 2
                      : t.sizeControl * 2 + t.spaceControlGap * 3,
                  ariaLabel: 'Kategorien und Angebote',
                  maxDepth: widget.kind == 'deep' ? null : 1,
                  canMove: (move) =>
                      widget.kind == 'deep' ||
                      flattenKSortableTree(nodes)
                              .firstWhere((e) => e.node.id == move.id)
                              .node
                              .children ==
                          null ||
                      move.parentId == null,
                  labels: const KSortableTreeLabels(
                    drag: 'Verschieben',
                    expand: 'Aufklappen',
                    collapse: 'Zuklappen',
                    move: 'Reihenfolge ändern',
                    up: 'Nach oben',
                    down: 'Nach unten',
                    moveTo: 'Verschieben',
                    root: 'Ohne Kategorie',
                    drop: 'Hier ablegen',
                    empty: 'Noch keine Einträge',
                  ),
                  expandedIds: expanded,
                  onExpandedChange: (ids) => setState(() => expanded = ids),
                  ungroupedLabel: mode == 'flat' ? null : 'Ohne Kategorie',
                  defaultUngroupedExpanded: widget.kind != 'ungrouped',
                  onMove: (move) {
                    final node = flattenKSortableTree(
                      nodes,
                    ).firstWhere((e) => e.node.id == move.id).node;
                    final target = flattenKSortableTree(
                      nodes,
                    ).where((e) => e.node.id == move.parentId).firstOrNull;
                    change(
                      moveKSortableTree(nodes, move),
                      '„${node.label}“ ${target == null ? 'umsortiert' : 'in „${target.node.label}“ einsortiert'}',
                    );
                  },
                  getActions: (c) => [
                    KMenuAction(
                      id: 'edit',
                      label: 'Bearbeiten',
                      iconContent: const KIcon(
                        KIconName.pencil),
                      onSelect: () => edit(c.node),
                    ),
                    KMenuAction(
                      id: 'remove',
                      label: 'Entfernen',
                      destructive: true,
                      iconContent: const KIcon(
                        KIconName.trash),
                      onSelect: () => remove(c.node),
                    ),
                  ],
                  renderContent: (context, c) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (large) ...[
                        KText(
                          c.node.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          variant: KTextVariant.bodySmall,
                        ),
                        if (c.node.data != null)
                          KText(
                            c.node.data!.price,
                            variant: KTextVariant.bodySmall,
                          ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: KText(
                                c.node.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                variant: KTextVariant.bodySmall,
                              ),
                            ),
                            if (c.node.data != null)
                              KText(
                                c.node.data!.price,
                                variant: KTextVariant.bodySmall,
                              ),
                          ],
                        ),
                      if (c.node.children != null && !c.expanded)
                        KText(
                          '${c.node.children!.length} Einträge',
                          variant: KTextVariant.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: t.colorTextMuted),
                        ),
                      if (c.node.data != null)
                        // Rows have a fixed extent for drag motion: secondary
                        // lines stay single-line and truncate.
                        KText(
                          c.node.data!.detail,
                          variant: KTextVariant.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: t.colorTextMuted),
                        ),
                    ],
                  ),
                ),
                KInline(
                  gap: KLayoutGap.action,
                  wrap: true,
                  children: [
                    KButton(
                      label: 'Kategorie',
                      variant: KButtonVariant.secondary,
                      leading: const KIcon(
                        KIconName.folderPlus),
                      onPressed: () => edit(
                        Node(
                          id: 'new-${DateTime.now().microsecondsSinceEpoch}',
                          label: '',
                          children: const [],
                        ),
                        fresh: true,
                      ),
                    ),
                    KButton(
                      label: 'Angebot',
                      variant: KButtonVariant.ghost,
                      leading: const KIcon(KIconName.plus),
                      onPressed: () => edit(
                        Node(
                          id: 'new-${DateTime.now().microsecondsSinceEpoch}',
                          label: '',
                          data: (
                            kind: 'service',
                            detail: 'Dienstleistung',
                            price: '',
                          ),
                        ),
                        fresh: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
