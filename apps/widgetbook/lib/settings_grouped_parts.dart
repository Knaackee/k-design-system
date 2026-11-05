import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

// Gallery composition only. Public K shell, buttons, fields, and overlays.
KDesignTokens settingsGroupedTokens(KDesignTokens t, bool dark) => t.copyWith(
  colorSurfaceCanvas: Color(dark ? 0xff09090b : 0xfff4f4f5),
  colorSurfaceRaised: Color(dark ? 0xff18181b : 0xffffffff),
  colorSurfaceSubtle: Color(dark ? 0xff27272a : 0xffe4e4e7),
  colorTextPrimary: Color(dark ? 0xfffafafa : 0xff18181b),
  colorTextMuted: Color(dark ? 0xffa1a1aa : 0xff52525b),
  colorBorderDefault: Color(dark ? 0xff27272a : 0xffe4e4e7),
  colorActionPrimaryBackground: Color(dark ? 0xff7ac1f2 : 0xff0c679f),
  colorActionPrimaryForeground: Color(dark ? 0xff082f49 : 0xffffffff),
  colorActionGhostForeground: Color(dark ? 0xfffafafa : 0xff18181b),
  colorActionGhostHover: Color(dark ? 0xff27272a : 0xfff4f4f5),
  colorStatusErrorAccent: Color(dark ? 0xfffb7185 : 0xffe11d48),
  colorStatusSuccessForeground: Color(dark ? 0xff34d399 : 0xff047857),
  colorStatusSuccessBackground: Color(dark ? 0xff12372f : 0xffecfdf5),
  colorBrandPrimaryBackground: Color(dark ? 0xff113449 : 0xffeaf4fa),
  colorBrandPrimaryForeground: Color(dark ? 0xffa9daf9 : 0xff0c679f),
  radiusCard: 18,
  layoutPanelWidth: 290,
  fontCaptionSize: 13,
  fontHeading2Size: 34,
  fontHeading3Size: 24,
  spaceLayoutSectionGap: 26,
  spaceContentActionGap: 14,
  spaceControlGap: 8,
  spaceControlInsetInline: 16,
);

class SgGroup extends StatelessWidget {
  const SgGroup({
    required this.children,
    this.title = '',
    this.footer,
    this.plain = false,
    super.key,
  });
  final String title;
  final String? footer;
  final bool plain;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return KStack(
      gap: KLayoutGap.control,
      align: KLayoutAlign.stretch,
      children: [
        if (title.isNotEmpty)
          KText(
            title,
            variant: KTextVariant.caption,
            style: TextStyle(
              color: t.colorTextMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: plain ? Colors.transparent : t.colorSurfaceRaised,
            border: plain ? null : Border.all(color: t.colorBorderDefault),
            borderRadius: BorderRadius.circular(t.radiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0 && !plain)
                  Padding(
                    padding: EdgeInsets.only(left: t.spaceControlInsetInline),
                    child: Container(
                      height: t.borderWidthDefault,
                      color: t.colorBorderDefault,
                    ),
                  ),
                children[i],
              ],
            ],
          ),
        ),
        if (footer != null) SgMuted(footer!),
      ],
    );
  }
}

class SgMuted extends StatelessWidget {
  const SgMuted(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => KText(
    text,
    variant: KTextVariant.caption,
    style: TextStyle(
      color: Theme.of(context).extension<KDesignTokens>()!.colorTextMuted,
    ),
  );
}

class SgStatus extends StatelessWidget {
  const SgStatus(
    this.text, {
    this.success = false,
    this.warning = false,
    super.key,
  });
  final String text;
  final bool success, warning;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: t.spaceControlGap + t.borderWidthDefault,
          vertical: t.spaceSmallInset - t.borderWidthDefault,
        ),
        decoration: BoxDecoration(
          color: success
              ? t.colorStatusSuccessBackground
              : warning
              ? t.colorStatusWarningBackground
              : t.colorSurfaceSubtle,
          borderRadius: BorderRadius.circular(t.radiusCard),
        ),
        child: KText(
          text,
          variant: KTextVariant.caption,
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: success
                ? t.colorStatusSuccessForeground
                : warning
                ? t.colorStatusWarningForeground
                : t.colorTextPrimary,
          ),
        ),
      ),
    );
  }
}

