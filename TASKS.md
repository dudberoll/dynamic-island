# Dynamic Island Tasks

## Stage 0: Completed Foundation

- [x] Build the native macOS overlay as a top-centered island attached to the main screen.
- [x] Implement the compact notch-like collapsed state.
- [x] Implement hover sizing and visual feedback for the collapsed island without revealing task content.
- [x] Implement the expanded dark task widget with rounded corners and board columns.
- [x] Parse Obsidian Kanban markdown from `/Users/dudberoll/obsidian-local/to-dos.md`.
- [x] Display non-empty `##` boards and task rows from the markdown file.
- [x] Hide boards named `Archive` case-insensitively.
- [x] Exclude archived tasks from visible board lists and active task counters.
- [x] Toggle task completion while preserving task position and unrelated markdown.
- [x] Watch the markdown file and refresh the UI after Obsidian saves changes.
- [x] Ignore redundant reloads caused by the app's own writes.
- [x] Support direct file writes and editor save patterns that replace or rename the markdown file.
- [x] Implement inline task editing.
- [x] Implement add-task controls for each visible board.
- [x] Implement error and empty states in the expanded widget.
- [x] Run as an accessory/background-style macOS app without a normal Dock window.

## Stage 1: Completed Expanded Panel Dismissal

- [x] Audit expanded/collapsed gesture handling in `IslandRootView`, `TaskRow`, `NewTaskRow`, and `IslandPanelController`.
- [x] Refactor panel dismissal into a shared coordination path in `IslandRootView`.
- [x] Preserve edit and add-task drafts when validation or persistence fails.
- [x] Implement Escape so it cancels active edit/add state before collapsing the panel.
- [x] Commit active edit/add context before switching to another edit/add/toggle action.
- [x] Add AppKit outside-click detection in `IslandPanelController`.
- [x] Route outside clicks through the shared dismiss coordinator.
- [x] Route header and non-working-area background taps through the shared commit-and-collapse path.
- [x] Prevent task rows, add-task controls, text fields, and scrollable working-area clicks from causing unintended collapse.
- [x] Ensure collapse returns to the base compact size after every dismissal path.
- [x] Add focused expansion-state tests.
- [x] Run `swift test` and `swift build`.
- [x] Update `docs/EXPANDED_PANEL_DISMISSAL_AUDIT.md` as a completed audit.

## Stage 2: Archive Completed Tasks

- [x] Add an archive button to each visible board header immediately to the left of the add-task button.
- [ ] Use a minimal archive-box icon for the archive button; use a custom simple line icon if the system icon is not close enough.
- [ ] Keep the archive button enabled even when the board has no completed tasks.
- [ ] Make archive button clicks a no-op when the board has no completed tasks.
- [ ] Add tooltip/help text that describes the action as archiving completed tasks from the board.
- [ ] Archive all completed tasks from the selected source board on click.
- [ ] Leave active tasks in the source board.
- [ ] Move archived tasks into the hidden `Archive` board.
- [ ] Preserve the checkbox state of archived tasks.
- [ ] Append `_<source board name>` to every archived task title before writing it into `Archive`.
- [ ] Preserve the order of multiple archived tasks from the same source board.
- [ ] Remove archived task lines from the source board.
- [ ] Preserve unrelated markdown content in the source board.
- [ ] Append archived tasks to an existing `Archive` board when it exists.
- [ ] Create an `Archive` board at the end of the markdown file when it does not exist.
- [ ] Keep the `Archive` board hidden from the island UI after archive operations.
- [ ] Resolve any active inline edit or add-task draft before archiving.
- [ ] Cancel archiving and preserve the draft when validation or persistence fails.
- [ ] Resolve archive operations against the latest known markdown state.
- [ ] Refuse unsafe archive operations when the source board or task lines cannot be matched safely.
- [ ] Show an operation error when archive cannot be completed safely.

## Stage 3: Archive Markdown Tests

- [ ] Add parser/writer tests for moving completed tasks into an existing `Archive` board.
- [ ] Add parser/writer tests for creating `Archive` when it does not exist.
- [ ] Add tests that archived task titles receive `_<source board name>`.
- [ ] Add tests that active tasks remain in the source board.
- [ ] Add tests that multiple archived tasks preserve source order.
- [ ] Add tests that unrelated markdown, settings blocks, hidden archive content, and line endings are preserved as much as practical.
- [ ] Add tests that unsafe archive conflicts do not modify markdown.
- [ ] Run `swift test`.
- [ ] Run `swift build`.

## Stage 4: Manual Validation

- [ ] Validate archive button placement in the expanded island UI.
- [ ] Validate the archive icon against the desired minimal archive-box style.
- [ ] Validate that boards with no completed tasks do nothing on archive click.
- [ ] Validate archiving completed tasks from `/Users/dudberoll/obsidian-local/to-dos.md`.
- [ ] Validate that archived tasks disappear from the visible island UI.
- [ ] Validate that archived tasks are written to the markdown `Archive` board with the source board suffix.
- [ ] Validate Obsidian-to-app updates after archive operations.
- [ ] Validate app-to-Obsidian updates after archive operations.
- [ ] Validate archive behavior while an inline edit is active.
- [ ] Validate archive behavior while an add-task draft is active.

## Stage 5: Deferred Product Work

- [ ] Design task deletion separately before implementation.
- [ ] Design manual move-between-boards behavior separately before implementation.
- [ ] Design automatic archive-on-completion separately before implementation.
- [ ] Design manual refresh controls only if automatic synchronization becomes insufficient.
- [ ] Design configurable task file selection for a future version.
- [ ] Design multi-display behavior beyond the current main-display island.
- [ ] Design future island tabs separately from archive work.
