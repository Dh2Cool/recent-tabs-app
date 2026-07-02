import XCTest
@testable import SafariRecentTabsCore

final class SwitcherStateTests: XCTestCase {
    func testCycleWrapsThroughTabs() {
        let tabs = [
            SafariTab(windowID: 1, index: 1, title: "One", url: URL(string: "https://one.example")!),
            SafariTab(windowID: 1, index: 2, title: "Two", url: URL(string: "https://two.example")!),
            SafariTab(windowID: 1, index: 3, title: "Three", url: URL(string: "https://three.example")!)
        ]
        var state = SwitcherState(tabs: tabs, highlightedIndex: 1)

        state.cycleForward()
        XCTAssertEqual(state.highlightedTab?.id, tabs[2].id)

        state.cycleForward()
        XCTAssertEqual(state.highlightedTab?.id, tabs[0].id)
    }

    func testEmptyStateHasNoHighlightedTab() {
        let state = SwitcherState(tabs: [], highlightedIndex: 1)

        XCTAssertNil(state.highlightedTab)
    }
}
