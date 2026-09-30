import AppKit
import CoreGraphics

enum Input {
    // NX_KEYTYPE_* values for media keys
    static let mediaKeys: [String: Int32] = [
        "vol_up": 0, "vol_down": 1, "mute": 7, "play": 16, "next": 17, "prev": 18,
    ]

    // Virtual key codes (ANSI)
    static let keys: [String: CGKeyCode] = [
        "left": 123, "right": 124, "down": 125, "up": 126,
        "enter": 36, "esc": 53, "tab": 48, "space": 49, "backspace": 51,
    ]

    static func postMediaKey(_ key: Int32) {
        for down in [true, false] {
            let state: Int32 = down ? 0xa : 0xb
            let flags = NSEvent.ModifierFlags(rawValue: UInt(state << 8))
            let ev = NSEvent.otherEvent(with: .systemDefined, location: .zero, modifierFlags: flags,
                                        timestamp: 0, windowNumber: 0, context: nil, subtype: 8,
                                        data1: Int((key << 16) | (state << 8)), data2: -1)
            ev?.cgEvent?.post(tap: .cghidEventTap)
        }
    }

    static func postKey(_ code: CGKeyCode, flags: CGEventFlags = []) {
        for down in [true, false] {
            let ev = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: down)
            ev?.flags = flags
            ev?.post(tap: .cghidEventTap)
        }
    }

    static func type(_ text: String) {
        let utf16 = Array(text.utf16)
        var i = 0
        while i < utf16.count {
            let chunk = Array(utf16[i..<min(i + 16, utf16.count)])
            for down in [true, false] {
                let ev = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: down)
                ev?.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: chunk)
                ev?.post(tap: .cghidEventTap)
            }
            i += chunk.count
        }
    }

    static func displaySleep() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        p.arguments = ["displaysleepnow"]
        try? p.run()
    }

    static func lock() {
        postKey(12, flags: [.maskControl, .maskCommand]) // Ctrl+Cmd+Q
    }
}
