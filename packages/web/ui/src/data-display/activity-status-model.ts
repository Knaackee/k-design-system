export interface ActivityStatusItem {
  completed?: boolean;
}

export function activityDayStatus(
  items: readonly ActivityStatusItem[],
  legacyCompleted: boolean,
) {
  const count = items.length;
  const completed = items.filter(
    (item) => item.completed ?? legacyCompleted,
  ).length;
  const open = count - completed;
  return {
    count,
    completed,
    open,
    level:
      count === 0 ? 0 : count === 1 ? 1 : count <= 3 ? 2 : count <= 7 ? 3 : 4,
    tone: count === 0 ? "empty" : open > 0 ? "open" : "done",
    summary: `${count} Issues, ${open} offen, ${completed} erledigt`,
  } as const;
}
