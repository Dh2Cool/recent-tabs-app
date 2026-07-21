import AppKit
import SafariRecentTabsCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let includesAllWindowsPreferenceKey = "includesTabsFromAllWindows"
    private var statusItem: NSStatusItem?
    private var coordinator: SwitcherCoordinator?
    private var hotkeyController: HotkeyController?
    private var pollTimer: Timer?
    private var includesTabsFromAllWindows = UserDefaults.standard.bool(forKey: includesAllWindowsPreferenceKey)

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
            includesTabsFromAllWindows: includesTabsFromAllWindows,
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
        item.button?.image = NSImage(
            systemSymbolName: "rectangle.3.group",
            accessibilityDescription: "Safari Recent Tabs"
        )
        item.button?.image?.isTemplate = true
        item.button?.toolTip = "Safari Recent Tabs"

        let menu = NSMenu()
        menu.addItem(menuHeader("Safari Recent Tabs", font: .systemFont(ofSize: 14, weight: .semibold)))
        menu.addItem(menuHeader("Switch Safari tabs in most-recently-used order"))
        menu.addItem(.separator())

        menu.addItem(menuSectionHeader("SWITCHER"))
        let allWindowsItem = NSMenuItem(
            title: "Include tabs from all windows",
            action: #selector(toggleIncludesTabsFromAllWindows(_:)),
            keyEquivalent: ""
        )
        allWindowsItem.target = self
        allWindowsItem.state = includesTabsFromAllWindows ? .on : .off
        allWindowsItem.toolTip = "Include tabs from every Safari window in the switcher."
        menu.addItem(allWindowsItem)
        menu.addItem(.separator())

        menu.addItem(menuSectionHeader("SHORTCUTS"))
        menu.addItem(shortcutMenuItem(title: "Next tab", keyEquivalent: "\t", modifiers: .control))
        menu.addItem(shortcutMenuItem(title: "Previous tab", keyEquivalent: "\t", modifiers: [.control, .shift]))
        menu.addItem(shortcutMenuItem(title: "Close highlighted tab", keyEquivalent: "w", modifiers: .control))
        menu.addItem(shortcutMenuItem(title: "Fallback switcher", keyEquivalent: "`", modifiers: .control))
        menu.addItem(.separator())

        menu.addItem(menuSectionHeader("PERMISSIONS"))
        let permissionItem = NSMenuItem(
            title: "Request Accessibility permission…",
            action: #selector(requestAccessibilityPermission),
            keyEquivalent: ""
        )
        permissionItem.target = self
        menu.addItem(permissionItem)

        let settingsItem = NSMenuItem(
            title: "Open Accessibility Settings…",
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

    private func menuHeader(_ title: String, font: NSFont = .systemFont(ofSize: 11, weight: .regular)) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: font,
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        return item
    }

    private func menuSectionHeader(_ title: String) -> NSMenuItem {
        menuHeader(title, font: .systemFont(ofSize: 10, weight: .semibold))
    }

    private func shortcutMenuItem(
        title: String,
        keyEquivalent: String,
        modifiers: NSEvent.ModifierFlags
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: keyEquivalent)
        item.keyEquivalentModifierMask = modifiers
        item.isEnabled = false
        return item
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

    @MainActor @objc private func toggleIncludesTabsFromAllWindows(_ sender: NSMenuItem) {
        includesTabsFromAllWindows.toggle()
        UserDefaults.standard.set(includesTabsFromAllWindows, forKey: Self.includesAllWindowsPreferenceKey)
        sender.state = includesTabsFromAllWindows ? .on : .off
        coordinator?.setIncludesTabsFromAllWindows(includesTabsFromAllWindows)
    }

    @objc private func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
