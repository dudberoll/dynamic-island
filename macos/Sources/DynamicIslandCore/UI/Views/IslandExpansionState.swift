import CoreGraphics

struct IslandExpansionState: Equatable {
    private(set) var isHovered = false
    private(set) var isExpanded = false

    var size: CGSize {
        if isExpanded {
            return IslandTheme.expandedSize
        }

        return isHovered ? IslandTheme.hoverSize : IslandTheme.collapsedSize
    }

    var radius: CGFloat {
        if isExpanded {
            return IslandTheme.expandedRadius
        }

        return isHovered ? IslandTheme.hoverRadius : IslandTheme.collapsedRadius
    }

    mutating func setHovered(_ hovered: Bool) -> CGSize? {
        guard !isExpanded else {
            return nil
        }

        isHovered = hovered
        return size
    }

    mutating func setExpanded(_ expanded: Bool) -> CGSize {
        isExpanded = expanded

        if expanded {
            return IslandTheme.expandedSize
        }

        isHovered = false
        return IslandTheme.collapsedSize
    }
}
