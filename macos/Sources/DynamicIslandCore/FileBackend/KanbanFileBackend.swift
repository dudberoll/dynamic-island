import Foundation

public struct KanbanFileSnapshot {
    public var markdown: String
    public var document: KanbanDocument

    public init(markdown: String, document: KanbanDocument) {
        self.markdown = markdown
        self.document = document
    }
}

public struct KanbanFileBackend {
    public var sourceURL: URL
    private var parser: KanbanMarkdownParser

    public init(sourceURL: URL, parser: KanbanMarkdownParser = KanbanMarkdownParser()) {
        self.sourceURL = sourceURL
        self.parser = parser
    }

    public func load() throws -> KanbanDocument {
        try loadSnapshot().document
    }

    public func loadSnapshot() throws -> KanbanFileSnapshot {
        let markdown = try String(contentsOf: sourceURL, encoding: .utf8)
        return KanbanFileSnapshot(markdown: markdown, document: parser.parse(markdown))
    }

    @discardableResult
    public func toggle(_ task: KanbanTask) throws -> KanbanFileSnapshot {
        let markdown = try String(contentsOf: sourceURL, encoding: .utf8)
        let updatedMarkdown = try parser.toggleTask(in: markdown, taskID: task.id)
        try updatedMarkdown.write(to: sourceURL, atomically: true, encoding: .utf8)
        return KanbanFileSnapshot(markdown: updatedMarkdown, document: parser.parse(updatedMarkdown))
    }

    @discardableResult
    public func editTitle(_ task: KanbanTask, title: String) throws -> KanbanFileSnapshot {
        let markdown = try String(contentsOf: sourceURL, encoding: .utf8)
        let updatedMarkdown = try parser.editTaskTitle(in: markdown, taskID: task.id, title: title)
        try updatedMarkdown.write(to: sourceURL, atomically: true, encoding: .utf8)
        return KanbanFileSnapshot(markdown: updatedMarkdown, document: parser.parse(updatedMarkdown))
    }
}
