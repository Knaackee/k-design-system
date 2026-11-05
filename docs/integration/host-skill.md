# Host skill entry

A host application should not copy the workflow skill: a copy stays at the
version it was copied from while the submodule moves on, and agents then load
outdated rules without noticing. Install this small entry instead. It has the
same trigger as the real skill and only routes to the pinned version.

Save as `.agents/skills/k-design-system/SKILL.md` in the host repository
(adjust the submodule path if it is not `vendor/k-design-system`), and delete
any older copied `k-design-system-workflow` directory there:

```markdown
---
name: k-design-system
description: Build, review or migrate UI in this app with K Design System (Web/React or Flutter). Use for any screen, component composition, spacing/typography decision, token change or design-system update — including phone/tablet layout, text-size problems and translating a design mock into K components.
---

# K Design System

The rules live in the pinned design-system submodule, not here.

1. Read `vendor/k-design-system/.agents/skills/k-design-system-workflow/SKILL.md`
   and follow it. Load its `references/` files when it says so.
2. If that file is missing, run `git submodule update --init` and read it then.
   Never fall back to memory or to another copy of these rules.
3. After the submodule pin changed, read `vendor/k-design-system/CHANGELOG.md`
   (Unreleased) before changing UI.
```

Also add this line to the host's `AGENTS.md`, for tools that do not load
skills:

> For every UI change, read and follow
> `vendor/k-design-system/.agents/skills/k-design-system-workflow/SKILL.md`
> before implementing controls, layouts or styling.
