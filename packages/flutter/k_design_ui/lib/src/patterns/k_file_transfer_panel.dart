part of 'k_files.dart';

/// A consumer-controlled transfer surface anchored by its parent workspace.
class KFileTransferPanel extends StatelessWidget {
  const KFileTransferPanel({
    required this.items,
    required this.collapsed,
    required this.onCollapsedChange,
    required this.onClose,
    this.label = 'Übertragungen',
    this.child,
    super.key,
  });
  final List<KFileTransfer> items;
  final bool collapsed;
  final ValueChanged<bool> onCollapsedChange;
  final VoidCallback onClose;
  final String label;

  /// Optional consumer-owned controls within the shared transfer surface.
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Material(
      color: t.colorSurfaceCanvas,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusControl),
        side: BorderSide(color: t.colorBorderDefault),
      ),
      child: SizedBox(
        width: t.layoutCompactWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: t.colorSurfaceRaised,
              padding: EdgeInsets.symmetric(
                horizontal: t.spaceControlInsetInline,
                vertical: t.spaceControlGap,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: t.fontControlSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  KIconButton(
                    label: collapsed
                        ? 'Übertragungen aufklappen'
                        : 'Übertragungen einklappen',
                    icon: collapsed
                        ? KIconName.chevronUp
                        : KIconName.chevronDown,
                    onPressed: () => onCollapsedChange(!collapsed),
                  ),
                  KIconButton(
                    label: 'Übertragungen schließen',
                    icon: KIconName.x,
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            Offstage(
              offstage: collapsed,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      (MediaQuery.sizeOf(context).height * .5 -
                              t.sizeHitTarget -
                              16)
                          .clamp(0, double.infinity),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child:
                        child ??
                        (items.isEmpty
                            ? const Text('Keine Übertragungen')
                            : KTransferList(items: items)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
