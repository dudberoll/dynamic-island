import AppKit

enum NotchGeometry {
    static func panelRect(for requestedSize: CGSize, on screen: NSScreen?) -> NSRect {
        let screenFrame = screen?.frame ?? NSScreen.main?.frame ?? .zero
        let size = adjustedSize(requestedSize, on: screen)
        let x = screenFrame.midX - size.width / 2
        let y = screenFrame.maxY - size.height - IslandTheme.topInset

        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }

    private static func adjustedSize(_ requestedSize: CGSize, on screen: NSScreen?) -> CGSize {
        guard requestedSize == IslandTheme.collapsedSize || requestedSize == IslandTheme.hoverSize else {
            return requestedSize
        }

        guard let notchWidth = systemNotchWidth(on: screen), notchWidth > 0 else {
            return requestedSize
        }

        let horizontalPadding: CGFloat = requestedSize == IslandTheme.collapsedSize ? 16 : 44
        return CGSize(
            width: max(requestedSize.width, notchWidth + horizontalPadding),
            height: requestedSize.height
        )
    }

    private static func systemNotchWidth(on screen: NSScreen?) -> CGFloat? {
        guard let screen else {
            return nil
        }

        guard
            let leftArea = screen.auxiliaryTopLeftArea,
            let rightArea = screen.auxiliaryTopRightArea
        else {
            return nil
        }

        let gap = rightArea.minX - leftArea.maxX

        return gap > 0 ? gap : nil
    }
}
