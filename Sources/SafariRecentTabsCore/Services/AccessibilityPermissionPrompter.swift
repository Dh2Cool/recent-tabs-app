import ApplicationServices

public enum AccessibilityPermissionPrompter {
    public static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    public static func requestIfNeeded() -> Bool {
        guard isTrusted == false else {
            return true
        }

        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
