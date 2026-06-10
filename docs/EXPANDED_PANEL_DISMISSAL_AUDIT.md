# Expanded Panel Dismissal Audit

This audit covers the current expanded/collapsed gesture and edit-state handling
for the accepted `Expanded Panel Dismissal` behavior in `TASKS.md`.

## Current Ownership

- `IslandRootView` owns expansion state, hover state, active task edit state, and
  active new-task draft state.
- `compactSurface.onTapGesture` expands the island directly through
  `setExpanded(true)`.
- The expanded header's `onTapGesture` is the only current collapse gesture. It
  calls `collapseAfterSavingActiveEdit()`.
- There is no root-level Escape or keyboard dismissal handler on
  `IslandRootView` or the expanded surface. Escape only reaches active row text
  fields through `onExitCommand`, so Escape with no focused editor does not
  collapse the panel.
- `TaskRow` owns text-field focus for task edits and commits on submit or focus
  loss. Escape currently cancels the row edit through `onExitCommand`.
- `NewTaskRow` owns text-field focus for add-task drafts and commits on submit
  or focus loss. Escape currently cancels the add-task draft through
  `onExitCommand`.
- `BoardColumnView` forwards task toggle, begin-edit, begin-add, commit, and
  cancel callbacks without deciding dismissal policy.
- `IslandPanelController` only creates and resizes the `NSPanel`; it has no
  outside-click monitor or dismissal callback channel.

## Source Trail

| Behavior | Current code path | Observed gap | Follow-up |
| --- | --- | --- | --- |
| Expand compact island | `IslandRootView.compactSurface` tap, `IslandRootView.swift:100` | Direct expand path is separate from dismissal coordination. | Keep expand simple, but make collapse and edit cleanup flow through one root coordinator. |
| Header click collapse | `expandedSurface` header tap, `IslandRootView.swift:131`; `collapseAfterSavingActiveEdit()`, `IslandRootView.swift:290` | Header is the only collapse gesture and infers commit success from cleared state. | Route header clicks through an explicit commit-and-collapse result path. |
| Escape while editing task | `TaskRow` text field `onExitCommand`, `TaskRow.swift:58` | Cancels only when the text field has focus; root has no Escape fallback. | Add root-level Escape behavior that cancels local edit state first, then collapses. |
| Escape while adding task | `NewTaskRow` text field `onExitCommand`, `TaskRow.swift:110` | Same focus dependency as task edit; empty draft behavior is only local cancel. | Share Escape handling with the root coordinator. |
| Task edit blur | `TaskRow` focus change, `TaskRow.swift:59` | Blur can commit before header/outside/context-switch logic runs. | Decide whether blur commits directly or delegates to the coordinator without double commit. |
| Add-task blur | `NewTaskRow` focus change, `TaskRow.swift:111` | Empty draft blur currently attempts validation instead of silent discard. | Treat empty add drafts as discardable in dismissal and transition paths. |
| Begin task edit | `TaskRow` double tap, `TaskRow.swift:78`; `beginEditing(_:)`, `IslandRootView.swift:244` | Opening an edit cancels add-task state and overwrites active edit draft. | Commit current context first; proceed only on success or empty-draft discard. |
| Begin add task | Add button, `BoardColumnView.swift:42`; `beginAddingTask(to:)`, `IslandRootView.swift:337` | Partially coordinates active contexts, but failure is confused by commit methods clearing state. | Use explicit commit result semantics before switching add/edit contexts. |
| Toggle task | `BoardColumnView.swift:64` -> `store.toggle`, `IslandRootView.swift:155` | Toggle bypasses dismissal coordination; it may blur an editor as a side effect. | Ensure interactive row controls do not collapse the panel and handle any active edit intentionally. |
| Outside click | `IslandPanelController.show()`, `IslandPanelController.swift:13`; root injection, `IslandPanelController.swift:35` | Controller has no event monitor or callback beyond resize. | Add AppKit outside-click detection and call the root coordinator. |
| Panel sizing after collapse | `setExpanded(_:)`, `IslandRootView.swift:233`; `currentCollapsedSize`, `IslandRootView.swift:240` | Hover state can make collapse return to hover size. | Normalize desired compact size for dismissal paths. |

