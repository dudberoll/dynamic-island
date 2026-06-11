# Dynamic Island Tasks

## Done

- [x] Feature: Inline Task Editing
- [x] Feature: Add Task Button

## Current

### Decision: Expanded Panel Dismissal

Accepted behavior:

- `Escape` cancels inline edit or add-task draft first, and only collapses the expanded panel when no local edit state is active.
- Header clicks attempt to commit active edits/drafts, collapse on success, and preserve the expanded state when validation or persistence fails.
- Outside clicks behave like header clicks: attempt to commit, collapse on success, and stay expanded when validation or persistence fails.
- Interactive controls inside the working area do not collapse the panel.
- Switching from one task/edit context to another first attempts to commit the current context and only proceeds when that commit succeeds.
- Empty add-task drafts can be discarded silently.
- Persistence failures must preserve the user's in-progress text and keep the relevant edit UI active.
- Clicks in the scrollable working area background do not collapse the panel.

Implementation plan:

- [x] Audit current expanded/collapsed gesture handling in `IslandRootView`, `TaskRow`, `NewTaskRow`, and `IslandPanelController`.
- [x] Refactor panel dismissal into a single coordination layer in `IslandRootView` for escape, commit-and-collapse, and edit/add-task transitions.
- [x] Update inline edit and add-task flows so focus changes, validation, and persistence failures preserve in-progress text instead of clearing local state.
- [x] Implement `Escape` handling so it cancels active inline edit or add-task draft before collapsing the panel.
- [x] Implement safe transitions between editing one task, editing another task, and opening add-task mode by committing the current context first.
- [x] Add AppKit-driven outside-click detection in `IslandPanelController` and route it into the shared dismiss coordinator.
- [x] Ensure header clicks and non-working-area background clicks use the shared commit-and-collapse path.
- [x] Ensure task rows, add-task controls, text fields, and the scrollable working area do not trigger unintended collapse.
- [x] Verify the panel still expands from the compact island and returns to the correct compact size after every dismissal path.
- [x] Add or update focused tests where practical, then run `swift test` and `swift build`.
- [ ] Mark `Decision: Expanded Panel Dismissal` as done after review and validation.
