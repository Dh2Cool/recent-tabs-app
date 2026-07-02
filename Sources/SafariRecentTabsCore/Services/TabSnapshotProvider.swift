import AppKit
import Foundation
import WebKit

@MainActor
public protocol TabSnapshotLoading: AnyObject {
    func loadSnapshotIfNeeded(for tab: SafariTab)
}

@MainActor
public final class TabSnapshotProvider: ObservableObject, TabSnapshotLoading {
    @Published private var cache: [SafariTab.ID: NSImage] = [:]
    private var captures: [SafariTab.ID: WebSnapshotCapture] = [:]

    public init() {}

    public func snapshot(for tab: SafariTab) -> NSImage? {
        cache[tab.id]
    }

    public func loadSnapshotIfNeeded(for tab: SafariTab) {
        guard cache[tab.id] == nil, captures[tab.id] == nil, tab.url.isWebURL else {
            return
        }

        let capture = WebSnapshotCapture(url: tab.url, size: NSSize(width: 420, height: 260)) { [weak self] image in
            Task { @MainActor in
                self?.captures[tab.id] = nil
                if let image {
                    self?.cache[tab.id] = image
                }
            }
        }
        captures[tab.id] = capture
        capture.start()
    }
}

private final class WebSnapshotCapture: NSObject, WKNavigationDelegate {
    private let url: URL
    private let size: NSSize
    private let completion: (NSImage?) -> Void
    private let webView: WKWebView
    private var didComplete = false

    init(url: URL, size: NSSize, completion: @escaping (NSImage?) -> Void) {
        self.url = url
        self.size = size
        self.completion = completion

        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = false
        self.webView = WKWebView(frame: NSRect(origin: .zero, size: size), configuration: configuration)
        super.init()
        webView.navigationDelegate = self
    }

    func start() {
        webView.load(URLRequest(url: url, timeoutInterval: 5))
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.finish(with: nil)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.capture()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(with: nil)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finish(with: nil)
    }

    private func capture() {
        let configuration = WKSnapshotConfiguration()
        configuration.rect = NSRect(origin: .zero, size: size)
        webView.takeSnapshot(with: configuration) { [weak self] image, _ in
            self?.finish(with: image)
        }
    }

    private func finish(with image: NSImage?) {
        guard didComplete == false else {
            return
        }
        didComplete = true
        completion(image)
    }
}

private extension URL {
    var isWebURL: Bool {
        scheme == "https" || scheme == "http"
    }
}
