import AppKit
import Foundation

@MainActor
public final class SwitcherCoordinator {
    private let safariClient: SafariControlling
    private let faviconProvider: FaviconProvider
    private let panelController: SwitcherPanelControlling
    private let activeApplicationProvider: ActiveApplicationProviding
    private var recentTabs = RecentTabStore()
    private var state: SwitcherState?
    private var isActivating = false

    public init(
        safariClient: SafariControlling,
        faviconProvider: FaviconProvider,
        panelController: SwitcherPanelControlling,
        activeApplicationProvider: ActiveApplicationProviding = WorkspaceActiveApplicationProvider()
    ) {
        self.safariClient = safariClient
        self.faviconProvider = faviconProvider
        self.panelController = panelController
        self.activeApplicationProvider = activeApplicationProvider
    }

    public func refreshActiveTab() async {
        guard activeApplicationProvider.isSafariFrontmost else {
            return
        }
        guard let current = try? safariClient.frontmostWindowTabs().first(where: \.isActive) else {
            return
        }
        recentTabs.noteActive(current)
    }

    public func handleHotkey() async {
        if var existingState = state {
            existingState.cycleForward()
            state = existingState
            panelController.show(state: existingState)
            return
        }

        await openSwitcher(reverse: false)
    }

    public func handleReverseHotkey() async {
        if var existingState = state {
            existingState.cycleBackward()
            state = existingState
            panelController.show(state: existingState)
            return
        }

        await openSwitcher(reverse: true)
    }

    private func openSwitcher(reverse: Bool) async {
        guard activeApplicationProvider.isSafariFrontmost else {
            return
        }

        do {
            let tabs = try safariClient.frontmostWindowTabs()
            guard tabs.count > 1, let current = tabs.first(where: \.isActive) else {
                return
            }

            recentTabs.noteActive(current)
            let ordered = recentTabs.orderedTabs(current: current, availableTabs: tabs)
            let newState = SwitcherState(
                tabs: ordered,
                highlightedIndex: initialHighlightIndex(for: ordered, reverse: reverse)
            )
            state = newState
            ordered.forEach { faviconProvider.loadIconIfNeeded(for: $0) }
            panelController.show(state: newState)
        } catch {
            panelController.hide()
            state = nil
        }
    }

    private func initialHighlightIndex(for orderedTabs: [SafariTab], reverse: Bool) -> Int {
        guard reverse, orderedTabs.count > 1 else {
            return RecentTabStore.initialHighlightIndex(for: orderedTabs)
        }
        return orderedTabs.count - 1
    }

    public func handleControlRelease() async {
        guard isActivating == false, let selected = state?.highlightedTab else {
            return
        }

        isActivating = true
        defer {
            isActivating = false
            state = nil
            panelController.hide()
        }

        do {
            try safariClient.activate(tab: selected)
            recentTabs.noteActive(selected)
        } catch {
            return
        }
    }

    public func cancel() {
        state = nil
        panelController.hide()
    }
}
