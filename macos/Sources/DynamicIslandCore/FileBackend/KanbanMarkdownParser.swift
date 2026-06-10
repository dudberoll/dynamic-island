import Foundation

public enum KanbanMarkdownError: LocalizedError, Equatable {
    case boardLineNotFound(Int)
    case lineIsNotBoard(Int)
    case boardLineChanged(Int)
    case hiddenBoardCannotBeModified(String)
    case taskLineNotFound(Int)
    case lineIsNotTask(Int)
    case taskLineChanged(Int)
    case emptyTaskTitle
    case multilineTaskTitle

    public var errorDescription: String? {
        switch self {
        case let .boardLineNotFound(lineIndex):
            return "Board line \(lineIndex) was not found."
        case let .lineIsNotBoard(lineIndex):
            return "Line \(lineIndex) is not an Obsidian Kanban board."
        case let .boardLineChanged(lineIndex):
            return "Board line \(lineIndex) changed before the operation could be saved."
        case let .hiddenBoardCannotBeModified(name):
            return "Board \(name) is hidden and cannot be modified."
        case let .taskLineNotFound(lineIndex):
            return "Task line \(lineIndex) was not found."
        case let .lineIsNotTask(lineIndex):
            return "Line \(lineIndex) is not an Obsidian Kanban task."
        case let .taskLineChanged(lineIndex):
            return "Task line \(lineIndex) changed before the operation could be saved."
        case .emptyTaskTitle:
            return "Task title cannot be empty."
        case .multilineTaskTitle:
            return "Task title cannot contain line breaks."
        }
    }
}

public struct KanbanMarkdownParser {
    public init() {}

    public func parse(_ markdown: String) -> KanbanDocument {
        var boards: [KanbanBoard] = []
        var currentBoardName: String?
        var currentBoardID: KanbanBoard.ID?
        var currentTasks: [KanbanTask] = []

        for (lineIndex, line) in SourceLine.split(markdown).enumerated() {
            if let boardName = parseBoardName(line.content) {
                appendCurrentBoard(id: &currentBoardID, name: &currentBoardName, tasks: &currentTasks, boards: &boards)
                currentBoardName = boardName.isEmpty ? nil : boardName
                currentBoardID = boardName.isEmpty ? nil : KanbanBoard.ID(
                    headingLineIndex: lineIndex,
                    name: boardName,
                    sourceLine: line.content
                )
                continue
            }

            guard let boardName = currentBoardName else {
                continue
            }

            if let task = parseTask(line.content, boardName: boardName, lineIndex: lineIndex) {
                currentTasks.append(task)
            }
        }

        appendCurrentBoard(id: &currentBoardID, name: &currentBoardName, tasks: &currentTasks, boards: &boards)
        return KanbanDocument(boards: boards)
    }

    public func toggleTask(in markdown: String, taskID: KanbanTask.ID) throws -> String {
        var lines = SourceLine.split(markdown)

        guard lines.indices.contains(taskID.lineIndex) else {
            throw KanbanMarkdownError.taskLineNotFound(taskID.lineIndex)
        }

        guard let checkboxIndex = taskCheckboxIndex(in: lines[taskID.lineIndex].content) else {
            throw KanbanMarkdownError.lineIsNotTask(taskID.lineIndex)
        }

        try validateTaskLineIdentity(lines[taskID.lineIndex].content, taskID: taskID)

        let currentValue = lines[taskID.lineIndex].content[checkboxIndex]
        lines[taskID.lineIndex].content.replaceSubrange(
            checkboxIndex...checkboxIndex,
            with: currentValue == " " ? "x" : " "
        )

        return lines.map { $0.content + $0.ending }.joined()
    }

    public func editTaskTitle(in markdown: String, taskID: KanbanTask.ID, title: String) throws -> String {
        let cleanedTitle = try cleanTaskTitle(title)

        var lines = SourceLine.split(markdown)

        guard lines.indices.contains(taskID.lineIndex) else {
            throw KanbanMarkdownError.taskLineNotFound(taskID.lineIndex)
        }

        guard let parts = taskLineParts(in: lines[taskID.lineIndex].content) else {
            throw KanbanMarkdownError.lineIsNotTask(taskID.lineIndex)
        }

        try validateTaskLineIdentity(lines[taskID.lineIndex].content, taskID: taskID)

        lines[taskID.lineIndex].content.replaceSubrange(parts.titleRange, with: " \(cleanedTitle)")

        return lines.map { $0.content + $0.ending }.joined()
    }

    public func appendTask(in markdown: String, boardID: KanbanBoard.ID, title: String) throws -> String {
        let cleanedTitle = try cleanTaskTitle(title)

        var lines = SourceLine.split(markdown)

        guard lines.indices.contains(boardID.headingLineIndex) else {
            throw KanbanMarkdownError.boardLineNotFound(boardID.headingLineIndex)
        }

        guard let boardName = parseBoardName(lines[boardID.headingLineIndex].content) else {
            throw KanbanMarkdownError.lineIsNotBoard(boardID.headingLineIndex)
        }

        try validateBoardLineIdentity(lines[boardID.headingLineIndex].content, boardID: boardID)

        guard !isHiddenBoard(boardName) else {
            throw KanbanMarkdownError.hiddenBoardCannotBeModified(boardName)
        }

        let sectionEndIndex = nextBoardLineIndex(in: lines, after: boardID.headingLineIndex) ?? lines.endIndex
        let taskIndices = lines.indices.filter { index in
            index > boardID.headingLineIndex && index < sectionEndIndex && taskLineParts(in: lines[index].content) != nil
        }
        let anchorIndex = taskIndices.last ?? boardID.headingLineIndex
        let indentation = taskIndices.last.flatMap { taskIndentation(in: lines[$0].content) } ?? ""
        let lineEnding = preferredLineEnding(in: lines)
        let insertIndex = anchorIndex + 1
        let insertedEnding = insertIndex < lines.endIndex ? lineEnding : ""

        if lines[anchorIndex].ending.isEmpty {
            lines[anchorIndex].ending = lineEnding
        }

        lines.insert(
            SourceLine(content: "\(indentation)- [ ] \(cleanedTitle)", ending: insertedEnding),
            at: insertIndex
        )

        return lines.map { $0.content + $0.ending }.joined()
    }

