import AppKit
import Foundation

@MainActor
public final class FaviconProvider: ObservableObject {
    @Published private var cache: [String: NSImage] = [:]
    private var inFlight: Set<String> = []

    public init() {}

    public func image(for tab: SafariTab) -> NSImage? {
        cache[cacheKey(for: tab)]
    }

    public func loadIconIfNeeded(for tab: SafariTab) {
        let key = cacheKey(for: tab)
        guard cache[key] == nil, inFlight.contains(key) == false else {
            return
        }
        inFlight.insert(key)

        Task {
            defer {
                Task { @MainActor in
                    self.inFlight.remove(key)
                }
            }

            guard let url = faviconURL(for: tab) else {
                return
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = NSImage(data: data) else {
                    return
                }
                await MainActor.run {
                    self.cache[key] = image
                }
            } catch {
                await MainActor.run {
                    self.cache[key] = nil
                }
            }
        }
    }

    public func fallbackInitial(for tab: SafariTab) -> String {
        TabDisplayModel(tab: tab).fallbackInitial
    }

    private func faviconURL(for tab: SafariTab) -> URL? {
        guard let host = tab.url.host(percentEncoded: false) ?? tab.url.host else {
            return nil
        }
        return URL(string: "https://www.google.com/s2/favicons?sz=128&domain=\(host)")
    }

    private func cacheKey(for tab: SafariTab) -> String {
        tab.url.host(percentEncoded: false) ?? tab.url.host ?? tab.url.absoluteString
    }
}
