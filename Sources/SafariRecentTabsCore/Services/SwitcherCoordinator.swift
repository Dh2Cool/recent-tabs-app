import AppKit
import Foundation

@MainActor
public final class SwitcherCoordinator {
    private let safariClient: SafariControlling
    private let faviconProvider: FaviconProvider
    private let panelController: SwitcherPanelControlling
    private let activeApplicationProvider: ActiveApplicationProviding
    private let onSwitcherVisibilityChanged: (Bool) -> Void
    private var recentTabs = RecentTabStore()
    private var state: SwitcherState?
    private var isActivating = false

    public init(
        safariClient: SafariControlling,
        faviconProvider: FaviconProvider,
        panelController: SwitcherPanelControlling,
        activeApplicationProvider: ActiveApplicationProviding = WorkspaceActiveApplicationProvider(),
        onSwitcherVisibilityChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.safariClient = safariClient
        self.faviconProvider = faviconProvider
        self.panelController = panelController
        self.activeApplicationProvider = activeApplicationProvider
        self.onSwitcherVisibilityChanged = onSwitcherVisibilityChanged
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
            onSwitcherVisibilityChanged(true)
            panelController.show(state: newState)
        } catch {
            panelController.hide()
            state = nil
            onSwitcherVisibilityChanged(false)
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
            onSwitcherVisibilityChanged(false)
        }

        do {
            try safariClient.activate(tab: selected)
            recentTabs.noteActive(selected)
        } catch {
            return
        }
    }

    public func handleCloseHighlightedTab() async {
        guard var existingState = state, let selected = existingState.highlightedTab else {
            return
        }

        do {
            try safariClient.close(tab: selected)
            let remainingTabs = try safariClient.frontmostWindowTabs()
            guard !remainingTabs.isEmpty else {
                cancel()
                return
            }

            let remainingOrderedTabs = existingState.tabs.compactMap {
                updatedTab(for: $0, afterClosing: selected, in: remainingTabs)
            }
            guard !remainingOrderedTabs.isEmpty else {
                cancel()
                return
            }

            let nextHighlightedIndex = min(existingState.highlightedIndex, remainingOrderedTabs.count - 1)
            existingState = SwitcherState(
                tabs: remainingOrderedTabs,
                highlightedIndex: nextHighlightedIndex
            )
            state = existingState
            existingState.tabs.forEach { faviconProvider.loadIconIfNeeded(for: $0) }
            panelController.show(state: existingState)
        } catch {
            return
        }
    }

    public func cancel() {
        guard state != nil else {
            return
        }
        state = nil
        panelController.hide()
        onSwitcherVisibilityChanged(false)
    }

    private func updatedTab(for tab: SafariTab, afterClosing closedTab: SafariTab, in remainingTabs: [SafariTab]) -> SafariTab? {
        guard tab.id != closedTab.id else {
            return nil
        }

        let updatedIndex: Int
        if tab.windowID == closedTab.windowID, tab.index > closedTab.index {
            updatedIndex = tab.index - 1
        } else {
            updatedIndex = tab.index
        }

        return remainingTabs.first {
            $0.windowID == tab.windowID && $0.index == updatedIndex
        }
    }
}
