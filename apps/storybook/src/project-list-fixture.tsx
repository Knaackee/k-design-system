import {
  KBadge,
  KButton,
  KCard,
  KSearchField,
  KSelect,
  KStack,
  KText,
} from "@k-design-system/ui";
import type { DemoProject } from "./project-form-fixture.js";

export function ProjectListFixture({
  projects,
  onSelect,
  onCreate,
  search,
  setSearch,
  status,
  setStatus,
}: {
  search: string;
  setSearch: (value: string) => void;
  status: string;
  setStatus: (value: string) => void;
  projects: DemoProject[];
  onSelect: (project: DemoProject) => void;
  onCreate?: () => void;
}) {
  const matches = projects.filter(
    (project) =>
      project.name
        .toLocaleLowerCase()
        .includes(search.trim().toLocaleLowerCase()) &&
      (status === "all" || project.status === status),
  );
  return (
    <KCard>
      <KStack gap="action" align="stretch">
        <KText variant="heading4" as="h2">
          Projects
        </KText>
        <KSearchField
          aria-label="Search projects"
          placeholder="Search projects"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <KSelect
          label="Project status"
          value={status}
          onValueChange={setStatus}
          options={[
            { value: "all", label: "All statuses" },
            ...["Planned", "In progress", "In review"].map((value) => ({
              value,
              label: value,
            })),
          ]}
        />
        {onCreate && (
          <KButton variant="secondary" onClick={onCreate}>
            New project
          </KButton>
        )}
        <KText variant="bodySmall" role="status">
          {matches.length} projects
        </KText>
        {matches.map((project, index) => (
          <div
            className="dashboard-shell__project"
            key={`${project.name}-${index}`}
          >
            <KButton variant="ghost" onClick={() => onSelect(project)}>
              {project.name}
            </KButton>
            <KBadge variant="secondary">{project.status}</KBadge>
          </div>
        ))}
        {matches.length === 0 && (
          <KStack gap="control">
            <KText>No matching projects.</KText>
            <KButton
              variant="ghost"
              onClick={() => {
                setSearch("");
                setStatus("all");
              }}
            >
              Clear filters
            </KButton>
          </KStack>
        )}
      </KStack>
    </KCard>
  );
}
