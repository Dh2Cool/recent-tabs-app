import AppKit
import Carbon
import CoreGraphics

public final class HotkeyController {
    private let onHotkey: () -> Void
    private let onReverseHotkey: () -> Void
    private let onControlReleased: () -> Void
    private let onEscape: () -> Void
    private let activeApplicationProvider: ActiveApplicationProviding

    private var hotKeyRefs: [EventHotKeyRef] = []
    private var eventHandlerRef: EventHandlerRef?
    private var controlTabEventTap: CFMachPort?
    private var controlTabRunLoopSource: CFRunLoopSource?
    private var flagsMonitor: Any?
    private var keyMonitor: Any?
    private var localKeyMonitor: Any?

    public init(
        onHotkey: @escaping () -> Void,
        onReverseHotkey: @escaping () -> Void,
        onControlReleased: @escaping () -> Void,
        onEscape: @escaping () -> Void,
        activeApplicationProvider: ActiveApplicationProviding = WorkspaceActiveApplicationProvider()
    ) {
        self.onHotkey = onHotkey
        self.onReverseHotkey = onReverseHotkey
        self.onControlReleased = onControlReleased
        self.onEscape = onEscape
        self.activeApplicationProvider = activeApplicationProvider
    }

    public func start() {
        registerCarbonHotkey()
        installControlTabEventTap()
        installEventMonitors()
    }

    public func stop() {
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs.removeAll()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
        if let controlTabRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), controlTabRunLoopSource, .commonModes)
        }
        if let controlTabEventTap {
            CGEvent.tapEnable(tap: controlTabEventTap, enable: false)
        }
        controlTabRunLoopSource = nil
        controlTabEventTap = nil
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
                if hotKeyID.id == 2 {
                    controller.onReverseHotkey()
                } else {
                    controller.onHotkey()
                }
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )

        registerHotkey(id: 1, modifiers: UInt32(controlKey))
        registerHotkey(id: 2, modifiers: UInt32(controlKey | shiftKey))
    }

    private func registerHotkey(id: UInt32, modifiers: UInt32) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: fourCharCode("SRTS"), id: id)
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_Grave),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if status == noErr, let hotKeyRef {
            hotKeyRefs.append(hotKeyRef)
        }
    }

    private func installControlTabEventTap() {
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { _, type, event, userInfo in
                guard type == .keyDown, let userInfo else {
                    return Unmanaged.passUnretained(event)
                }

                let controller = Unmanaged<HotkeyController>.fromOpaque(userInfo).takeUnretainedValue()
                let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                guard let action = KeyboardShortcutClassifier.action(keyCode: keyCode, flags: event.flags),
                      controller.activeApplicationProvider.isSafariFrontmost
                else {
                    return Unmanaged.passUnretained(event)
                }

                switch action {
                case .forward:
                    controller.onHotkey()
                case .reverse:
                    controller.onReverseHotkey()
                }

                return nil
            },
            userInfo: selfPointer
        ) else {
            return
        }

        controlTabEventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        controlTabRunLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
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
