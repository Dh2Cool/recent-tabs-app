import AppKit
import Carbon

public final class HotkeyController {
    private let onHotkey: () -> Void
    private let onControlReleased: () -> Void
    private let onEscape: () -> Void

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var flagsMonitor: Any?
    private var keyMonitor: Any?
    private var localKeyMonitor: Any?

    public init(
        onHotkey: @escaping () -> Void,
        onControlReleased: @escaping () -> Void,
        onEscape: @escaping () -> Void
    ) {
        self.onHotkey = onHotkey
        self.onControlReleased = onControlReleased
        self.onEscape = onEscape
    }

    public func start() {
        registerCarbonHotkey()
        installEventMonitors()
    }

    public func stop() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
        if let flagsMonitor {
            NSEvent.removeMonitor(flagsMonitor)
        }
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
        }
    }

    private func registerCarbonHotkey() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else {
                    return noErr
                }
                let controller = Unmanaged<HotkeyController>.fromOpaque(userData).takeUnretainedValue()
                controller.onHotkey()
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )

        let hotKeyID = EventHotKeyID(signature: fourCharCode("SRTS"), id: 1)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_Grave),
            UInt32(controlKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func installEventMonitors() {
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            if event.modifierFlags.contains(.control) == false {
                self?.onControlReleased()
            }
        }

        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == UInt16(kVK_Escape) {
                self?.onEscape()
            }
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == UInt16(kVK_Escape) {
                self?.onEscape()
                return nil
            }
            return event
        }
    }
}

private func fourCharCode(_ string: String) -> OSType {
    string.utf8.reduce(0) { result, byte in
        (result << 8) + OSType(byte)
    }
}
