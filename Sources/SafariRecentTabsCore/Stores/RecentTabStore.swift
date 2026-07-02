import Foundation

public struct RecentTabStore: Equatable {
    private var mostRecentIDs: [SafariTab.ID] = []

    public init() {}

    public mutating func noteActive(_ tab: SafariTab) {
        mostRecentIDs.removeAll { $0 == tab.id }
        mostRecentIDs.insert(tab.id, at: 0)
    }

    public mutating func orderedTabs(current: SafariTab, availableTabs: [SafariTab]) -> [SafariTab] {
        let availableByID = Dictionary(uniqueKeysWithValues: availableTabs.map { ($0.id, $0) })
        mostRecentIDs.removeAll { availableByID[$0] == nil }

        var ordered: [SafariTab] = [current]
        var included = Set<SafariTab.ID>([current.id])

        for id in mostRecentIDs where !included.contains(id) {
            guard let tab = availableByID[id] else {
                continue
            }
            ordered.append(tab)
            included.insert(id)
        }

        for tab in availableTabs where !included.contains(tab.id) {
            ordered.append(tab)
        }

        return ordered
    }

    public static func initialHighlightIndex(for orderedTabs: [SafariTab]) -> Int {
        orderedTabs.count > 1 ? 1 : 0
    }
}
