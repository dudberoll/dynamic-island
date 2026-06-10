import XCTest
@testable import DynamicIslandCore

final class KanbanMarkdownParserTests: XCTestCase {
    private let parser = KanbanMarkdownParser()

    func testParsesObsidianKanbanBoardsAndTasks() {
        let markdown = """
        ---

        kanban-plugin: board

        ---

        ## main

        - [ ] active task
        - [x] completed task

        ## fork

          - [X] indented completed task
        - [ ] - [x] literal checkbox text

        %% kanban:settings
        ```
        {"kanban-plugin":"board"}
        ```
        %%
        """

        let document = parser.parse(markdown)

        XCTAssertEqual(document.boards.count, 2)
        XCTAssertEqual(document.boards[0].name, "main")
        XCTAssertEqual(document.boards[0].tasks.map(\.text), ["active task", "completed task"])
        XCTAssertEqual(document.boards[0].tasks.map(\.isCompleted), [false, true])
        XCTAssertEqual(document.boards[1].name, "fork")
        XCTAssertEqual(document.boards[1].tasks.map(\.text), ["indented completed task", "- [x] literal checkbox text"])
        XCTAssertEqual(document.activeTaskCount, 2)
    }

    func testTogglePreservesUnrelatedMarkdown() throws {
        let markdown = """
        ---
        kanban-plugin: board
        ---

        ## main

        - [ ] active task
        - [x] completed task

        ## fork

        - [ ] other task

        %% kanban:settings
        ```
        {"kanban-plugin":"board","list-collapse":[false,false]}
        ```
        %%
        """

        let task = parser.parse(markdown).boards[0].tasks[0]
        let updated = try parser.toggleTask(in: markdown, taskID: task.id)

        XCTAssertTrue(updated.contains("- [x] active task"))
        XCTAssertTrue(updated.contains("- [x] completed task"))
        XCTAssertTrue(updated.contains("%% kanban:settings"))
        XCTAssertTrue(updated.contains("\"list-collapse\":[false,false]"))
        XCTAssertEqual(updated.replacingOccurrences(of: "- [x] active task", with: "- [ ] active task"), markdown)
    }

    func testHidesArchiveBoardCaseInsensitively() {
        let markdown = """
        ## main

        - [ ] visible task

        ***

        ## Archive

        - [ ] - [x] archived task

        ## fork

        - [x] visible completed task

        ## archive

        - [ ] another archived task
        """

        let document = parser.parse(markdown)

        XCTAssertEqual(document.boards.map(\.name), ["main", "fork"])
        XCTAssertEqual(document.boards.flatMap(\.tasks).map(\.text), ["visible task", "visible completed task"])
        XCTAssertEqual(document.activeTaskCount, 1)
    }

    func testToggleThrowsWhenLineNoLongerContainsTask() {
        let markdown = """
        ## main

        - [ ] active task
        """

        XCTAssertThrowsError(try parser.toggleTask(in: markdown, taskID: KanbanTask.ID(lineIndex: 1))) { error in
            XCTAssertEqual(error as? KanbanMarkdownError, .lineIsNotTask(1))
        }
    }

    func testEditTaskTitlePreservesCheckboxStateAndUnrelatedMarkdown() throws {
        let markdown = """
        ---
        kanban-plugin: board
        ---

        ## main

          - [X] old title - [ ] literal checkbox

        ## fork

        - [ ] other task

        %% kanban:settings
        ```
        {"kanban-plugin":"board","list-collapse":[false,false]}
        ```
        %%
        """

        let task = parser.parse(markdown).boards[0].tasks[0]
        let updated = try parser.editTaskTitle(in: markdown, taskID: task.id, title: "renamed task")

        XCTAssertTrue(updated.contains("  - [X] renamed task"))
        XCTAssertFalse(updated.contains("old title - [ ] literal checkbox"))
        XCTAssertTrue(updated.contains("- [ ] other task"))
        XCTAssertTrue(updated.contains("%% kanban:settings"))
        XCTAssertTrue(updated.contains("\"list-collapse\":[false,false]"))
    }

    func testEditTaskTitleRejectsEmptyTitle() {
        let markdown = """
        ## main

        - [ ] active task
        """

        let task = parser.parse(markdown).boards[0].tasks[0]

        XCTAssertThrowsError(try parser.editTaskTitle(in: markdown, taskID: task.id, title: "   \n\t")) { error in
            XCTAssertEqual(error as? KanbanMarkdownError, .emptyTaskTitle)
        }
    }

    func testEditTaskTitleRejectsMultilineTitle() {
        let markdown = """
        ## main

        - [ ] active task
        """

        let task = parser.parse(markdown).boards[0].tasks[0]

        XCTAssertThrowsError(try parser.editTaskTitle(in: markdown, taskID: task.id, title: "first\nsecond")) { error in
            XCTAssertEqual(error as? KanbanMarkdownError, .multilineTaskTitle)
        }
    }

