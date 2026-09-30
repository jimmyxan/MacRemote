import Foundation
import CoreGraphics
import ImageIO
import ScreenCaptureKit
import UniformTypeIdentifiers

/// On-demand screen snapshots. Off by default: the phone must switch it on, and it lapses by itself
/// when the phone stops asking (closed page, lost Wi-Fi).
enum ScreenPreview {
    struct Failure: Error { let message: String }

    private static let lock = NSLock()
    private static var enabledUntil = Date.distantPast
    private static let lease: TimeInterval = 15

    static func setEnabled(_ on: Bool) -> [String: Any] {
        if on && !CGPreflightScreenCaptureAccess() {
            CGRequestScreenCaptureAccess()
            return ["ok": false, "info": "Permesso Registrazione schermo mancante: Impostazioni › Privacy › Registrazione schermo › MacRemote"]
        }
        lock.lock()
        enabledUntil = on ? Date().addingTimeInterval(lease) : .distantPast
        lock.unlock()
        return ["ok": true]
    }

    /// True (and renews the lease) only while the preview is switched on.
    private static func touch() -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard enabledUntil > Date() else { return false }
        enabledUntil = Date().addingTimeInterval(lease)
        return true
    }

    static func displayCount() -> Int {
        var n: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &n)
        return Int(n)
    }

    static func jpeg(display index: Int, maxWidth: Int = 1280) throws -> Data {
        guard touch() else { throw Failure(message: "Anteprima disattivata") }
        guard CGPreflightScreenCaptureAccess() else { throw Failure(message: "Permesso Registrazione schermo mancante") }

        let sem = DispatchSemaphore(value: 0)
        var result: Result<CGImage, Error> = .failure(Failure(message: "Timeout"))
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                let main = CGMainDisplayID()
                let displays = content.displays.sorted { ($0.displayID == main ? 0 : 1, $0.displayID) < ($1.displayID == main ? 0 : 1, $1.displayID) }
                guard !displays.isEmpty else { throw Failure(message: "Nessuno schermo") }
                let d = displays[((index % displays.count) + displays.count) % displays.count]
                let cfg = SCStreamConfiguration()
                let scale = min(1.0, Double(maxWidth) / Double(d.width))
                cfg.width = max(1, Int(Double(d.width) * scale))
                cfg.height = max(1, Int(Double(d.height) * scale))
                cfg.showsCursor = true
                let img = try await SCScreenshotManager.captureImage(contentFilter: SCContentFilter(display: d, excludingWindows: []),
                                                                     configuration: cfg)
                result = .success(img)
            } catch { result = .failure(error) }
            sem.signal()
        }
        if sem.wait(timeout: .now() + 6) == .timedOut { throw Failure(message: "Timeout cattura schermo") }
        let image = try result.get()

        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw Failure(message: "Codifica fallita")
        }
        CGImageDestinationAddImage(dest, image, [kCGImageDestinationLossyCompressionQuality: 0.55] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { throw Failure(message: "Codifica fallita") }
        return out as Data
    }
}
