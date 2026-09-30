import Foundation
import ApplicationServices

final class Commands {
    private let brightness = Brightness()

    init() { brightness.resetGamma() }
    private let queue = DispatchQueue(label: "macremote.commands")

    func run(_ action: String, _ value: String?) -> [String: Any] {
        queue.sync {
            let needsAccessibility = !action.contains("bright") && action != "display_sleep"
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
            default:
                return ["ok": false, "info": "azione sconosciuta"]
            }
            return ["ok": true]
        }
    }
}
