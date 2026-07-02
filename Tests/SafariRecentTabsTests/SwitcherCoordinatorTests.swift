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
        let snapshots = FakeSnapshotProvider()
        let coordinator = SwitcherCoordinator(
            safariClient: safari,
            faviconProvider: FaviconProvider(),
            panelController: panel,
            activeApplicationProvider: activeApp,
            snapshotProvider: snapshots
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

    func testHotkeyStartsSnapshotLoadingForDisplayedTabs() async {
        let safari = FakeSafariClient(tabs: sampleTabs)
        let panel = FakePanelController()
        let activeApp = FakeActiveApplicationProvider(isSafariFrontmost: true)
        let snapshots = FakeSnapshotProvider()
        let coordinator = SwitcherCoordinator(
            safariClient: safari,
            faviconProvider: FaviconProvider(),
            panelController: panel,
            activeApplicationProvider: activeApp,
            snapshotProvider: snapshots
        )

        await coordinator.handleHotkey()

        XCTAssertEqual(snapshots.loadedTabIDs, sampleTabs.map(\.id))
    }

    private var sampleTabs: [SafariTab] {
        [
            SafariTab(windowID: 1, index: 1, title: "One", url: URL(string: "https://one.example")!, isActive: true),
            SafariTab(windowID: 1, index: 2, title: "Two", url: URL(string: "https://two.example")!)
        ]
    }
}

private final class FakeSafariClient: SafariControlling {
    private let tabs: [SafariTab]
    private(set) var frontmostWindowTabCallCount = 0

    init(tabs: [SafariTab]) {
        self.tabs = tabs
    }

    func frontmostWindowTabs() throws -> [SafariTab] {
        frontmostWindowTabCallCount += 1
        return tabs
    }

    func activate(tab: SafariTab) throws {}
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

@MainActor
private final class FakeSnapshotProvider: TabSnapshotLoading {
    private(set) var loadedTabIDs: [SafariTab.ID] = []

    func loadSnapshotIfNeeded(for tab: SafariTab) {
        loadedTabIDs.append(tab.id)
    }
}
