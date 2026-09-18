import { useState } from "react";
import {
  KContainer,
  KStack,
  KText,
  KTable,
  KSelect,
  KOverflowMenu,
  type KTableColumn,
} from "@k-design-system/ui";
const projects = [
  {
    id: "atlas",
    title: "Atlas website",
    owner: "Alex Morgan",
    amount: "€12,000",
    status: "active",
  },
  {
    id: "orbit",
    title: "Orbit mobile app",
    owner: "Jordan Lee",
    amount: "€8,500",
    status: "planned",
  },
  {
    id: "docs",
    title: "Design system documentation and accessibility review",
    owner: "Sam Rivera",
    amount: "€3,200",
    status: "done",
  },
];
const options = [
  { value: "planned", label: "Planned", icon: "minus" as const },
  { value: "active", label: "In progress", icon: "clock" as const },
  { value: "done", label: "Done", icon: "check" as const },
];
export function TableFixture({ kind = "basic" }: { kind?: "basic" | "cells" }) {
  const [statuses, setStatuses] = useState<Record<string, string>>(
    Object.fromEntries(projects.map((p) => [p.id, p.status])),
  );
  const [result, setResult] = useState("No action selected");
  const project: KTableColumn = {
    id: "project",
    header: "Project",
    minWidth: 240,
    flex: 2,
  };
  const owner: KTableColumn = { id: "owner", header: "Owner", minWidth: 160 };
  const columns: KTableColumn[] =
    kind === "basic"
      ? [
          project,
          owner,
          { id: "amount", header: "Budget", width: 120, align: "end" },
        ]
      : [
          project,
          { id: "status", header: "Status", minWidth: 180 },
          owner,
          { id: "actions", header: "Actions", width: 88, align: "end" },
        ];
  return (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="stretch" gap="section">
          <KText variant="heading4">Project overview</KText>
          <KTable
            label="Project overview"
            columns={columns}
            rows={projects.map((p) => ({
              id: p.id,
              cells:
                kind === "basic"
                  ? [p.title, p.owner, p.amount]
                  : [
                      p.title,
                      <KSelect
                        label={`Status for ${p.title}`}
                        options={options}
                        value={statuses[p.id]}
                        onValueChange={(value) => {
                          setStatuses((previous) => ({
                            ...previous,
                            [p.id]: value,
                          }));
                          setResult(
                            `${p.title}: ${options.find((o) => o.value === value)?.label}`,
                          );
                        }}
                      />,
                      p.owner,
                      <KOverflowMenu
                        label={`Actions for ${p.title}`}
                        actions={[
                          {
                            id: "open",
                            label: "Open",
                            icon: "external-link",
                            onSelect: () => setResult(`Open: ${p.title}`),
                          },
                          {
                            id: "copy",
                            label: "Copy name",
                            icon: "copy",
                            onSelect: () => setResult(`Copy name: ${p.title}`),
                          },
                        ]}
                      />,
                    ],
            }))}
          />
          {kind === "cells" ? <KText role="status">{result}</KText> : null}
        </KStack>
      </KContainer>
    </div>
  );
}
