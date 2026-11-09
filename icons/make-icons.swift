// Renders an SF Symbol to a 32x32 px template PNG (16pt @2x; tray.m shows it at half its pixel size).
// Run: swift icons/make-icons.swift   (needs only Command Line Tools)
import AppKit

func bitmap(_ px: Int) -> NSBitmapImageRep {
    NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                     samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                     colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
}

func draw(into rep: NSBitmapImageRep, _ body: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    body()
    NSGraphicsContext.restoreGraphicsState()
}

// Symbols carry padding, so render big, crop to the inked pixels, then fill the 16pt box.
func render(_ symbol: String, to path: String) {
    let config = NSImage.SymbolConfiguration(pointSize: 200, weight: .medium)
    guard let img = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else { fatalError("no symbol \(symbol)") }
    let big = bitmap(512)
    draw(into: big) { img.draw(in: NSRect(x: 0, y: 0, width: 512, height: 512 * img.size.height / img.size.width)) }

    var minX = 512, minY = 512, maxX = -1, maxY = -1
    for y in 0..<512 { for x in 0..<512 where big.colorAt(x: x, y: y)!.alphaComponent > 0.05 {
        minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
    } }
    let cw = CGFloat(maxX - minX + 1), ch = CGFloat(maxY - minY + 1)
    let crop = NSRect(x: CGFloat(minX), y: 512 - CGFloat(maxY) - 1, width: cw, height: ch) // bitmap rows are top-down

    let out = bitmap(32)
    out.size = NSSize(width: 16, height: 16)
    let scale = min(16 / cw, 16 / ch), w = cw * scale, h = ch * scale
    draw(into: out) {
        NSImage(cgImage: big.cgImage!, size: NSSize(width: 512, height: 512))
            .draw(in: NSRect(x: (16 - w) / 2, y: (16 - h) / 2, width: w, height: h), from: crop, operation: .sourceOver, fraction: 1)
    }
    try! out.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

// App icon on Apple's 1024 grid: 824pt rounded square, blue gradient, white glyph.
func appIcon(_ px: Int) -> Data {
    let rep = bitmap(px)
    draw(into: rep) {
        let s = CGFloat(px) / 1024
        let tile = NSRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
        let path = NSBezierPath(roundedRect: tile, xRadius: 185 * s, yRadius: 185 * s)
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(white: 0, alpha: 0.3)
        shadow.shadowOffset = NSSize(width: 0, height: -10 * s)
        shadow.shadowBlurRadius = 20 * s
        shadow.set()
        NSColor.black.setFill()
        path.fill()
        NSGraphicsContext.restoreGraphicsState()
        NSGradient(starting: NSColor(srgbRed: 0.33, green: 0.55, blue: 1.0, alpha: 1),
                   ending: NSColor(srgbRed: 0.10, green: 0.18, blue: 0.55, alpha: 1))!
            .draw(in: path, angle: -90)

        let config = NSImage.SymbolConfiguration(pointSize: 420 * s, weight: .semibold)
            .applying(.init(paletteColors: [.white]))
        let glyph = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right", accessibilityDescription: nil)!
            .withSymbolConfiguration(config)!
        let g = glyph.size
        glyph.draw(in: NSRect(x: (CGFloat(px) - g.width) / 2, y: (CGFloat(px) - g.height) / 2,
                              width: g.width, height: g.height))
    }
    return rep.representation(using: .png, properties: [:])!
}

func makeIcns(to path: String) {
    let set = NSTemporaryDirectory() + "AppIcon.iconset"
    try? FileManager.default.removeItem(atPath: set)
    try! FileManager.default.createDirectory(atPath: set, withIntermediateDirectories: true)
    for pt in [16, 32, 128, 256, 512] {
        try! appIcon(pt).write(to: URL(fileURLWithPath: "\(set)/icon_\(pt)x\(pt).png"))
        try! appIcon(pt * 2).write(to: URL(fileURLWithPath: "\(set)/icon_\(pt)x\(pt)@2x.png"))
    }
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    p.arguments = ["-c", "icns", set, "-o", path]
    try! p.run()
    p.waitUntilExit()
    precondition(p.terminationStatus == 0, "iconutil failed")
}

let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().path
render("antenna.radiowaves.left.and.right", to: "\(dir)/icon.png")
makeIcns(to: "\(dir)/AppIcon.icns")
