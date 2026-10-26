import { useState } from "react";
import {
  KButton,
  KCard,
  KCheckbox,
  KField,
  KInline,
  KInput,
  KSelect,
  KStack,
  KText,
} from "@k-design-system/ui";

export type DemoProject = { name: string; status: string };

/** Product state and submission belong to the consumer, never the UI package. */
export function ProjectFormFixture({
  onCreate,
  onCancel,
}: {
  onCreate: (project: DemoProject) => void;
  onCancel: () => void;
}) {
  const [projectName, setProjectName] = useState("");
  const [projectStatus, setProjectStatus] = useState("Planned");
  const [notifyTeam, setNotifyTeam] = useState(true);
  const [formError, setFormError] = useState(false);
  return (
    <KCard>
      <form
        noValidate
        onSubmit={(event) => {
          event.preventDefault();
          if (!projectName.trim()) {
            setFormError(true);
            return;
          }
          const project = {
            name: projectName.trim(),
            status: projectStatus,
          };
          onCreate(project);
        }}
      >
        <KStack gap="section" align="stretch">
          <KStack gap="control" align="stretch">
            <KText variant="heading4" as="h2">
              Project basics
            </KText>
            <KText variant="bodySmall">
              Create a shared space for your next team project.
            </KText>
          </KStack>
          <KField
            label="Project name"
            required
            errorText={formError ? "Enter a project name." : undefined}
          >
            <KInput
              value={projectName}
              onChange={(event) => setProjectName(event.target.value)}
            />
          </KField>
          <KSelect
            label="Status"
            value={projectStatus}
            onValueChange={setProjectStatus}
            options={["Planned", "In progress", "In review"].map((value) => ({
              value,
              label: value,
            }))}
          />
          <KCheckbox
            label="Notify the team when this project is created"
            value={notifyTeam}
            onValueChange={(value) => setNotifyTeam(value === true)}
          />
          <KInline gap="action" wrap>
            <KButton type="submit">Create project</KButton>
            <KButton variant="ghost" type="button" onClick={onCancel}>
              Cancel
            </KButton>
          </KInline>
        </KStack>
      </form>
    </KCard>
  );
}
