import Combine
import Foundation

@MainActor
public final class TodoStore: ObservableObject {
    @Published public private(set) var document = KanbanDocument(boards: [])
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var operationErrorMessage: String?

    private let backend: KanbanFileBackend
    private var watcher: KanbanFileWatcher?
    private var lastAppliedMarkdown: String?

    public init(sourceURL: URL) {
        backend = KanbanFileBackend(sourceURL: sourceURL)
        reload()
        startWatching(sourceURL: sourceURL)
    }

    public func reload() {
        do {
            apply(try backend.loadSnapshot())
        } catch {
            document = KanbanDocument(boards: [])
            errorMessage = error.localizedDescription
            operationErrorMessage = nil
        }
    }

    public func toggle(_ task: KanbanTask) {
        do {
            apply(try backend.toggle(task))
        } catch {
            applyOperationFailure(error)
        }
    }

    @discardableResult
    public func editTitle(_ task: KanbanTask, title: String) -> Bool {
        do {
            apply(try backend.editTitle(task, title: title))
            return true
        } catch {
            applyOperationFailure(error)
            return false
        }
    }

    private func startWatching(sourceURL: URL) {
        let watcher = KanbanFileWatcher(sourceURL: sourceURL) { [weak self] in
            Task { @MainActor in
                self?.reloadFromFileEvent()
            }
        }

        self.watcher = watcher
        watcher.start()
    }

    private func reloadFromFileEvent() {
        do {
            let snapshot = try backend.loadSnapshot()

            guard snapshot.markdown != lastAppliedMarkdown else {
                return
            }

            apply(snapshot)
        } catch {
            document = KanbanDocument(boards: [])
            errorMessage = error.localizedDescription
            operationErrorMessage = nil
        }
    }

    private func apply(_ snapshot: KanbanFileSnapshot) {
        document = snapshot.document
        lastAppliedMarkdown = snapshot.markdown
        errorMessage = nil
        operationErrorMessage = nil
    }

    private func applyOperationFailure(_ error: Error) {
        let message = error.localizedDescription

        do {
            let snapshot = try backend.loadSnapshot()
            document = snapshot.document
            lastAppliedMarkdown = snapshot.markdown
            errorMessage = nil
            operationErrorMessage = message
        } catch {
            document = KanbanDocument(boards: [])
            errorMessage = message
            operationErrorMessage = nil
        }
    }
}
