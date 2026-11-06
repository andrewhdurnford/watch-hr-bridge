import AppKit

// Usage: swift tools/make_icon.swift <output.png>
// Draws the 1024x1024 app icon: dark-to-red gradient, white heart, ECG line, broadcast arcs.

let size = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: size, height: size)
NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx
let cg = ctx.cgContext

let s = CGFloat(size)

// Background gradient (top: deep red, bottom: near-black).
let colors = [NSColor(red: 0.93, green: 0.18, blue: 0.22, alpha: 1).cgColor,
              NSColor(red: 0.42, green: 0.05, blue: 0.10, alpha: 1).cgColor,
              NSColor(red: 0.10, green: 0.02, blue: 0.04, alpha: 1).cgColor] as CFArray
let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.6, 1])!
cg.drawLinearGradient(grad, start: CGPoint(x: s / 2, y: s), end: CGPoint(x: s / 2, y: 0), options: [])

// Broadcast arcs on the upper right.
cg.setStrokeColor(NSColor.white.withAlphaComponent(0.55).cgColor)
cg.setLineWidth(34)
cg.setLineCap(.round)
let center = CGPoint(x: s * 0.72, y: s * 0.74)
for (i, r) in [CGFloat(110), 190, 270].enumerated() {
    cg.setStrokeColor(NSColor.white.withAlphaComponent(0.85 - CGFloat(i) * 0.22).cgColor)
    cg.addArc(center: center, radius: r, startAngle: -.pi * 0.05, endAngle: .pi * 0.5, clockwise: false)
    cg.strokePath()
}

// Heart (SF Symbol, tinted white).
let cfg = NSImage.SymbolConfiguration(pointSize: 560, weight: .bold)
if let sym = NSImage(systemSymbolName: "heart.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(cfg) {
    let w = sym.size.width, h = sym.size.height
    let tinted = NSImage(size: sym.size)
    tinted.lockFocus()
    sym.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1)
    NSColor.white.set()
    NSRect(origin: .zero, size: sym.size).fill(using: .sourceAtop)
    tinted.unlockFocus()
    let rect = NSRect(x: s * 0.44 - w / 2, y: s * 0.40 - h / 2, width: w, height: h)
    cg.setShadow(offset: CGSize(width: 0, height: -14), blur: 40, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    tinted.draw(in: rect)
    cg.setShadow(offset: .zero, blur: 0, color: nil)
}

// ECG line across the heart.
let ecg = CGMutablePath()
let y0 = s * 0.40
ecg.move(to: CGPoint(x: s * 0.12, y: y0))
ecg.addLine(to: CGPoint(x: s * 0.30, y: y0))
ecg.addLine(to: CGPoint(x: s * 0.36, y: y0 + s * 0.12))
ecg.addLine(to: CGPoint(x: s * 0.44, y: y0 - s * 0.20))
ecg.addLine(to: CGPoint(x: s * 0.51, y: y0 + s * 0.08))
ecg.addLine(to: CGPoint(x: s * 0.56, y: y0))
ecg.addLine(to: CGPoint(x: s * 0.88, y: y0))
cg.setStrokeColor(NSColor(red: 0.62, green: 0.07, blue: 0.14, alpha: 1).cgColor)
cg.setLineWidth(46)
cg.setLineJoin(.round)
cg.setLineCap(.round)
cg.addPath(ecg)
cg.strokePath()

NSGraphicsContext.restoreGraphicsState()
// App Store icons must not have an alpha channel: redraw into an opaque RGB context and write that.
let src = rep.cgImage!
let opaque = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
opaque.draw(src, in: CGRect(x: 0, y: 0, width: size, height: size))
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, opaque.makeImage()!, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out)")
