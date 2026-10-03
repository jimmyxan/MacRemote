import AppKit
import Carbon.HIToolbox
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

    /// Virtual key codes are key positions, not characters: on an Italian layout code 24 types "ì", not "=".
    /// Ask the current layout which key types `char`, so shortcuts like ⌘+ and ⌘− hit the right key.
    static func keyCode(typing char: String, shift: Bool = false) -> CGKeyCode? {
        // The Text Input Sources API asserts that it runs on the main queue: called from the commands queue it kills the app.
        if !Thread.isMainThread { return DispatchQueue.main.sync { keyCode(typing: char, shift: shift) } }
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return nil }
        let data = Unmanaged<CFData>.fromOpaque(raw).takeUnretainedValue()
        guard let bytes = CFDataGetBytePtr(data) else { return nil }
        let layout = UnsafeRawPointer(bytes).assumingMemoryBound(to: UCKeyboardLayout.self)
        let capacity = 4
        for code in 0..<128 {
            var dead: UInt32 = 0
            var length = 0
            var buffer = [UniChar](repeating: 0, count: capacity)
            let status = UCKeyTranslate(layout, UInt16(code), UInt16(kUCKeyActionDown), shift ? 2 : 0,
                                        UInt32(LMGetKbdType()), 1, &dead, capacity, &length, &buffer)
            if status == noErr, length == 1, String(utf16CodeUnits: buffer, count: 1) == char { return CGKeyCode(code) }
        }
        return nil
    }

    /// There is no public API for a pinch, so a zoom step is ⌘+ / ⌘−, the shortcut of browsers, Preview, Pages, Maps…
    /// Typed on whatever layout is active ("+" is unshifted on Italian, "=" on US, where ⌘= also zooms in).
    static func zoom(in zoomIn: Bool) {
        let tries: [(String, Bool)] = zoomIn ? [("+", false), ("=", false), ("+", true)] : [("-", false)]
        for (char, shift) in tries {
            if let code = keyCode(typing: char, shift: shift) {
                return postKey(code, flags: shift ? [.maskCommand, .maskShift] : .maskCommand)
            }
        }
        postKey(zoomIn ? 24 : 27, flags: .maskCommand)   // layout lookup failed: ANSI positions
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
