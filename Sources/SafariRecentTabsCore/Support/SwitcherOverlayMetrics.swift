import AppKit

public enum SwitcherOverlayMetrics {
    public static let tileWidth: CGFloat = 132
    public static let tileSpacing: CGFloat = 14
    public static let horizontalChrome: CGFloat = 72
    public static let panelHeight: CGFloat = 210
    public static let minimumPanelWidth: CGFloat = 360
    public static let screenMargin: CGFloat = 24

    public static func panelFrame(tabCount: Int, visibleFrame: NSRect) -> NSRect {
        let safeTabCount = max(tabCount, 1)
        let contentWidth = CGFloat(safeTabCount) * tileWidth
            + CGFloat(max(safeTabCount - 1, 0)) * tileSpacing
            + horizontalChrome
        let maximumWidth = max(minimumPanelWidth, visibleFrame.width - screenMargin * 2)
        let width = min(max(contentWidth, minimumPanelWidth), maximumWidth)
        let height = min(panelHeight, max(panelHeight, visibleFrame.height - screenMargin * 2))

        return NSRect(
            x: visibleFrame.midX - width / 2,
            y: visibleFrame.midY - height / 2,
            width: width,
            height: height
        )
    }
}
