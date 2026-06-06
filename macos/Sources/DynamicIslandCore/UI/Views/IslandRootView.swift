import SwiftUI

public struct IslandRootView: View {
    @StateObject private var store: TodoStore
    @State private var isHovered = false
    @State private var isExpanded = false
    @State private var editingTaskID: KanbanTask.ID?
    @State private var draftTitle = ""
    @State private var editingValidationMessage: String?

    private let onSizeChange: (CGSize) -> Void

    public init(sourceURL: URL, onSizeChange: @escaping (CGSize) -> Void = { _ in }) {
        _store = StateObject(wrappedValue: TodoStore(sourceURL: sourceURL))
        self.onSizeChange = onSizeChange
    }

    public var body: some View {
        ZStack(alignment: .top) {
            compactSurface
                .opacity(isExpanded ? 0 : 1)
                .allowsHitTesting(!isExpanded)

            if isExpanded {
                expandedSurface
                    .allowsHitTesting(true)
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
        .frame(
            width: currentSize.width,
            height: currentSize.height,
            alignment: .top
        )
        .preferredColorScheme(.dark)
        .contentShape(RoundedRectangle(cornerRadius: currentRadius, style: .continuous))
        .onHover { hovering in
            guard !isExpanded else {
                return
            }

            withAnimation(IslandTheme.animation) {
                isHovered = hovering
                onSizeChange(currentSize)
            }
        }
        .onChange(of: store.document) { _ in
            reconcileEditingTask()
        }
        .accessibilityIdentifier("dynamic-island-root")
    }

    private var currentSize: CGSize {
        if isExpanded {
            return IslandTheme.expandedSize
        }

        return isHovered ? IslandTheme.hoverSize : IslandTheme.collapsedSize
    }

    private var currentRadius: CGFloat {
        if isExpanded {
            return IslandTheme.expandedRadius
        }

        return isHovered ? IslandTheme.hoverRadius : IslandTheme.collapsedRadius
    }

    private var compactSurface: some View {
        HStack(spacing: 9) {
            if isHovered {
                Image(systemName: "checklist")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.86))
                    .frame(width: 18, height: 18)

                Text("\(store.document.activeTaskCount)")
                    .font(.system(size: 12, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.88))
                    .transition(.opacity.combined(with: .scale(scale: 0.86)))
            } else {
                Capsule()
                    .fill(.white.opacity(0.12))
                    .frame(width: 34, height: 3)
                    .blur(radius: 0.2)
                    .opacity(0.45)
            }
        }
        .frame(width: currentSize.width, height: currentSize.height)
        .background(Color.black.opacity(0.94), in: RoundedRectangle(cornerRadius: currentRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: currentRadius, style: .continuous)
                .strokeBorder(.white.opacity(isHovered ? 0.13 : 0.05), lineWidth: 1)
        }
        .shadow(color: .black.opacity(isHovered ? 0.36 : 0.18), radius: isHovered ? 14 : 7, y: isHovered ? 8 : 3)
        .onTapGesture {
            setExpanded(true)
        }
    }

    private var expandedSurface: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 30, height: 30)
                    .background(.white.opacity(0.08), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Obsidian Kanban")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("\(store.document.activeTaskCount) active")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.56))
                        .monospacedDigit()
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .contentShape(Rectangle())
            .onTapGesture {
                collapseAfterSavingActiveEdit()
            }

            if let operationErrorMessage = store.operationErrorMessage {
                operationErrorView(operationErrorMessage)
            }

            if let errorMessage = store.errorMessage {
                errorView(errorMessage)
            } else if store.document.boards.isEmpty {
                emptyView
            } else {
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    HStack(alignment: .top, spacing: IslandTheme.spacing) {
                        ForEach(store.document.boards) { board in
                            BoardColumnView(
                                board: board,
                                editingTaskID: editingTaskID,
                                draftTitle: draftTitle,
                                editingValidationMessage: editingValidationMessage,
                                onToggle: { task in
                                    store.toggle(task)
                                },
                                onBeginEditing: beginEditing,
                                onDraftTitleChange: updateDraftTitle,
                                onCommitEditing: commitEditing,
                                onCancelEditing: cancelEditing
                            )
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 22)
                }
            }
        }
        .frame(width: IslandTheme.expandedSize.width, height: IslandTheme.expandedSize.height, alignment: .topLeading)
        .background(Color.black.opacity(0.92), in: RoundedRectangle(cornerRadius: IslandTheme.expandedRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: IslandTheme.expandedRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.42), radius: 28, y: 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func operationErrorView(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.orange)
            .lineLimit(2)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.orange.opacity(0.24), lineWidth: 1)
            }
            .padding(.horizontal, 22)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white.opacity(0.48))

            Text("No Kanban tasks")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Cannot read tasks", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.orange)

            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(3)

            Button("Retry") {
                store.reload()
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 22)
    }

    private func setExpanded(_ expanded: Bool) {
        withAnimation(IslandTheme.animation) {
            isExpanded = expanded
            onSizeChange(expanded ? IslandTheme.expandedSize : currentCollapsedSize)
        }
    }

    private var currentCollapsedSize: CGSize {
        isHovered ? IslandTheme.hoverSize : IslandTheme.collapsedSize
    }

    private func beginEditing(_ task: KanbanTask) {
        editingTaskID = task.id
        draftTitle = task.text
        editingValidationMessage = nil
    }

    private func updateDraftTitle(_ title: String) {
        draftTitle = title

        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            editingValidationMessage = nil
        }
    }

    private func commitEditing(_ task: KanbanTask) {
        guard editingTaskID == task.id else {
            return
        }

        let cleanedTitle = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else {
            editingValidationMessage = "Task title is required"
            return
        }

        if store.editTitle(task, title: cleanedTitle) {
            cancelEditing()
        } else {
            editingTaskID = nil
            draftTitle = ""
            editingValidationMessage = nil
        }
    }

    private func cancelEditing() {
        editingTaskID = nil
        draftTitle = ""
        editingValidationMessage = nil
    }

    private func collapseAfterSavingActiveEdit() {
        if let task = activeEditingTask {
            commitEditing(task)

            if editingTaskID != nil {
                return
            }
        }

        setExpanded(false)
    }

    private var activeEditingTask: KanbanTask? {
        guard let editingTaskID else {
            return nil
        }

        return store.document.boards
            .flatMap(\.tasks)
            .first { $0.id == editingTaskID }
    }

    private func reconcileEditingTask() {
        guard editingTaskID != nil else {
            return
        }

        if activeEditingTask == nil {
            cancelEditing()
        }
    }
}
