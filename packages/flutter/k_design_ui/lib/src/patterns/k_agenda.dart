import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_text.dart';

enum KAgendaState { upcoming, current, completed }

class KAgendaItem {
  const KAgendaItem({
    required this.id,
    required this.time,
    required this.title,
    this.description,
    this.transition,
    this.state = KAgendaState.upcoming,
  });
  final String id, time, title;
  final String? description;
  final Widget? transition;
  final KAgendaState state;
}

class KAgenda extends StatelessWidget {
  const KAgenda({required this.items, required this.label, super.key});
  final List<KAgendaItem> items;
  final String label;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      label: label,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: t.fontBodySmallSize * 4,
                    child: KText(
                      items[i].time,
                      variant: KTextVariant.bodySmall,
                      align: TextAlign.end,
                      style: TextStyle(
                        fontWeight: t.fontHeadingWeight,
                        color: items[i].state == KAgendaState.completed
                            ? t.colorTextMuted
                            : t.colorTextPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: t.spaceControlGap,
                    ),
                    child: SizedBox(
                      width: t.fontBodySize,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          if (i < items.length - 1)
                            Positioned(
                              top: t.sizeIconDefault / 2,
                              bottom: -t.sizeIconDefault / 2,
                              child: Container(
                                width: t.borderWidthStrong,
                                color: t.colorBorderDefault,
                              ),
                            ),
                          Positioned(
                            top: t.sizeIconDefault / 4,
                            child: Container(
                              width: t.sizeIconDefault / 2,
                              height: t.sizeIconDefault / 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: switch (items[i].state) {
                                  KAgendaState.current =>
                                    t.colorBrandPrimaryAccent,
                                  KAgendaState.completed => t.colorTextMuted,
                                  KAgendaState.upcoming => t.colorSurfaceCanvas,
                                },
                                border: Border.all(
                                  width: t.borderWidthStrong,
                                  color: items[i].state == KAgendaState.current
                                      ? t.colorBrandPrimaryAccent
                                      : t.colorTextMuted,
                                ),
                                boxShadow:
                                    items[i].state == KAgendaState.current
                                    ? [
                                        BoxShadow(
                                          color: t.colorBrandPrimaryBackground,
                                          spreadRadius: t.borderWidthStrong * 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: t.spaceContentActionGap),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          KText(
                            items[i].title,
                            variant: KTextVariant.label,
                            style: items[i].state == KAgendaState.completed
                                ? TextStyle(color: t.colorTextMuted)
                                : null,
                          ),
                          if (items[i].description != null) ...[
                            SizedBox(height: t.spaceControlGap),
                            KText(
                              items[i].description!,
                              variant: KTextVariant.bodySmall,
                              style: TextStyle(color: t.colorTextMuted),
                            ),
                          ],
                          if (items[i].transition != null)
                            Padding(
                              padding: EdgeInsets.only(top: t.spaceControlGap),
                              child: items[i].transition!,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