    private func appendCurrentBoard(
        id: inout KanbanBoard.ID?,
        name: inout String?,
        tasks: inout [KanbanTask],
        boards: inout [KanbanBoard]
    ) {
        guard let name else {
            id = nil
            tasks.removeAll()
            return
        }

        if !isHiddenBoard(name) {
            boards.append(KanbanBoard(id: id, name: name, tasks: tasks))
        }

        id = nil
        tasks.removeAll()
    }

    private func isHiddenBoard(_ name: String) -> Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("archive") == .orderedSame
    }

    private func cleanTaskTitle(_ title: String) throws -> String {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedTitle.isEmpty else {
            throw KanbanMarkdownError.emptyTaskTitle
        }

        guard !cleanedTitle.contains(where: \.isNewline) else {
            throw KanbanMarkdownError.multilineTaskTitle
        }

        return cleanedTitle
    }

    private func parseBoardName(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        guard trimmed.hasPrefix("##") else {
            return nil
        }

        let markerEnd = trimmed.index(trimmed.startIndex, offsetBy: 2)
        guard markerEnd == trimmed.endIndex || trimmed[markerEnd] != "#" else {
            return nil
        }

        return trimmed[markerEnd...].trimmingCharacters(in: .whitespaces)
    }

    private func parseTask(_ line: String, boardName: String, lineIndex: Int) -> KanbanTask? {
        guard let parts = taskLineParts(in: line) else {
            return nil
        }

        let status = line[parts.checkboxIndex]
        let text = line[parts.titleRange].trimmingCharacters(in: .whitespaces)

        return KanbanTask(
            id: KanbanTask.ID(lineIndex: lineIndex, sourceLine: line),
            boardName: boardName,
            text: text,
            isCompleted: status == "x" || status == "X"
        )
    }

    private func validateTaskLineIdentity(_ line: String, taskID: KanbanTask.ID) throws {
        guard let sourceLine = taskID.sourceLine else {
            return
        }

        guard line == sourceLine else {
            throw KanbanMarkdownError.taskLineChanged(taskID.lineIndex)
        }
    }

    private func validateBoardLineIdentity(_ line: String, boardID: KanbanBoard.ID) throws {
        guard let sourceLine = boardID.sourceLine else {
            return
        }

        guard line == sourceLine else {
            throw KanbanMarkdownError.boardLineChanged(boardID.headingLineIndex)
        }
    }

    private func nextBoardLineIndex(in lines: [SourceLine], after headingLineIndex: Int) -> Int? {
        lines.indices.first { index in
            index > headingLineIndex && parseBoardName(lines[index].content) != nil
        }
    }

    private func taskIndentation(in line: String) -> String {
        String(line.prefix { $0.isWhitespace })
    }

    private func preferredLineEnding(in lines: [SourceLine]) -> String {
        lines.first { !$0.ending.isEmpty }?.ending ?? "\n"
    }

    private struct TaskLineParts {
        var checkboxIndex: String.Index
        var titleRange: Range<String.Index>
    }

    private func taskLineParts(in line: String) -> TaskLineParts? {
        guard let checkboxIndex = taskCheckboxIndex(in: line) else {
            return nil
        }

        let closeBracketIndex = line.index(after: checkboxIndex)
        let titleStart = line.index(after: closeBracketIndex)
        return TaskLineParts(checkboxIndex: checkboxIndex, titleRange: titleStart..<line.endIndex)
    }

    private func taskCheckboxIndex(in line: String) -> String.Index? {
        var index = line.startIndex

        while index < line.endIndex, line[index].isWhitespace {
            index = line.index(after: index)
        }

        guard index < line.endIndex, line[index] == "-" else {
            return nil
        }

        let spaceIndex = line.index(after: index)
        guard spaceIndex < line.endIndex, line[spaceIndex] == " " else {
            return nil
        }

        let openBracketIndex = line.index(after: spaceIndex)
        guard openBracketIndex < line.endIndex, line[openBracketIndex] == "[" else {
            return nil
        }

        let statusIndex = line.index(after: openBracketIndex)
        guard statusIndex < line.endIndex else {
            return nil
        }

        let status = line[statusIndex]
        guard status == " " || status == "x" || status == "X" else {
            return nil
        }

        let closeBracketIndex = line.index(after: statusIndex)
        guard closeBracketIndex < line.endIndex, line[closeBracketIndex] == "]" else {
            return nil
        }

        return statusIndex
    }
}

private struct SourceLine {
    var content: String
    var ending: String

    static func split(_ text: String) -> [SourceLine] {
        guard !text.isEmpty else {
            return []
        }

        var lines: [SourceLine] = []
        var lineStart = text.startIndex
        var index = text.startIndex

        while index < text.endIndex {
            if text[index].isNewline {
                lines.append(SourceLine(content: String(text[lineStart..<index]), ending: String(text[index])))
                lineStart = text.index(after: index)
            }

            index = text.index(after: index)
        }

        if lineStart < text.endIndex {
            lines.append(SourceLine(content: String(text[lineStart..<text.endIndex]), ending: ""))
        }

        return lines
    }
}
