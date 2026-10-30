import { useState } from "react";
import {
  KContainer,
  KIcon,
  KStack,
  KInline,
  KText,
  KField,
  KInput,
  KSearchField,
  KCheckbox,
  KSelect,
  KCombobox,
  KFilterChip,
  KFilterBar,
  type KSelectOption,
} from "@k-design-system/ui";

const statuses: KSelectOption[] = [
  { value: "active", label: "Active", icon: "circle-check" },
  { value: "planned", label: "Planned", icon: "clock" },
  { value: "closed", label: "Closed", icon: "lock", disabled: true },
];
const people: KSelectOption[] = [
  {
    value: "alex",
    label: "Alex",
    imageSrc: new URL("./assets/alex.png", import.meta.url).href,
    icon: "user",
  },
  {
    value: "jordan",
    label: "Jordan",
    imageSrc: new URL("./assets/jordan.png", import.meta.url).href,
    icon: "user",
  },
  { value: "sam", label: "Sam", icon: "user", disabled: true },
];

export function MultiSelectFixture() {
  const [teams, setTeams] = useState<string[]>([]);
  const [projects, setProjects] = useState<string[]>([]);
  const [persons, setPersons] = useState<string[]>([]);
  return (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="stretch" gap="section">
          <KText variant="heading4">Workspace filters</KText>
          <KField label="Teams">
            <KSelect
              multiple
              clearable
              label="Teams"
              placeholder="All teams and private projects"
              values={teams}
              onValuesChange={setTeams}
              selectionLabel={
                teams.length > 1 ? `${teams.length} areas` : undefined
              }
              options={[
                {
                  value: "private",
                  label: "Private workspace projects",
                  icon: "lock",
                },
                { value: "design", label: "Design", icon: "palette" },
                { value: "engineering", label: "Engineering", icon: "code" },
              ]}
            />
          </KField>
          <KField label="Projects">
            <KSelect
              multiple
              clearable
              label="Projects"
              placeholder="All projects"
              values={projects}
              onValuesChange={setProjects}
              selectionLabel={
                projects.length > 1 ? `${projects.length} projects` : undefined
              }
              options={[
                {
                  value: "orbit",
                  label: "Orbit",
                  leading: <KIcon name="rocket" color="#E76F51" />,
                },
                {
                  value: "tasks",
                  label: "Tasks",
                  leading: <KIcon name="code" color="#2A9D8F" />,
                },
              ]}
            />
          </KField>
          <KField label="People">
            <KCombobox
              multiple
              clearable
              label="People"
              placeholder="All people"
              values={persons}
              onValuesChange={setPersons}
              selectionLabel={
                persons.length > 1 ? `${persons.length} people` : undefined
              }
              options={people}
            />
          </KField>
        </KStack>
      </KContainer>
    </div>
  );
}
export type FormFixtureKind =
  | "field"
  | "input"
  | "search-field"
  | "checkbox"
  | "select"
  | "combobox"
  | "filter-chip"
  | "filter-bar";

