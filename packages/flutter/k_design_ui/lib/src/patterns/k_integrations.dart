import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../basic_components.dart';
import '../forms/k_input.dart';
import '../primitives/k_button.dart';
import '../primitives/k_text.dart';

enum KIntegrationConnectionState {
  disconnected,
  pending,
  connected,
  error,
  unavailable,
}

class KIntegrationCategory {
  const KIntegrationCategory({required this.id, required this.label});
  final String id;
  final String label;
}

class KIntegrationItem {
  const KIntegrationItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
    this.state = KIntegrationConnectionState.disconnected,
    this.availabilityLabel,
    this.accountLabel,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final Widget icon;
  final KIntegrationConnectionState state;
  final String? availabilityLabel;
  final String? accountLabel;
}

class KIntegrationMarketplaceLabels {
  const KIntegrationMarketplaceLabels({
    this.title = 'Integrationen',
    this.description =
        'Verbinde Dienste, die dein Assistent als Arbeitskontext verwenden darf.',
    this.searchPlaceholder = 'Integrationen durchsuchen',
    this.connectedTitle = 'Verbunden',
    this.catalogTitle = 'Verfügbare Integrationen',
    this.emptyLabel = 'Keine Integrationen gefunden.',
    this.connectLabel = 'Verbinden',
    this.disconnectLabel = 'Trennen',
    this.retryLabel = 'Erneut versuchen',
    this.pendingLabel = 'Wird verbunden',
    this.disconnectedLabel = 'Nicht verbunden',
    this.connectedLabel = 'Verbunden',
    this.errorLabel = 'Verbindung fehlgeschlagen',
    this.unavailableLabel = 'Nicht verfügbar',
  });

  final String title;
  final String description;
  final String searchPlaceholder;
  final String connectedTitle;
  final String catalogTitle;
  final String emptyLabel;
  final String connectLabel;
  final String disconnectLabel;
  final String retryLabel;
  final String pendingLabel;
  final String disconnectedLabel;
  final String connectedLabel;
  final String errorLabel;
  final String unavailableLabel;

  String stateLabel(KIntegrationConnectionState state) => switch (state) {
    KIntegrationConnectionState.disconnected => disconnectedLabel,
    KIntegrationConnectionState.pending => pendingLabel,
    KIntegrationConnectionState.connected => connectedLabel,
    KIntegrationConnectionState.error => errorLabel,
    KIntegrationConnectionState.unavailable => unavailableLabel,
  };
}

typedef KIntegrationItemCallback = void Function(KIntegrationItem item);

class KIntegrationMarketplace extends StatefulWidget {
  static const double defaultMaxWidth = 1120;
  static const double defaultSearchWidth = 340;
  static const double defaultCardCompactBreakpoint = 520;

  const KIntegrationMarketplace({
    required this.integrations,
    required this.categories,
    required this.activeCategory,
    required this.searchValue,
    required this.onCategoryChanged,
    required this.onSearchChanged,
    required this.onConnect,
    this.activeIntegrationId,
    this.onDisconnect,
    this.panelBuilder,
    this.labels = const KIntegrationMarketplaceLabels(),
    this.maxWidth = defaultMaxWidth,
    this.searchWidth = defaultSearchWidth,
    super.key,
  });

  final List<KIntegrationItem> integrations;
  final List<KIntegrationCategory> categories;
  final String activeCategory;
  final String searchValue;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;
  final KIntegrationItemCallback onConnect;
  final KIntegrationItemCallback? onDisconnect;
  final String? activeIntegrationId;
  final Widget Function(BuildContext context, KIntegrationItem item)?
  panelBuilder;
  final KIntegrationMarketplaceLabels labels;
  final double maxWidth;
  final double searchWidth;

  @override
  State<KIntegrationMarketplace> createState() =>
      _KIntegrationMarketplaceState();
}

