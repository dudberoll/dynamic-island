import XCTest
@testable import DynamicIslandCore

final class BoardCollapseStateTests: XCTestCase {
    func testToggleCollapsesAndExpandsBoardByID() {
        let boardID = makeBoard(name: "main", headingLineIndex: 3).id
        var state = BoardCollapseState()

        XCTAssertFalse(state.isCollapsed(boardID))

        state.toggle(boardID)
        XCTAssertTrue(state.isCollapsed(boardID))

        state.toggle(boardID)
        XCTAssertFalse(state.isCollapsed(boardID))
    }

    func testReconcilePreservesExistingBoardsAndRemovesStaleIDs() {
        let retainedBoard = makeBoard(name: "main", headingLineIndex: 3)
        let removedBoard = makeBoard(name: "fork", headingLineIndex: 8)
        let newBoard = makeBoard(name: "later", headingLineIndex: 12)
        var state = BoardCollapseState()
        state.toggle(retainedBoard.id)
        state.toggle(removedBoard.id)

        state.reconcile(with: [retainedBoard, newBoard])

        XCTAssertTrue(state.isCollapsed(retainedBoard.id))
        XCTAssertFalse(state.isCollapsed(removedBoard.id))
        XCTAssertFalse(state.isCollapsed(newBoard.id))
    }

    func testBoardsWithSameNameKeepIndependentCollapseState() {
        let firstBoard = makeBoard(name: "main", headingLineIndex: 3)
        let secondBoard = makeBoard(name: "main", headingLineIndex: 8)
        var state = BoardCollapseState()

        state.toggle(firstBoard.id)

        XCTAssertTrue(state.isCollapsed(firstBoard.id))
        XCTAssertFalse(state.isCollapsed(secondBoard.id))
    }

    func testReconcileWithSuccessfulEmptyDocumentRemovesAllCollapsedIDs() {
        let board = makeBoard(name: "main", headingLineIndex: 3)
        var state = BoardCollapseState()
        state.toggle(board.id)

        state.reconcile(with: [])

        XCTAssertFalse(state.isCollapsed(board.id))
    }

    func testCollapseAndExpandMutateStateExplicitly() {
        let boardID = makeBoard(name: "main", headingLineIndex: 3).id
        var state = BoardCollapseState()

        state.collapse(boardID)
        XCTAssertTrue(state.isCollapsed(boardID))

        state.expand(boardID)
        XCTAssertFalse(state.isCollapsed(boardID))
    }

    func testBoardCollapseTransitionBlocksOnActiveContextFailure() {
        XCTAssertFalse(BoardCollapseTransition.allowsCollapse(after: .blocked))
        XCTAssertTrue(BoardCollapseTransition.allowsCollapse(after: .noActiveContext))
        XCTAssertTrue(BoardCollapseTransition.allowsCollapse(after: .committed))
        XCTAssertTrue(BoardCollapseTransition.allowsCollapse(after: .discardedEmptyDraft))
    }

    func testActiveContextResultContinuationSemantics() {
        XCTAssertTrue(ActiveContextResult.noActiveContext.allowsContinuation)
        XCTAssertTrue(ActiveContextResult.committed.allowsContinuation)
        XCTAssertTrue(ActiveContextResult.discardedEmptyDraft.allowsContinuation)
        XCTAssertFalse(ActiveContextResult.blocked.allowsContinuation)
    }

    private func makeBoard(name: String, headingLineIndex: Int) -> KanbanBoard {
        KanbanBoard(
            id: KanbanBoard.ID(
                headingLineIndex: headingLineIndex,
                name: name,
                sourceLine: "## \(name)"
            ),
            name: name,
            tasks: []
        )
    }
}
