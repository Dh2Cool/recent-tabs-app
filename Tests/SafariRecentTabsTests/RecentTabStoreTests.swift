import XCTest
@testable import SafariRecentTabsCore

final class RecentTabStoreTests: XCTestCase {
    func testCurrentTabAppearsFirstAndPreviousTabIsHighlighted() {
        var store = RecentTabStore()
        let first = SafariTab(windowID: 1, index: 1, title: "First", url: URL(string: "https://example.com/first")!)
        let second = SafariTab(windowID: 1, index: 2, title: "Second", url: URL(string: "https://example.com/second")!)
        let third = SafariTab(windowID: 1, index: 3, title: "Third", url: URL(string: "https://example.com/third")!)

        store.noteActive(first)
        store.noteActive(second)
        store.noteActive(third)

        let ordered = store.orderedTabs(current: third, availableTabs: [first, second, third])

        XCTAssertEqual(ordered.map(\.id), [third.id, second.id, first.id])
        XCTAssertEqual(RecentTabStore.initialHighlightIndex(for: ordered), 1)
    }

    func testClosedTabsArePrunedFromMRUOrder() {
        var store = RecentTabStore()
        let first = SafariTab(windowID: 1, index: 1, title: "First", url: URL(string: "https://example.com/first")!)
        let second = SafariTab(windowID: 1, index: 2, title: "Second", url: URL(string: "https://example.com/second")!)
        let third = SafariTab(windowID: 1, index: 3, title: "Third", url: URL(string: "https://example.com/third")!)

        store.noteActive(first)
        store.noteActive(second)
        store.noteActive(third)

        let ordered = store.orderedTabs(current: third, availableTabs: [first, third])

        XCTAssertEqual(ordered.map(\.id), [third.id, first.id])
    }
}
