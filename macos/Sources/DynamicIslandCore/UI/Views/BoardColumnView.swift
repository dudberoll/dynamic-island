import SwiftUI

struct BoardColumnView: View {
    let board: KanbanBoard
    let editingTaskID: KanbanTask.ID?
    let draftTitle: String
    let editingValidationMessage: String?
    let recoveryEditingTask: KanbanTask?
    let pendingBoardID: KanbanBoard.ID?
    let newTaskDraftTitle: String
    let newTaskValidationMessage: String?
    let onToggle: (KanbanTask) -> Void
    let onArchive: (KanbanBoard) -> Void
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

                HStack(spacing: 6) {
                    Button {
                        onArchive(board)
                    } label: {
                        ArchiveBoxIcon()
                            .frame(width: 22, height: 22)
                            .background(.white.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Archive completed tasks from this board")
                    .accessibilityLabel("Archive completed tasks from this board")
                    .accessibilityIdentifier("archive-\(board.id.headingLineIndex)")

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

                if let recoveryEditingTask {
                    TaskRow(
                        task: recoveryEditingTask,
                        isEditing: true,
                        draftTitle: draftTitle,
                        validationMessage: editingValidationMessage,
                        onToggle: {},
                        onBeginEditing: {},
                        onDraftTitleChange: onDraftTitleChange,
                        onCommitEditing: {
                            onCommitEditing(recoveryEditingTask)
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

                if board.tasks.isEmpty && !isAddingTask && recoveryEditingTask == nil {
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

private struct ArchiveBoxIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1.4, style: .continuous)
                .stroke(iconColor, style: strokeStyle)
                .frame(width: 12, height: 7.5)
                .offset(y: 2.5)

            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .stroke(iconColor, style: strokeStyle)
                .frame(width: 14, height: 3)
                .offset(y: -4.5)

            Capsule()
                .fill(iconColor)
                .frame(width: 4.5, height: 1.3)
                .offset(y: -2.4)
        }
        .frame(width: 14, height: 14)
    }

    private var iconColor: Color {
        .white.opacity(0.76)
    }

    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: 1.45, lineCap: .round, lineJoin: .round)
    }
}
