import AppKit
import CoreGraphics

/// Trackpad on the phone. The page batches its gestures into small ops, applied here in order:
/// ["m",dx,dy] move · ["s",dx,dy] scroll · ["c"] click · ["r"] right click
/// ["d"] / ["u"] left button down / up (drag) · ["g",dir] three-finger swipe (l, r, u, d) · ["z",dir] pinch step (i = in, o = out)
final class Pointer {
    private let queue: DispatchQueue
    private var held = false
    private var lastClick: (at: Date, button: CGMouseButton, pos: CGPoint, count: Int)?
    private var moveRest = CGPoint.zero     // sub-pixel remainders carried between batches
    private var scrollRest = CGPoint.zero
    private var release: DispatchWorkItem?

    init(queue: DispatchQueue) { self.queue = queue }

    func apply(_ ops: [[Any]]) -> [String: Any] {
        for op in ops.prefix(512) {
            guard let kind = op.first as? String else { continue }
            let x = Self.number(op, 1), y = Self.number(op, 2)
            switch kind {
            case "m": move(x, y)
            case "s": scroll(x, y)
            case "c" where !held: click(.left)
            case "r" where !held: click(.right)
            case "d" where !held:
                held = true
                let p = location()
                post(.leftMouseDown, .left, p, nextCount(.left, at: p))
            case "u" where held:
                held = false
                post(.leftMouseUp, .left, location(), lastClick?.count ?? 1)
            case "g": swipe(op.count > 1 ? op[1] as? String : nil)
            case "z": zoom(in: (op.count > 1 ? op[1] as? String : nil) == "i")
            default: break
            }
        }
        armRelease()
        return ["ok": true]
    }

    private static func number(_ op: [Any], _ i: Int) -> CGFloat {
        guard op.count > i, let v = op[i] as? Double, v.isFinite else { return 0 }
        return CGFloat(min(max(v, -5000), 5000))
    }

    private func location() -> CGPoint { CGEvent(source: nil)?.location ?? .zero }

    private func move(_ dx: CGFloat, _ dy: CGFloat) {
        moveRest.x += dx; moveRest.y += dy
        let sx = moveRest.x.rounded(.towardZero), sy = moveRest.y.rounded(.towardZero)
        guard sx != 0 || sy != 0 else { return }
        moveRest.x -= sx; moveRest.y -= sy
        let from = location()
        let to = clamp(CGPoint(x: from.x + sx, y: from.y + sy), from: from)
        let e = CGEvent(mouseEventSource: nil, mouseType: held ? .leftMouseDragged : .mouseMoved,
                        mouseCursorPosition: to, mouseButton: .left)
        e?.setIntegerValueField(.mouseEventDeltaX, value: Int64(to.x - from.x))
        e?.setIntegerValueField(.mouseEventDeltaY, value: Int64(to.y - from.y))
        e?.post(tap: .cghidEventTap)
    }

    /// Free movement across displays; at the outer edges the cursor stops on the display it was on.
    private func clamp(_ p: CGPoint, from: CGPoint) -> CGPoint {
        var ids = [CGDirectDisplayID](repeating: 0, count: 16)
        var n: UInt32 = 0
        guard CGGetActiveDisplayList(16, &ids, &n) == .success else { return p }
        let screens = ids.prefix(Int(n)).map { CGDisplayBounds($0) }
        if screens.contains(where: { $0.contains(p) }) { return p }
        guard let r = screens.first(where: { $0.contains(from) }) ?? screens.first else { return p }
        return CGPoint(x: min(max(p.x, r.minX), r.maxX - 1), y: min(max(p.y, r.minY), r.maxY - 1))
    }

    private func scroll(_ dx: CGFloat, _ dy: CGFloat) {
        // The page sends "natural" deltas (content follows the fingers). Synthetic events skip the
        // system's inversion, so flip them here when the Mac has natural scrolling turned off.
        let sign: CGFloat = UserDefaults.standard.object(forKey: "com.apple.swipescrolldirection") as? Bool == false ? -1 : 1
        scrollRest.x += dx * sign; scrollRest.y += dy * sign
        let ix = scrollRest.x.rounded(.towardZero), iy = scrollRest.y.rounded(.towardZero)
        guard ix != 0 || iy != 0 else { return }
        scrollRest.x -= ix; scrollRest.y -= iy
        let e = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2,
                        wheel1: Int32(iy), wheel2: Int32(ix), wheel3: 0)
        e?.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        e?.post(tap: .cghidEventTap)
    }

    private func click(_ button: CGMouseButton) {
        let p = location(), n = nextCount(button, at: p)
        let types: [CGEventType] = button == .right ? [.rightMouseDown, .rightMouseUp] : [.leftMouseDown, .leftMouseUp]
        for t in types { post(t, button, p, n) }
    }

    /// Taps close in time and place become double and triple clicks, as with a real trackpad.
    private func nextCount(_ button: CGMouseButton, at p: CGPoint) -> Int {
        let now = Date()
        var count = 1
        if let l = lastClick, l.button == button, now.timeIntervalSince(l.at) < NSEvent.doubleClickInterval,
           hypot(l.pos.x - p.x, l.pos.y - p.y) < 8 {
            count = l.count % 3 + 1
        }
        lastClick = (now, button, p, count)
        return count
    }

    private func post(_ type: CGEventType, _ button: CGMouseButton, _ p: CGPoint, _ count: Int) {
        let e = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: p, mouseButton: button)
        e?.setIntegerValueField(.mouseEventClickState, value: Int64(count))
        e?.post(tap: .cghidEventTap)
    }

    /// Default macOS shortcuts behind the three-finger swipes: Spaces, Mission Control, App Exposé.
    private func swipe(_ dir: String?) {
        let keys: [String: CGKeyCode] = ["l": 124, "r": 123, "u": 126, "d": 125]
        guard let dir, let key = keys[dir] else { return }
        Input.postKey(key, flags: [.maskControl, .maskSecondaryFn])
    }

    /// There is no public API for a pinch gesture, so a pinch step is ⌘+ / ⌘−, the zoom shortcut of browsers, Preview, Pages, Maps…
    private func zoom(in zoomIn: Bool) {
        Input.postKey(zoomIn ? 24 : 27, flags: .maskCommand)   // ANSI = and -
    }

    /// A lost "up" (phone locked, Wi-Fi dropped) must not leave the button stuck down.
    private func armRelease() {
        release?.cancel()
        release = nil
        guard held else { return }
        let w = DispatchWorkItem { [weak self] in
            guard let self, self.held else { return }
            self.held = false
            self.post(.leftMouseUp, .left, self.location(), 1)
        }
        release = w
        queue.asyncAfter(deadline: .now() + 8, execute: w)
    }
}
