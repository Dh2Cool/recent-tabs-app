import AppKit
import Carbon
import CoreGraphics
import OSLog

private let hotkeyLogger = Logger(subsystem: "com.dhruvshetty.SafariRecentTabs", category: "HotkeyController")

public final class HotkeyController {
    private let onHotkey: () -> Void
    private let onReverseHotkey: () -> Void
    private let onControlReleased: () -> Void
    private let onEscape: () -> Void
    private let onCloseHighlightedTab: () -> Void
    private let activeApplicationProvider: ActiveApplicationProviding

    private var fallbackHotKeyRefs: [EventHotKeyRef] = []
    private var safariHotKeyRefs: [EventHotKeyRef] = []
    private var eventHandlerRef: EventHandlerRef?
    private var keyMonitor: Any?
    private var localKeyMonitor: Any?
    private var activeApplicationObserver: NSObjectProtocol?
    private var modifierReleaseTimer: Timer?

    public init(
        onHotkey: @escaping () -> Void,
        onReverseHotkey: @escaping () -> Void,
        onControlReleased: @escaping () -> Void,
        onEscape: @escaping () -> Void,
        onCloseHighlightedTab: @escaping () -> Void,
        activeApplicationProvider: ActiveApplicationProviding = WorkspaceActiveApplicationProvider()
    ) {
        self.onHotkey = onHotkey
        self.onReverseHotkey = onReverseHotkey
        self.onControlReleased = onControlReleased
        self.onEscape = onEscape
        self.onCloseHighlightedTab = onCloseHighlightedTab
        self.activeApplicationProvider = activeApplicationProvider
    }

    public func start() {
        installCarbonEventHandler()
        registerFallbackHotkeys()
        refreshSafariScopedHotkeys()
        installActiveApplicationObserver()
        installEventMonitors()
    }

    public func refreshSafariScopedHotkeys() {
        if activeApplicationProvider.isSafariFrontmost {
            registerSafariHotkeysIfNeeded()
        } else {
            unregisterSafariHotkeys()
        }
    }

    public func stop() {
        unregisterFallbackHotkeys()
        unregisterSafariHotkeys()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
        eventHandlerRef = nil
        modifierReleaseTimer?.invalidate()
        modifierReleaseTimer = nil
        if let activeApplicationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activeApplicationObserver)
        }
        activeApplicationObserver = nil
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
        }
    }

    private func installCarbonEventHandler() {
        guard eventHandlerRef == nil else {
            return
        }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else {
                    return noErr
                }
                let controller = Unmanaged<HotkeyController>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard status == noErr else {
                    controller.onHotkey()
                    return noErr
                }
                switch hotKeyID.id {
                case HotkeyID.fallbackReverse.rawValue, HotkeyID.safariReverse.rawValue:
                    controller.trigger(.reverse)
                default:
                    controller.trigger(.forward)
                }
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )
    }

    private func registerFallbackHotkeys() {
        guard fallbackHotKeyRefs.isEmpty else {
            return
        }
        registerHotkey(
            id: HotkeyID.fallbackForward.rawValue,
            keyCode: UInt32(kVK_ANSI_Grave),
            modifiers: UInt32(controlKey),
            label: "Control-`",
            refs: &fallbackHotKeyRefs
        )
        registerHotkey(
            id: HotkeyID.fallbackReverse.rawValue,
            keyCode: UInt32(kVK_ANSI_Grave),
            modifiers: UInt32(controlKey | shiftKey),
            label: "Control-Shift-`",
            refs: &fallbackHotKeyRefs
        )
    }

    private func registerSafariHotkeysIfNeeded() {
        guard safariHotKeyRefs.isEmpty else {
            return
        }
        registerHotkey(
            id: HotkeyID.safariForward.rawValue,
            keyCode: UInt32(kVK_Tab),
            modifiers: UInt32(controlKey),
            label: "Safari Control-Tab",
            refs: &safariHotKeyRefs
        )
        registerHotkey(
            id: HotkeyID.safariReverse.rawValue,
            keyCode: UInt32(kVK_Tab),
            modifiers: UInt32(controlKey | shiftKey),
            label: "Safari Control-Shift-Tab",
            refs: &safariHotKeyRefs
        )
    }

    private func unregisterFallbackHotkeys() {
        unregisterHotkeys(&fallbackHotKeyRefs)
    }

    private func unregisterSafariHotkeys() {
        unregisterHotkeys(&safariHotKeyRefs)
    }

    private func unregisterHotkeys(_ refs: inout [EventHotKeyRef]) {
        for hotKeyRef in refs {
            UnregisterEventHotKey(hotKeyRef)
        }
        refs.removeAll()
    }

    private func registerHotkey(
        id: UInt32,
        keyCode: UInt32,
        modifiers: UInt32,
        label: String,
        refs: inout [EventHotKeyRef]
    ) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: fourCharCode("SRTS"), id: id)
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if status == noErr, let hotKeyRef {
            refs.append(hotKeyRef)
            hotkeyLogger.info("Registered \(label, privacy: .public) hotkey")
        } else {
            hotkeyLogger.error("Failed to register \(label, privacy: .public) hotkey. status=\(status, privacy: .public)")
        }
    }

    private func installActiveApplicationObserver() {
        guard activeApplicationObserver == nil else {
            return
        }
        activeApplicationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshSafariScopedHotkeys()
        }
    }

    private func installEventMonitors() {
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == UInt16(kVK_Escape) {
                self?.onEscape()
            } else if KeyboardShortcutClassifier.action(
                keyCode: event.keyCode,
                flags: CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))
            ) == .closeHighlightedTab {
                self?.onCloseHighlightedTab()
            }
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == UInt16(kVK_Escape) {
                self?.onEscape()
                return nil
            }
            if KeyboardShortcutClassifier.action(
                keyCode: event.keyCode,
                flags: CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))
            ) == .closeHighlightedTab {
                self?.onCloseHighlightedTab()
                return nil
            }
            return event
        }
    }

    private func trigger(_ action: KeyboardShortcutAction) {
        beginModifierReleasePolling()
        switch action {
        case .forward:
            onHotkey()
        case .reverse:
            onReverseHotkey()
        case .closeHighlightedTab:
            onCloseHighlightedTab()
        }
    }

    private func beginModifierReleasePolling() {
        guard modifierReleaseTimer == nil else {
            return
        }
        modifierReleaseTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            let modifiers = GetCurrentKeyModifiers()
            if modifiers & UInt32(controlKey) == 0 {
                timer.invalidate()
                self.modifierReleaseTimer = nil
                self.onControlReleased()
            }
        }
    }
}

private enum HotkeyID: UInt32 {
    case fallbackForward = 1
    case fallbackReverse = 2
    case safariForward = 3
    case safariReverse = 4
}

private func fourCharCode(_ string: String) -> OSType {
    string.utf8.reduce(0) { result, byte in
        (result << 8) + OSType(byte)
    }
}