export function FormFixture({
  kind = "filter-bar",
}: {
  kind?: FormFixtureKind;
}) {
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState<string | null>("active");
  const [person, setPerson] = useState<string | null>("alex");
  const [archived, setArchived] = useState(false);
  const [mixed, setMixed] = useState<boolean | null>(null);
  const reset = () => {
    setQuery("");
    setStatus(null);
    setPerson(null);
    setArchived(false);
  };
  const chips = (
    <>
      {status && (
        <KFilterChip
          label={`Status: ${statuses.find((o) => o.value === status)?.label}`}
          onRemove={() => setStatus(null)}
        />
      )}
      {person && (
        <KFilterChip
          label={`Assignee: ${people.find((o) => o.value === person)?.label}`}
          onRemove={() => setPerson(null)}
        />
      )}
      {!query && !status && !person && !archived && (
        <KText>No active filters</KText>
      )}
    </>
  );
  let content;
  if (kind === "filter-bar") {
    content = (
      <KStack align="stretch" gap="action">
        <KField label="Search items">
          <KSearchField
            placeholder="Search items"
            clearable
            clearLabel="Clear search"
            onClear={() => setQuery("")}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </KField>
        <KField label="Status">
          <KSelect
            options={statuses}
            clearable
            clearLabel="Clear status"
            onClear={() => setStatus(null)}
            value={status}
            onValueChange={setStatus}
            placeholder="Choose status"
          />
        </KField>
        <KField label="Assignee">
          <KCombobox
            options={people}
            clearable
            clearLabel="Clear assignee"
            onClear={() => setPerson(null)}
            value={person}
            onValueChange={setPerson}
            placeholder="Find a person"
          />
        </KField>
        <KCheckbox
          label="Include archived"
          value={archived}
          onValueChange={setArchived}
        />
        <KFilterBar
          label="Workspace filters"
          onReset={reset}
          resetLabel="Reset all"
          resetEnabled={Boolean(query || status || person || archived)}
        >
          {chips}
        </KFilterBar>
      </KStack>
    );
  } else if (kind === "checkbox") {
    content = (
      <KStack gap="action">
        <KCheckbox
          label="Include archived"
          value={archived}
          onValueChange={setArchived}
        />
        <KCheckbox
          label="Select group"
          value={mixed}
          onValueChange={setMixed}
        />
        <KCheckbox
          label="Unavailable"
          value={false}
          onValueChange={() => {}}
          disabled
        />
      </KStack>
    );
  } else if (kind === "select" || kind === "combobox") {
    const Control = kind === "select" ? KSelect : KCombobox;
    content = (
      <KStack align="stretch" gap="section">
        {kind === "select" && (
          <KSelect
            expandedPopup
            label="Conversation"
            value="conversation"
            onValueChange={() => {}}
            options={[
              {
                value: "conversation",
                label:
                  "A long conversation about open tasks and recent changes",
                description: "21.10.2026, 17:30",
              },
            ]}
          />
        )}

        <KField label="Assignee" helperText="Sam is unavailable.">
          <Control
            options={people}
            clearable
            clearLabel="Clear assignee"
            onClear={() => setPerson(null)}
            value={person}
            onValueChange={setPerson}
            placeholder="Find a person"
          />
        </KField>
        <KField label="Unavailable">
          <Control
            options={people.map(({ value, label, disabled }) => ({
              value,
              label,
              disabled,
            }))}
            value="alex"
            onValueChange={() => {}}
            disabled
          />
        </KField>
      </KStack>
    );
  } else if (kind === "filter-chip") {
    content = (
      <KInline wrap gap="control">
        {chips}
      </KInline>
    );
  } else {
    const Control = kind === "search-field" ? KSearchField : KInput;
    content = (
      <KStack align="stretch" gap="section">
        <KField
          label="Title"
          helperText="Use a clear, descriptive name."
          required
        >
          <Control
            placeholder="New item"
            clearable={kind === "search-field"}
            clearLabel="Clear search"
            onClear={() => setQuery("")}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </KField>
        <KField label="Required name" errorText="Enter an item name.">
          <Control placeholder="New item" />
        </KField>
        {kind === "input" && (
          <KField label="Website">
            <KInput
              leading={<KIcon name="globe" size={20} strokeWidth={1.5} />}
              placeholder="www.example.com"
              inputMode="url"
            />
          </KField>
        )}
        <KField label="Read only">
          <Control value="Workspace overview" readOnly />
        </KField>
        <KField label="Unavailable">
          <Control value="Unavailable item" disabled />
        </KField>
      </KStack>
    );
  }
  return (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="stretch" gap="section">
          <KText variant="heading4">Workspace filters</KText>
          {content}
          <KText role="status">{`Query: ${query || "All items"} · Status: ${status || "Any"} · Assignee: ${person || "Anyone"} · Archived: ${archived ? "Yes" : "No"}`}</KText>
        </KStack>
      </KContainer>
    </div>
  );
}
