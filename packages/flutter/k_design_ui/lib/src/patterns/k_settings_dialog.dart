import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/k_icon_button.dart';
import '../basic_feedback.dart';
import '../data_display/k_list.dart';
import '../localization/k_localization.dart';
import '../navigation/k_sidebar.dart';
import '../overlays/k_adaptive_dialog.dart';
import '../overlays/k_sheet_drag.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_text.dart';

/// One area of a [KSettingsDialog] (Decision 0017).
class KSettingsDialogSection {
  const KSettingsDialogSection({
    required this.id,
    required this.title,
    required this.child,
    this.group,
    this.icon,
    this.description,
    this.summary,
    this.status,
    this.dirty = false,
  });

  final String id;
  final String title;

  /// Sections with the same group are listed under one label, in order.
  final String? group;

  /// Icon in the navigation on tablets and desktops.
  final KIconName? icon;
  final String? description;

  /// Short state on the phone list ("2 of 3 active").
  final String? summary;

  /// [KStatusTone.warning] or [KStatusTone.error] marks the section in the
  /// navigation; the section itself explains it with a [KAlert].
  final KStatusTone? status;

  /// Unsaved changes in this section.
  final bool dirty;
  final Widget child;
}

/// Settings of one object in a dialog: a section navigation beside the
/// content on tablets and desktops, a bottom sheet with a section list and
/// detail pages on phones (Decision 0017). One [footer] (usually
/// [KSaveBar]) saves all sections together.
class KSettingsDialog extends StatefulWidget {
  const KSettingsDialog({
    required this.title,
    required this.sections,
    this.subtitle,
    this.leading,
    this.headerAction,
    this.footer,
    this.selectedId,
    this.onSelectedIdChanged,
    this.onClose,
    this.closeLabel = 'Close',
    this.navigationLabel = 'Sections',
    super.key,
  });

  /// Below this width the dialog shows the phone layout.
  static const breakpoint = KAdaptiveDialog.breakpoint;

  final String title;
  final String? subtitle;

  /// Avatar or icon before the title.
  final Widget? leading;

  /// A status shown in the header, for example a [KButton] that selects
  /// the section with a problem.
  final Widget? headerAction;
  final Widget? footer;
  final List<KSettingsDialogSection> sections;

  /// The open section. On phones `null` shows the section list.
  final String? selectedId;
  final ValueChanged<String?>? onSelectedIdChanged;
  final VoidCallback? onClose;
  final String closeLabel;
  final String navigationLabel;

  /// Opens the dialog as a centred dialog or, on phones, a bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    if (MediaQuery.sizeOf(context).width < breakpoint) {
      return showModalBottomSheet<T>(
        context: context,
        useRootNavigator: true,
        useSafeArea: true,
        isScrollControlled: true,
        isDismissible: barrierDismissible,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (routeContext) => LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: SizedBox(
              height: constraints.maxHeight * .9,
              child: KSheetDrag(
                enabled: barrierDismissible,
                onDismiss: () => Navigator.of(routeContext).maybePop(),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(routeContext).bottom,
                  ),
                  child: builder(routeContext),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: true,
      builder: (routeContext) => Center(child: builder(routeContext)),
    );
  }

  @override
  State<KSettingsDialog> createState() => _KSettingsDialogState();
}

class _KSettingsDialogState extends State<KSettingsDialog> {
  String? _selected;
  final _scroll = ScrollController();

  String? get _current => widget.onSelectedIdChanged != null
      ? widget.selectedId
      : _selected ?? widget.selectedId;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _select(String? id) {
    if (_scroll.hasClients) _scroll.jumpTo(0);
    if (widget.onSelectedIdChanged case final changed?) {
      changed(id);
    } else {
      setState(() => _selected = id);
    }
  }

