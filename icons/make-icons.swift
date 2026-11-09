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

let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().path
render("antenna.radiowaves.left.and.right", to: "\(dir)/icon.png")
