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
              constraints: const BoxConstraints(maxWidth: 640),
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
              width: 320,
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
                    style: TextStyle(fontSize: 13, color: t.colorTextMuted),
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
  Widget build(BuildContext context) => Container(
    width: 300,
    height: 600,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.black,
      border: Border.all(color: const Color(0xff0b0b0d), width: 9),
      borderRadius: BorderRadius.circular(40),
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(31), child: child),
  );
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
                constraints: const BoxConstraints(minHeight: 48),
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
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),
                            if (widget.subtitle != null)
                              Text(
                                widget.subtitle!,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
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
                        size: 18,
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
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(width: 64, height: 118, child: thumbnail),
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
                          width: 9,
                          height: 9,
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: t.spaceControlGap),
                    Row(
                      children: [
                        const KIcon(KIconName.link, size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
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
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: o.id == value
                                      ? t.colorActionPrimaryBackground
                                      : t.colorBorderDefault,
                                  width: o.id == value ? 2 : 1,
                                ),
                              ),
                              child: AspectRatio(
                                aspectRatio: 3 / 4,
                                child: ExcludeSemantics(child: o.image),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              o.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
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
