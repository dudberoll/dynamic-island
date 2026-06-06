# Dynamic Island macOS

Native macOS app surface for the Dynamic Island overlay. This surface uses SwiftPM, AppKit, and SwiftUI because the core product behavior depends on macOS windowing APIs such as `NSPanel`, transparent always-on-top windows, click-through hit testing, screen geometry, and Spaces/fullscreen behavior.

## Surface Status

- Active surface: native macOS app.
- Current implementation: SwiftPM package with `DynamicIsland` executable, `DynamicIslandCore` library, markdown parser/writer tests, and a minimal `NSPanel` + SwiftUI island shell.
- Deferred surfaces kept from the template: `mobile`, `backend`, `webapp`, `website`, auth, payments, push notifications, EAS, and deployment.
- Product source of truth for tasks: `/Users/dudberoll/obsidian-local/to-dos.md`.
- First user journey: hover/click the top-screen island, inspect Obsidian Kanban boards, view tasks, and toggle task completion in the source markdown file.

## Stack

- SwiftPM for package structure and builds.
- AppKit for app lifecycle, `NSPanel`, screen/window behavior, event handling, and click-through support.
- SwiftUI for island content, board/task UI, reusable components, and visual state.
- Foundation file APIs for reading, parsing, writing, and watching the Obsidian markdown source.

## Architecture Rules

Keep the macOS surface organized by ownership:

```text
Sources
├── DynamicIsland
│   └── App
└── DynamicIslandCore
    ├── Core
    ├── FileBackend
    ├── Services
    └── UI
        ├── Components
        ├── Theme
        ├── Views
        └── Window
```

- `DynamicIsland/App` owns app startup, lifecycle, app delegate/controller wiring, and top-level orchestration.
- `DynamicIslandCore` owns reusable app logic, persistence, services, UI, and AppKit panel behavior.
- `UI/Window` owns all AppKit window and panel behavior: `NSPanel`, window levels, Spaces behavior, transparent host windows, hit testing, and hosting SwiftUI content.
- `Core` owns state machines, screen/notch geometry, event-monitor abstractions, and pure rules.
- `FileBackend` owns reading, parsing, writing, and watching the Obsidian markdown file.
- `Services` owns app-facing stores such as `TodoStore`; SwiftUI views talk to services, not directly to files.
- `UI/Views` owns feature views such as the island and task board.
- `UI/Components` owns reusable SwiftUI controls.
- `UI/Theme` owns colors, typography, spacing, radii, animation constants, and visual tokens.

## Adapted Template Rules

These rules are adapted from the `mobile` template conventions, but translated to native macOS:

- Use a shared shell/container view for consistent padding, clipping, hover state, expansion layout, and scroll/non-scroll behavior.
- Keep visible text styling centralized through `UI/Theme`; do not scatter ad hoc fonts, colors, or spacing across feature views.
- Give interactive controls stable `accessibilityIdentifier` constants so future UI tests do not depend on coordinates or fragile text.
- Keep file path handling, parse errors, write failures, debounce, and reload behavior centralized in the backend/store layer.
- SwiftUI views should render state and send user intents; they should not parse markdown, mutate files, or decide persistence rules.
- Model loading, empty, error, success, disabled, selected, expanded, and collapsed states explicitly when they affect user behavior.
- Prefer small reusable primitives for repeated UI patterns, but add abstractions only when they remove current complexity.
- Keep cosmetic visual checks manual or screenshot-based; reserve automated tests for parsing, persistence, state transitions, and critical user journeys.

## Obsidian Kanban Contract

The app reads tasks from:

```text
/Users/dudberoll/obsidian-local/to-dos.md
```

Supported board format:

```markdown
## main

- [ ] active task
- [x] completed task

## fork

- [ ] another task
```

Rules:

- Named `##` sections are boards.
- Empty board names are hidden from the UI.
- Boards named `Archive` are hidden from the UI case-insensitively.
- `- [ ]` is an active task.
- `- [x]` is a completed task.
- Toggling a task must preserve unrelated markdown content as much as practical.
- File watching should debounce reloads.
- File watching debounces reloads, so changes saved by Obsidian refresh shortly after the write settles.

## Validation

Use the lightest meaningful signal for the touched surface:

- Build: `swift build` from `macos/`.
- Test: `swift test` from `macos/`.
- Run: `swift run DynamicIsland` from `macos/` for the current SwiftPM executable; move to an app bundle/build script when packaging or LaunchAgent behavior becomes necessary.
- Parser/store changes: add focused Swift tests for markdown parsing, task toggling, write preservation, and debounce-sensitive behavior where practical.
- Window and hover behavior: validate manually on the target display setup; add screenshot or UI automation only after the behavior stabilizes.

## Product Boundaries

- Do not require backend, database, auth, payments, push notifications, or deployment for the first macOS overlay version.
- Do not move Obsidian task persistence into the template backend unless the product goal changes.
- Do not implement the macOS overlay in Expo/React Native; using that stack would still require a native AppKit bridge for the hard part.
- Keep the deferred template surfaces intact until the user asks to activate, remove, or repurpose them.