    func testEditTaskTitlePreservesLineEndings() throws {
        let markdown = "## main\r\n\r\n- [ ] active task\r\n\r\n---\r\n"
        let taskID = KanbanTask.ID(lineIndex: 2)

        let updated = try parser.editTaskTitle(in: markdown, taskID: taskID, title: "renamed task")

        XCTAssertEqual(updated, "## main\r\n\r\n- [ ] renamed task\r\n\r\n---\r\n")
    }

    func testEditTaskTitleThrowsWhenLineNoLongerContainsTask() {
        let markdown = """
        ## main

        - [ ] active task
        """

        XCTAssertThrowsError(try parser.editTaskTitle(in: markdown, taskID: KanbanTask.ID(lineIndex: 1), title: "renamed task")) { error in
            XCTAssertEqual(error as? KanbanMarkdownError, .lineIsNotTask(1))
        }
    }

    func testEditTaskTitleThrowsWhenSourceLineChanged() {
        let original = """
        ## main

        - [ ] active task
        """
        let changed = """
        ## main

        - [ ] externally renamed task
        """

        let task = parser.parse(original).boards[0].tasks[0]

        XCTAssertThrowsError(try parser.editTaskTitle(in: changed, taskID: task.id, title: "app rename")) { error in
            XCTAssertEqual(error as? KanbanMarkdownError, .taskLineChanged(task.id.lineIndex))
        }
    }

    func testEditTaskTitleThrowsWhenTaskMovedByInsertedLineAbove() {
        let original = """
        ## main

        - [ ] active task
        """
        let changed = """
        ## main

        - [ ] inserted task
        - [ ] active task
        """

        let task = parser.parse(original).boards[0].tasks[0]

        XCTAssertThrowsError(try parser.editTaskTitle(in: changed, taskID: task.id, title: "app rename")) { error in
            XCTAssertEqual(error as? KanbanMarkdownError, .taskLineChanged(task.id.lineIndex))
        }
    }

    func testToggleThrowsWhenSourceLineChanged() {
        let original = """
        ## main

        - [ ] active task
        """
        let changed = """
        ## main

        - [x] active task
        """

        let task = parser.parse(original).boards[0].tasks[0]

        XCTAssertThrowsError(try parser.toggleTask(in: changed, taskID: task.id)) { error in
            XCTAssertEqual(error as? KanbanMarkdownError, .taskLineChanged(task.id.lineIndex))
        }
    }

    func testAppendTaskAfterLastTaskBeforeNonTaskContent() throws {
        let markdown = """
        ## main

        - [ ] first task

        note that should stay after tasks

        ## fork

        - [ ] other task
        """

        let board = parser.parse(markdown).boards[0]
        let updated = try parser.appendTask(in: markdown, boardID: board.id, title: "new task")

        XCTAssertTrue(updated.contains("""
        ## main

        - [ ] first task
        - [ ] new task

        note that should stay after tasks
        """))
        XCTAssertTrue(updated.contains("## fork"))
    }

    func testAppendTaskToEmptyBoardAfterHeading() throws {
        let markdown = """
        ## main

        board note

        ## fork

        - [ ] other task
        """

        let board = parser.parse(markdown).boards[0]
        let updated = try parser.appendTask(in: markdown, boardID: board.id, title: "new task")

        XCTAssertTrue(updated.contains("""
        ## main
        - [ ] new task

        board note
        """))
    }

    func testAppendTaskPreservesLineEndingsAndNoFinalNewline() throws {
        let markdown = "## main\r\n\r\n- [ ] first task"
        let board = parser.parse(markdown).boards[0]

        let updated = try parser.appendTask(in: markdown, boardID: board.id, title: "new task")

        XCTAssertEqual(updated, "## main\r\n\r\n- [ ] first task\r\n- [ ] new task")
    }

    func testAppendTaskRejectsHiddenArchiveBoard() {
        let markdown = """
        ## Archive

        - [ ] archived task
        """
        let boardID = KanbanBoard.ID(headingLineIndex: 0, name: "Archive", sourceLine: "## Archive")

        XCTAssertThrowsError(try parser.appendTask(in: markdown, boardID: boardID, title: "new task")) { error in
            XCTAssertEqual(error as? KanbanMarkdownError, .hiddenBoardCannotBeModified("Archive"))
        }
    }

    func testAppendTaskRejectsMultilineTitle() {
        let markdown = """
        ## main

        - [ ] first task
        """
        let board = parser.parse(markdown).boards[0]

        XCTAssertThrowsError(try parser.appendTask(in: markdown, boardID: board.id, title: "first\rsecond")) { error in
            XCTAssertEqual(error as? KanbanMarkdownError, .multilineTaskTitle)
        }
    }

    func testAppendTaskThrowsWhenBoardLineChanged() {
        let original = """
        ## main

        - [ ] first task
        """
        let changed = """
        ## renamed

        - [ ] first task
        """

        let board = parser.parse(original).boards[0]

        XCTAssertThrowsError(try parser.appendTask(in: changed, boardID: board.id, title: "new task")) { error in
            XCTAssertEqual(error as? KanbanMarkdownError, .boardLineChanged(board.id.headingLineIndex))
        }
    }
}
