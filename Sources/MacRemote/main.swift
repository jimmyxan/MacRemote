import AppKit
import CoreImage
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var server: Server!
    private var qrWindow: NSWindow?
    private let commands = Commands()

    private var token: String {
        if let t = UserDefaults.standard.string(forKey: "token") { return t }
        return regenerateToken()
    }

    @discardableResult
    private func regenerateToken() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let t = bytes.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(t, forKey: "token")
        return t
    }

    private var url: String {
        "http://\(Self.lanIP() ?? "localhost"):\(Server.port)/?t=\(token)"
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)

        server = Server(token: { [unowned self] in self.token }, handler: { [unowned self] a, v in
            switch a {
            case "preview_on": return ScreenPreview.setEnabled(true)
            case "preview_off": return ScreenPreview.setEnabled(false)
            default: return self.commands.run(a, v)
            }
        }, resource: { req in
            switch req.path {
            case "/nowplaying":
                let json = (try? JSONSerialization.data(withJSONObject: NowPlaying.current())) ?? Data("{}".utf8)
                return (200, "application/json", json)
            case "/artwork":
                guard let art = NowPlaying.artwork(key: req.query["k"] ?? "") else { return nil }
                return (200, art.mime, art.data)
            case "/screen":
                do { return (200, "image/jpeg", try ScreenPreview.jpeg(display: Int(req.query["d"] ?? "") ?? 0)) }
                catch let e as ScreenPreview.Failure { return (403, "text/plain; charset=utf-8", Data(e.message.utf8)) }
                catch { return (500, "text/plain; charset=utf-8", Data("Cattura fallita".utf8)) }
            default:
                return nil
            }
        })
        do { try server.start() } catch {
            let a = NSAlert()
            a.messageText = "MacRemote: porta \(Server.port) non disponibile"
            a.informativeText = "\(error)"
            a.runModal()
            NSApp.terminate(nil)
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "iphone.and.arrow.forward", accessibilityDescription: "MacRemote")
        rebuildMenu()
        showQR()
    }

    /// Double-clicking the app while it is already running lands here. Without this nothing visible happens,
    /// which looks like "it doesn't start" whenever the menu bar has no room for the status item.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showQR()
        return false
    }

    @objc private func quit() { NSApp.terminate(nil) }

    private func rebuildMenu() {
        let m = NSMenu()
        m.addItem(withTitle: url.components(separatedBy: "?").first ?? url, action: nil, keyEquivalent: "")
        m.addItem(NSMenuItem(title: "Mostra QR", action: #selector(showQR), keyEquivalent: "q"))
        m.addItem(NSMenuItem(title: "Copia link", action: #selector(copyLink), keyEquivalent: "c"))
        m.addItem(NSMenuItem(title: "Rigenera token", action: #selector(newToken), keyEquivalent: ""))
        let login = NSMenuItem(title: "Avvia al login", action: #selector(toggleLogin), keyEquivalent: "")
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        m.addItem(login)
        m.addItem(.separator())
        m.addItem(NSMenuItem(title: "Esci", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
        m.items.forEach { $0.target = $0.action == #selector(NSApplication.terminate(_:)) ? NSApp : self }
        statusItem.menu = m
    }

    @objc private func copyLink() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)
    }

    @objc private func newToken() {
        regenerateToken()
        rebuildMenu()
        showQR()
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch { NSLog("login item: \(error)") }
        rebuildMenu()
    }

    @objc private func showQR() {
        let size: CGFloat = 280
        let filter = CIFilter(name: "CIQRCodeGenerator")!
        filter.setValue(Data(url.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let out = filter.outputImage else { return }
        let scaled = out.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let rep = NSCIImageRep(ciImage: scaled)
        let img = NSImage(size: NSSize(width: size, height: size))
        img.addRepresentation(rep)

        let view = NSImageView(frame: NSRect(x: 20, y: 90, width: size, height: size))
        view.image = img
        let label = NSTextField(labelWithString: "Inquadra con la fotocamera dell'iPhone (stessa Wi-Fi)")
        label.frame = NSRect(x: 10, y: 20, width: size + 20, height: 20)
        label.alignment = .center

        let quit = NSButton(title: "Esci da MacRemote", target: self, action: #selector(quit))
        quit.bezelStyle = .rounded
        quit.frame = NSRect(x: 20 + (size - 160) / 2, y: 14, width: 160, height: 28)
        label.frame.origin.y = 48

        let w = qrWindow ?? NSWindow(contentRect: NSRect(x: 0, y: 0, width: size + 40, height: size + 120),
                                     styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "MacRemote"
        w.contentView = NSView(frame: w.contentRect(forFrameRect: w.frame))
        w.contentView?.addSubview(view)
        w.contentView?.addSubview(label)
        w.contentView?.addSubview(quit)
        w.isReleasedWhenClosed = false
        if qrWindow == nil { w.center() }
        qrWindow = w
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
    }

    static func lanIP() -> String? {
        var ifap: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifap) == 0, let first = ifap else { return nil }
        defer { freeifaddrs(ifap) }
        for p in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let i = p.pointee
            guard let sa = i.ifa_addr, sa.pointee.sa_family == UInt8(AF_INET),
                  String(cString: i.ifa_name).hasPrefix("en") else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(sa, socklen_t(sa.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
            let ip = String(cString: host)
            if ip.hasPrefix("192.168.") || ip.hasPrefix("10.") || ip.hasPrefix("172.") { return ip }
        }
        return nil
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
