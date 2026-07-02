import AppKit
import Foundation

public protocol SafariControlling {
    func frontmostWindowTabs() throws -> [SafariTab]
    func activate(tab: SafariTab) throws
}

public enum SafariAutomationError: Error, LocalizedError {
    case safariNotRunning
    case appleScriptError(String)
    case invalidResult

    public var errorDescription: String? {
        switch self {
        case .safariNotRunning:
            return "Safari is not running."
        case .appleScriptError(let message):
            return message
        case .invalidResult:
            return "Safari returned tab data in an unexpected format."
        }
    }
}

public final class AppleScriptSafariAutomationClient: SafariControlling {
    private let separator = "\u{1F}"

    public init() {}

    public func frontmostWindowTabs() throws -> [SafariTab] {
        guard NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Safari").isEmpty == false else {
            throw SafariAutomationError.safariNotRunning
        }

        let script = """
        tell application "Safari"
            if (count of windows) is 0 then return ""
            set frontWindow to front window
            set windowID to id of frontWindow
            set activeIndex to index of current tab of frontWindow
            set output to ""
            set sep to ASCII character 31
            repeat with tabIndex from 1 to count of tabs of frontWindow
                set safariTab to tab tabIndex of frontWindow
                set isActive to "0"
                if tabIndex is activeIndex then set isActive to "1"
                set output to output & windowID & sep & tabIndex & sep & isActive & sep & name of safariTab & sep & URL of safariTab & linefeed
            end repeat
            return output
        end tell
        """

        let result = try run(script: script)
        guard !result.isEmpty else {
            return []
        }

        return result
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line in
                let parts = line.split(separator: Character(separator), omittingEmptySubsequences: false).map(String.init)
                guard parts.count >= 5,
                      let windowID = Int(parts[0]),
                      let index = Int(parts[1]),
                      let url = URL(string: parts[4])
                else {
                    return nil
                }
                return SafariTab(
                    windowID: windowID,
                    index: index,
                    title: parts[3],
                    url: url,
                    isActive: parts[2] == "1"
                )
            }
    }

    public func activate(tab: SafariTab) throws {
        let escapedURL = tab.url.absoluteString.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Safari"
            set targetWindow to first window whose id is \(tab.windowID)
            set current tab of targetWindow to tab \(tab.index) of targetWindow
            set index of targetWindow to 1
            activate
        end tell
        """

        do {
            try run(script: script)
        } catch {
            let fallbackScript = """
            tell application "Safari"
                repeat with safariWindow in windows
                    repeat with safariTab in tabs of safariWindow
                        if URL of safariTab is "\(escapedURL)" then
                            set current tab of safariWindow to safariTab
                            set index of safariWindow to 1
                            activate
                            return
                        end if
                    end repeat
                end repeat
            end tell
            """
            try run(script: fallbackScript)
        }
    }

    @discardableResult
    private func run(script: String) throws -> String {
        guard let appleScript = NSAppleScript(source: script) else {
            throw SafariAutomationError.invalidResult
        }

        var errorInfo: NSDictionary?
        let descriptor = appleScript.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error."
            throw SafariAutomationError.appleScriptError(message)
        }

        return descriptor.stringValue ?? ""
    }
}
