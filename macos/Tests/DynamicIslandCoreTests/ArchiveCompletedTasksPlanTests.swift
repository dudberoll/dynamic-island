import XCTest
@testable import DynamicIslandCore

final class ArchiveCompletedTasksPlanTests: XCTestCase {
    func testPlanIsNilWhenBoardHasNoCompletedTasks() {
        let board = KanbanBoard(
            id: KanbanBoard.ID(headingLineIndex: 3, name: "main", sourceLine: "## main"),
            name: "main",
            tasks: [
                KanbanTask(
                    id: KanbanTask.ID(lineIndex: 5, sourceLine: "- [ ] active task"),
                    boardName: "main",
                    text: "active task",
                    isCompleted: false
                )
            ]
        )

        XCTAssertNil(ArchiveCompletedTasksPlan.make(for: board))
    }

    func testPlanIsNilWhenBoardIsEmpty() {
        let board = KanbanBoard(
            id: KanbanBoard.ID(headingLineIndex: 3, name: "main", sourceLine: "## main"),
            name: "main",
            tasks: []
        )

        XCTAssertNil(ArchiveCompletedTasksPlan.make(for: board))
    }

    func testPlanContainsCompletedTasksOnlyInSourceOrder() throws {
        let activeTask = KanbanTask(
            id: KanbanTask.ID(lineIndex: 5, sourceLine: "- [ ] active task"),
            boardName: "main",
            text: "active task",
            isCompleted: false
        )
        let firstCompletedTask = KanbanTask(
            id: KanbanTask.ID(lineIndex: 6, sourceLine: "- [x] first done"),
            boardName: "main",
            text: "first done",
            isCompleted: true
        )
        let secondCompletedTask = KanbanTask(
            id: KanbanTask.ID(lineIndex: 8, sourceLine: "- [X] second done"),
            boardName: "main",
            text: "second done",
            isCompleted: true
        )
        let board = KanbanBoard(
            id: KanbanBoard.ID(headingLineIndex: 3, name: "main", sourceLine: "## main"),
            name: "main",
            tasks: [activeTask, firstCompletedTask, secondCompletedTask]
        )

        let plan = try XCTUnwrap(ArchiveCompletedTasksPlan.make(for: board))

        XCTAssertEqual(plan.sourceBoard, board)
        XCTAssertEqual(plan.completedTasks, [firstCompletedTask, secondCompletedTask])
    }
}
