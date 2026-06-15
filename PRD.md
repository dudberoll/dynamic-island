# Dynamic Island PRD

## Product Goal

Dynamic Island is a native macOS overlay for quick work with an Obsidian Kanban task file. The app should feel like a small system-level interface attached to the top center of the screen, stay visually lightweight while collapsed, and expand into a focused task widget when the user needs to inspect or update tasks.

The app uses `/Users/dudberoll/obsidian-local/to-dos.md` as the source of truth. All task state changes made in the app must be written back to the markdown file. All task state changes made in Obsidian must appear in the app automatically after the file is saved.

## Feature: Notch-Like Collapsed Island

The app is always available as a small overlay centered at the top edge of the main screen. In the collapsed state it looks like a compact black system notch and does not show task text or board names.

The collapsed island occupies minimal screen space and visually blends with the macOS top area. It remains above normal windows and is available across Spaces and fullscreen contexts where macOS allows auxiliary panels.

Hovering the collapsed island slightly increases its size and shows a subtle interactive response. Hover does not reveal task content. Full task content appears only after the user clicks the island.

## Feature: Expanded Task Widget

Clicking the island expands it downward into a dark task widget. The expanded panel uses large rounded corners, clear internal spacing, and a visual style that feels close to native macOS overlays.

The expanded widget displays visible Kanban boards as separate sections. Each board shows its board name, active task count, and task rows. Task rows show the task title and completion state.

Completed tasks remain in their current board and stay visible in place. Completed tasks are visually muted compared with active tasks.

Clicking the expanded island again collapses it back to the compact top overlay.

## Feature: Obsidian Kanban Parsing

The app reads tasks from markdown sections in `/Users/dudberoll/obsidian-local/to-dos.md`.

Each markdown heading in the form `## board_name` represents a board. Empty board names are not displayed.

Each task line in the form `- [ ] task_name` represents an active task. Each task line in the form `- [x] task_name` or `- [X] task_name` represents a completed task.

The app preserves unrelated markdown content when updating tasks, including frontmatter, separators, non-task content, Obsidian Kanban settings blocks, and hidden archive content.

## Feature: Hide Archive Board

Boards named `Archive` are never displayed in the app. The match is case-insensitive, so `Archive`, `archive`, and `ARCHIVE` are all hidden.

Tasks inside the archive board remain in the markdown file and are not modified by the app unless a future archive-management feature explicitly adds that behavior.

Archived tasks are not included in board lists or active task counters.

## Feature: Toggle Task Completion

The user can toggle task completion from the expanded widget.

When the user marks a task completed in the app, the corresponding markdown line changes from `- [ ] task_name` to `- [x] task_name`.

When the user marks a completed task active in the app, the corresponding markdown line changes from `- [x] task_name` to `- [ ] task_name`.

Toggling a task does not move the task to another board and does not archive it. The task remains in the same board and in the same markdown location.

The app updates its visible state immediately after a successful toggle.

## Feature: Two-Way File Synchronization

The app watches `/Users/dudberoll/obsidian-local/to-dos.md` and refreshes task data automatically after the file changes.

When the user edits task status or task text in Obsidian, the app updates the visible task list shortly after Obsidian saves the file.

When the user toggles a task in the app, Obsidian sees the updated markdown file.

The app ignores redundant reloads caused by its own writes when the saved markdown content is already applied in the UI.

File watching supports both direct file writes and editor save patterns that replace or rename the markdown file.

## Feature: Inline Task Editing

Status: Done.

The user can edit a task title directly from the expanded widget.

Double-clicking a task title switches that task row into inline editing mode. The existing task title appears in an editable text field in the same row.

Pressing Enter saves the edited task title to the markdown file and exits editing mode.

Pressing Escape cancels editing and restores the previous task title.

Losing focus saves the edited task title.

Editing a task title changes only the title text after the checkbox marker. The task completion state, board, order, and unrelated markdown content remain unchanged.

After the edit is saved, Obsidian sees the updated markdown file. If the same task title is edited in Obsidian, the app updates after Obsidian saves the file.

## Feature: Add Task Button

Status: Done.

Each visible board has an add task button.

Clicking the add task button creates a new editable task row at the end of that board.

The new task starts as active and is written to markdown as `- [ ] task_name`.

When the user enters a title and saves, the task is appended to the corresponding board in the markdown file.

If the user cancels creation before entering a title, no task is written to the markdown file.

New tasks are not added to hidden archive boards.

## Feature: Archive Completed Tasks

Each visible board has an archive button in its board header. The archive button appears immediately to the left of the add task button.

The archive button uses a minimal archive-box icon. The icon should feel visually close to a simple outlined storage box: a small horizontal lid above a rectangular box body. If the system icon set does not provide a close enough match, the app should use a custom minimal line icon.

Clicking the archive button archives all completed tasks in that board. Active tasks are not archived.

The archive button is always enabled. If a board has no completed tasks, clicking the archive button performs no operation and does not show an error.

Archived tasks are moved from their current board into the hidden `Archive` board. After a successful archive operation, archived tasks disappear from the visible board list because the `Archive` board is not shown in the island.

When a task is archived, the source board name is appended to the task title before it is written into `Archive`. The app appends an underscore followed by the source board name. For example, a task named `название_задачи` archived from the `диплом` board becomes `название_задачи_диплом`.

The task checkbox state is preserved when archiving. Completed tasks are written into `Archive` as completed markdown tasks.

