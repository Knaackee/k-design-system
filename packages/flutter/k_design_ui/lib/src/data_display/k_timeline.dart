import 'timeline/timeline_model.dart';

export 'timeline/timeline_canvas.dart' show KTimeline;
export 'timeline/timeline_model.dart'
    show TimelineEntry, TimelineGroup, applyTimelineProposal, addTimelineDays;

typedef KTimelineItem = TimelineEntry;
typedef KTimelineGroup = TimelineGroup;
