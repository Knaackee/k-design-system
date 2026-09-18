export type Project = {
  id: string;
  title: string;
  owner: string;
  budget: number;
  status: string;
  platform: string;
};
export const projects: Project[] = [
  {
    id: "atlas",
    title: "Atlas website",
    owner: "Alex Morgan",
    budget: 12000,
    status: "active",
    platform: "Web",
  },
  {
    id: "orbit",
    title: "Orbit mobile app",
    owner: "Jordan Lee",
    budget: 8500,
    status: "planned",
    platform: "Mobile",
  },
  {
    id: "docs",
    title: "Design system documentation",
    owner: "Sam Rivera",
    budget: 3200,
    status: "active",
    platform: "Web",
  },
  {
    id: "portal",
    title: "Customer portal",
    owner: "Alex Morgan",
    budget: 6400,
    status: "planned",
    platform: "Web",
  },
  {
    id: "audit",
    title: "Accessibility review",
    owner: "Sam Rivera",
    budget: 1800,
    status: "done",
    platform: "Web",
  },
  {
    id: "sync",
    title: "Offline sync",
    owner: "Jordan Lee",
    budget: 4200,
    status: "active",
    platform: "Mobile",
  },
];
export const statuses = [
  { value: "planned", label: "Planned", icon: "minus" as const },
  { value: "active", label: "In progress", icon: "clock" as const },
  { value: "done", label: "Done", icon: "check" as const },
];
export const statusLabel = (value: string) =>
  statuses.find((option) => option.value === value)?.label ?? value;
