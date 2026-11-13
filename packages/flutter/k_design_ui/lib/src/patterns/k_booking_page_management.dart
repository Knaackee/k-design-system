import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_icon.dart';
export 'k_booking_theme_picker.dart';
export 'k_booking_page_settings.dart';

/// Shared booking-page editor geometry. Application owns the preview and save state.
class KBookingPageLayout extends StatelessWidget {
  const KBookingPageLayout({
    required this.child,
    required this.preview,
    this.previewAction,
    this.settings = false,
    this.previewHelp =
        'Änderungen sehen Kund:innen erst nach dem Veröffentlichen.',
    super.key,
  });
  final Widget child, preview;
  final bool settings;
  final Widget? previewAction;
  final String previewHelp;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < (settings ? 700 : 900)) {
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
              width: settings ? t.layoutPanelWidth : t.layoutCompactWidth,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          settings ? 'Live-Vorschau' : 'Vorschau',
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
