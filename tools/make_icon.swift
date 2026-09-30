// Renders the app icon (1024px PNG). Usage: swift tools/make_icon.swift out.png [flat]
// "flat" = full-bleed square without transparency (iOS applies its own rounding).
import AppKit

let size: CGFloat = 1024
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()
let rect = NSRect(x: 0, y: 0, width: size, height: size)
let flat = CommandLine.arguments.count > 2
if !flat { NSBezierPath(roundedRect: rect.insetBy(dx: 40, dy: 40), xRadius: 200, yRadius: 200).addClip() }
NSGradient(colors: [NSColor(red: 0.25, green: 0.30, blue: 0.95, alpha: 1),
                    NSColor(red: 0.55, green: 0.20, blue: 0.85, alpha: 1)])!.draw(in: rect, angle: -60)
let cfg = NSImage.SymbolConfiguration(pointSize: flat ? 480 : 520, weight: .medium)
    .applying(.init(paletteColors: [.white]))
if let sym = NSImage(systemSymbolName: "macbook.and.iphone", accessibilityDescription: nil)?.withSymbolConfiguration(cfg) {
    let s = sym.size
    sym.draw(in: NSRect(x: (size - s.width) / 2, y: (size - s.height) / 2, width: s.width, height: s.height))
}
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
