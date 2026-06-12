struct BoardCollapseState: Equatable {
    private(set) var collapsedBoardIDs: Set<KanbanBoard.ID> = []

    func isCollapsed(_ boardID: KanbanBoard.ID) -> Bool {
        collapsedBoardIDs.contains(boardID)
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
