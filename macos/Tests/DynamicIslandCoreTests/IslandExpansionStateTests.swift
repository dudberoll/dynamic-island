import XCTest
@testable import DynamicIslandCore

final class IslandExpansionStateTests: XCTestCase {
    func testHoverUpdatesCompactSizeOnlyWhileCollapsed() {
        var state = IslandExpansionState()

        XCTAssertEqual(state.size, IslandTheme.collapsedSize)
        XCTAssertEqual(state.setHovered(true), IslandTheme.hoverSize)
        XCTAssertTrue(state.isHovered)
        XCTAssertEqual(state.size, IslandTheme.hoverSize)

        XCTAssertEqual(state.setExpanded(true), IslandTheme.expandedSize)
        XCTAssertTrue(state.isExpanded)
        XCTAssertNil(state.setHovered(false))
        XCTAssertTrue(state.isHovered)
        XCTAssertEqual(state.size, IslandTheme.expandedSize)
    }

    func testCollapseAlwaysReturnsBaseCompactSizeAndClearsHover() {
        var state = IslandExpansionState()

        XCTAssertEqual(state.setHovered(true), IslandTheme.hoverSize)
        XCTAssertEqual(state.setExpanded(true), IslandTheme.expandedSize)

        XCTAssertEqual(state.setExpanded(false), IslandTheme.collapsedSize)
        XCTAssertFalse(state.isExpanded)
        XCTAssertFalse(state.isHovered)
        XCTAssertEqual(state.size, IslandTheme.collapsedSize)
        XCTAssertEqual(state.radius, IslandTheme.collapsedRadius)
    }

    func testRepeatedCollapseStaysAtBaseCompactSize() {
        var state = IslandExpansionState()

        XCTAssertEqual(state.setExpanded(true), IslandTheme.expandedSize)
        XCTAssertEqual(state.setExpanded(false), IslandTheme.collapsedSize)
        XCTAssertEqual(state.setExpanded(false), IslandTheme.collapsedSize)

        XCTAssertEqual(state.size, IslandTheme.collapsedSize)
        XCTAssertFalse(state.isHovered)
        XCTAssertFalse(state.isExpanded)
    }
}
