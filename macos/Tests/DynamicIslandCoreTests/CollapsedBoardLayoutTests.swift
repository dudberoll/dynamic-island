import XCTest
@testable import DynamicIslandCore

final class CollapsedBoardLayoutTests: XCTestCase {
    func testCollapsedSectionsHaveDisjointVerticalRanges() {
        XCTAssertLessThanOrEqual(CollapsedBoardLayout.actionRange.upperBound, CollapsedBoardLayout.nameRange.lowerBound)
        XCTAssertLessThanOrEqual(CollapsedBoardLayout.nameRange.upperBound, CollapsedBoardLayout.countRange.lowerBound)
        XCTAssertEqual(CollapsedBoardLayout.countRange.upperBound + CollapsedBoardLayout.verticalPadding, CollapsedBoardLayout.totalHeight)
    }

    func testCollapsedSectionsFitWithinStripWidth() {
        XCTAssertLessThanOrEqual(CollapsedBoardLayout.actionSize, IslandTheme.collapsedBoardWidth)
        XCTAssertLessThanOrEqual(CollapsedBoardLayout.nameWidth, IslandTheme.collapsedBoardWidth)
        XCTAssertLessThanOrEqual(CollapsedBoardLayout.countWidth, IslandTheme.collapsedBoardWidth)
    }
}
