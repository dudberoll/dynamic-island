struct ArchiveCompletedTasksPlan: Equatable {
    let sourceBoard: KanbanBoard
    let completedTasks: [KanbanTask]

    static func make(for board: KanbanBoard) -> ArchiveCompletedTasksPlan? {
        let completedTasks = board.tasks.filter(\.isCompleted)
        guard !completedTasks.isEmpty else {
            return nil
        }

        return ArchiveCompletedTasksPlan(sourceBoard: board, completedTasks: completedTasks)
    }
}
