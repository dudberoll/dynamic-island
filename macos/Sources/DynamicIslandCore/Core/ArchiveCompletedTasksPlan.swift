public struct ArchiveCompletedTasksPlan: Equatable {
    public let sourceBoard: KanbanBoard
    public let completedTasks: [KanbanTask]

    public static func make(for board: KanbanBoard) -> ArchiveCompletedTasksPlan? {
        let completedTasks = board.tasks.filter(\.isCompleted)
        guard !completedTasks.isEmpty else {
            return nil
        }

        return ArchiveCompletedTasksPlan(sourceBoard: board, completedTasks: completedTasks)
    }
}
