import { useState } from "react";
import "./animated-icon-fixture.css";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KAnimatedIcon,
  KButton,
  KCombobox,
  KSearchField,
  KField,
  KPagination,
  KSelect,
  KSlider,
  KStack,
  KText,
  kIconNames,
  type KAnimatedIconSpring,
  type KIconName,
} from "@k-design-system/ui";

const pairs: readonly [KIconName, KIconName, string][] = [
  ["sun", "moon", "Theme"],
  ["menu", "x", "Menu"],
  ["play", "pause", "Playback"],
  ["heart", "check", "Status"],
];

function AnimatedIconFixture() {
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [states, setStates] = useState([false, false, false, false]);
  const [spring, setSpring] = useState<KAnimatedIconSpring>("snappy");
  const [from, setFrom] = useState<KIconName>("sun");
  const [to, setTo] = useState<KIconName>("moon");
  const [destination, setDestination] = useState(false);
  const [progress, setProgress] = useState(50);
  const [status, setStatus] = useState("Ready");
  const matches = kIconNames.filter((name) =>
    name.includes(query.trim().toLowerCase()),
  );
  const pageCount = Math.max(1, Math.ceil(matches.length / 48));
  const visible = matches.slice((page - 1) * 48, page * 48);
  const options = Array.from(new Set([from, to, ...visible])).map((name) => ({
    value: name,
    label: name,
    icon: name,
  }));
  return (
    <section
      className="k-animated-icon-demo"
      style={{
        width: "100%",
        maxWidth: 640,
        marginInline: "auto",
        padding: "var(--k-space-card-padding)",
        boxSizing: "border-box",
      }}
    >
      <KStack gap="section" align="stretch">
        <div>
          <KText variant="heading3">Animated icons</KText>
          <KText variant="bodySmall">Lucide · Web + Flutter</KText>
        </div>
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(2, minmax(0, 1fr))",
            gap: "var(--k-space-control-gap)",
          }}
        >
          {pairs.map(([a, b, label], index) => (
            <KButton
              key={label}
              fullWidth
              style={{ justifyContent: "center" }}
              variant="secondary"
              aria-pressed={states[index]}
              onClick={() =>
                setStates((current) =>
                  current.map((value, i) => (i === index ? !value : value)),
                )
              }
            >
              <span
                style={{
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "var(--k-space-control-gap)",
                }}
              >
                <KAnimatedIcon
                  name={states[index] ? b : a}
                  spring={spring}
                  size={24}
                />
                {label}
              </span>
            </KButton>
          ))}
        </div>
        <KSelect
          label="Motion"
          value={spring}
          onValueChange={(value) => setSpring(value as KAnimatedIconSpring)}
          options={[
            { value: "smooth", label: "Smooth" },
            { value: "snappy", label: "Snappy" },
            { value: "bouncy", label: "Bouncy" },
          ]}
        />
        <KText variant="heading4">Try any pair</KText>
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
          {matches.length} / {kIconNames.length} icons · {visible.length} on
          this page
        </KText>
        {pageCount > 1 && (
          <KPagination
            page={page}
            pageCount={pageCount}
            onPageChange={setPage}
            siblingCount={0}
          />
        )}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(2, minmax(0, 1fr))",
            gap: "var(--k-space-control-gap)",
          }}
        >
          <KCombobox
            label="From"
            value={from}
            onValueChange={(value) => setFrom(value as KIconName)}
            options={options}
          />
          <KCombobox
            label="To"
            value={to}
            onValueChange={(value) => setTo(value as KIconName)}
            options={options}
          />
        </div>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            minHeight: 112,
          }}
        >
          <KAnimatedIcon
            name={destination ? to : from}
            spring={spring}
            size={64}
            label="Animated preview"
            onAnimationStart={() => setStatus("Animating")}
            onAnimationEnd={() => setStatus("Ready")}
          />
        </div>
        <KButton
          fullWidth
          style={{ justifyContent: "center" }}
          variant="secondary"
          onClick={() => setDestination((value) => !value)}
        >
          Animate
        </KButton>
        <KText variant="bodySmall">{status}</KText>
        <KText variant="heading4">Controlled progress</KText>
        <div
          style={{ display: "flex", justifyContent: "center", minHeight: 80 }}
        >
          <KAnimatedIcon
            name={to}
            from={from}
            progress={progress / 100}
            size={64}
            label="Controlled preview"
          />
        </div>
        <KSlider
          label="Progress"
          value={progress}
          onValueChange={setProgress}
          valueLabel={(value) => `${value}%`}
        />
        <KText variant="bodySmall">
          {progress}% · {kIconNames.length} bundled icons · Additional Lucide
          SVGs supported
        </KText>
      </KStack>
    </section>
  );
}

export default {
  title: "Primitives/AnimatedIcon",
  component: AnimatedIconFixture,
  parameters: { fixtureId: "animated-icon-morphing", layout: "fullscreen" },
} satisfies Meta<typeof AnimatedIconFixture>;
export const Morphing: StoryObj<typeof AnimatedIconFixture> = {
  name: "animated-icon-morphing",
};
