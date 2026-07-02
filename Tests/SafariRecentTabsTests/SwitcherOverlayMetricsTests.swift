import AppKit
import XCTest
@testable import SafariRecentTabsCore

final class SwitcherOverlayMetricsTests: XCTestCase {
    func testPanelFrameIsCenteredForComputedWidth() {
        let screen = NSRect(x: 0, y: 0, width: 1440, height: 900)

        let frame = SwitcherOverlayMetrics.panelFrame(tabCount: 4, visibleFrame: screen)

        XCTAssertEqual(frame.midX, screen.midX, accuracy: 0.5)
        XCTAssertEqual(frame.midY, screen.midY, accuracy: 0.5)
    }

    func testPanelWidthIsCappedToVisibleFrame() {
        let screen = NSRect(x: 0, y: 0, width: 700, height: 500)

        let frame = SwitcherOverlayMetrics.panelFrame(tabCount: 12, visibleFrame: screen)

        XCTAssertLessThanOrEqual(frame.width, screen.width - 48)
    }
}
