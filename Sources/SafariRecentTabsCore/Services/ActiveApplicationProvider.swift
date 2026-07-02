import AppKit

public protocol ActiveApplicationProviding {
    var isSafariFrontmost: Bool { get }
}

public struct WorkspaceActiveApplicationProvider: ActiveApplicationProviding {
    public init() {}

    public var isSafariFrontmost: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.Safari"
    }
}
