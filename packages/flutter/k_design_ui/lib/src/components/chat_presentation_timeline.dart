part of 'chat_presentations.dart';

class KPresentationStop {
  const KPresentationStop({
    required this.id,
    required this.title,
    required this.time,
    this.description,
    this.current = false,
  });
  final String id;
  final String title;
  final String time;
  final String? description;
  final bool current;
}

class KPresentationTimeline extends StatelessWidget {
  const KPresentationTimeline({
    required this.label,
    required this.stops,
    super.key,
  });
  final String label;
  final List<KPresentationStop> stops;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final gap = t.spaceControlGap;
    return _paddedSurface(
      t,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _meta(label, t),
          SizedBox(height: gap * 2),
          for (var index = 0; index < stops.length; index++)
            Semantics(
              key: ValueKey(stops[index].id),
              selected: stops[index].current,
              child: Stack(
                children: [
                  if (index < stops.length - 1)
                    Positioned(
                      top: t.spaceControlInsetInline,
                      bottom: -4,
                      left: t.spaceTight,
                      child: Container(
                        width: t.borderWidthDefault,
                        color: t.colorBorderDefault,
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == stops.length - 1 ? 0 : gap * 3,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: t.componentPresentationTimelineRailWidth,
                          child: Align(
                            alignment: AlignmentDirectional.topStart,
                            child: Container(
                              width: t.spaceControlGap,
                              height: t.spaceControlGap,
                              margin: EdgeInsets.only(
                                top: t.componentPresentationTimelineDotOffset,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: stops[index].current
                                    ? t.colorTextPrimary
                                    : null,
                                border: Border.all(
                                  color: stops[index].current
                                      ? t.colorTextPrimary
                                      : t.colorTextMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: gap * 1.5),
                        KText(
                          stops[index].time,
                          style: TextStyle(
                            color: t.colorTextMuted,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        SizedBox(width: gap * 1.5),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _strong(stops[index].title, t),
                              if (stops[index].description != null)
                                KText(
                                  stops[index].description!,
                                  style: TextStyle(color: t.colorTextMuted),
                                ),
                            ],
                          ),
                        ),
                      ],
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