  List<(String?, List<KSettingsDialogSection>)> get _groups {
    final groups = <(String?, List<KSettingsDialogSection>)>[];
    for (final section in widget.sections) {
      if (groups.isEmpty || groups.last.$1 != section.group) {
        groups.add((section.group, []));
      }
      groups.last.$2.add(section);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= KSettingsDialog.breakpoint;
        final width = wide
            ? constraints.maxWidth.clamp(0, t.componentSettingsDialogWidth)
            : constraints.maxWidth;
        final height = wide && constraints.hasBoundedHeight
            ? constraints.maxHeight.clamp(0, t.componentSettingsDialogHeight)
            : constraints.hasBoundedHeight
            ? constraints.maxHeight
            : t.componentSettingsDialogHeight;
        final radius = Radius.circular(t.radiusOverlay);
        return SizedBox(
          width: width.toDouble(),
          height: height.toDouble(),
          child: Material(
            color: t.colorSurfaceRaised,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: t.colorBorderDefault,
                width: t.borderWidthDefault,
              ),
              borderRadius: wide
                  ? BorderRadius.all(radius)
                  : BorderRadius.vertical(top: radius),
            ),
            clipBehavior: Clip.antiAlias,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeLeft: true,
              removeRight: true,
              removeBottom: wide,
              child: wide ? _wide(context, t) : _compact(context, t),
            ),
          ),
        );
      },
    );
  }

  Widget _divider(KDesignTokens t) =>
      Divider(height: t.borderWidthDefault, color: t.colorBorderDefault);

  Widget _close(KDesignTokens t) => widget.onClose == null
      ? const SizedBox.shrink()
      : KIconButton(
          label: widget.closeLabel,
          icon: KIconName.x,
          onPressed: widget.onClose,
        );

  Widget _header(KDesignTokens t, {Widget? back, String? title}) => Padding(
    padding: EdgeInsetsDirectional.fromSTEB(
      back == null ? t.spaceLayoutGutter : t.spaceTight,
      t.spaceControlInsetInline,
      t.spaceSmallInset,
      t.spaceControlInsetInline,
    ),
    child: Row(
      spacing: t.spaceControlInsetInline,
      children: [
        ?(back ?? widget.leading),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              KText(
                title ?? widget.title,
                variant: KTextVariant.heading5,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (back == null && widget.subtitle != null)
                KText(
                  widget.subtitle!,
                  variant: KTextVariant.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.colorTextMuted),
                ),
            ],
          ),
        ),
        if (back == null && widget.headerAction != null) widget.headerAction!,
        _close(t),
      ],
    ),
  );

  Widget _content(
    KDesignTokens t,
    KSettingsDialogSection section,
    double pad, {
    required bool showTitle,
  }) => SingleChildScrollView(
    controller: _scroll,
    padding: EdgeInsets.all(pad),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) KText(section.title, variant: KTextVariant.heading4),
        if (section.description case final text?) ...[
          if (showTitle) SizedBox(height: t.spaceTight),
          KText(
            text,
            variant: KTextVariant.bodySmall,
            style: TextStyle(color: t.colorTextMuted),
          ),
        ],
        if (showTitle || section.description != null)
          SizedBox(height: t.spaceLayoutGutter),
        section.child,
      ],
    ),
  );

  Widget? _marker(KDesignTokens t, KSettingsDialogSection section) {
    final color = section.dirty
        ? t.colorActionPrimaryBackground
        : switch (section.status) {
            KStatusTone.error => t.colorStatusErrorAccent,
            KStatusTone.warning => t.colorStatusWarningAccent,
            KStatusTone.info => t.colorStatusInfoAccent,
            KStatusTone.success => t.colorStatusSuccessAccent,
            _ => null,
          };
    if (color == null) return null;
    return Container(
      width: t.spaceSmallInset,
      height: t.spaceSmallInset,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _wide(BuildContext context, KDesignTokens t) {
    final current =
        widget.sections.where((s) => s.id == _current).firstOrNull ??
        widget.sections.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(t),
        _divider(t),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KSidebar(
                mode: KSidebarMode.expanded,
                expandedWidth: t.componentSettingsDialogNavWidth,
                semanticLabel: widget.navigationLabel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KSidebarBody(
                      children: [
                        for (final (label, sections) in _groups)
                          KSidebarGroup(
                            label: label,
                            children: [
                              for (final section in sections)
                                KSidebarItem(
                                  key: ValueKey('k-settings-nav:${section.id}'),
                                  label: section.title,
                                  leading: section.icon == null
                                      ? null
                                      : KIcon(section.icon!),
                                  active: section.id == current.id,
                                  trailing: _marker(t, section),
                                  onPressed: () => _select(section.id),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _content(
                  t,
                  current,
                  t.componentSettingsDialogContentPadding,
                  showTitle: true,
                ),
              ),
            ],
          ),
        ),
        if (widget.footer case final footer?) ...[_divider(t), footer],
      ],
    );
  }

  Widget _compact(BuildContext context, KDesignTokens t) {
    final current = widget.sections.where((s) => s.id == _current).firstOrNull;
    final back = current == null
        ? null
        : KButton(
            label: KLocalization.of(context).text('settingsBack'),
            leading: const KIcon(KIconName.chevronLeft),
            variant: KButtonVariant.ghost,
            onPressed: () => _select(null),
          );
    final list = SingleChildScrollView(
      controller: _scroll,
      padding: EdgeInsets.all(t.spaceLayoutGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: t.spaceLayoutGutter,
        children: [
          for (final (label, sections) in _groups)
            KList(
              title: label,
              children: [
                for (final section in sections)
                  KListItem(
                    key: ValueKey('k-settings-row:${section.id}'),
                    title: section.title,
                    description: section.summary,
                    trailing: _marker(t, section),
                    disclosure: true,
                    onPressed: () => _select(section.id),
                  ),
              ],
            ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: t.componentBottomSheetGripAreaMinHeight / 2,
          child: Center(
            child: Container(
              width: t.componentBottomSheetGripWidth,
              height: t.componentBottomSheetGripHeight,
              decoration: BoxDecoration(
                color: t.colorBorderStrong,
                borderRadius: BorderRadius.circular(t.radiusExtraSmall),
              ),
            ),
          ),
        ),
        _header(t, back: back, title: current?.title),
        _divider(t),
        Expanded(
          child: current == null
              ? list
              : _content(t, current, t.spaceLayoutGutter, showTitle: false),
        ),
        if (widget.footer case final footer?) ...[
          _divider(t),
          SafeArea(top: false, child: footer),
        ],
      ],
    );
  }
}

/// Saves the changes of a form or [KSettingsDialog] together: the count of
/// unsaved changes, Discard and Save (Decision 0017).
class KSaveBar extends StatelessWidget {
  const KSaveBar({
    required this.changes,
    required this.onSave,
    this.onDiscard,
    this.saving = false,
    super.key,
  });

  final int changes;
  final VoidCallback onSave;
  final VoidCallback? onDiscard;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final l = KLocalization.of(context);
    final dirty = changes > 0;
    final state = !dirty
        ? l.text('allSaved')
        : changes == 1
        ? l.text('unsavedChange')
        : l.text('unsavedChanges').replaceAll('{count}', '$changes');
    final stateText = Semantics(
      liveRegion: true,
      child: KText(
        state,
        variant: KTextVariant.bodySmall,
        style: TextStyle(color: dirty ? t.colorTextPrimary : t.colorTextMuted),
      ),
    );
    final buttons = [
      if (onDiscard != null)
        KButton(
          label: l.text('discard'),
          variant: KButtonVariant.ghost,
          onPressed: dirty && !saving ? onDiscard : null,
        ),
      KButton(
        label: l.text('save'),
        onPressed: dirty && !saving ? onSave : null,
      ),
    ];
    // Narrow or large text: the state above the buttons (Web: container
    // query on the bar's outer width).
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: t.spaceLayoutGutter,
          vertical: t.spaceControlInsetInline,
        ),
        child:
            constraints.maxWidth < 360 ||
                MediaQuery.textScalerOf(context).scale(1) >= 1.3
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: t.spaceControlGap,
                children: [
                  stateText,
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: t.spaceControlGap,
                    runSpacing: t.spaceControlGap,
                    children: buttons,
                  ),
                ],
              )
            : Row(
                spacing: t.spaceControlGap,
                children: [
                  Expanded(child: stateText),
                  ...buttons,
                ],
              ),
      ),
    );
  }
}
