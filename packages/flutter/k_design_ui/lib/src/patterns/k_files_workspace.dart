import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../actions/k_icon_button.dart';
import '../navigation/k_sidebar.dart';
import '../primitives/k_icon.dart';

/// Docked explorer on tablet and desktop; modal explorer on compact screens.
class KFilesWorkspace extends StatelessWidget {
  const KFilesWorkspace({
    required this.sidebarOpen,
    required this.onSidebarOpenChange,
    required this.navigation,
    required this.child,
    this.sidebarHeader,
    this.header,
    this.search,
    this.tabs,
    this.title,
    this.sidebarFooter,
    this.actions,
    this.constrainContentWidth = true,
    super.key,
  });

  final bool sidebarOpen;
  final ValueChanged<bool> onSidebarOpenChange;
  final Widget navigation, child;

  /// Persistent content-area header above file tabs and actions.
  final Widget? header;
  final Widget? sidebarHeader, search, tabs, title, sidebarFooter, actions;
  final bool constrainContentWidth;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : t.componentFilesTransition;
    return LayoutBuilder(
      builder: (context, bounds) {
        final mobile = bounds.maxWidth < 600;
        final panelWidth = math.min(
          t.layoutPanelWidth,
          math.max(0.0, bounds.maxWidth - (mobile ? 32.0 : 0.0)),
        );

        Widget panel({required bool modal}) => Semantics(
          key: ValueKey(modal ? 'files-drawer' : 'files-sidebar'),
          scopesRoute: modal,
          explicitChildNodes: modal,
          namesRoute: modal,
          label: 'Dateien',
          child: FocusScope(
            autofocus: modal,
            child: KSidebar(
              mode: KSidebarMode.expanded,
              expandedWidth: panelWidth,
              semanticLabel: 'Dateien',
              child: Column(
                children: [
                  KSidebarHeader(
                    child: Column(
                      children: [
                        Row(
                          spacing: t.spaceControlGap,
                          children: [
                            Expanded(child: sidebarHeader ?? SizedBox()),
                            KIconButton(
                              label: 'Dateien schließen',
                              icon: KIconName.menu,
                              onPressed: () => onSidebarOpenChange(false),
                            ),
                          ],
                        ),
                        if (search != null) ...[
                          SizedBox(height: t.spaceControlGap),
                          search!,
                        ],
                      ],
                    ),
                  ),
                  KSidebarBody(children: [navigation]),
                  if (sidebarFooter != null)
                    KSidebarFooter(child: sidebarFooter!),
                ],
              ),
            ),
          ),
        );

        final stage = ExcludeFocus(
          excluding: mobile && sidebarOpen,
          child: ExcludeSemantics(
            excluding: mobile && sidebarOpen,
            child: Column(
              children: [
                if (header != null)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      header!,
                      if (!sidebarOpen)
                        Positioned(
                          left: t.spaceControlInsetInline,
                          child: KIconButton(
                            label: 'Dateien öffnen',
                            icon: KIconName.menu,
                            onPressed: () => onSidebarOpenChange(true),
                          ),
                        ),
                    ],
                  ),
                if (tabs != null ||
                    title != null ||
                    actions != null ||
                    (header == null && !sidebarOpen))
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: t.colorBorderDefault),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: t.spaceControlInsetInline,
                      ),
                      child: Row(
                        spacing: 4,
                        children: [
                          if (!sidebarOpen && header == null)
                            SizedBox(
                              width:
                                  t.componentFilesIconSize +
                                  t.spaceControlInsetInline * 2,
                              child: KIconButton(
                                label: 'Dateien öffnen',
                                icon: KIconName.menu,
                                onPressed: () => onSidebarOpenChange(true),
                              ),
                            ),
                          Expanded(
                            child: tabs ?? title ?? const SizedBox.shrink(),
                          ),
                          ?actions,
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: mobile || !constrainContentWidth
                      ? child
                      : Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: t.layoutContentWidth,
                            ),
                            child: SizedBox.expand(child: child),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );

        return Material(
          color: t.colorSurfaceCanvas,
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () {
                if (mobile && sidebarOpen) onSidebarOpenChange(false);
              },
            },
            child: mobile
                ? Stack(
                    children: [
                      stage,
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: !sidebarOpen,
                          child: AnimatedOpacity(
                            duration: duration,
                            opacity: sidebarOpen ? 1 : 0,
                            child: ModalBarrier(
                              color: t.componentFilesBackdrop,
                              dismissible: true,
                              onDismiss: () => onSidebarOpenChange(false),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedSwitcher(
                          duration: duration,
                          transitionBuilder: (child, animation) =>
                              SlideTransition(
                                position: Tween(
                                  begin: const Offset(-1, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                          child: sidebarOpen
                              ? panel(modal: true)
                              : SizedBox.shrink(),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      ClipRect(
                        child: AnimatedAlign(
                          duration: duration,
                          alignment: Alignment.centerLeft,
                          widthFactor: sidebarOpen ? 1 : 0,
                          child: IgnorePointer(
                            ignoring: !sidebarOpen,
                            child: ExcludeFocus(
                              excluding: !sidebarOpen,
                              child: ExcludeSemantics(
                                excluding: !sidebarOpen,
                                child: panel(modal: false),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: stage),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
