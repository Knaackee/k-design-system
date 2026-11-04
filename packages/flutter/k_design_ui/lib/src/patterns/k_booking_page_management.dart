import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_button.dart';

/// Shared booking-page editor geometry. Application owns the preview and save state.
class KBookingPageLayout extends StatelessWidget {
  const KBookingPageLayout({
    required this.child,
    required this.preview,
    this.previewAction,
    this.previewHelp =
        'Änderungen sehen Kund:innen erst nach dem Veröffentlichen.',
    super.key,
  });
  final Widget child, preview;
  final Widget? previewAction;
  final String previewHelp;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 900) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: t.layoutContentWidth),
              child: child,
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: child),
            SizedBox(width: t.spaceLayoutSectionGap),
            SizedBox(
              width: t.layoutCompactWidth,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Vorschau',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      ?previewAction,
                    ],
                  ),
                  SizedBox(height: t.spaceControlInsetInline),
                  KBookingPagePhone(child: preview),
                  SizedBox(height: t.spaceControlInsetInline),
                  Text(
                    previewHelp,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: t.fontBodySmallSize,
                      color: t.colorTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class KBookingPagePhone extends StatelessWidget {
  const KBookingPagePhone({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return SizedBox(
      width: t.layoutPanelWidth,
      child: AspectRatio(
        aspectRatio: 1 / 2,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: t.colorBorderStrong,
            border: Border.all(
              color: t.colorBorderStrong,
              width: t.borderWidthStrong,
            ),
            borderRadius: BorderRadius.circular(t.radiusProminent),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              t.radiusProminent - t.borderWidthStrong,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class KBookingPageSection extends StatefulWidget {
  const KBookingPageSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.open,
    this.defaultOpen = false,
    this.onOpenChange,
    super.key,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final bool? open;
  final bool defaultOpen;
  final ValueChanged<bool>? onOpenChange;
  @override
  State<KBookingPageSection> createState() => _KBookingPageSectionState();
}

class _KBookingPageSectionState extends State<KBookingPageSection> {
  late bool local = widget.defaultOpen;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final expanded = widget.open ?? local;
    return Padding(
      padding: EdgeInsets.only(bottom: t.spaceLayoutSectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            child: InkWell(
              borderRadius: BorderRadius.circular(t.radiusControl),
              onTap: () {
                setState(() => local = !expanded);
                widget.onOpenChange?.call(!expanded);
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: t.sizeHitTarget),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: t.spaceControlGap / 2,
                    vertical: t.spaceControlGap,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: t.fontHeading4Size,
                                fontWeight: FontWeight.w700,
                                height:
                                    t.fontBodySmallLineHeight /
                                    t.fontBodySmallSize,
                              ),
                            ),
                            if (widget.subtitle != null)
                              Text(
                                widget.subtitle!,
                                style: TextStyle(
                                  fontSize: t.fontBodySmallSize,
                                  height:
                                      t.fontBodySmallLineHeight /
                                      t.fontBodySmallSize,
                                  color: t.colorTextMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      KIcon(
                        expanded
                            ? KIconName.chevronDown
                            : KIconName.chevronRight,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (expanded) widget.child,
        ],
      ),
    );
  }
}

class KBookingPageCard extends StatelessWidget {
  const KBookingPageCard({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(t.spaceControlInsetInline),
      decoration: BoxDecoration(
        color: t.colorSurfaceRaised,
        borderRadius: BorderRadius.circular(t.radiusCard),
        border: Border.all(color: t.colorBorderDefault),
      ),
      child: child,
    );
  }
}

class KBookingPageStatus extends StatelessWidget {
  const KBookingPageStatus({
    required this.online,
    required this.url,
    required this.actions,
    this.thumbnail,
    this.addressAction,
    super.key,
  });
  final bool online;
  final String url;
  final Widget? thumbnail, addressAction;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return KBookingPageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (thumbnail != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(t.radiusExtraLarge),
                  child: SizedBox(
                    width: t.componentAttachmentMediaSize * 2,
                    child: AspectRatio(aspectRatio: 64 / 118, child: thumbnail),
                  ),
                ),
                SizedBox(width: t.spaceControlInsetInline),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: t.sizeDot,
                          height: t.sizeDot,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: online
                                ? t.colorStatusSuccessForeground
                                : t.colorTextMuted,
                          ),
                        ),
                        SizedBox(width: t.spaceControlGap),
                        Text(
                          online ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: t.fontHeading5Size,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: t.spaceControlGap),
                    Row(
                      children: [
                        const KIcon(KIconName.link, size: 16),
                        SizedBox(width: t.spaceControlGap),
                        Expanded(
                          child: Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: t.fontBodySize,
                              color: t.colorTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ?addressAction,
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: t.spaceControlInsetInline),
          Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) SizedBox(width: t.spaceControlGap),
                Expanded(child: actions[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class KBookingThemeChoice {
  const KBookingThemeChoice({
    required this.id,
    required this.label,
    required this.image,
  });
  final String id, label;
  final Widget image;
}

class KBookingThemePicker extends StatefulWidget {
  const KBookingThemePicker({
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
  });
  final List<KBookingThemeChoice> options;
  final String value;
  final ValueChanged<String>? onChanged;
  @override
  State<KBookingThemePicker> createState() => _KBookingThemePickerState();
}

class _KBookingThemePickerState extends State<KBookingThemePicker> {
  bool expanded = false;
  List<KBookingThemeChoice> get options => widget.options;
  String get value => widget.value;
  ValueChanged<String>? get onChanged => widget.onChanged;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final selected = options.where((o) => o.id == value).firstOrNull;
    final first = options.take(4).toList();
    if (selected != null &&
        !first.any((o) => o.id == value) &&
        first.isNotEmpty) {
      first[first.length - 1] = selected;
    }
    final visible = expanded ? options : first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final width = (c.maxWidth - 3 * t.spaceControlGap) / 4;
            return Wrap(
              spacing: t.spaceControlGap,
              runSpacing: t.spaceControlInsetInline,
              children: [
                for (final o in visible)
                  SizedBox(
                    width: width,
                    child: Semantics(
                      button: true,
                      selected: o.id == value,
                      label: o.label,
                      child: InkWell(
                        onTap: onChanged == null
                            ? null
                            : () => onChanged!(o.id),
                        borderRadius: BorderRadius.circular(t.radiusExtraLarge),
                        child: Column(
                          children: [
                            Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  t.radiusExtraLarge,
                                ),
                                border: Border.all(
                                  color: o.id == value
                                      ? t.colorActionPrimaryBackground
                                      : t.colorBorderDefault,
                                  width: o.id == value
                                      ? t.borderWidthStrong
                                      : t.borderWidthDefault,
                                ),
                              ),
                              child: AspectRatio(
                                aspectRatio: 3 / 4,
                                child: ExcludeSemantics(child: o.image),
                              ),
                            ),
                            SizedBox(height: t.spaceControlGap),
                            Text(
                              o.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: t.fontBodySmallSize,
                                fontWeight: FontWeight.w600,
                                color: o.id == value
                                    ? t.colorTextPrimary
                                    : t.colorTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (options.length > 4)
          Align(
            alignment: Alignment.centerLeft,
            child: KButton(
              label: expanded
                  ? 'Weniger Designs'
                  : 'Alle ${options.length} Designs ansehen',
              variant: KButtonVariant.ghost,
              onPressed: () => setState(() => expanded = !expanded),
            ),
          ),
      ],
    );
  }
}
