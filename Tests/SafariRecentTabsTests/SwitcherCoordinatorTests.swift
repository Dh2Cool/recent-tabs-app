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
    private(set) var frontmostWindowTabCallCount = 0
    private(set) var closedTabIDs: [SafariTab.ID] = []

    init(tabs: [SafariTab]) {
        self.tabs = tabs
    }

    func frontmostWindowTabs() throws -> [SafariTab] {
        frontmostWindowTabCallCount += 1
        return tabs
    }

    func activate(tab: SafariTab) throws {}

    func close(tab: SafariTab) throws {
        closedTabIDs.append(tab.id)
        tabs.removeAll { $0.id == tab.id }
        tabs = tabs.enumerated().map { offset, tab in
            SafariTab(
                windowID: tab.windowID,
                index: offset + 1,
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
