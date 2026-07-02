import Foundation

public struct SafariTab: Identifiable, Equatable, Hashable, Sendable {
    public let windowID: Int
    public let index: Int
    public let title: String
    public let url: URL
    public let isActive: Bool

    public init(windowID: Int, index: Int, title: String, url: URL, isActive: Bool = false) {
        self.windowID = windowID
        self.index = index
        self.title = title
        self.url = url
        self.isActive = isActive
    }

    public var id: String {
        "\(windowID):\(index):\(url.absoluteString)"
    }
}

public struct TabDisplayModel: Identifiable, Equatable {
    public let tab: SafariTab
    public let title: String
    public let domain: String
    public let fallbackInitial: String

    public var id: String { tab.id }

    public init(tab: SafariTab) {
        self.tab = tab

        let host = tab.url.host(percentEncoded: false) ?? tab.url.host ?? "Safari"
        let registrableDomain = Self.registrableDomain(from: host)
        let trimmedTitle = tab.title.trimmingCharacters(in: .whitespacesAndNewlines)

        self.title = trimmedTitle.isEmpty ? host : trimmedTitle
        self.domain = registrableDomain
        self.fallbackInitial = String((registrableDomain.first ?? "S")).uppercased()
    }

    static func registrableDomain(from host: String) -> String {
        let parts = host
            .split(separator: ".")
            .map(String.init)
            .filter { !$0.isEmpty }

        guard parts.count >= 2 else {
            return host
        }

        return parts.suffix(2).joined(separator: ".")
    }
}