class _KIntegrationMarketplaceState extends State<KIntegrationMarketplace> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.searchValue);
  }

  @override
  void didUpdateWidget(covariant KIntegrationMarketplace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchValue != _search.text) {
      _search.value = TextEditingValue(
        text: widget.searchValue,
        selection: TextSelection.collapsed(offset: widget.searchValue.length),
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final query = widget.searchValue.trim().toLowerCase();
    bool visible(KIntegrationItem item) =>
        (widget.activeCategory == 'all' ||
            item.category == widget.activeCategory) &&
        (query.isEmpty ||
            item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query));
    final connected = widget.integrations
        .where((item) => item.state == KIntegrationConnectionState.connected)
        .toList();
    final catalog = widget.integrations.where(visible).toList();
    final active = widget.integrations
        .where((item) => item.id == widget.activeIntegrationId)
        .firstOrNull;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: Padding(
          padding: EdgeInsets.all(t.spaceCardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, bounds) {
                  final copy = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KText(
                        widget.labels.title,
                        variant: KTextVariant.heading2,
                      ),
                      SizedBox(height: t.spaceTight),
                      KText(
                        widget.labels.description,
                        variant: KTextVariant.bodySmall,
                        style: TextStyle(color: t.colorTextMuted),
                      ),
                    ],
                  );
                  final search = KInput(
                    controller: _search,
                    placeholder: widget.labels.searchPlaceholder,
                    clearable: true,
                    onChanged: widget.onSearchChanged,
                  );
                  return bounds.maxWidth < 700
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            copy,
                            SizedBox(height: t.spaceContentActionGap),
                            search,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: copy),
                            SizedBox(width: t.spaceContentActionGap),
                            SizedBox(width: widget.searchWidth, child: search),
                          ],
                        );
                },
              ),
              SizedBox(height: t.spaceLayoutSectionGap),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: t.spaceControlGap,
                  children: [
                    for (final category in widget.categories)
                      ChoiceChip(
                        label: Text(category.label),
                        selected: category.id == widget.activeCategory,
                        showCheckmark: false,
                        backgroundColor: t.colorSurfaceRaised,
                        selectedColor: t.colorSurfaceSubtle,
                        side: BorderSide(
                          color: category.id == widget.activeCategory
                              ? t.colorBorderStrong
                              : t.colorBorderDefault,
                        ),
                        shape: const StadiumBorder(),
                        onSelected: (_) =>
                            widget.onCategoryChanged(category.id),
                      ),
                  ],
                ),
              ),
              if (active != null && widget.panelBuilder != null) ...[
                SizedBox(height: t.spaceLayoutSectionGap),
                _IntegrationSurface(
                  child: widget.panelBuilder!(context, active),
                ),
              ],
              if (connected.isNotEmpty) ...[
                SizedBox(height: t.spaceLayoutSectionGap),
                _MarketplaceSection(
                  title: widget.labels.connectedTitle,
                  items: connected,
                  labels: widget.labels,
                  onConnect: widget.onConnect,
                  onDisconnect: widget.onDisconnect,
                ),
              ],
              SizedBox(height: t.spaceLayoutSectionGap),
              if (catalog.isEmpty)
                _IntegrationSurface(
                  child: Padding(
                    padding: EdgeInsets.all(t.spaceCardPadding),
                    child: KText(
                      widget.labels.emptyLabel,
                      align: TextAlign.center,
                      style: TextStyle(color: t.colorTextMuted),
                    ),
                  ),
                )
              else
                _MarketplaceSection(
                  title: widget.labels.catalogTitle,
                  items: catalog,
                  labels: widget.labels,
                  onConnect: widget.onConnect,
                  onDisconnect: widget.onDisconnect,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketplaceSection extends StatelessWidget {
  const _MarketplaceSection({
    required this.title,
    required this.items,
    required this.labels,
    required this.onConnect,
    this.onDisconnect,
  });
  final String title;
  final List<KIntegrationItem> items;
  final KIntegrationMarketplaceLabels labels;
  final KIntegrationItemCallback onConnect;
  final KIntegrationItemCallback? onDisconnect;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KText(title, variant: KTextVariant.heading5),
        SizedBox(height: t.spaceControlInsetInline),
        LayoutBuilder(
          builder: (context, bounds) {
            final width = bounds.maxWidth >= 760
                ? (bounds.maxWidth - t.spaceControlInsetInline) / 2
                : bounds.maxWidth;
            return Wrap(
              spacing: t.spaceControlInsetInline,
              runSpacing: t.spaceControlInsetInline,
              children: [
                for (final item in items)
                  SizedBox(
                    width: width,
                    child: _IntegrationCard(
                      item: item,
                      labels: labels,
                      onConnect: onConnect,
                      onDisconnect: onDisconnect,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  const _IntegrationCard({
    required this.item,
    required this.labels,
    required this.onConnect,
    this.onDisconnect,
  });
  final KIntegrationItem item;
  final KIntegrationMarketplaceLabels labels;
  final KIntegrationItemCallback onConnect;
  final KIntegrationItemCallback? onDisconnect;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final action = switch (item.state) {
      KIntegrationConnectionState.connected => KButton(
        label: labels.disconnectLabel,
        variant: KButtonVariant.ghost,
        onPressed: onDisconnect == null ? null : () => onDisconnect!(item),
      ),
      KIntegrationConnectionState.pending => KButton(
        label: labels.pendingLabel,
        loading: true,
        onPressed: null,
      ),
      KIntegrationConnectionState.unavailable => KBadge(
        variant: KBadgeVariant.warning,
        child: Text(labels.stateLabel(item.state)),
      ),
      KIntegrationConnectionState.error => KButton(
        label: labels.retryLabel,
        variant: KButtonVariant.secondary,
        onPressed: () => onConnect(item),
      ),
      KIntegrationConnectionState.disconnected => KButton(
        label: labels.connectLabel,
        onPressed: () => onConnect(item),
      ),
    };
    return _IntegrationSurface(
      child: Padding(
        padding: EdgeInsets.all(t.spaceCardPadding),
        child: LayoutBuilder(
          builder: (context, bounds) {
            final compact =
                bounds.maxWidth <=
                KIntegrationMarketplace.defaultCardCompactBreakpoint;
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: t.spaceControlGap,
                  runSpacing: t.spaceControlGap,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    KText(item.name, variant: KTextVariant.label),
                    if (item.availabilityLabel != null)
                      KBadge(
                        variant: KBadgeVariant.info,
                        child: Text(item.availabilityLabel!),
                      ),
                  ],
                ),
                SizedBox(height: t.spaceTight),
                KText(
                  item.description,
                  variant: KTextVariant.bodySmall,
                  style: TextStyle(color: t.colorTextMuted),
                ),
                if (item.accountLabel != null) ...[
                  SizedBox(height: t.spaceTight),
                  KText(
                    item.accountLabel!,
                    variant: KTextVariant.caption,
                    style: TextStyle(color: t.colorStatusSuccessForeground),
                  ),
                ],
              ],
            );
            final identity = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KIntegrationIcon(child: item.icon),
                SizedBox(width: t.spaceControlInsetInline),
                Expanded(child: content),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  identity,
                  SizedBox(height: t.spaceControlInsetInline),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: action,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: identity),
                SizedBox(width: t.spaceControlInsetInline),
                action,
              ],
            );
          },
        ),
      ),
    );
  }
}

class KIntegrationIcon extends StatelessWidget {
  const KIntegrationIcon({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Container(
      width: t.sizeAvatarLarge,
      height: t.sizeAvatarLarge,
      alignment: Alignment.center,
      padding: EdgeInsets.all(t.spaceControlGap),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.colorSurfaceCanvas,
        border: Border.all(color: t.colorBorderDefault),
        borderRadius: BorderRadius.circular(t.radiusMedium),
      ),
      child: child,
    );
  }
}

class _IntegrationSurface extends StatelessWidget {
  const _IntegrationSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.colorSurfaceRaised,
        border: Border.all(color: t.colorBorderDefault),
        borderRadius: BorderRadius.circular(t.radiusCard),
        boxShadow: t.elevationLow,
      ),
      child: child,
    );
  }
}
