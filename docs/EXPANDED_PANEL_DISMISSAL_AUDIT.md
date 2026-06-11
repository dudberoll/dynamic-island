# Expanded Panel Dismissal Audit

This audit records the completed `Expanded Panel Dismissal` decision from
`TASKS.md`. The original audit identified fragmented dismissal behavior across
the root view, row focus handlers, and the panel controller. The current
implementation now routes dismissal-sensitive flows through shared coordination
in `IslandRootView`.

## Completed Behavior

- The compact island still expands through `compactSurface` and
  `setExpanded(true)`.
- Header taps and outside clicks both attempt to commit the active edit or
  non-empty add-task draft before collapsing.
- Validation and persistence failures keep the expanded panel open and preserve
  the user's in-progress text.
- Conflicting task-edit saves can render a recovery edit row in the original
  board when the task cannot be rebound after an external file change.
- Empty add-task drafts are discarded silently during dismissal or context
  switching.
- `Escape` cancels inline edit or add-task state first, and only collapses the
  panel when no local edit state is active.
- Switching between task edits, add-task mode, toggles, and other interactive
  controls first resolves the current context and proceeds only when allowed.
- Task rows, add-task controls, text fields, and the scrollable working area do
  not trigger unintended collapse.
- Collapse now returns to the base compact size instead of the hover compact
  size, even when the panel was expanded from a hovered state.

## Current Source Trail

| Behavior | Current code path |
| --- | --- |
| Compact expand | `IslandRootView.compactSurface` -> `setExpanded(true)` |
| Shared collapse | `commitActiveContextAndCollapse()` -> `setExpanded(false)` |
| Header tap | Expanded header tap -> `commitActiveContextAndCollapse()` |
| Expanded background tap | Non-working-area background tap -> `commitActiveContextAndCollapse()` |
| Outside click | `IslandPanelController` event monitors -> `IslandDismissBridge` -> `handleOutsideClickDismissRequest()` |
| Escape | `EscapeKeyMonitor` / `.onExitCommand` -> `handleEscape()` |
| Edit/add transitions | `prepareActiveContextForTransition()` before switching context |
| Dismissal commit policy | `prepareActiveContextForDismissal()` and `prepareActiveContext(allowsEmptyDraftDiscard:)` |
| Compact sizing | `IslandExpansionState.setExpanded(false)` clears hover and returns `IslandTheme.collapsedSize` |

## Validation

- `swift test` passes with 22 tests.
- `swift build` passes.
- Focused regression coverage exists in `IslandExpansionStateTests` for hover,
  expand, collapse, repeated collapse, and repeated transition behavior.

## Residual Risks

- The project does not currently have UI-level tests for every dismissal path,
  so AppKit event monitor behavior, recovery edit-row rendering, and text-field
  focus interactions still rely on manual validation.
- Outside-click behavior depends on local and global `NSEvent` monitors, which
  can vary across app focus, Spaces, and system UI interactions.
- Text-field focus loss can still fire near root-level dismissal actions; the
  coordinator is designed to make those transitions safe, but very fast manual
  interactions remain worth checking when changing related code.
- Line-index based task and board identity can become stale after external file
  edits. The current reconciliation paths preserve recoverable drafts where
  practical, but future file-watcher changes should keep this risk in mind.
