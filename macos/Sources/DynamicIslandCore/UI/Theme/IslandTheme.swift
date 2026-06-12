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

    static let animation = Animation.spring(response: 0.28, dampingFraction: 0.86)
    static let boardCollapseAnimation = Animation.spring(response: 0.24, dampingFraction: 0.9)
}
