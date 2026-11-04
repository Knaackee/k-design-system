import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_layout.dart';
import '../primitives/k_text.dart';
import '../primitives/k_surface.dart';
import '../primitives/k_icon.dart';
import '../actions/k_icon_button.dart';

/// A full-page editor on phones and a bounded editor dialog on larger screens.
/// Scrollable body and fixed actions keep long catalog forms usable.
class KCatalogEditorDialog extends StatelessWidget {
  const KCatalogEditorDialog({
    required this.title,
    required this.child,
    this.description,
    this.actions,
    this.onClose,
    this.maxWidth = 1040,
    super.key,
  });
  final Widget title;
  final Widget child;
  final Widget? description;
  final Widget? actions;
  final VoidCallback? onClose;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final phone = MediaQuery.sizeOf(context).width < 600;
    final gutter = phone ? t.spaceControlInsetInline : t.spaceLayoutGutter;
    return SafeArea(
      minimum: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SizedBox(
              width: maxWidth,
              height: phone
                  ? constraints.maxHeight
                  : constraints.maxHeight * .92,
              child: Material(
                color: Colors.transparent,
                child: KSurface(
                  tone: KSurfaceTone.canvas,
                  radius: phone ? KSurfaceRadius.none : KSurfaceRadius.overlay,
                  border: phone ? KSurfaceBorder.none : KSurfaceBorder.standard,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(gutter),
                        child: Row(
                          children: [
                            KIconButton(
                              label: 'Schließen',
                              icon: KIconName.x,
                              onPressed: onClose,
                            ),
                            SizedBox(width: t.spaceControlGap),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DefaultTextStyle(
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: t.colorTextPrimary,
                                    ),
                                    child: title,
                                  ),
                                  if (description != null)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: t.spaceMicro,
                                      ),
                                      child: DefaultTextStyle(
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: t.colorTextMuted,
                                        ),
                                        child: description!,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            gutter,
                            0,
                            gutter,
                            gutter,
                          ),
                          child: child,
                        ),
                      ),
                      if (actions != null)
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: t.colorBorderDefault),
                            ),
                          ),
                          padding: EdgeInsets.all(gutter),
                          child: actions,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shared catalogue editor composition. Business state and controls are slots.
/// Preview precedes the form on phones and sits beside it on wide surfaces.
class KCatalogEditorBody extends StatelessWidget {
  const KCatalogEditorBody({
    required this.preview,
    required this.children,
    super.key,
  });
  final Widget preview;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final t = Theme.of(context).extension<KDesignTokens>()!;
      final form = KStack(
        gap: KLayoutGap.section,
        align: KLayoutAlign.stretch,
        children: children,
      );
      if (box.maxWidth < 800) {
        return KStack(
          gap: KLayoutGap.section,
          align: KLayoutAlign.stretch,
          children: [preview, form],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: form),
          SizedBox(width: t.spaceControlInsetInline * 2),
          SizedBox(
            width: 340,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Reserve the same scaled heading line as the form section.
                ExcludeSemantics(
                  child: Opacity(
                    opacity: 0,
                    child: KText(
                      ' ',
                      variant: KTextVariant.caption,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ),
                SizedBox(height: t.spaceControlGap),
                preview,
              ],
            ),
          ),
        ],
      );
    },
  );
}

class KCatalogEditorSection extends StatelessWidget {
  const KCatalogEditorSection({
    required this.title,
    required this.child,
    this.action,
    this.help,
    super.key,
  });
  final String title;
  final Widget child;
  final Widget? action;
  final String? help;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return KStack(
      gap: KLayoutGap.control,
      align: KLayoutAlign.stretch,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.spaceMicro),
            child: Row(
              children: [
                Expanded(
                  child: KText(
                    title,
                    variant: KTextVariant.caption,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.5,
                      color: t.colorTextMuted,
                    ),
                  ),
                ),
                ?action,
              ],
            ),
          ),
        child,
        if (help != null)
          KText(
            help!,
            variant: KTextVariant.caption,
            style: TextStyle(color: t.colorTextMuted),
          ),
      ],
    );
  }
}

class KCatalogEditorCard extends StatelessWidget {
  const KCatalogEditorCard({required this.child, this.inset = true, super.key});
  final Widget child;
  final bool inset;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: inset ? EdgeInsets.all(t.spaceControlInsetInline) : null,
      decoration: BoxDecoration(
        color: t.colorSurfaceRaised,
        border: Border.all(
          color: t.colorBorderDefault,
          width: t.borderWidthDefault,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
        borderRadius: BorderRadius.circular(t.radiusCard),
      ),
      child: child,
    );
  }
}

class KCatalogEditorRow extends StatelessWidget {
  const KCatalogEditorRow({
    required this.title,
    required this.trailing,
    this.help,
    this.divider = false,
    super.key,
  });
  final String title;
  final String? help;
  final Widget trailing;
  final bool divider;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: t.spaceControlInsetInline,
        vertical: t.spaceControlGap + t.spaceMicro,
      ),
      decoration: BoxDecoration(
        border: divider
            ? Border(top: BorderSide(color: t.colorBorderDefault))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KText(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (help != null) ...[
                  SizedBox(height: t.borderWidthDefault),
                  KText(
                    help!,
                    variant: KTextVariant.caption,
                    style: TextStyle(color: t.colorTextMuted),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: t.spaceContentActionGap),
          trailing,
        ],
      ),
    );
  }
}

class KCatalogEditorPreview extends StatelessWidget {
  const KCatalogEditorPreview({
    required this.image,
    required this.name,
    required this.subtitle,
    this.tags = const [],
    this.label = 'So sehen es Kund:innen',
    super.key,
  });
  final Widget image;
  final String name, subtitle, label;
  final List<Widget> tags;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return KCatalogEditorCard(
      inset: false,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(t.spaceContentActionGap),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(t.radiusControl),
                    child: image,
                  ),
                ),
                SizedBox(width: t.spaceContentActionGap),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: t.spaceControlGap + t.spaceMicro,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KText(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: t.spaceMicro / 2),
                        KText(
                          subtitle,
                          variant: KTextVariant.caption,
                          style: TextStyle(color: t.colorTextMuted),
                        ),
                        if (tags.isNotEmpty) ...[
                          SizedBox(height: t.spaceControlGap),
                          KInline(
                            gap: KLayoutGap.control,
                            wrap: true,
                            children: tags,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: t.spaceControlGap + t.spaceMicro,
            top: t.spaceControlGap + t.spaceMicro / 2,
            child: KText(
              label,
              variant: KTextVariant.caption,
              style: TextStyle(fontSize: 11.5, color: t.colorTextMuted),
            ),
          ),
        ],
      ),
    );
  }
}
