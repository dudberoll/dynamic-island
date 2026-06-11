import AppKit
import SwiftUI

public struct IslandRootView: View {
    @StateObject private var store: TodoStore
    @ObservedObject private var dismissBridge: IslandDismissBridge
    @State private var expansionState = IslandExpansionState()
    @State private var editingTaskID: KanbanTask.ID?
    @State private var editingTaskBoardName: String?
    @State private var draftTitle = ""
    @State private var editingValidationMessage: String?
    @State private var pendingBoardID: KanbanBoard.ID?
    @State private var newTaskDraftTitle = ""
    @State private var newTaskValidationMessage: String?

    private let onSizeChange: (CGSize) -> Void

    private enum ActiveContextResult {
        case noActiveContext
        case committed
        case discardedEmptyDraft
        case blocked

        var allowsContinuation: Bool {
            self != .blocked
        }
    }

    public init(
        sourceURL: URL,
        dismissBridge: IslandDismissBridge = IslandDismissBridge(),
        onSizeChange: @escaping (CGSize) -> Void = { _ in }
    ) {
        _store = StateObject(wrappedValue: TodoStore(sourceURL: sourceURL))
        self.dismissBridge = dismissBridge
        self.onSizeChange = onSizeChange
    }

    public var body: some View {
        ZStack(alignment: .top) {
            compactSurface
                .opacity(expansionState.isExpanded ? 0 : 1)
                .allowsHitTesting(!expansionState.isExpanded)

            if expansionState.isExpanded {
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
            withAnimation(IslandTheme.animation) {
                if let size = expansionState.setHovered(hovering) {
                    onSizeChange(size)
                }
            }
        }
        .onChange(of: store.document) { _ in
            reconcileEditingTask()
        }
        .onChange(of: dismissBridge.outsideClickRequestID) { _ in
            handleOutsideClickDismissRequest()
        }
        .background {
            EscapeKeyMonitor(isEnabled: expansionState.isExpanded, onEscape: handleEscape)
                .frame(width: 0, height: 0)
        }
        .onExitCommand(perform: handleEscape)
        .accessibilityIdentifier("dynamic-island-root")
    }

    private var currentSize: CGSize {
        expansionState.size
    }

    private var currentRadius: CGFloat {
        expansionState.radius
    }

    private var compactSurface: some View {
        HStack(spacing: 9) {
            if expansionState.isHovered {
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
                .strokeBorder(.white.opacity(expansionState.isHovered ? 0.13 : 0.05), lineWidth: 1)
        }
        .shadow(
            color: .black.opacity(expansionState.isHovered ? 0.36 : 0.18),
            radius: expansionState.isHovered ? 14 : 7,
            y: expansionState.isHovered ? 8 : 3
        )
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
                commitActiveContextAndCollapse()
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
                                recoveryEditingTask: recoveryEditingTask(for: board),
                                pendingBoardID: pendingBoardID,
                                newTaskDraftTitle: newTaskDraftTitle,
                                newTaskValidationMessage: newTaskValidationMessage,
                                onToggle: { task in
                                    toggleTask(task)
                                },
                                onArchive: archiveCompletedTasks,
                                onBeginEditing: beginEditing,
                                onDraftTitleChange: updateDraftTitle,
                                onCommitEditing: { task in
                                    _ = commitEditing(task)
                                },
                                onBeginAdding: beginAddingTask,
                                onNewTaskDraftChange: updateNewTaskDraftTitle,
                                onCommitNewTask: { board in
                                    _ = commitNewTask(board, allowsEmptyDraftDiscard: false)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 22)
                }
                .contentShape(Rectangle())
                .onTapGesture {}
            }
        }
        .frame(width: IslandTheme.expandedSize.width, height: IslandTheme.expandedSize.height, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: IslandTheme.expandedRadius, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .contentShape(RoundedRectangle(cornerRadius: IslandTheme.expandedRadius, style: .continuous))
                .onTapGesture {
                    commitActiveContextAndCollapse()
                }
        }
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
            onSizeChange(expansionState.setExpanded(expanded))
        }
    }

    private func toggleTask(_ task: KanbanTask) {
        guard prepareActiveContextForTransition().allowsContinuation else {
            return
        }

        guard let currentTask = resolveCurrentTask(matching: task) else {
            return
        }

        store.toggle(currentTask)
    }

    private func archiveCompletedTasks(in board: KanbanBoard) {
        guard let currentBoard = resolveCurrentBoard(matching: board) else {
            return
        }

        guard ArchiveCompletedTasksPlan.make(for: currentBoard) != nil else {
            return
        }
    }

    private func beginEditing(_ task: KanbanTask) {
        guard prepareActiveContextForTransition().allowsContinuation else {
            return
        }

        guard let currentTask = resolveCurrentTask(matching: task) else {
            cancelEditing()
            return
        }

        editingTaskID = currentTask.id
        editingTaskBoardName = currentTask.boardName
        draftTitle = currentTask.text
        editingValidationMessage = nil
    }

    private func updateDraftTitle(_ title: String) {
        draftTitle = title

        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            editingValidationMessage = nil
        }
    }

    @discardableResult
    private func commitEditing(_ task: KanbanTask) -> ActiveContextResult {
        guard editingTaskID == task.id else {
            return .noActiveContext
        }

        let cleanedTitle = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else {
            editingValidationMessage = "Task title is required"
            return .blocked
        }

        guard !cleanedTitle.contains(where: \.isNewline) else {
            editingValidationMessage = "Task title must be one line"
            return .blocked
        }

        if store.editTitle(task, title: cleanedTitle) {
            cancelEditing()
            return .committed
        } else {
            editingValidationMessage = "Could not save task title"
            return .blocked
        }
    }

    private func cancelEditing() {
        editingTaskID = nil
        editingTaskBoardName = nil
        draftTitle = ""
        editingValidationMessage = nil
    }

    private func commitActiveContextAndCollapse() {
        guard prepareActiveContextForDismissal().allowsContinuation else {
            return
        }

        setExpanded(false)
    }

    private func handleOutsideClickDismissRequest() {
        guard expansionState.isExpanded else {
            return
        }

        commitActiveContextAndCollapse()
    }

    private func handleEscape() {
        let hadActiveEditState = editingTaskID != nil || pendingBoardID != nil

        if editingTaskID != nil {
            cancelEditing()
        }

        if pendingBoardID != nil {
            cancelNewTask()
        }

        if hadActiveEditState {
            return
        }

        if expansionState.isExpanded {
            setExpanded(false)
        }
    }

    private func prepareActiveContextForDismissal() -> ActiveContextResult {
        prepareActiveContext(allowsEmptyDraftDiscard: true)
    }

    private func prepareActiveContextForTransition() -> ActiveContextResult {
        prepareActiveContext(allowsEmptyDraftDiscard: true)
    }

    private func prepareActiveContext(allowsEmptyDraftDiscard: Bool) -> ActiveContextResult {
        var result: ActiveContextResult = .noActiveContext

        if let task = activeEditingTask {
            editingTaskID = task.id
            editingTaskBoardName = task.boardName
            result = commitEditing(task)

            guard result.allowsContinuation else {
                return result
            }
        } else if editingTaskID != nil {
            editingValidationMessage = editingValidationMessage ?? "Could not save task title"
            return .blocked
        }

        if let board = activePendingBoard {
            pendingBoardID = board.id
            let addResult = commitNewTask(board, allowsEmptyDraftDiscard: allowsEmptyDraftDiscard)

            guard addResult.allowsContinuation else {
                return addResult
            }

            result = addResult
        }

        return result
    }

    private var activeEditingTask: KanbanTask? {
        guard let editingTaskID else {
            return nil
        }

        let tasks = store.document.boards.flatMap(\.tasks)

        if let exactMatch = tasks.first(where: { $0.id == editingTaskID }) {
            return exactMatch
        }

        if let sourceLine = editingTaskID.sourceLine {
            if let boardMatch = tasks.first(where: {
                $0.boardName == editingTaskBoardName && $0.id.sourceLine == sourceLine
            }) {
                return boardMatch
            }

            if editingTaskBoardName == nil {
                return tasks.only { $0.id.sourceLine == sourceLine }
            }
        }

        return tasks.only {
            $0.boardName == editingTaskBoardName && $0.id.lineIndex == editingTaskID.lineIndex
        }
    }

    private func recoveryEditingTask(for board: KanbanBoard) -> KanbanTask? {
        guard
            let editingTaskID,
            activeEditingTask == nil,
            store.operationErrorMessage != nil,
            editingTaskBoardName == board.name
        else {
            return nil
        }

        return KanbanTask(
            id: editingTaskID,
            boardName: board.name,
            text: draftTitle,
            isCompleted: false
        )
    }

    private func reconcileEditingTask() {
        guard editingTaskID != nil else {
            reconcilePendingBoard()
            return
        }

        if let reboundTask = activeEditingTask {
            editingTaskID = reboundTask.id
            editingTaskBoardName = reboundTask.boardName
        } else if store.operationErrorMessage != nil {
            editingValidationMessage = editingValidationMessage ?? "Could not save task title"
        } else {
            cancelEditing()
        }

        reconcilePendingBoard()
    }

    private func beginAddingTask(to board: KanbanBoard) {
        guard prepareActiveContextForTransition().allowsContinuation else {
            return
        }

        guard let currentBoard = resolveCurrentBoard(matching: board) else {
            cancelNewTask()
            return
        }

        pendingBoardID = currentBoard.id
        newTaskDraftTitle = ""
        newTaskValidationMessage = nil
    }

    private func updateNewTaskDraftTitle(_ title: String) {
        newTaskDraftTitle = title

        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            newTaskValidationMessage = nil
        }
    }

    @discardableResult
    private func commitNewTask(_ board: KanbanBoard, allowsEmptyDraftDiscard: Bool) -> ActiveContextResult {
        guard pendingBoardID == board.id else {
            return .noActiveContext
        }

        let cleanedTitle = newTaskDraftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else {
            if allowsEmptyDraftDiscard {
                cancelNewTask()
                return .discardedEmptyDraft
            }

            newTaskValidationMessage = "Task title is required"
            return .blocked
        }

        guard !cleanedTitle.contains(where: \.isNewline) else {
            newTaskValidationMessage = "Task title must be one line"
            return .blocked
        }

        if store.addTask(to: board, title: cleanedTitle) {
            cancelNewTask()
            return .committed
        } else {
            newTaskValidationMessage = "Could not save new task"
            return .blocked
        }
    }

    private func cancelNewTask() {
        pendingBoardID = nil
        newTaskDraftTitle = ""
        newTaskValidationMessage = nil
    }

    private var activePendingBoard: KanbanBoard? {
        guard let pendingBoardID else {
            return nil
        }

        if let exactMatch = store.document.boards.first(where: { $0.id == pendingBoardID }) {
            return exactMatch
        }

        if let sourceLine = pendingBoardID.sourceLine {
            if let sourceMatch = store.document.boards.first(where: {
                $0.name == pendingBoardID.name && $0.id.sourceLine == sourceLine
            }) {
                return sourceMatch
            }
        }

        if let lineMatch = store.document.boards.first(where: {
            $0.name == pendingBoardID.name && $0.id.headingLineIndex == pendingBoardID.headingLineIndex
        }) {
            return lineMatch
        }

        return store.document.boards.only { $0.name == pendingBoardID.name }
    }

    private func reconcilePendingBoard() {
        guard pendingBoardID != nil else {
            return
        }

        if let reboundBoard = activePendingBoard {
            pendingBoardID = reboundBoard.id
        } else if store.operationErrorMessage != nil {
            newTaskValidationMessage = newTaskValidationMessage ?? "Could not save new task"
        } else {
            cancelNewTask()
        }
    }

    private func resolveCurrentTask(matching task: KanbanTask) -> KanbanTask? {
        let tasks = store.document.boards.flatMap(\.tasks)

        if let exactMatch = tasks.first(where: { $0.id == task.id }) {
            return exactMatch
        }

        if let sourceLine = task.id.sourceLine {
            if let sourceMatch = tasks.first(where: {
                $0.boardName == task.boardName && $0.id.sourceLine == sourceLine
            }) {
                return sourceMatch
            }
        }

        return tasks.only {
            $0.boardName == task.boardName && $0.id.lineIndex == task.id.lineIndex
        }
    }

    private func resolveCurrentBoard(matching board: KanbanBoard) -> KanbanBoard? {
        if let exactMatch = store.document.boards.first(where: { $0.id == board.id }) {
            return exactMatch
        }

        if let sourceLine = board.id.sourceLine {
            if let sourceMatch = store.document.boards.first(where: {
                $0.name == board.name && $0.id.sourceLine == sourceLine
            }) {
                return sourceMatch
            }
        }

        if let lineMatch = store.document.boards.first(where: {
            $0.name == board.name && $0.id.headingLineIndex == board.id.headingLineIndex
        }) {
            return lineMatch
        }

        return store.document.boards.only {
            $0.name == board.name
        }
    }
}

private extension Array {
    func only(where predicate: (Element) -> Bool) -> Element? {
        var match: Element?

        for element in self where predicate(element) {
            guard match == nil else {
                return nil
            }

            match = element
        }

        return match
    }
}

private struct EscapeKeyMonitor: NSViewRepresentable {
    let isEnabled: Bool
    let onEscape: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(isEnabled: isEnabled, onEscape: onEscape)
    }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.installMonitorIfNeeded()
        return NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.isEnabled = isEnabled
        context.coordinator.onEscape = onEscape
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }

    final class Coordinator {
        private static let escapeKeyCode: UInt16 = 53

        var isEnabled: Bool
        var onEscape: () -> Void
        private var monitor: Any?

        init(isEnabled: Bool, onEscape: @escaping () -> Void) {
            self.isEnabled = isEnabled
            self.onEscape = onEscape
        }

        func installMonitorIfNeeded() {
            guard monitor == nil else {
                return
            }

            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.isEnabled, event.keyCode == Self.escapeKeyCode else {
                    return event
                }

                self.onEscape()
                return nil
            }
        }

        func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        deinit {
            removeMonitor()
        }
    }
}
