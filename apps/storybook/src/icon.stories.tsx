import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KContainer,
  KSearchField,
  KField,
  KPagination,
  KIcon,
  KGrid,
  KInline,
  KStack,
  KText,
  kIconNames,
  type KIconName,
} from "@k-design-system/ui";
const meta = {
  title: "Primitives/Icon",
  parameters: { fixtureId: "icon-lucide" },
  args: { size: 16 },
  argTypes: { size: { control: "select", options: [12, 16, 20, 24] } },
} satisfies Meta<{ size: number }>;
export default meta;
type Story = StoryObj<{ size: number }>;
function IconCatalog({ size }: { size: number }) {
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const matches = kIconNames.filter((name) =>
    name.includes(query.trim().toLowerCase()),
  );
  const pageCount = Math.max(1, Math.ceil(matches.length / 96));
  return (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="stretch" gap="section">
          <KText variant="heading4">Shared Lucide icons</KText>
          <KInline wrap gap="section" align="center">
            {(
              [
                ["check", "Check"],
                ["x", "Close"],
                ["arrow-right", "Next"],
                ["info", "Information"],
              ] as [KIconName, string][]
            ).map(([name, label]) => (
              <KIcon key={name} name={name} label={label} size={size} />
            ))}
          </KInline>
          <KInline gap="section" align="center">
            {[12, 16, 20].map((size) => (
              <KIcon
                key={size}
                name="check"
                size={size}
                label={`Check ${size}`}
              />
            ))}
          </KInline>
          <KField label="Search icons">
            <KSearchField
              aria-label="Search icons"
              placeholder="Search all Lucide icons"
              value={query}
              onChange={(event) => {
                setQuery(event.target.value);
                setPage(1);
              }}
            />
          </KField>
          <KText variant="bodySmall">
            {matches.length} / {kIconNames.length} Lucide icons
          </KText>
          <KGrid minColumnWidth={48} gap="control">
            {matches.slice((page - 1) * 96, page * 96).map((name) => (
              <div key={name} className="k-icon-cell" title={name}>
                <KIcon name={name} size={size} label={name} />
              </div>
            ))}
          </KGrid>
          {matches.length === 0 && <KText>No icons found</KText>}
          {pageCount > 1 && (
            <KPagination
              page={page}
              pageCount={pageCount}
              onPageChange={setPage}
              siblingCount={0}
            />
          )}
        </KStack>
      </KContainer>
    </div>
  );
}
export const Lucide: Story = {
  render: ({ size }) => <IconCatalog size={size} />,
};
