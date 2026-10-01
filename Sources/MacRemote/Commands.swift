import Foundation
import AppKit
import ApplicationServices

final class Commands {
    private let brightness = Brightness()

    init() { brightness.resetGamma() }
    private let queue = DispatchQueue(label: "macremote.commands")

    func run(_ action: String, _ value: String?) -> [String: Any] {
        queue.sync {
            let needsAccessibility = !action.contains("bright") && !["display_sleep", "quit_app", "quit_self"].contains(action)
            if needsAccessibility && !AXIsProcessTrusted() {
                return ["ok": false, "info": "Permesso Accessibilità mancante: Impostazioni › Privacy › Accessibilità › MacRemote"]
            }
            if let k = Input.mediaKeys[action] {
                Input.postMediaKey(k)
                return ["ok": true]
            }
            if let code = Input.keys[action] {
                Input.postKey(code)
                return ["ok": true]
            }
            switch action {
            case "shift_tab":
                Input.postKey(48, flags: .maskShift)
            case "text":
                guard let value else { return ["ok": false] }
                Input.type(value)
            case "bright_up", "bright_down", "ext_bright_up", "ext_bright_down":
                return ["ok": true, "info": brightness.adjust(up: action.hasSuffix("_up"),
                                                              target: action.hasPrefix("ext_") ? "ext" : "mac")]
            case "display_sleep":
                Input.displaySleep()
            case "lock":
                Input.lock()
            case "quit_app":
                // Same as Cmd+Q: apps with unsaved work still ask before closing.
                guard let app = NSWorkspace.shared.frontmostApplication,
                      app.processIdentifier != getpid(), app.bundleIdentifier != "com.apple.finder" else {
                    return ["ok": false, "info": "Nessuna app da chiudere"]
                }
                app.terminate()
                return ["ok": true, "info": "Chiusa: \(app.localizedName ?? "app")"]
            case "quit_self":
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { NSApp.terminate(nil) }   // let the reply go out first
                return ["ok": true, "info": "MacRemote chiuso"]
            default:
                return ["ok": false, "info": "azione sconosciuta"]
            }
            return ["ok": true]
        }
    }
}
