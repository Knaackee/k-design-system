import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class BookingDetailsFixture extends StatefulWidget {
  const BookingDetailsFixture({super.key});
  @override
  State<BookingDetailsFixture> createState() => _BookingDetailsFixtureState();
}

class _BookingDetailsFixtureState extends State<BookingDetailsFixture> {
  bool confirm = false;
  bool cancelled = false;
  bool open = true;

  Widget detail(BuildContext context, bool inline) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return KAdaptiveSheet(
      title: 'Buchungsdetails',
      inline: inline,
      hero: ColoredBox(
        color: t.colorSurfaceSubtle,
        child: const Center(child: KIcon(KIconName.mapPin)),
      ),
      floatingActions: KMenuButton(
        label: 'Mehr',
        overflow: true,
        actions: [
          KMenuAction(id: 'refresh', label: 'Aktualisieren', onSelect: () {}),
        ],
      ),
      heroOverlays: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const KBadge(
            child: KText('7 Min. · 2,2 km', variant: KTextVariant.caption),
          ),
          KIconButton(
            label: 'Karte öffnen',
            icon: KIconName.maximize,
            onPressed: () {},
          ),
        ],
      ),
      onClose: () => setState(() => open = false),
      closeLabel: 'Schließen',
      footer: confirm
          ? KStack(
              align: KLayoutAlign.stretch,
              children: [
                const KText('Termin absagen?', variant: KTextVariant.label),
                const KText(
                  'Anna Winter wird benachrichtigt. Das lässt sich nicht rückgängig machen.',
                  variant: KTextVariant.bodySmall,
                ),
                KInline(
                  gap: KLayoutGap.control,
                  wrap: true,
                  children: [
                    KButton(
                      label: 'Behalten',
                      variant: KButtonVariant.ghost,
                      onPressed: () => setState(() => confirm = false),
                    ),
                    KButton(
                      label: 'Absagen',
                      tone: KButtonTone.destructive,
                      onPressed: () => setState(() {
                        confirm = false;
                        cancelled = true;
                      }),
                    ),
                  ],
                ),
              ],
            )
          : null,
      child: KStack(
        gap: KLayoutGap.action,
        align: KLayoutAlign.stretch,
        children: [
          KInline(
            gap: KLayoutGap.control,
            wrap: true,
            children: [
              const KAvatar(alt: 'Anna Winter', size: KAvatarSize.small),
              const KStack(
                children: [
                  KText('Anna Winter', variant: KTextVariant.heading3),
                  KText(
                    'Haarschnitt · 60 Min.',
                    variant: KTextVariant.bodySmall,
                  ),
                ],
              ),
              KBadge(
                variant: cancelled
                    ? KBadgeVariant.destructive
                    : KBadgeVariant.success,
                child: KText(
                  cancelled ? 'Abgesagt' : 'Bestätigt',
                  variant: KTextVariant.caption,
                ),
              ),
            ],
          ),
          KInline(
            gap: KLayoutGap.control,
            wrap: true,
            children: [
              KButton(
                label: 'Route starten',
                leading: const KIcon(KIconName.route),
                onPressed: cancelled ? null : () {},
              ),
              KButton(
                label: 'Tagesplan',
                variant: KButtonVariant.secondary,
                leading: const KIcon(KIconName.mapPin),
                onPressed: () {},
              ),
            ],
          ),
          KList(
            children: [
              const KListItem(
                leadingIcon: KIconName.clock,
                title: '08:30–09:30',
                description: 'Mo., 23. November 2026',
              ),
              if (!cancelled)
                const KListItem(
                  leadingIcon: KIconName.car,
                  title: 'Losfahren um 07:45',
                  description: '45 Min. vor Beginn · 7 Min. · 2,2 km',
                ),
              const KListItem(
                leadingIcon: KIconName.mapPin,
                title: 'Torstraße 120, 10119 Berlin',
                description: 'Rosenthaler Vorstadt',
              ),
              const KListItem(
                leadingIcon: KIconName.mail,
                title: 'demo.customer.1@example.invalid',
                description: 'E-Mail',
              ),
              KListItem(
                leadingIcon: KIconName.users,
                title: 'Kundenprofil',
                description: 'Frühere Termine und Notizen',
                onPressed: () {},
              ),
            ],
          ),
          if (!cancelled)
            KList(
              children: [
                KListItem(
                  leadingIcon: KIconName.x,
                  title: 'Termin absagen',
                  tone: KListItemTone.destructive,
                  description: 'Anna Winter wird benachrichtigt.',
                  onPressed: () => setState(() => confirm = true),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final inline = constraints.maxWidth >= KAdaptiveDialog.breakpoint;
      final list = KStack(
        children: [
          const KText('Buchungen', variant: KTextVariant.heading2),
          KButton(
            label: 'Anna Winter öffnen',
            onPressed: () => setState(() => open = true),
          ),
        ],
      );
      if (!inline) return open ? detail(context, false) : list;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: list),
          if (open) detail(context, true),
        ],
      );
    },
  );
}
