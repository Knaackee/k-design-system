import 'gantt/gantt_model.dart';

export 'gantt/gantt_canvas.dart' show KGantt;
export 'gantt/gantt_model.dart'
    show
        GanttTask,
        GanttLink,
        applyGanttProposal,
        summarizeGanttTasks,
        ganttAddDays;

typedef KGanttTask = GanttTask;
typedef KGanttLink = GanttLink;
