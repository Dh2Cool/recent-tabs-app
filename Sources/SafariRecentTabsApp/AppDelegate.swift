import AppKit
import SafariRecentTabsCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var coordinator: SwitcherCoordinator?
    private var hotkeyController: HotkeyController?
    private var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let safariClient = AppleScriptSafariAutomationClient()
        let faviconProvider = FaviconProvider()
        let panelController = SwitcherPanelController(faviconProvider: faviconProvider)
        let activeApplicationProvider = WorkspaceActiveApplicationProvider()
        var hotkeyController: HotkeyController?
        let coordinator = SwitcherCoordinator(
            safariClient: safariClient,
            faviconProvider: faviconProvider,
            panelController: panelController,
            activeApplicationProvider: activeApplicationProvider,
            onSwitcherVisibilityChanged: { isVisible in
                hotkeyController?.setCloseHighlightedTabHotkeyEnabled(isVisible)
            }
        )
        let newHotkeyController = HotkeyController(
            onHotkey: { [weak coordinator] in
                Task { @MainActor in
                    await coordinator?.handleHotkey()
                }
            },
            onReverseHotkey: { [weak coordinator] in
                Task { @MainActor in
                    await coordinator?.handleReverseHotkey()
                }
            },
            onControlReleased: { [weak coordinator] in
                Task { @MainActor in
                    await coordinator?.handleControlRelease()
                }
            },
            onEscape: { [weak coordinator] in
                Task { @MainActor in
                    coordinator?.cancel()
                }
            },
            onCloseHighlightedTab: { [weak coordinator] in
                Task { @MainActor in
                    await coordinator?.handleCloseHighlightedTab()
                }
            },
            activeApplicationProvider: activeApplicationProvider
        )

        self.coordinator = coordinator
        self.hotkeyController = newHotkeyController
        hotkeyController = newHotkeyController

        configureStatusItem()
        newHotkeyController.start()
        startPollingSafari()
    }

    func applicationWillTerminate(_ notification: Notification) {
        pollTimer?.invalidate()
        hotkeyController?.stop()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.title = "S"
        item.button?.toolTip = "Safari Recent Tabs"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Safari Recent Tabs", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Shortcut: Control-Tab", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Reverse: Control-Shift-Tab", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Fallback: Control-`", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        let permissionItem = NSMenuItem(
            title: "Grant Accessibility Permission",
            action: #selector(requestAccessibilityPermission),
            keyEquivalent: ""
        )
        permissionItem.target = self
        menu.addItem(permissionItem)

        let settingsItem = NSMenuItem(
            title: "Open Accessibility Settings",
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    private func startPollingSafari() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak coordinator] _ in
            guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.Safari" else {
                return
            }
            Task { @MainActor in
                await coordinator?.refreshActiveTab()
            }
        }
    }

    @objc private func requestAccessibilityPermission() {
        AccessibilityPermissionPrompter.requestIfNeeded()
        hotkeyController?.refreshSafariScopedHotkeys()
    }

    @objc private func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
