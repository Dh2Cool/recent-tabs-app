import Carbon
import CoreGraphics
import XCTest
@testable import SafariRecentTabsCore

final class KeyboardShortcutClassifierTests: XCTestCase {
    func testControlTabIsForwardShortcut() {
        let action = KeyboardShortcutClassifier.action(
            keyCode: UInt16(kVK_Tab),
            flags: [.maskControl]
        )

        XCTAssertEqual(action, .forward)
    }

    func testControlShiftTabIsReverseShortcut() {
        let action = KeyboardShortcutClassifier.action(
            keyCode: UInt16(kVK_Tab),
            flags: [.maskControl, .maskShift]
        )

        XCTAssertEqual(action, .reverse)
    }

    func testTabWithoutControlIsIgnored() {
        let action = KeyboardShortcutClassifier.action(
            keyCode: UInt16(kVK_Tab),
            flags: [.maskShift]
        )

        XCTAssertNil(action)
    }

    func testControlBacktickIsIgnoredByControlTabClassifier() {
        let action = KeyboardShortcutClassifier.action(
            keyCode: UInt16(kVK_ANSI_Grave),
            flags: [.maskControl]
        )

        XCTAssertNil(action)
    }

}
