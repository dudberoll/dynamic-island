import SwiftUI

struct TaskRow: View {
    let task: KanbanTask
    let isEditing: Bool
    let draftTitle: String
    let validationMessage: String?
    let onToggle: () -> Void
    let onBeginEditing: () -> Void
    let onDraftTitleChange: (String) -> Void
    let onCommitEditing: () -> Void

    @FocusState private var isTitleFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 10) {
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(task.isCompleted ? .green : .white.opacity(0.52))
                        .frame(width: 18, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isEditing)

                titleContent
            }
            .padding(.horizontal, 10)
            .padding(.vertical, isEditing ? 7 : 8)

            if let validationMessage, isEditing {
                Text(validationMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.red.opacity(0.88))
                    .padding(.horizontal, 38)
                    .padding(.bottom, 7)
            }
        }
        .background(validationMessage == nil ? Color.clear : Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .accessibilityIdentifier("task-row-\(task.id.lineIndex)")
    }

    @ViewBuilder
    private var titleContent: some View {
        if isEditing {
            TextField("Task title", text: Binding(
                get: { draftTitle },
                set: onDraftTitleChange
            ))
            .textFieldStyle(.plain)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(0.92))
            .focused($isTitleFieldFocused)
            .onSubmit(onCommitEditing)
            .onChange(of: isTitleFieldFocused) { focused in
                if !focused, isEditing {
                    onCommitEditing()

                    if validationMessage != nil {
                        focusTitleField()
                    }
                }
            }
            .onChange(of: validationMessage) { message in
                if message != nil, isEditing {
                    focusTitleField()
                }
            }
            .onAppear {
                focusTitleField()
            }
            .accessibilityIdentifier("task-title-editor-\(task.id.lineIndex)")
        } else {
            Text(task.text.isEmpty ? "Untitled task" : task.text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(task.isCompleted ? .white.opacity(0.44) : .white.opacity(0.9))
                .strikethrough(task.isCompleted)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(count: 2, perform: onBeginEditing)
                .accessibilityIdentifier("task-title-\(task.id.lineIndex)")
        }
    }

    private func focusTitleField() {
        DispatchQueue.main.async {
            isTitleFieldFocused = true
        }
    }
}

struct NewTaskRow: View {
    let draftTitle: String
    let validationMessage: String?
    let onDraftTitleChange: (String) -> Void
    let onCommit: () -> Void

    @FocusState private var isTitleFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.green)
                    .frame(width: 18, height: 18)

                TextField("New task", text: Binding(
                    get: { draftTitle },
                    set: onDraftTitleChange
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
                .focused($isTitleFieldFocused)
                .onSubmit(onCommit)
                .onChange(of: isTitleFieldFocused) { focused in
                    if !focused {
                        onCommit()

                        if validationMessage != nil {
                            focusTitleField()
                        }
                    }
                }
                .onChange(of: validationMessage) { message in
                    if message != nil {
                        focusTitleField()
                    }
                }
                .onAppear {
                    focusTitleField()
                }
                .accessibilityIdentifier("new-task-title-editor")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)

            if let validationMessage {
                Text(validationMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.red.opacity(0.88))
                    .padding(.horizontal, 38)
                    .padding(.bottom, 7)
            }
        }
        .background(validationMessage == nil ? Color.clear : Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .accessibilityIdentifier("new-task-row")
    }

    private func focusTitleField() {
        DispatchQueue.main.async {
            isTitleFieldFocused = true
        }
    }
}
