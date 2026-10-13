import { useEffect, useState, type ReactNode } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KDiceBearAvatar,
  KStack,
  KInline,
  KLink,
  KText,
  kDiceBearStyleIds,
  kDiceBearAnimatedStyleIds,
  loadKDiceBearStyle,
  getKDiceBearOptions,
  type KDiceBearStyleId,
} from "@k-design-system/ui";
type Style = Awaited<ReturnType<typeof loadKDiceBearStyle>>;

function AttributionLink({
  href,
  children,
}: {
  href?: string;
  children: ReactNode;
}) {
  return href ? (
    <KLink href={href} target="_blank" rel="noopener noreferrer">
      {children}
    </KLink>
  ) : (
    <>{children}</>
  );
}

interface FixtureProps {
  styleId: KDiceBearStyleId;
  seed: string;
  options: Record<string, unknown>;
  size: "small" | "standard" | "large";
  animationSpeed?: "none" | "slowest" | "slow" | "medium" | "fast" | "fastest";
  motionPaused?: boolean;
  showSizes?: boolean;
}

function DiceBearFixture({
  styleId,
  seed,
  options,
  size,
  showSizes = true,
  animationSpeed,
  motionPaused = false,
}: FixtureProps) {
  const [loaded, setLoaded] = useState<{ id: string; style: Style }>();
  const [error, setError] = useState<string>();
  useEffect(() => {
    let active = true;
    setError(undefined);
    loadKDiceBearStyle(styleId).then(
      (style) => {
        if (active) setLoaded({ id: styleId, style });
      },
      (cause: unknown) => {
        if (active) setError(String(cause));
      },
    );
    return () => {
      active = false;
    };
  }, [styleId]);
  if (error) return <KText role="alert">{error}</KText>;
  if (loaded?.id !== styleId) return <KText>Loading {styleId}…</KText>;
  const meta = loaded.style.meta();
  const avatarOptions = animationSpeed
    ? { ...options, animationVariant: [animationSpeed] }
    : options;
  return (
    <KStack gap="control">
      <KDiceBearAvatar
        avatarStyle={loaded.style}
        seed={seed}
        options={avatarOptions}
        motionPaused={motionPaused}
        alt={`${styleId}: ${seed}`}
        size={size}
        style={{ width: showSizes ? 160 : 96, height: showSizes ? 160 : 96 }}
      />
      {showSizes ? (
        <KInline gap="action" align="end">
          {(["small", "standard", "large"] as const).map((sampleSize) => (
            <KStack key={sampleSize} gap="control">
              <KDiceBearAvatar
                avatarStyle={loaded.style}
                seed={seed}
                options={avatarOptions}
                motionPaused={motionPaused}
                alt={`${styleId}: ${seed}`}
                size={sampleSize}
              />
              <KText variant="label">
                {sampleSize}
                {sampleSize === size ? " · selected" : ""}
              </KText>
            </KStack>
          ))}
        </KInline>
      ) : null}
      <KText>{styleId}</KText>
      {showSizes ? (
        <details>
          <summary>Available DiceBear options</summary>
          <pre style={{ whiteSpace: "pre-wrap", maxWidth: "100%" }}>
            {JSON.stringify(getKDiceBearOptions(loaded.style), null, 2)}
          </pre>
        </details>
      ) : null}
      <KText variant="label">
        <AttributionLink href={meta.source().url()}>
          {meta.source().name()}
        </AttributionLink>
        {" by "}
        <AttributionLink href={meta.creator().url()}>
          {meta.creator().name()}
        </AttributionLink>
        {" · "}
        <AttributionLink href={meta.license().url()}>
          {meta.license().name()}
        </AttributionLink>
        {meta.license().name() === "CC BY 4.0"
          ? " · Generated remix; retain attribution when using this artwork."
          : null}
      </KText>
      {meta.license().name() === "MIT" ? (
        <details>
          <summary>Required MIT notice</summary>
          <pre style={{ whiteSpace: "pre-wrap" }}>{meta.license().text()}</pre>
        </details>
      ) : null}
    </KStack>
  );
}

const meta = {
  title: "Data display/DiceBear Avatar",
  component: DiceBearFixture,
  args: {
    styleId: "adventurer",
    seed: "K Design System",
    options: {},
    size: "large",
  },
  argTypes: {
    styleId: { control: "select", options: kDiceBearStyleIds },
    seed: { control: "text" },
    options: {
      control: "object",
      description:
        "All DiceBear 10 style options, e.g. { scale: 0.85, backgroundColor: ['#ffccaa'] }. Expand Available DiceBear options for the selected style's names, values and ranges.",
    },
    size: { control: "select", options: ["small", "standard", "large"] },
    showSizes: { table: { disable: true } },
    animationSpeed: {
      control: "select",
      options: ["none", "slowest", "slow", "medium", "fast", "fastest"],
    },
    motionPaused: { control: "boolean" },
  },
  parameters: {
    docs: {
      description: {
        component:
          "Locally generated SVG avatars. 57 styles: CC0, CC BY 4.0 with attribution, and MIT with notice. Avataaars and Bottts families await separate license review. Use the controls to change the seed, style and DiceBear options. Style definitions load separately on demand.",
      },
    },
  },
} satisfies Meta<typeof DiceBearFixture>;
export default meta;
type Story = StoryObj<typeof meta>;

export const Playground: Story = {
  name: "dicebear-avatar-playground",
  parameters: { fixtureId: "dicebear-avatar-playground" },
};

export const Animation: Story = {
  name: "dicebear-avatar-animation",
  args: { styleId: "critters", animationSpeed: "fastest", motionPaused: false },
  argTypes: {
    styleId: {
      control: "select",
      options: kDiceBearAnimatedStyleIds,
    },
  },
  parameters: { fixtureId: "dicebear-avatar-animation" },
};

export const Catalogue: Story = {
  name: "dicebear-avatar-catalogue",
  parameters: { fixtureId: "dicebear-avatar-catalogue" },
  argTypes: { styleId: { table: { disable: true } } },
  render: (args) => (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
        gap: "var(--k-space-layout-section-gap)",
        width: "100%",
      }}
    >
      {kDiceBearStyleIds.map((styleId) => (
        <DiceBearFixture
          key={styleId}
          {...args}
          styleId={styleId}
          showSizes={false}
        />
      ))}
    </div>
  ),
};
