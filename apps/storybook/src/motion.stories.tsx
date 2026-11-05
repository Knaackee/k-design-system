import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState, type CSSProperties } from "react";
import {
  KButton,
  KInline,
  KText,
  kMotion,
  type KMotionRole,
} from "@k-design-system/ui";
import "./motion.css";

const roles: { role: KMotionRole; use: string }[] = [
  { role: "feedback", use: "Press, hover, focus" },
  { role: "control", use: "Toggle, select, expand" },
  { role: "enter", use: "Sheet, dialog, toast appears" },
  { role: "exit", use: "Something leaves" },
  { role: "page", use: "Screen and tab change" },
  { role: "attention", use: "Rare emphasis" },
];

/** Same fixture as Widgetbook Primitives/Motion/motion-roles. */
function MotionRoles() {
  const [on, setOn] = useState(false);
  return (
    <div className="motion-demo">
      <KInline gap="control" align="center" wrap>
        <KButton onClick={() => setOn((value) => !value)}>
          {on ? "Back" : "Play"}
        </KButton>
        <KText variant="bodySmall">
          Switch the style in the toolbar: Motion (Apple, Expressive, reduced).
        </KText>
      </KInline>
      {roles.map(({ role, use }) => {
        const spec =
          typeof document === "undefined" ? undefined : kMotion(role);
        return (
          <div className="motion-demo__row" key={role}>
            <KText variant="label">
              {role} · {use}
              {spec ? ` · ${spec.settle} ms` : ""}
            </KText>
            <div
              className="motion-demo__track"
              data-on={on ? "" : undefined}
              data-parity={`motion-${role}`}
            >
              <span
                className="motion-demo__dot"
                style={
                  {
                    transitionDuration: `var(--k-motion-${role}-settle)`,
                    transitionTimingFunction: `var(--k-motion-${role}-easing)`,
                    "--motion-distance": `var(--k-motion-${role}-distance)`,
                  } as CSSProperties
                }
              />
            </div>
          </div>
        );
      })}
    </div>
  );
}

export default {
  title: "Primitives/Motion",
  parameters: { fixtureId: "motion-roles" },
} satisfies Meta;

export const Roles: StoryObj = {
  name: "motion-roles",
  render: () => <MotionRoles />,
};