## Transition Matrix

| Scenario | Current behavior | Accepted behavior |
| --- | --- | --- |
| Edit task A -> edit task B | `beginEditing(_:)` replaces `editingTaskID` and `draftTitle`. | Commit task A first; switch only when commit succeeds. |
| Edit task -> add task | `beginAddingTask(to:)` attempts commit, but persistence failure can clear edit state and allow transition. | Commit edit first; stay editing with draft preserved on validation or persistence failure. |
| Add task -> edit task | `beginEditing(_:)` calls `cancelNewTask()` immediately. | Empty add draft may be discarded; non-empty add draft must commit successfully before edit starts. |
| Add task board A -> add task board B | `beginAddingTask(to:)` attempts commit/discard, but failure state can be cleared. | Empty draft may be discarded; non-empty draft must commit successfully before moving. |
| Header/outside click with active edit | Header uses `collapseAfterSavingActiveEdit()`; outside click is absent. | Commit and collapse on success; preserve text and stay expanded on failure. |
| Header/outside click with empty add draft | Header discards through `isNewTaskDraftEmpty`; outside click is absent. | Discard silently and collapse. |
| Scroll working-area background click | No explicit collapse handler on the scroll area. | Keep panel expanded and avoid accidental commit/collapse. |

## Risk Areas

- Dismissal is split across root taps and row text-field focus handlers instead
  of one coordination layer.
- Focus-loss commits in `TaskRow` and `NewTaskRow` can race with header clicks,
  future outside clicks, or context switches.
- Persistence failures currently clear local edit/add state in the root, which
  conflicts with the accepted requirement to preserve in-progress text.
- Because `commitEditing(_:)` and `commitNewTask(_:)` return `Void`, callers
  infer success from cleared state. On persistence failure the state is cleared,
  so `collapseAfterSavingActiveEdit()` can continue and collapse the panel as if
  the commit had succeeded.
- Switching from an add-task draft to a task edit currently cancels the add draft
  immediately in `beginEditing(_:)`.
- Switching from one task edit to another currently overwrites the active draft
  instead of attempting to commit the current edit first.
- Empty add-task drafts need special handling because dismissal may silently
  discard them, while blur currently attempts to commit them.
- `IslandPanelController` uses a non-activating panel with
  `hidesOnDeactivate = false`, so outside-click behavior must be explicit.
- Collapse size depends on `currentCollapsedSize`; if hover state remains true
  after expansion, collapse can return to hover size rather than the compact
  resting size.

## Edge Cases To Preserve

- Escape should cancel the active row edit or add-task draft before collapsing
  the panel.
- Escape with no active local edit state should collapse the expanded panel.
- Header and outside clicks should commit active edits or non-empty add drafts,
  collapse only on success, and keep the panel expanded on validation or
  persistence failure.
- Empty add-task drafts should be discarded without surfacing validation errors
  when dismissing or switching context.
- Task rows, add-task controls, text fields, and the scrollable working area
  should not trigger unintended collapse.
- Background clicks inside the scrollable working area should be ignored for
  collapse.
- Store reloads can invalidate line-index based task IDs; reconciliation should
  avoid clearing recoverable user text unless the edited object truly no longer
  exists.

## Implementation Hotspots

- `IslandRootView.beginEditing(_:)`: currently cancels add-task state before
  opening an edit and does not commit active edit/add contexts first.
- `IslandRootView.beginAddingTask(to:)`: partially coordinates transitions but
  still depends on commit methods whose failure path clears state.
- `IslandRootView.commitEditing(_:)` and `commitNewTask(_:)`: validation is
  local, but persistence failure currently resets the user's draft state. A
  shared coordinator will need explicit commit result semantics such as success,
  failure, and empty-draft discard.
- `IslandRootView.collapseAfterSavingActiveEdit()`: should become part of a
  shared commit-and-collapse path used by header clicks and outside clicks.
- `TaskRow` and `NewTaskRow`: focus-loss commit behavior should be reconciled
  with the shared dismissal coordinator to avoid double commits and unexpected
  validation.
- `IslandPanelController`: needs an AppKit outside-click detection path and a
  callback into the root dismissal coordinator.
