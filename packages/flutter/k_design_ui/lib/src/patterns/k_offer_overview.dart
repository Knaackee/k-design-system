import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../../k_design_ui.dart';
part 'k_offer_drag.dart';
part 'k_offer_overview_controls.dart';

/// Host-owned data and actions for the shared offer overview.
class KOfferEntry {
  const KOfferEntry({
    required this.id,
    required this.name,
    required this.kind,
    required this.price,
    required this.detail,
    required this.onEdit,
    this.image,
    this.archived = false,
    this.actions = const [],
  });
  final String id, name, kind, price, detail;
  final Widget? image;
  final bool archived;
  final VoidCallback onEdit;
  final List<KMenuAction> actions;
}

class KOfferCategory {
  const KOfferCategory({
    required this.id,
    required this.name,
    required this.entries,
    required this.onAdd,
    this.description = '',
    this.color,
    this.actions = const [],
  });
  final String id, name, description;
  final Color? color;
  final List<KOfferEntry> entries;
  final VoidCallback onAdd;
  final List<KMenuAction> actions;
}

/// Search, filter and long-press ordering; persistence remains with the host.
class KOfferOverview extends StatefulWidget {
  const KOfferOverview({
    required this.categories,
    required this.onAddCategory,
    required this.newActions,
    this.onReorderCategories,
    this.onReorderEntries,
    this.onMoveEntry,
    this.translate,
    this.footer,
    this.settings,
    this.enabled = true,
    super.key,
  });
  final List<KOfferCategory> categories;
  final VoidCallback onAddCategory;
  final List<KMenuAction> newActions;
  final void Function(List<String> ids, int from, int to)? onReorderCategories;
  final void Function(String category, List<String> ids, int from, int to)?
  onReorderEntries;
  final void Function(String itemId, String categoryId, String? beforeId)?
  onMoveEntry;
  final String Function(String source)? translate;
  final Widget? footer, settings;
  final bool enabled;
  @override
  State<KOfferOverview> createState() => _KOfferOverviewState();
}

