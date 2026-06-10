import Foundation

public struct KanbanDocument: Equatable {
    public var boards: [KanbanBoard]

    public init(boards: [KanbanBoard]) {
        self.boards = boards
    }

    public var activeTaskCount: Int {
        boards.reduce(0) { total, board in
            total + board.tasks.filter { !$0.isCompleted }.count
        }
    }
}

public struct KanbanBoard: Identifiable, Equatable {
    public struct ID: Hashable, Codable {
        public let headingLineIndex: Int
        public let name: String
        public let sourceLine: String?

        public init(headingLineIndex: Int, name: String, sourceLine: String? = nil) {
            self.headingLineIndex = headingLineIndex
            self.name = name
            self.sourceLine = sourceLine
        }
    }

    public var id: ID
    public var name: String
    public var tasks: [KanbanTask]

    public init(id: ID? = nil, name: String, tasks: [KanbanTask]) {
        self.id = id ?? ID(headingLineIndex: -1, name: name)
        self.name = name
        self.tasks = tasks
    }
}

public struct KanbanTask: Identifiable, Equatable {
    public struct ID: Hashable, Codable {
        public let lineIndex: Int
        public let sourceLine: String?

        public init(lineIndex: Int, sourceLine: String? = nil) {
            self.lineIndex = lineIndex
            self.sourceLine = sourceLine
        }
    }

    public var id: ID
    public var boardName: String
    public var text: String
    public var isCompleted: Bool

    public init(id: ID, boardName: String, text: String, isCompleted: Bool) {
        self.id = id
        self.boardName = boardName
        self.text = text
        self.isCompleted = isCompleted
    }
}
