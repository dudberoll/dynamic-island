import XCTest
@testable import DynamicIslandCore

@MainActor
final class TodoStoreArchiveTests: XCTestCase {
    func testArchiveCompletedTasksArchivesOnlySelectedBoardThroughStore() throws {
        let markdown = """
        ## main

        - [ ] main active
        - [x] main done

        ## other

        - [x] other done
        - [ ] other active
        """
        let sourceURL = try makeTemporaryMarkdownFile(markdown)
        let store = TodoStore(sourceURL: sourceURL)
        let sourceBoard = try XCTUnwrap(store.document.boards.first { $0.name == "main" })
        let plan = try XCTUnwrap(ArchiveCompletedTasksPlan.make(for: sourceBoard))

        XCTAssertTrue(store.archiveCompletedTasks(plan))

        let updated = try String(contentsOf: sourceURL, encoding: .utf8)
        XCTAssertTrue(updated.contains("- [ ] main active"))
        XCTAssertFalse(updated.contains("- [x] main done\n"))
        XCTAssertTrue(updated.contains("- [x] other done"))
        XCTAssertTrue(updated.contains("- [ ] other active"))
        XCTAssertTrue(updated.contains("## Archive\n\n- [x] main done_main"))
        XCTAssertNil(store.operationErrorMessage)
        XCTAssertEqual(store.document.boards.map(\.name), ["main", "other"])
        XCTAssertFalse(store.document.boards.contains { $0.name.localizedCaseInsensitiveCompare("Archive") == .orderedSame })
        XCTAssertEqual(store.document.boards[0].tasks.map(\.text), ["main active"])
        XCTAssertEqual(store.document.boards[1].tasks.map(\.text), ["other done", "other active"])
    }

    private func makeTemporaryMarkdownFile(_ markdown: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("tasks.md")
        try markdown.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
