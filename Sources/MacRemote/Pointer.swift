import AppKit
import CoreGraphics

/// Touchpad on the phone. The page batches its gestures into small ops, applied here in order:
/// ["m",dx,dy] move · ["s",dx,dy] scroll · ["c"] click · ["r"] right click
/// ["d"] / ["u"] left button down / up (drag) · ["g",dir] three-finger swipe (l, r, u, d) · ["z",dir] pinch step (i = in, o = out)
final class Pointer {
    private let queue: DispatchQueue
    private var held = false
    private var lastClick: (at: Date, button: CGMouseButton, pos: CGPoint, count: Int)?
    private var scrollRest = CGPoint.zero   // sub-pixel scroll carried between events
    private var release: DispatchWorkItem?

    // Batches arrive in bursts over Wi-Fi. Applied as they come, the cursor jumps; instead motion is buffered
    // and played back at 120 Hz, spread over the time the next batch is expected to take.
    private static let tick = 1.0 / 120
    private var pendingMove = CGPoint.zero
    private var pendingScroll = CGPoint.zero
    private var interval = 0.016          // running estimate of the time between batches
    private var lastBatch = Date.distantPast
    private var ticker: DispatchSourceTimer?

    // Where we last put the cursor. Reading it back right after posting can still return the old position,
    // which lost steps or pulled the cursor back; while we are moving it, our own value is the truth.
    private var cursor = CGPoint.zero
    private var cursorAt = Date.distantPast

    init(queue: DispatchQueue) { self.queue = queue }

    func apply(_ ops: [[Any]]) -> [String: Any] {
        let now = Date()
        if ops.contains(where: { let k = $0.first as? String; return k == "m" || k == "s" }) {
            let gap = now.timeIntervalSince(lastBatch)
            if gap < 0.25 { interval = min(max(interval * 0.7 + gap * 0.3, 0.008), 0.06) }
            lastBatch = now
        }
        for op in ops.prefix(512) {
            guard let kind = op.first as? String else { continue }
            let x = Self.number(op, 1), y = Self.number(op, 2)
            switch kind {
            case "m":
                pendingMove.x += x; pendingMove.y += y
                startTicker()
            case "s":
                pendingScroll.x += x; pendingScroll.y += y
                startTicker()
            default:
                drain(1)   // clicks and keys act where the cursor is meant to be: play the buffered motion out first
                act(kind, op)
            }
        }
        armRelease()
        return ["ok": true]
    }

    private func act(_ kind: String, _ op: [Any]) {
        let arg = op.count > 1 ? op[1] as? String : nil
        switch kind {
        case "c" where !held: click(.left)
        case "r" where !held: click(.right)
        case "d" where !held:
            held = true
            let p = position()
            post(.leftMouseDown, .left, p, nextCount(.left, at: p))
        case "u" where held:
            held = false
            post(.leftMouseUp, .left, position(), lastClick?.count ?? 1)
        case "g": swipe(arg)
        case "z": Input.zoom(in: arg == "i")
        default: break
        }
    }

    private static func number(_ op: [Any], _ i: Int) -> CGFloat {
        guard op.count > i, let v = op[i] as? Double, v.isFinite else { return 0 }
        return CGFloat(min(max(v, -5000), 5000))
    }

    // MARK: Smoothing

    private func startTicker() {
        guard ticker == nil else { return }
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: Self.tick, leeway: .milliseconds(1))
        t.setEventHandler { [weak self] in self?.step() }
        ticker = t
        t.resume()
    }

    private func step() {
        drain(CGFloat(min(1, max(0.2, Self.tick / interval))))
        if pendingMove == .zero && pendingScroll == .zero {
            ticker?.cancel()
            ticker = nil
        }
    }

    /// Plays out `fraction` of the buffered motion; small leftovers go out whole so the buffer empties.
    private func drain(_ fraction: CGFloat) {
        let m = Self.take(&pendingMove, fraction)
        if m != .zero { move(m.x, m.y) }
        let s = Self.take(&pendingScroll, fraction)
        if s != .zero { scroll(s.x, s.y) }
    }

    private static func take(_ p: inout CGPoint, _ fraction: CGFloat) -> CGPoint {
        let part = fraction >= 1 || hypot(p.x, p.y) < 1 ? p : CGPoint(x: p.x * fraction, y: p.y * fraction)
        p.x -= part.x; p.y -= part.y
        return part
    }

    // MARK: Events

    private func position() -> CGPoint {
        if Date().timeIntervalSince(cursorAt) < 0.5 { return cursor }
        return CGEvent(source: nil)?.location ?? .zero
    }

    private func move(_ dx: CGFloat, _ dy: CGFloat) {
        let from = position()
        let to = clamp(CGPoint(x: from.x + dx, y: from.y + dy), from: from)
        let e = CGEvent(mouseEventSource: nil, mouseType: held ? .leftMouseDragged : .mouseMoved,
                        mouseCursorPosition: to, mouseButton: .left)
        e?.flags = []
        e?.setIntegerValueField(.mouseEventDeltaX, value: Int64((to.x - from.x).rounded()))
        e?.setIntegerValueField(.mouseEventDeltaY, value: Int64((to.y - from.y).rounded()))
        e?.post(tap: .cghidEventTap)
        cursor = to
        cursorAt = Date()
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
        e?.flags = []
        e?.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        e?.post(tap: .cghidEventTap)
    }

    private func click(_ button: CGMouseButton) {
        let p = position(), n = nextCount(button, at: p)
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
        // Explicitly no modifiers: after a ⌘+ zoom step a click must not land as a ⌘-click.
        e?.flags = []
        e?.setIntegerValueField(.mouseEventClickState, value: Int64(count))
        e?.post(tap: .cghidEventTap)
    }

    /// Default macOS shortcuts behind the three-finger swipes: Spaces, Mission Control, App Exposé.
    private func swipe(_ dir: String?) {
        let keys: [String: CGKeyCode] = ["l": 124, "r": 123, "u": 126, "d": 125]
        guard let dir, let key = keys[dir] else { return }
        Input.postKey(key, flags: [.maskControl, .maskSecondaryFn])
    }

    /// A lost "up" (phone locked, Wi-Fi dropped) must not leave the button stuck down.
    private func armRelease() {
        release?.cancel()
        release = nil
        guard held else { return }
        let w = DispatchWorkItem { [weak self] in
            guard let self, self.held else { return }
            self.held = false
            self.post(.leftMouseUp, .left, self.position(), 1)
        }
        release = w
        queue.asyncAfter(deadline: .now() + 8, execute: w)
    }
}
