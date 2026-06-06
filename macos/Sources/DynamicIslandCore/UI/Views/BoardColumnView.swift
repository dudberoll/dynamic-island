import SwiftUI

struct BoardColumnView: View {
    let board: KanbanBoard
    let editingTaskID: KanbanTask.ID?
    let draftTitle: String
    let editingValidationMessage: String?
    let onToggle: (KanbanTask) -> Void
    let onBeginEditing: (KanbanTask) -> Void
    let onDraftTitleChange: (String) -> Void
    let onCommitEditing: (KanbanTask) -> Void
    let onCancelEditing: () -> Void

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
                        },
                        onCancelEditing: onCancelEditing
                    )
                }

                if board.tasks.isEmpty {
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
