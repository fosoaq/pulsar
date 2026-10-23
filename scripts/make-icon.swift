// Draws the app icon into Pulsar/Assets.xcassets/AppIcon.appiconset.
// Run from the repository root: swift scripts/make-icon.swift
import AppKit

let outputDirectory = URL(filePath: "Pulsar/Assets.xcassets/AppIcon.appiconset")

func drawIcon(size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let context = NSGraphicsContext.current!.cgContext
    let scale = size / 1024
    context.scaleBy(x: scale, y: scale)

    // macOS icon grid: an 824-point rounded square centered on a 1024 canvas.
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    context.addPath(tilePath)
    context.setFillColor(NSColor.black.cgColor)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(tilePath)
    context.clip()
    let background = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [NSColor(red: 0.06, green: 0.11, blue: 0.32, alpha: 1).cgColor, NSColor(red: 0.36, green: 0.16, blue: 0.75, alpha: 1).cgColor] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(background, start: CGPoint(x: 200, y: 924), end: CGPoint(x: 824, y: 100), options: [])
    context.restoreGState()

    // Gauge: a 240° arc opening downwards, filled to about 70%.
    let center = CGPoint(x: 512, y: 448)
    let radius: CGFloat = 270
    let startAngle = CGFloat.pi * 7 / 6   // lower left
    let sweep = -CGFloat.pi * 4 / 3       // clockwise to lower right
    let value: CGFloat = 0.7

    context.setLineCap(.round)
    context.setLineWidth(58)
    context.setStrokeColor(NSColor.white.withAlphaComponent(0.18).cgColor)
    context.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: startAngle + sweep, clockwise: true)
    context.strokePath()

    context.saveGState()
    context.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: startAngle + sweep * value, clockwise: true)
    context.replacePathWithStrokedPath()
    context.clip()
    let arc = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [NSColor(red: 0.22, green: 0.85, blue: 1, alpha: 1).cgColor, NSColor.white.cgColor] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(arc, start: CGPoint(x: 200, y: 300), end: CGPoint(x: 800, y: 700), options: [])
    context.restoreGState()

    // Needle pointing at the value.
    let needleAngle = startAngle + sweep * value
    let tip = CGPoint(x: center.x + cos(needleAngle) * (radius - 70), y: center.y + sin(needleAngle) * (radius - 70))
    context.setStrokeColor(NSColor.white.cgColor)
    context.setLineWidth(34)
    context.move(to: center)
    context.addLine(to: tip)
    context.strokePath()
    context.setFillColor(NSColor.white.cgColor)
    context.fillEllipse(in: CGRect(x: center.x - 48, y: center.y - 48, width: 96, height: 96))
    context.setFillColor(NSColor(red: 0.22, green: 0.2, blue: 0.6, alpha: 1).cgColor)
    context.fillEllipse(in: CGRect(x: center.x - 20, y: center.y - 20, width: 40, height: 40))

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

struct Entry: Encodable {
    let idiom = "mac"
    let size: String
    let scale: String
    let filename: String
}

var images: [Entry] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = points * scale
        let filename = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        let data = drawIcon(size: CGFloat(pixels)).representation(using: .png, properties: [:])!
        try data.write(to: outputDirectory.appending(path: filename))
        images.append(Entry(size: "\(points)x\(points)", scale: "\(scale)x", filename: filename))
    }
}

struct Contents: Encodable {
    struct Info: Encodable { let author = "xcode"; let version = 1 }
    let images: [Entry]
    let info = Info()
}
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
try encoder.encode(Contents(images: images)).write(to: outputDirectory.appending(path: "Contents.json"))
print("Wrote \(images.count) icons to \(outputDirectory.path)")
