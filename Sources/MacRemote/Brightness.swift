import Foundation
import IOKit
import CoreGraphics

// Private IOAVService API (Apple Silicon DDC/CI). May be unavailable on some systems.
@_silgen_name("IOAVServiceCreateWithService")
private func IOAVServiceCreateWithService(_ allocator: CFAllocator?, _ service: io_service_t) -> Unmanaged<CFTypeRef>?
@_silgen_name("IOAVServiceWriteI2C")
private func IOAVServiceWriteI2C(_ service: CFTypeRef, _ chip: UInt32, _ offset: UInt32,
                                 _ buf: UnsafeMutableRawPointer, _ size: UInt32) -> IOReturn
@_silgen_name("IOAVServiceReadI2C")
private func IOAVServiceReadI2C(_ service: CFTypeRef, _ chip: UInt32, _ offset: UInt32,
                                _ buf: UnsafeMutableRawPointer, _ size: UInt32) -> IOReturn

/// Built-in display: DisplayServices. External monitors: DDC/CI (VCP 0x10); if the monitor ignores DDC writes,
/// falls back to software dimming through the display gamma table.
final class Brightness {
    private typealias GetF = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetF = @convention(c) (CGDirectDisplayID, Float) -> Int32
    private let getBrightness: GetF?
    private let setBrightness: SetF?

    private var level: Int?
    private var maxLevel = 100
    private var ddcWorks = true
    private var softLevel = 100   // software dimming, percent
    private let step = 10

    init() {
        let h = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW)
        getBrightness = h.flatMap { dlsym($0, "DisplayServicesGetBrightness") }.map { unsafeBitCast($0, to: GetF.self) }
        setBrightness = h.flatMap { dlsym($0, "DisplayServicesSetBrightness") }.map { unsafeBitCast($0, to: SetF.self) }
    }

    private func externalServices() -> [CFTypeRef] {
        var result: [CFTypeRef] = []
        var iter: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("DCPAVServiceProxy"), &iter) == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iter) }
        while case let entry = IOIteratorNext(iter), entry != 0 {
            defer { IOObjectRelease(entry) }
            let loc = IORegistryEntryCreateCFProperty(entry, "Location" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? String
            guard loc == "External", let svc = IOAVServiceCreateWithService(kCFAllocatorDefault, entry) else { continue }
            result.append(svc.takeRetainedValue())
        }
        return result
    }

    private func write(_ svc: CFTypeRef, vcp: UInt8, value: Int) {
        var d: [UInt8] = [0x84, 0x03, vcp, UInt8((value >> 8) & 0xff), UInt8(value & 0xff), 0]
        d[5] = d[0..<5].reduce(0x6E ^ 0x51, ^)
        for _ in 0..<2 {
            _ = IOAVServiceWriteI2C(svc, 0x37, 0x51, &d, UInt32(d.count))
            usleep(20_000)
        }
    }

    private func read(_ svc: CFTypeRef, vcp: UInt8) -> (cur: Int, max: Int)? {
        var req: [UInt8] = [0x82, 0x01, vcp, 0]
        req[3] = req[0..<3].reduce(0x6E ^ 0x51, ^)
        guard IOAVServiceWriteI2C(svc, 0x37, 0x51, &req, UInt32(req.count)) == KERN_SUCCESS else { return nil }
        usleep(50_000)
        var reply = [UInt8](repeating: 0, count: 12)
        guard IOAVServiceReadI2C(svc, 0x37, 0x51, &reply, UInt32(reply.count)) == KERN_SUCCESS else { return nil }
        let max = Int(reply[6]) << 8 | Int(reply[7])
        let cur = Int(reply[8]) << 8 | Int(reply[9])
        return max > 0 ? (cur, max) : nil
    }

    /// Which kinds of display are online right now (the UI hides sections that do not apply).
    static func availability() -> [String: Any] {
        let ids = displays()
        return ["hasMacDisplay": ids.contains { CGDisplayIsBuiltin($0) != 0 },
                "hasExternalDisplay": ids.contains { CGDisplayIsBuiltin($0) == 0 }]
    }

    private static func displays() -> [CGDirectDisplayID] {
        var ids = [CGDirectDisplayID](repeating: 0, count: 16)
        var n: UInt32 = 0
        CGGetOnlineDisplayList(16, &ids, &n)
        return Array(ids.prefix(Int(n)))
    }

    /// target: "mac" (built-in) or "ext" (external monitors). Returns a short status message for the UI.
    func adjust(up: Bool, target: String) -> String {
        let builtin = target == "mac"
        let ids = Self.displays().filter { (CGDisplayIsBuiltin($0) != 0) == builtin }
        guard !ids.isEmpty else { return builtin ? "Mac display not active" : "No external monitor" }

        // DisplayServices drives the same brightness as the macOS slider, one display at a time.
        var failed: [CGDirectDisplayID] = []
        var levels: [Int] = []
        for id in ids {
            var b: Float = 0
            if let get = getBrightness, let set = setBrightness, get(id, &b) == 0 {
                let next = max(0, min(1, b + (up ? 0.1 : -0.1)))
                if set(id, next) == 0 {
                    usleep(100_000)
                    var after: Float = -1
                    // Trust the change only if the system reports the new value back.
                    if get(id, &after) == 0, abs(after - next) < 0.03 {
                        levels.append(Int((next * 100).rounded()))
                        continue
                    }
                }
            }
            failed.append(id)
        }
        let name = builtin ? "Mac display" : "Monitor"
        if !failed.isEmpty, !builtin, let msg = adjustExternal(up: up, displays: failed) {
            return "\(name) \(msg)"
        }
        return levels.isEmpty ? "\(name): brightness not controllable" : "\(name) \(levels[0])%"
    }

    /// Undo any software dimming left from a previous run.
    func resetGamma() { CGDisplayRestoreColorSyncSettings() }

    private func adjustExternal(up: Bool, displays: [CGDirectDisplayID]) -> String? {
        let services = ddcWorks ? externalServices() : []
        if let svc = services.first {
            if level == nil, let r = read(svc, vcp: 0x10) {
                maxLevel = r.max
                level = r.cur * 100 / r.max
            }
            let before = level ?? 50
            let next = max(0, min(100, before + (up ? step : -step)))
            if next != before {
                for s in services { write(s, vcp: 0x10, value: next * maxLevel / 100) }
                usleep(150_000)
                if let r = read(svc, vcp: 0x10), r.cur * 100 / r.max == next {
                    level = next
                    return "\(next)%"
                }
                ddcWorks = false   // monitor ignores DDC writes
            } else {
                return "\(next)%"
            }
        }
        softLevel = max(10, min(100, softLevel + (up ? step : -step)))
        let f = CGGammaValue(softLevel) / 100
        for id in displays { CGSetDisplayTransferByFormula(id, 0, f, 1, 0, f, 1, 0, f, 1) }
        return "\(softLevel)% (software)"
    }
}
