import { useState } from "react";

import { KActivityHeatmap, KIcon, KSelect } from "@k-design-system/ui";

import "./activity-fixture.css";

// Gallery prototype only: fixed dates and sample issues, not product activity.

const today = "2026-10-02";

const projects = [
  { value: "tasks", label: "Tasks", color: "#2A9D8F" },

  { value: "orbit", label: "Orbit", color: "#E76F51" },
];

const titles = [
  "Projekt-Icons angleichen",

  "Artefakte bereitstellen",

  "Orbit-Filter verbessern",

  "Webvorschau prÃ¼fen",

  "Profilwechsel absichern",

  "Dokumentation aktualisieren",
];

function day(offset: number) {
  return new Date(Date.UTC(2026, 5, 29 + offset)).toISOString().slice(0, 10);
}

const issues = Array.from({ length: 140 }, (_, i) => {
  const completed = i < 100;

  return {
    id: `ISS-${600 + i}`,

    title: titles[i % titles.length],

    project: projects[i % 2],

    person: i % 3 ? "Denis" : "Hans",

    status: completed ? "done" : i % 2 ? "in-progress" : "backlog",

    date: completed
      ? day((i * i * 13 + i * 7) % 96)
      : i % 7
        ? day(96 + ((i * 7) % 85))
        : null,
  };
});

const statusIssues = [1, 3, 7, 8].flatMap((count, group) =>
  Array.from({ length: count }, (_, index) => ({
    id: `STATUS-${group}-${index}`,
    title: `Statusbeispiel ${group + 1}`,
    project: projects[group % 2],
    person: "Denis",
    status:
      group === 0 || (group === 2 && index === 0) ? "in-progress" : "done",
    date: day(95 + group),
  })),
);

export function ActivityFixture({
  initialMode = "completed",
  phone = false,
  empty = false,
  statusView = false,
}: {
  initialMode?: "completed" | "upcoming";
  phone?: boolean;
  empty?: boolean;
  statusView?: boolean;
}) {
  const [mode, setMode] = useState(initialMode);

  const [selectedProjects, setProjects] = useState<string[]>([]);

  const [people, setPeople] = useState<string[]>([]);

  const [statuses, setStatuses] = useState<string[]>([]);

  const [detail, setDetail] = useState<string | null>(null);

  const filtered = (empty ? [] : statusView ? statusIssues : issues).filter(
    (issue) =>
      (statusView ||
        (mode === "completed"
          ? issue.status === "done"
          : issue.status !== "done")) &&
      (!selectedProjects.length ||
        selectedProjects.includes(issue.project.value)) &&
      (!people.length || people.includes(issue.person)) &&
      (!statuses.length || statuses.includes(issue.status)),
  );

  const changeMode = (value: string) => {
    setMode(value as typeof mode);
    setStatuses([]);
    setDetail(null);
  };

  return (
    <section className={`activity-demo${phone ? " activity-demo--phone" : ""}`}>
      <header>
        <span className="activity-demo-eyebrow">
          WORKSPACE Â· BEISPIELDATEN
        </span>

        <h1>AktivitÃ¤t</h1>

        <p>Was geschafft wurde. Was als NÃ¤chstes ansteht.</p>
      </header>

      <div className="activity-demo-toolbar">
        <KSelect
          label="Ansicht"

          value={mode}

          onValueChange={changeMode}

          options={[
            { value: "completed", label: "Erledigt", icon: "circle-check" },

            { value: "upcoming", label: "Anstehend", icon: "calendar" },
          ]}
        />

        <KSelect
          label="Projekte"

          multiple

          values={selectedProjects}

          onValuesChange={setProjects}

          placeholder="Alle Projekte"

          options={projects.map((project) => ({
            ...project,

            leading: (
              <span style={{ color: project.color }}>
                <KIcon
                  name={project.value === "orbit" ? "rocket" : "code"}

                  size={16}
                />
              </span>
            ),
          }))}
        />

        <KSelect
          label="Personen"

          multiple

          values={people}

          onValuesChange={setPeople}

          placeholder="Alle Personen"

          options={[
            { value: "Denis", label: "Denis", icon: "user" },

            { value: "Hans", label: "Hans", icon: "user" },
          ]}
        />

        <KSelect
          label="Status"

          multiple

          values={statuses}

          onValuesChange={setStatuses}

          placeholder={mode === "completed" ? "Erledigt" : "Alle offenen"}

          options={
            mode === "completed"
              ? [{ value: "done", label: "Erledigt", icon: "circle-check" }]
              : [
                  { value: "backlog", label: "Backlog", icon: "inbox" },

                  { value: "in-progress", label: "In Arbeit", icon: "loader" },
                ]
          }
        />
      </div>

      <KActivityHeatmap
        mode={mode}
        today={today}
        phone={phone}
        items={filtered.map((issue) => ({
          ...issue,
          completed: issue.status === "done",
          metadata: `${issue.id} · ${issue.project.label} · ${issue.person}`,
          leading: (
            <KIcon
              name={issue.project.value === "orbit" ? "rocket" : "code"}
              size={18}
            />
          ),
        }))}
        onOpenItem={setDetail}
        onAddDate={(date) => setDetail(`add:${date}`)}
        addLabel="Issue hinzufügen"
      />

      {detail && (
        <p role="status">
          {detail} ausgewählt. In Tasks öffnet sich hier die
          Issue-Detailansicht.
        </p>
      )}
    </section>
  );
}
