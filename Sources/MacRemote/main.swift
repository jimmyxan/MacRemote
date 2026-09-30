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

        server = Server(token: { [unowned self] in self.token }, handler: { [unowned self] a, v in self.commands.run(a, v) })
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

        let view = NSImageView(frame: NSRect(x: 20, y: 60, width: size, height: size))
        view.image = img
        let label = NSTextField(labelWithString: "Inquadra con la fotocamera dell'iPhone (stessa Wi-Fi)")
        label.frame = NSRect(x: 10, y: 20, width: size + 20, height: 20)
        label.alignment = .center

        let w = qrWindow ?? NSWindow(contentRect: NSRect(x: 0, y: 0, width: size + 40, height: size + 90),
                                     styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "MacRemote"
        w.contentView = NSView(frame: w.contentRect(forFrameRect: w.frame))
        w.contentView?.addSubview(view)
        w.contentView?.addSubview(label)
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
