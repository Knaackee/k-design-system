import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../basic_components.dart';
import '../forms/k_select.dart';
import '../primitives/k_button.dart';
import '../primitives/k_text.dart';
import 'k_integrations.dart';
import 'k_tab_strip.dart';

enum KIntegrationCatalogState { draft, tested, published }

enum KIntegrationCatalogView { all, published }

class KIntegrationCatalogItem extends KIntegrationItem {
  const KIntegrationCatalogItem({
    required super.id,
    required super.name,
    required super.category,
    required super.description,
    required super.icon,
    required this.endpoint,
    required this.catalogState,
    super.state,
    super.availabilityLabel,
    super.accountLabel,
  });

  final String endpoint;
  final KIntegrationCatalogState catalogState;
}

class KIntegrationAdminCatalogLabels {
  const KIntegrationAdminCatalogLabels({
    this.title = 'Integrationskatalog verwalten',
    this.preview = 'Vorschau',
    this.create = 'Integration hinzufügen',
    this.list = 'Katalogeinträge',
    this.draft = 'Entwurf',
    this.tested = 'Getestet',
    this.published = 'Veröffentlicht',
    this.allView = 'Alle',
    this.publishedView = 'Veröffentlicht',
    this.category = 'Kategorie',
    this.allCategories = 'Alle Kategorien',
    this.empty = 'Keine Katalogeinträge für diese Filter.',
  });
  final String title;
  final String? preview;
  final String create;
  final String list;
  final String draft;
  final String tested;
  final String published;
  final String allView;
  final String publishedView;
  final String category;
  final String allCategories;
  final String empty;

  String status(KIntegrationCatalogState state) => switch (state) {
    KIntegrationCatalogState.draft => draft,
    KIntegrationCatalogState.tested => tested,
    KIntegrationCatalogState.published => published,
  };
}

class KIntegrationAdminCatalog extends StatefulWidget {
  static const double defaultMaxWidth = 980;
  static const double defaultCompactBreakpoint = 520;

  const KIntegrationAdminCatalog({
    required this.integrations,
    required this.onCreate,
    required this.onEdit,
    this.labels = const KIntegrationAdminCatalogLabels(),
    this.activeView,
    this.activeCategory,
    this.onViewChanged,
    this.onCategoryChanged,
    this.maxWidth = defaultMaxWidth,
    this.compactBreakpoint = defaultCompactBreakpoint,
    super.key,
  });

  final List<KIntegrationCatalogItem> integrations;
  final VoidCallback onCreate;
  final ValueChanged<KIntegrationCatalogItem> onEdit;
  final KIntegrationAdminCatalogLabels labels;
  final KIntegrationCatalogView? activeView;
  final String? activeCategory;
  final ValueChanged<KIntegrationCatalogView>? onViewChanged;
  final ValueChanged<String>? onCategoryChanged;
  final double maxWidth;
  final double compactBreakpoint;

  @override
  State<KIntegrationAdminCatalog> createState() =>
      _KIntegrationAdminCatalogState();
}

class _KIntegrationAdminCatalogState extends State<KIntegrationAdminCatalog> {
  var _view = KIntegrationCatalogView.all;
  var _category = 'all';

  void _selectView(String id) {
    final next = KIntegrationCatalogView.values.byName(id);
    if (widget.activeView == null) setState(() => _view = next);
    widget.onViewChanged?.call(next);
  }

