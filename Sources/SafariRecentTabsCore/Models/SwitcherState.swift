import Foundation

public struct SwitcherState: Equatable {
    public private(set) var tabs: [SafariTab]
    public private(set) var highlightedIndex: Int

    public init(tabs: [SafariTab], highlightedIndex: Int) {
        self.tabs = tabs
        guard !tabs.isEmpty else {
            self.highlightedIndex = 0
            return
        }
        self.highlightedIndex = min(max(highlightedIndex, 0), tabs.count - 1)
    }

    public var highlightedTab: SafariTab? {
        guard tabs.indices.contains(highlightedIndex) else {
            return nil
        }
        return tabs[highlightedIndex]
    }

    public mutating func cycleForward() {
        guard !tabs.isEmpty else {
            return
        }
        highlightedIndex = (highlightedIndex + 1) % tabs.count
    }

    public mutating func cycleBackward() {
        guard !tabs.isEmpty else {
            return
        }
        highlightedIndex = (highlightedIndex + tabs.count - 1) % tabs.count
    }
}
