import XCTest
@testable import SafariRecentTabsCore

@MainActor
final class SwitcherCoordinatorTests: XCTestCase {
    func testHotkeyIsIgnoredWhenSafariIsNotFrontmost() async {
        let safari = FakeSafariClient(tabs: sampleTabs)
        let panel = FakePanelController()
        let activeApp = FakeActiveApplicationProvider(isSafariFrontmost: false)
        let coordinator = SwitcherCoordinator(
            safariClient: safari,
            faviconProvider: FaviconProvider(),
            panelController: panel,
            activeApplicationProvider: activeApp
        )

        await coordinator.handleHotkey()

        XCTAssertEqual(safari.frontmostWindowTabCallCount, 0)
        XCTAssertEqual(panel.showCount, 0)
    }

    func testHotkeyOpensWhenSafariIsFrontmost() async {
        let safari = FakeSafariClient(tabs: sampleTabs)
        let panel = FakePanelController()
        let activeApp = FakeActiveApplicationProvider(isSafariFrontmost: true)
        let coordinator = SwitcherCoordinator(
            safariClient: safari,
            faviconProvider: FaviconProvider(),
            panelController: panel,
            activeApplicationProvider: activeApp
        )

        await coordinator.handleHotkey()

        XCTAssertEqual(safari.frontmostWindowTabCallCount, 1)
        XCTAssertEqual(panel.showCount, 1)
    }

    func testReverseHotkeyOpensWithLastTabHighlighted() async {
        let safari = FakeSafariClient(tabs: sampleTabs)
        let panel = FakePanelController()
        let activeApp = FakeActiveApplicationProvider(isSafariFrontmost: true)
        let coordinator = SwitcherCoordinator(
            safariClient: safari,
            faviconProvider: FaviconProvider(),
            panelController: panel,
            activeApplicationProvider: activeApp
        )

        await coordinator.handleReverseHotkey()

        XCTAssertEqual(panel.lastState?.highlightedTab?.id, sampleTabs.last?.id)
    }

    func testControlWClosesHighlightedTabAndKeepsSwitcherOpen() async {
        let safari = FakeSafariClient(tabs: sampleTabs)
        let panel = FakePanelController()
        let coordinator = SwitcherCoordinator(
            safariClient: safari,
            faviconProvider: FaviconProvider(),
            panelController: panel,
            activeApplicationProvider: FakeActiveApplicationProvider(isSafariFrontmost: true)
        )

        await coordinator.handleHotkey()
        await coordinator.handleCloseHighlightedTab()

        XCTAssertEqual(safari.closedTabIDs, [sampleTabs[1].id])
        XCTAssertEqual(panel.lastState?.tabs.map(\.title), ["One", "Three"])
        XCTAssertEqual(panel.lastState?.highlightedTab?.title, "Three")
    }

    func testSwitcherVisibilityIsReportedWhileOpen() async {
        var visibilityChanges: [Bool] = []
        let coordinator = SwitcherCoordinator(
            safariClient: FakeSafariClient(tabs: sampleTabs),
            faviconProvider: FaviconProvider(),
            panelController: FakePanelController(),
            activeApplicationProvider: FakeActiveApplicationProvider(isSafariFrontmost: true),
            onSwitcherVisibilityChanged: { visibilityChanges.append($0) }
        )

        await coordinator.handleHotkey()
        coordinator.cancel()

        XCTAssertEqual(visibilityChanges, [true, false])
    }

    func testAllWindowsModeIncludesTabsFromOtherWindows() async {
        let otherWindowTab = SafariTab(
            windowID: 2,
            index: 1,
            title: "Other Window",
            url: URL(string: "https://other.example")!
        )
        let safari = FakeSafariClient(tabs: sampleTabs + [otherWindowTab])
        let panel = FakePanelController()
        let coordinator = SwitcherCoordinator(
            safariClient: safari,
            faviconProvider: FaviconProvider(),
            panelController: panel,
            activeApplicationProvider: FakeActiveApplicationProvider(isSafariFrontmost: true),
            includesTabsFromAllWindows: true
        )

        await coordinator.handleHotkey()

        XCTAssertEqual(safari.allWindowTabCallCount, 1)
        XCTAssertEqual(panel.lastState?.tabs.map(\.title), ["One", "Two", "Three", "Other Window"])
    }

    private var sampleTabs: [SafariTab] {
        [
            SafariTab(windowID: 1, index: 1, title: "One", url: URL(string: "https://one.example")!, isActive: true),
            SafariTab(windowID: 1, index: 2, title: "Two", url: URL(string: "https://two.example")!),
            SafariTab(windowID: 1, index: 3, title: "Three", url: URL(string: "https://three.example")!)
        ]
    }
}

private final class FakeSafariClient: SafariControlling {
    private var tabs: [SafariTab]
    private let frontmostWindowID: Int
    private(set) var frontmostWindowTabCallCount = 0
    private(set) var allWindowTabCallCount = 0
    private(set) var closedTabIDs: [SafariTab.ID] = []

    init(tabs: [SafariTab], frontmostWindowID: Int = 1) {
        self.tabs = tabs
        self.frontmostWindowID = frontmostWindowID
    }

    func frontmostWindowTabs() throws -> [SafariTab] {
        frontmostWindowTabCallCount += 1
        return tabs.filter { $0.windowID == frontmostWindowID }
    }

    func allWindowTabs() throws -> [SafariTab] {
        allWindowTabCallCount += 1
        return tabs
    }

    func activate(tab: SafariTab) throws {}

    func close(tab: SafariTab) throws {
        closedTabIDs.append(tab.id)
        tabs.removeAll { $0.id == tab.id }
        var nextIndexByWindow: [Int: Int] = [:]
        tabs = tabs.map { tab in
            let nextIndex = nextIndexByWindow[tab.windowID, default: 0] + 1
            nextIndexByWindow[tab.windowID] = nextIndex
            return SafariTab(
                windowID: tab.windowID,
                index: nextIndex,
                title: tab.title,
                url: tab.url,
                isActive: tab.isActive
            )
        }
    }
}

@MainActor
private final class FakePanelController: SwitcherPanelControlling {
    private(set) var showCount = 0
    private(set) var lastState: SwitcherState?

    func show(state: SwitcherState) {
        showCount += 1
        lastState = state
    }

    func hide() {}
}

private struct FakeActiveApplicationProvider: ActiveApplicationProviding {
    let isSafariFrontmost: Bool
}
