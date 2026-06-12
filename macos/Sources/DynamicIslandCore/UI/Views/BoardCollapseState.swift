enum ActiveContextResult: Equatable {
    case noActiveContext
    case committed
    case discardedEmptyDraft
    case blocked

    var allowsContinuation: Bool {
        self != .blocked
    }
}

struct BoardCollapseState: Equatable {
    private(set) var collapsedBoardIDs: Set<KanbanBoard.ID> = []

    func isCollapsed(_ boardID: KanbanBoard.ID) -> Bool {
        collapsedBoardIDs.contains(boardID)
    }

    mutating func collapse(_ boardID: KanbanBoard.ID) {
        collapsedBoardIDs.insert(boardID)
    }

    mutating func expand(_ boardID: KanbanBoard.ID) {
        collapsedBoardIDs.remove(boardID)
    }

    mutating func toggle(_ boardID: KanbanBoard.ID) {
        if collapsedBoardIDs.remove(boardID) == nil {
            collapsedBoardIDs.insert(boardID)
        }
    }

    mutating func reconcile(with boards: [KanbanBoard]) {
        collapsedBoardIDs.formIntersection(boards.map(\.id))
    }
}

enum BoardCollapseTransition {
    static func allowsCollapse(after activeContextResult: ActiveContextResult) -> Bool {
        activeContextResult.allowsContinuation
    }
}
