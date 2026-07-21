import Carbon
import CoreGraphics

public enum KeyboardShortcutAction: Equatable {
    case forward
    case reverse
}

public enum KeyboardShortcutClassifier {
    public static func action(keyCode: UInt16, flags: CGEventFlags) -> KeyboardShortcutAction? {
        guard flags.contains(.maskControl) else {
            return nil
        }

        guard keyCode == UInt16(kVK_Tab) else {
            return nil
        }

        return flags.contains(.maskShift) ? .reverse : .forward
    }
}
