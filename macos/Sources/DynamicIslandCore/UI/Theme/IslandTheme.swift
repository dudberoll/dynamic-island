import SwiftUI

enum IslandTheme {
    static let collapsedSize = CGSize(width: 200, height: 36)
    static let hoverSize = CGSize(width: 246, height: 42)
    static let expandedSize = CGSize(width: 620, height: 500)
    static let collapsedRadius: CGFloat = 18
    static let hoverRadius: CGFloat = 21
    static let expandedRadius: CGFloat = 34
    static let controlRadius: CGFloat = 12
    static let spacing: CGFloat = 12
    static let topInset: CGFloat = 0
    static let expandedBoardWidth: CGFloat = 260
    static let collapsedBoardWidth: CGFloat = 48
    static let collapsedBoardNameHeight: CGFloat = 150

    static let animation = Animation.spring(response: 0.28, dampingFraction: 0.86)
    static let boardCollapseAnimation = Animation.spring(response: 0.24, dampingFraction: 0.9)
}

enum CollapsedBoardLayout {
    static let verticalPadding: CGFloat = 10
    static let sectionSpacing: CGFloat = 8
    static let actionSize: CGFloat = 22
    static let actionSpacing: CGFloat = 6
    static let nameWidth: CGFloat = 24
    static let countWidth: CGFloat = 24
    static let countHeight: CGFloat = 20

    static var actionHeight: CGFloat {
        (actionSize * 2) + actionSpacing
    }

    static var actionRange: Range<CGFloat> {
        verticalPadding..<(verticalPadding + actionHeight)
    }

    static var nameRange: Range<CGFloat> {
        let start = actionRange.upperBound + sectionSpacing
        return start..<(start + IslandTheme.collapsedBoardNameHeight)
    }

    static var countRange: Range<CGFloat> {
        let start = nameRange.upperBound + sectionSpacing
        return start..<(start + countHeight)
    }

    static var totalHeight: CGFloat {
        countRange.upperBound + verticalPadding
    }
}