If multiple completed tasks are archived from the same board, they are appended to `Archive` in the same order they appeared in the source board.

Archiving removes the archived task lines from the source board. Other markdown content in the source board remains in place.

Before archiving, the app resolves any active inline edit or add-task draft using the same shared transition rules as other task actions. If the active context commits successfully, or if an empty add-task draft can be discarded, archiving continues. If validation or persistence fails, archiving is cancelled, the island remains expanded, and the user's draft stays visible.

If the `Archive` board already exists in the markdown file, archived tasks are appended to that board. If the `Archive` board does not exist, the app creates it at the end of the markdown file.

## Feature: Error And Empty States

If the task file cannot be read, the expanded widget shows a clear error state and a retry action.

If the task file exists but contains no visible boards or tasks, the expanded widget shows an empty state instead of a broken layout.

The collapsed island remains available when an error or empty state is present.

## Feature: Deferred Task Operations

The app does not delete tasks in the current version.

The app does not move tasks between boards in the current version.

The app does not archive tasks automatically when they are marked completed.

The app does not provide manual refresh controls while automatic synchronization is working.

## Validation Requirements

Markdown parser and writer behavior must be covered by focused Swift tests.

Tests must cover parsing visible boards, hiding `Archive`, toggling task completion while preserving unrelated markdown, editing task titles while preserving checkbox state and unrelated markdown, and appending a new task to a board.

Tests for archive behavior must cover moving completed tasks into `Archive`, preserving task order, appending the source board name to each archived title, creating `Archive` when it does not exist, preserving unrelated markdown, and leaving active tasks in the source board.

The macOS package must build through SwiftPM.

The app must be manually validated against `/Users/dudberoll/obsidian-local/to-dos.md` by checking app-to-Obsidian updates and Obsidian-to-app updates.

## Product Decisions

These decisions resolve product behavior that is not fully defined by the feature sections above.

### Decision: Task File Configuration

The task source stays fixed to `/Users/dudberoll/obsidian-local/to-dos.md` for the current version.

The app does not provide a settings control or first-run file picker for choosing another markdown file in v1.

### Decision: Write Conflict Behavior

If the markdown file changes in Obsidian between the app loading a task and the user editing or toggling that task in the app, the app reloads the latest file before applying the operation.

The app applies the operation only if the original task line still exists and is still a task. If the line is missing or no longer contains a task, the app shows an error and refreshes the UI from the latest file.

### Decision: Empty Task Titles

When the user saves an empty title while editing an existing task, the app rejects the empty title, keeps editing mode open, and leaves the markdown file unchanged.

New task creation follows the same rule: an empty title is not written to markdown.

### Decision: Add Task Placement

When the user adds a task, the app appends the new task after the last task in the selected board and before the next board heading.

The app must preserve non-task content and settings blocks in the board section as much as practical.

### Decision: Archive Button Placement

Each visible board header includes an archive button placed immediately to the left of the add task button.

The archive button uses only an icon, without a visible text label. The button has a tooltip that describes the action as archiving completed tasks from the board.

The archive button remains enabled even when the board has no completed tasks. In that case, clicking the button does nothing.

### Decision: Archive Board Creation

Archive operations target a board named `Archive`.

If an `Archive` board already exists, archived tasks are appended to it.

If no `Archive` board exists, the app creates one at the end of the markdown file and appends archived tasks there.

The `Archive` board remains hidden from the island UI.

### Decision: Archive Conflict Behavior

Before archiving completed tasks, the app reloads or resolves against the latest known markdown state.

The app archives only completed tasks that still exist in the selected source board and can be matched safely.

If the source board or task lines changed in a way that makes the archive operation unsafe, the operation does not modify the markdown file and the app shows an operation error.

Archive operations must preserve unrelated markdown content, hidden archive content, Obsidian settings blocks, and the file's line-ending style as much as practical.

### Decision: Board Visibility Beyond Archive

The app shows every non-empty `##` board except `Archive`, regardless of Obsidian Kanban plugin UI state.

The app does not read collapsed-list state, hidden-list state, or other Obsidian Kanban plugin settings when deciding board visibility in v1.

### Decision: Local Board Collapse

Boards can be collapsed independently inside the expanded island panel.

Collapsed state is local to the island UI and is not read from or written to the Obsidian Kanban `list-collapse` setting. It does not need to persist across app launches.

An expanded board collapses when the user clicks its header. A collapsed board appears as a narrow vertical strip and expands when the user clicks anywhere on that strip. All boards may be collapsed at the same time.

The collapsed strip shows the board name rotated 90 degrees, the board task count, and space for board actions. It does not show a disclosure arrow. Long board names are truncated with an ellipsis.

If inline task editing or add-task creation is active when the user attempts to collapse a board, the app first attempts to commit the active context. The board collapses only when validation and persistence succeed. Validation or persistence failures keep the board expanded and preserve the user's in-progress text.

### Decision: Expanded Panel Dismissal

The expanded widget collapses when the user clicks the compact island, clicks the expanded header or background, presses Escape, or clicks outside the panel.

Task-row controls, inline editing controls, and add-task controls do not collapse the panel.

### Decision: App Lifecycle

The macOS app runs as an accessory/background-style app without a normal Dock window.

The app includes a minimal menu or status item for Quit and future settings.

### Decision: Multiple Displays

When multiple displays are connected, the app shows one island on the current main display.

The app repositions the island when the main display changes.
