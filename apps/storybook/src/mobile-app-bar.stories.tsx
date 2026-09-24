import { useRef, useState, type UIEvent } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KIcon,
  KMobileAppBar,
  type KGlassQuality,
  type KMobileAppBarItem,
  type KMobileAppBarVariant,
} from "@k-design-system/ui";
import "./mobile-app-bar.stories.css";

const items: readonly KMobileAppBarItem[] = [
  { id: "home", label: "Home", icon: <KIcon name="house" /> },
  { id: "inbox", label: "Inbox", icon: <KIcon name="mail" />, badge: 13 },
  { id: "search", label: "Search", icon: <KIcon name="search" /> },
  { id: "settings", label: "Settings", icon: <KIcon name="settings" /> },
];

function MobileAppBarFixture({
  quality,
  variant,
}: {
  quality: KGlassQuality;
  variant: KMobileAppBarVariant;
}) {
  const [selectedId, setSelectedId] = useState("home");
  const [message, setMessage] = useState("Home selected");
  const [collapsed, setCollapsed] = useState(false);
  const lastScrollTop = useRef(0);
  const usesPrimaryAction =
    variant === "floating-glass" || variant === "action";
  const handleScroll = (event: UIEvent<HTMLElement>) => {
    if (variant !== "collapsible") return;
    const scrollTop = event.currentTarget.scrollTop;
    const delta = scrollTop - lastScrollTop.current;
    if (scrollTop <= 24) {
      setCollapsed(false);
      lastScrollTop.current = scrollTop;
    } else if (Math.abs(delta) >= 6) {
      setCollapsed(delta > 0);
      lastScrollTop.current = scrollTop;
    }
  };
  return (
    <main className="mobile-app-bar-demo" onScroll={handleScroll}>
      <div className="mobile-app-bar-demo__orb mobile-app-bar-demo__orb--one" />
      <div className="mobile-app-bar-demo__orb mobile-app-bar-demo__orb--two" />
      <section className="mobile-app-bar-demo__content">
        <span className="mobile-app-bar-demo__eyebrow">Mobile workspace</span>
        <h1>{variant.replaceAll("-", " ")}</h1>
        <p>{message}</p>
        {variant === "collapsible" && (
          <p className="mobile-app-bar-demo__hint">
            Scroll down to hide the navigation and up to reveal it.
          </p>
        )}
        {Array.from({ length: 8 }, (_, index) => (
          <article key={index}>
            <strong>Project update {index + 1}</strong>
            <span>Content remains visible beneath the glass surface.</span>
          </article>
        ))}
      </section>
      <KMobileAppBar
        items={items}
        collapsed={collapsed}
        contextualContent={
          <div className="mobile-app-bar-demo__contextual">
            <strong>3 selected</strong>
            <button onClick={() => setMessage("Moved 3 items")} type="button">
              <KIcon name="folder" />
              Move
            </button>
            <button onClick={() => setMessage("Deleted 3 items")} type="button">
              <KIcon name="trash" />
              Delete
            </button>
          </div>
        }
        onSelectionChange={(id) => {
          setSelectedId(id);
          setMessage(`${items.find((item) => item.id === id)?.label} selected`);
        }}
        primaryAction={
          usesPrimaryAction ? (
            <button
              aria-label="Create issue"
              className="mobile-app-bar-demo__create"
              onClick={() => setMessage("Create issue action")}
              type="button"
            >
              <KIcon name="plus" />
            </button>
          ) : undefined
        }
        quality={quality}
        selectedId={selectedId}
        variant={variant}
        visibility="always"
      />
    </main>
  );
}

const meta = {
  title: "Navigation/MobileAppBar",
  component: MobileAppBarFixture,
  parameters: { layout: "fullscreen" },
  args: { quality: "auto", variant: "floating-glass" },
  argTypes: {
    quality: {
      control: "select",
      options: ["auto", "liquid", "frosted", "solid"],
    },
    variant: {
      control: "select",
      options: [
        "floating-glass",
        "fixed",
        "action",
        "floating-dock",
        "labeled",
        "collapsible",
        "contextual",
      ],
    },
  },
} satisfies Meta<typeof MobileAppBarFixture>;

export default meta;
type Story = StoryObj<typeof meta>;

export const FloatingGlass: Story = {};
export const Fixed: Story = { args: { variant: "fixed", quality: "solid" } };
export const Action: Story = { args: { variant: "action", quality: "solid" } };
export const FloatingDock: Story = {
  args: { variant: "floating-dock", quality: "frosted" },
};
export const Labeled: Story = {
  args: { variant: "labeled", quality: "solid" },
};
export const Collapsible: Story = {
  args: { variant: "collapsible", quality: "frosted" },
};
export const Contextual: Story = {
  args: { variant: "contextual", quality: "solid" },
};