class SgInset extends StatelessWidget {
  const SgInset({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(
      Theme.of(context).extension<KDesignTokens>()!.spaceControlInsetInline,
    ),
    child: child,
  );
}

class SgRow extends StatelessWidget {
  const SgRow(
    this.title, {
    this.value,
    this.description,
    this.icon,
    this.color,
    this.onTap,
    this.selected = false,
    this.danger = false,
    this.navigation = false,
    super.key,
  });
  final String title;
  final String? value, description;
  final KIconName? icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool selected, danger, navigation;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final ink = danger ? t.colorStatusErrorAccent : t.colorTextPrimary;
    final compact = navigation && MediaQuery.sizeOf(context).width >= 700;
    final button = KButton(
      label: '$title${value == null ? '' : ': $value'}',
      fullWidth: true,
      variant: KButtonVariant.ghost,
      onPressed: onTap,
      paddingInline: compact ? t.spaceControlGap : t.spaceControlInsetInline,
      content: Padding(
        padding: EdgeInsets.symmetric(
          vertical: compact
              ? t.spaceControlGap
              : t.spaceControlGap + t.spaceSmallInset,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: compact ? 26 : 30,
                height: compact ? 26 : 30,
                decoration: BoxDecoration(
                  color:
                      color ??
                      (danger
                          ? Colors.transparent
                          : t.colorActionPrimaryBackground),
                  borderRadius: BorderRadius.circular(t.radiusControl),
                ),
                child: Center(
                  child: KIcon(
                    icon!,
                    size: compact ? 15 : 16,
                    color: danger ? ink : Colors.white,
                  ),
                ),
              ),
              SizedBox(
                width: compact
                    ? t.spaceControlGap + t.spaceSmallInset / 2
                    : t.spaceContentActionGap,
              ),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: danger && icon == null
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  KText(
                    title,
                    style: TextStyle(
                      color: ink,
                      fontSize: compact ? 14.5 : 15.5,
                      height: 1.5,
                      fontWeight: danger ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (description != null)
                    Padding(
                      padding: EdgeInsets.only(top: t.borderWidthDefault),
                      child: SgMuted(description!),
                    ),
                ],
              ),
            ),
            if (value != null) ...[
              SizedBox(width: t.spaceControlGap),
              Flexible(
                fit: FlexFit.tight,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SgMuted(value!),
                ),
              ),
            ],
            SizedBox(width: t.spaceControlGap),
            if (selected && !navigation)
              KIcon(
                KIconName.check,
                size: 16,
                color: t.colorActionPrimaryBackground,
              )
            else if (!compact && !danger)
              KIcon(KIconName.chevronRight, size: 16, color: t.colorTextMuted),
          ],
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: compact && selected ? t.colorSurfaceRaised : Colors.transparent,
        border: compact && selected
            ? Border.all(color: t.colorBorderDefault)
            : null,
        borderRadius: BorderRadius.circular(t.radiusControl),
      ),
      child: button,
    );
  }
}

class SgChoices extends StatelessWidget {
  const SgChoices({
    required this.items,
    required this.value,
    required this.onChanged,
    super.key,
  });
  final List<String> items;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: KInline(
      gap: KLayoutGap.control,
      children: [
        for (final item in items)
          KButton(
            label: item,
            variant: value == item
                ? KButtonVariant.secondary
                : KButtonVariant.ghost,
            onPressed: () => onChanged(item),
          ),
      ],
    ),
  );
}

Future<void> sgDialog(BuildContext context, String title, Widget child) =>
    KAdaptiveDialog.show<void>(
      context: context,
      builder: (c) => KAdaptiveDialog(
        title: KText(title, variant: KTextVariant.heading3),
        closeLabel: 'Schließen',
        onClose: () => Navigator.of(c).pop(),
        child: child,
      ),
    );

class SgProfileAvatarFallback extends StatelessWidget {
  const SgProfileAvatarFallback(this.name, {super.key});
  final String name;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: double.infinity,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(-.3, -.4),
        radius: .9,
        colors: [Color(0xffd4d4d8), Color(0xff71717a), Color(0xff3f3f46)],
        stops: [0, .6, 1],
      ),
    ),
    child: KText(
      name
          .trim()
          .split(RegExp(r'\s+'))
          .take(2)
          .map((s) => s.isEmpty ? '' : s[0])
          .join(),
      style: const TextStyle(fontSize: 32, color: Colors.white),
    ),
  );
}

/// Row with leading visual, text and a trailing value or action. From 1.3x
/// system text the trailing part moves under the text (rules.md: Wrapping),
/// so neither the title nor a number has to truncate.
class SgAdaptiveRow extends StatelessWidget {
  const SgAdaptiveRow({super.key, this.leading, required this.body, this.trailing});

  final Widget? leading;
  final Widget body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    return KInline(
      gap: KLayoutGap.control,
      children: [
        ?leading,
        Expanded(
          child: large && trailing != null
              ? KStack(
                  gap: KLayoutGap.control,
                  align: KLayoutAlign.start,
                  children: [body, trailing!],
                )
              : body,
        ),
        if (!large && trailing != null) trailing!,
      ],
    );
  }
}