class _KOfferOverviewState extends State<KOfferOverview> {
  final _search = TextEditingController();
  String _filter = 'all';
  void _selectFilter(String value) => setState(() => _filter = value);
  String _t(String source) => widget.translate?.call(source) ?? source;
  final _collapsed = <String>{};
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool matches(KOfferEntry e) =>
      (_filter == 'archived' ? e.archived : !e.archived) &&
      (_filter == 'all' || _filter == 'archived' || e.kind == _filter) &&
      e.name.toLowerCase().contains(_search.text.trim().toLowerCase());
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final entries = widget.categories.expand((c) => c.entries).toList();
    final active = entries.where((e) => !e.archived).toList();
    final groups = widget.categories
        .where(
          (c) =>
              c.entries.any(matches) ||
              (_search.text.isEmpty && _filter == 'all'),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KText(
                    _t('Angebot'),
                    variant: KTextVariant.heading2,
                    style: TextStyle(
                      fontSize: t.fontHeading1Size,
                      fontWeight: FontWeight.w700,
                      height: t.fontHeading1LineHeight / t.fontHeading1Size,
                    ),
                  ),
                  SizedBox(height: t.spaceMicro),
                  KText(
                    '${active.where((e) => e.kind == 'service').length} ${_t('Leistungen')} · ${active.where((e) => e.kind == 'product').length} ${_t('Produkte')} · ${widget.categories.length} ${_t('Kategorien')}',
                    variant: KTextVariant.caption,
                    style: TextStyle(
                      color: t.colorTextMuted,
                      fontSize: t.fontBodySize,
                    ),
                  ),
                ],
              ),
            ),
            _newButton(t),
          ],
        ),
        SizedBox(height: t.spaceControlInsetInline),
        KSearchField(
          controller: _search,
          label: _t('Angebote suchen'),
          placeholder: _t('Angebote suchen'),
          clearable: true,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: t.spaceControlGap),
        _filters(entries, t),
        SizedBox(height: t.spaceControlInsetInline),
        _hint(t),
        SizedBox(height: t.spaceControlInsetInline),
        if (groups.isEmpty)
          KAlert(
            title: Text(_t('Keine passenden Angebote')),
            description: Text(_t('Passe deine Suche oder die Filter an.')),
            action: KButton(
              label: _t('Filter zurücksetzen'),
              onPressed: () => setState(() {
                _search.clear();
                _filter = 'all';
              }),
            ),
          ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: groups.length,
          onReorderItem: (from, to) => widget.onReorderCategories?.call(
            groups.map((c) => c.id).toList(),
            from,
            to > from ? to + 1 : to,
          ),
          itemBuilder: (context, index) => Padding(
            key: ValueKey(groups[index].id),
            padding: EdgeInsets.only(bottom: t.spaceControlInsetInline),
            child: _group(groups[index], index, t),
          ),
        ),
        KButton(
          label: _t('Kategorie hinzufügen'),
          leading: const KIcon(KIconName.plus),
          variant: KButtonVariant.secondary,
          onPressed: widget.enabled ? widget.onAddCategory : null,
        ),
        if (widget.settings != null) ...[
          SizedBox(height: t.spaceLayoutGutter),
          widget.settings!,
        ],
        if (widget.footer != null) ...[
          SizedBox(height: t.spaceLayoutGutter),
          widget.footer!,
        ],
      ],
    );
  }

  Widget _group(KOfferCategory c, int index, KDesignTokens t) {
    final rows = c.entries.where(matches).toList();
    final closed = _collapsed.contains(c.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReorderableDelayedDragStartListener(
          index: index,
          enabled: widget.enabled && widget.onReorderCategories != null,
          child: Row(
            children: [
              Container(
                width: t.sizeDot,
                height: t.sizeDot,
                decoration: BoxDecoration(
                  color: c.color ?? t.colorActionPrimaryBackground,
                  borderRadius: BorderRadius.circular(t.radiusFull),
                ),
              ),
              SizedBox(width: t.spaceControlGap),
              Expanded(
                child: KButton(
                  label: c.name,
                  fullWidth: true,
                  paddingInline: 0,
                  variant: KButtonVariant.ghost,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${c.name}  ${rows.length}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.colorTextPrimary,
                          fontSize: t.fontHeading5Size,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (c.description.isNotEmpty)
                        Text(
                          c.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: t.fontBodySmallSize,
                            color: t.colorTextMuted,
                          ),
                        ),
                    ],
                  ),
                  onPressed: () => setState(
                    () =>
                        closed ? _collapsed.remove(c.id) : _collapsed.add(c.id),
                  ),
                ),
              ),
              KMenuButton(
                label: 'Aktionen für ${c.name}',
                overflow: true,
                disabled: !widget.enabled,
                actions: c.actions,
              ),
              KIconButton(
                label: closed ? '${c.name} öffnen' : '${c.name} schließen',
                icon: closed ? KIconName.chevronDown : KIconName.chevronUp,
                onPressed: () => setState(
                  () => closed ? _collapsed.remove(c.id) : _collapsed.add(c.id),
                ),
              ),
            ],
          ),
        ),
        if (!closed)
          KCatalogEditorCard(
            inset: false,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  _KOfferDragRow(
                    key: ValueKey(rows[i].id),
                    data: _KOfferDragData(rows[i].id, c.id),
                    enabled:
                        widget.enabled &&
                        !rows[i].archived &&
                        widget.onReorderEntries != null,
                    onDrop: (data, after) =>
                        _drop(data, c, rows, after ? i + 1 : i),
                    child: _entry(rows[i], c, i > 0, t),
                  ),
                _KOfferDropArea(
                  enabled: widget.enabled && _filter != 'archived',
                  onDrop: (data) => _drop(data, c, rows, rows.length),
                  child: SizedBox(
                    width: double.infinity,
                    height: rows.isEmpty ? t.sizeControl : t.spaceMicro,
                  ),
                ),
                if (_filter != 'archived')
                  KButton(
                    label: _t('Angebot hinzufügen'),
                    leading: const KIcon(KIconName.plus),
                    fullWidth: true,
                    variant: KButtonVariant.ghost,
                    onPressed: widget.enabled ? c.onAdd : null,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _drop(
    _KOfferDragData data,
    KOfferCategory target,
    List<KOfferEntry> rows,
    int index,
  ) {
    if (data.category == target.id) {
      final from = rows.indexWhere((e) => e.id == data.id);
      if (from >= 0 && from != index && from + 1 != index) {
        widget.onReorderEntries?.call(
          target.id,
          rows.map((e) => e.id).toList(),
          from,
          index,
        );
      }
    } else {
      widget.onMoveEntry?.call(
        data.id,
        target.id,
        index < rows.length ? rows[index].id : null,
      );
    }
  }

  Widget _entry(
    KOfferEntry e,
    KOfferCategory c,
    bool divider,
    KDesignTokens t,
  ) => Container(
    decoration: BoxDecoration(
      border: divider
          ? Border(top: BorderSide(color: t.colorBorderDefault))
          : null,
    ),
    child: Row(
      children: [
        Expanded(
          child: KButton(
            label: e.name,
            variant: KButtonVariant.ghost,
            fullWidth: true,
            onPressed: widget.enabled ? e.onEdit : null,
            content: Padding(
              padding: EdgeInsets.symmetric(
                vertical: t.spaceControlGap + t.spaceMicro / 2,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(t.radiusControl),
                    child: SizedBox(
                      width: t.componentAttachmentMediaSize,
                      height: t.componentAttachmentMediaSize,
                      child:
                          e.image ??
                          ColoredBox(
                            color: c.color ?? t.colorActionPrimaryBackground,
                            child: Center(
                              child: Text(
                                e.name.isEmpty ? '?' : e.name[0],
                                style: TextStyle(
                                  color: t.colorActionPrimaryForeground,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                  SizedBox(width: t.spaceContentActionGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.colorTextPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: t.fontHeading5Size,
                          ),
                        ),
                        SizedBox(height: t.spaceMicro / 2),
                        Row(
                          children: [
                            KIcon(
                              e.kind == 'product'
                                  ? KIconName.package
                                  : KIconName.clock,
                              size: 16,
                              color: t.colorTextMuted,
                            ),
                            SizedBox(width: t.spaceMicro),
                            Expanded(
                              child: Text(
                                e.detail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: t.colorTextMuted,
                                  fontSize: t.fontBodySmallSize,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: t.spaceControlGap),
                  Text(
                    e.price,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: t.colorTextPrimary,
                      fontSize: t.fontHeading5Size,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        KMenuButton(
          label: 'Aktionen für ${e.name}',
          overflow: true,
          disabled: !widget.enabled,
          actions: e.actions,
        ),
      ],
    ),
  );
}