  void _selectCategory(String? next) {
    if (next == null) return;
    if (widget.activeCategory == null) setState(() => _category = next);
    widget.onCategoryChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final labels = widget.labels;
    final categories =
        widget.integrations
            .map((item) => item.category)
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort(_compareText);
    final requestedCategory = widget.activeCategory ?? _category;
    final category = categories.contains(requestedCategory)
        ? requestedCategory
        : 'all';
    final view = widget.activeView ?? _view;
    final visible =
        widget.integrations
            .where(
              (item) =>
                  (category == 'all' || item.category == category) &&
                  _matchesView(item.catalogState, view),
            )
            .toList()
          ..sort((left, right) {
            if (view == KIntegrationCatalogView.all) {
              final stateOrder =
                  (right.catalogState == KIntegrationCatalogState.published
                      ? 1
                      : 0) -
                  (left.catalogState == KIntegrationCatalogState.published
                      ? 1
                      : 0);
              if (stateOrder != 0) return stateOrder;
            }
            return _compareText(left.name, right.name) != 0
                ? _compareText(left.name, right.name)
                : _compareText(left.id, right.id);
          });
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal:
                MediaQuery.sizeOf(context).width <= widget.compactBreakpoint
                ? t.spaceControlGap
                : t.spaceCardPadding,
            vertical: t.spaceCardPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: t.spaceControlGap,
                runSpacing: t.spaceControlGap,
                children: [
                  KText(labels.title, variant: KTextVariant.heading3),
                  Wrap(
                    spacing: t.spaceControlGap,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (labels.preview != null)
                        KBadge(
                          variant: KBadgeVariant.warning,
                          child: Text(labels.preview!),
                        ),
                      KButton(label: labels.create, onPressed: widget.onCreate),
                    ],
                  ),
                ],
              ),
              SizedBox(height: t.spaceContentActionGap),
              LayoutBuilder(
                builder: (context, bounds) {
                  final tabs = KTabStrip(
                    items: [
                      KTabStripItem(
                        id: KIntegrationCatalogView.all.name,
                        label: labels.allView,
                      ),
                      KTabStripItem(
                        id: KIntegrationCatalogView.published.name,
                        label: labels.publishedView,
                      ),
                    ],
                    selectedId: view.name,
                    onSelect: _selectView,
                  );
                  final categorySelect = KSelect(
                    label: labels.category,
                    value: category,
                    options: [
                      KSelectOption(value: 'all', label: labels.allCategories),
                      for (final value in categories)
                        KSelectOption(value: value, label: value),
                    ],
                    onChanged: _selectCategory,
                  );
                  if (bounds.maxWidth <= widget.compactBreakpoint) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        tabs,
                        SizedBox(height: t.spaceControlInsetInline),
                        categorySelect,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: tabs),
                      SizedBox(width: t.spaceControlInsetInline),
                      Flexible(child: categorySelect),
                    ],
                  );
                },
              ),
              SizedBox(height: t.spaceContentActionGap),
              Semantics(
                label: labels.list,
                child: visible.isEmpty
                    ? Container(
                        padding: EdgeInsets.all(t.spaceCardPadding),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: t.colorBorderDefault),
                          borderRadius: BorderRadius.circular(t.radiusMedium),
                        ),
                        child: KText(
                          labels.empty,
                          variant: KTextVariant.bodySmall,
                          align: TextAlign.center,
                          style: TextStyle(color: t.colorTextMuted),
                        ),
                      )
                    : Column(
                        children: [
                          for (
                            var index = 0;
                            index < visible.length;
                            index++
                          ) ...[
                            _CatalogRow(
                              item: visible[index],
                              labels: labels,
                              compactBreakpoint: widget.compactBreakpoint,
                              onPressed: () => widget.onEdit(visible[index]),
                            ),
                            if (index != visible.length - 1)
                              SizedBox(height: t.spaceControlGap),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _matchesView(
  KIntegrationCatalogState state,
  KIntegrationCatalogView view,
) =>
    view == KIntegrationCatalogView.all ||
    (view == KIntegrationCatalogView.published &&
        state == KIntegrationCatalogState.published);

int _compareText(String left, String right) =>
    left.toLowerCase().compareTo(right.toLowerCase());

class _CatalogRow extends StatelessWidget {
  const _CatalogRow({
    required this.item,
    required this.labels,
    required this.compactBreakpoint,
    required this.onPressed,
  });
  final KIntegrationCatalogItem item;
  final KIntegrationAdminCatalogLabels labels;
  final double compactBreakpoint;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final variant = switch (item.catalogState) {
      KIntegrationCatalogState.draft => KBadgeVariant.outline,
      KIntegrationCatalogState.tested => KBadgeVariant.info,
      KIntegrationCatalogState.published => KBadgeVariant.success,
    };
    return Semantics(
      button: true,
      label:
          '${item.name}, ${item.category}, ${labels.status(item.catalogState)}',
      child: Material(
        color: t.colorSurfaceRaised,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: t.colorBorderDefault),
          borderRadius: BorderRadius.circular(t.radiusMedium),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.all(t.spaceControlGap),
            child: LayoutBuilder(
              builder: (context, bounds) {
                final compact = bounds.maxWidth <= compactBreakpoint;
                final badge = KBadge(
                  variant: variant,
                  child: Text(labels.status(item.catalogState)),
                );
                return Row(
                  crossAxisAlignment: compact
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    KIntegrationIcon(child: item.icon),
                    SizedBox(width: t.spaceControlGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          KText(item.name, variant: KTextVariant.label),
                          SizedBox(height: t.spaceTight),
                          KText(
                            item.category,
                            variant: KTextVariant.caption,
                            style: TextStyle(color: t.colorTextMuted),
                          ),
                          SizedBox(height: t.spaceTight),
                          KText(
                            item.description,
                            variant: KTextVariant.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: t.colorTextMuted),
                          ),
                          if (compact) ...[
                            SizedBox(height: t.spaceControlGap),
                            badge,
                          ],
                        ],
                      ),
                    ),
                    if (!compact) ...[
                      SizedBox(width: t.spaceControlGap),
                      badge,
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
