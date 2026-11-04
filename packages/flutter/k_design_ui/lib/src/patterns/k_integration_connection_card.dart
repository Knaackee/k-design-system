import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../basic_components.dart';
import '../primitives/k_button.dart';
import '../primitives/k_leading.dart';
import '../primitives/k_text.dart';
import 'k_integrations.dart';

class KIntegrationConnectionCard extends StatelessWidget {
  static const double defaultMaxWidth = 620;

  const KIntegrationConnectionCard({
    required this.name,
    required this.icon,
    required this.description,
    required this.permissions,
    required this.stateLabel,
    this.state = KIntegrationConnectionState.disconnected,
    this.availability,
    this.connectLabel = 'Verbinden',
    this.retryLabel = 'Erneut versuchen',
    this.disconnectLabel = 'Verbindung trennen',
    this.permissionsTitle = 'Zugriff auf',
    this.onConnect,
    this.onRetry,
    this.onDisconnect,
    this.maxWidth = defaultMaxWidth,
    super.key,
  });

  final String name;
  final Widget icon;
  final String description;
  final List<String> permissions;
  final KIntegrationConnectionState state;
  final String? availability;
  final String connectLabel;
  final String retryLabel;
  final String disconnectLabel;
  final String permissionsTitle;
  final String stateLabel;
  final VoidCallback? onConnect;
  final VoidCallback? onRetry;
  final VoidCallback? onDisconnect;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final color = switch (state) {
      KIntegrationConnectionState.pending => t.colorStatusInfoAccent,
      KIntegrationConnectionState.connected => t.colorStatusSuccessAccent,
      KIntegrationConnectionState.error => t.colorStatusErrorAccent,
      KIntegrationConnectionState.unavailable => t.colorStatusWarningAccent,
      KIntegrationConnectionState.disconnected => t.colorTextMuted,
    };
    final action = switch (state) {
      KIntegrationConnectionState.pending => KButton(
        label: connectLabel,
        loading: true,
        onPressed: null,
      ),
      KIntegrationConnectionState.connected => KButton(
        label: disconnectLabel,
        variant: KButtonVariant.secondary,
        onPressed: onDisconnect,
      ),
      KIntegrationConnectionState.error => KButton(
        label: retryLabel,
        variant: KButtonVariant.secondary,
        onPressed: onRetry,
      ),
      KIntegrationConnectionState.unavailable => KButton(
        label: connectLabel,
        onPressed: null,
      ),
      KIntegrationConnectionState.disconnected => KButton(
        label: connectLabel,
        onPressed: onConnect,
      ),
    };
    return Semantics(
      container: true,
      label: '$name. $stateLabel',
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.all(t.spaceCardPadding),
        decoration: BoxDecoration(
          color: t.colorSurfaceRaised,
          border: Border.all(color: t.colorBorderDefault),
          borderRadius: BorderRadius.circular(t.radiusCard),
          boxShadow: t.elevationLow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                KIntegrationIcon(child: icon),
                SizedBox(width: t.spaceControlInsetInline),
                Expanded(
                  child: Wrap(
                    spacing: t.spaceControlGap,
                    runSpacing: t.spaceControlGap,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      KText(name, variant: KTextVariant.heading4),
                      if (availability != null)
                        KBadge(
                          variant: KBadgeVariant.info,
                          child: Text(availability!),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: t.spaceContentActionGap),
            KText(description, style: TextStyle(color: t.colorTextMuted)),
            SizedBox(height: t.spaceContentActionGap),
            Container(
              padding: EdgeInsets.all(t.spaceControlInsetInline),
              decoration: BoxDecoration(
                color: t.colorSurfaceSubtle,
                borderRadius: BorderRadius.circular(t.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KText(permissionsTitle, variant: KTextVariant.label),
                  SizedBox(height: t.spaceControlGap),
                  for (final permission in permissions)
                    Padding(
                      padding: EdgeInsets.only(top: t.spaceControlGap),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(
                            child: KText(
                              permission,
                              variant: KTextVariant.bodySmall,
                              style: TextStyle(color: t.colorTextMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: t.spaceContentActionGap),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: t.spaceControlGap,
              runSpacing: t.spaceControlGap,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KLeading(
                      size: t.sizeIndicatorTiny,
                      textVariant: KTextVariant.bodySmall,
                      child: Container(
                        width: t.sizeIndicatorTiny,
                        height: t.sizeIndicatorTiny,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: t.spaceControlGap),
                    Flexible(
                      child: KText(
                        stateLabel,
                        variant: KTextVariant.bodySmall,
                        style: TextStyle(color: t.colorTextMuted),
                      ),
                    ),
                  ],
                ),
                action,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
