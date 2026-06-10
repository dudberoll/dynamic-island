import SwiftUI

struct BoardColumnView: View {
    let board: KanbanBoard
    let editingTaskID: KanbanTask.ID?
    let draftTitle: String
    let editingValidationMessage: String?
    let pendingBoardID: KanbanBoard.ID?
    let newTaskDraftTitle: String
    let newTaskValidationMessage: String?
    let onToggle: (KanbanTask) -> Void
    let onBeginEditing: (KanbanTask) -> Void
    let onDraftTitleChange: (String) -> Void
    let onCommitEditing: (KanbanTask) -> Void
    let onBeginAdding: (KanbanBoard) -> Void
    let onNewTaskDraftChange: (String) -> Void
    let onCommitNewTask: (KanbanBoard) -> Void

    private var isAddingTask: Bool {
        pendingBoardID == board.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(board.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)

                Text("\(board.tasks.filter { !$0.isCompleted }.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.56))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.08), in: Capsule())

                Spacer(minLength: 0)

                Button {
                    onBeginAdding(board)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.76))
                        .frame(width: 22, height: 22)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Add task")
                .accessibilityIdentifier("add-task-\(board.id.headingLineIndex)")
            }
            .padding(.horizontal, 10)

            VStack(spacing: 4) {
                ForEach(board.tasks) { task in
                    TaskRow(
                        task: task,
                        isEditing: editingTaskID == task.id,
                        draftTitle: editingTaskID == task.id ? draftTitle : task.text,
                        validationMessage: editingTaskID == task.id ? editingValidationMessage : nil,
                        onToggle: {
                            onToggle(task)
                        },
                        onBeginEditing: {
                            onBeginEditing(task)
                        },
                        onDraftTitleChange: onDraftTitleChange,
                        onCommitEditing: {
                            onCommitEditing(task)
                        }
                    )
                }

                if isAddingTask {
                    NewTaskRow(
                        draftTitle: newTaskDraftTitle,
                        validationMessage: newTaskValidationMessage,
                        onDraftTitleChange: onNewTaskDraftChange,
                        onCommit: {
                            onCommitNewTask(board)
                        }
                    )
                }

                if board.tasks.isEmpty && !isAddingTask {
                    Text("No tasks")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.46))
                        .frame(maxWidth: .infinity, minHeight: 38)
                }
            }
            .padding(.vertical, 4)
            .background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: IslandTheme.controlRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: IslandTheme.controlRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }
        }
        .frame(width: 260, alignment: .topLeading)
    }
}
