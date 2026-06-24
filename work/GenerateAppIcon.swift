import AppKit

let output = CommandLine.arguments.dropFirst().first ?? "Resources/AppIcon.iconset"
let outputURL = URL(fileURLWithPath: output)
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

struct IconSize {
    let fileName: String
    let pixels: Int
}

let sizes = [
    IconSize(fileName: "icon_16x16.png", pixels: 16),
    IconSize(fileName: "icon_16x16@2x.png", pixels: 32),
    IconSize(fileName: "icon_32x32.png", pixels: 32),
    IconSize(fileName: "icon_32x32@2x.png", pixels: 64),
    IconSize(fileName: "icon_128x128.png", pixels: 128),
    IconSize(fileName: "icon_128x128@2x.png", pixels: 256),
    IconSize(fileName: "icon_256x256.png", pixels: 256),
    IconSize(fileName: "icon_256x256@2x.png", pixels: 512),
    IconSize(fileName: "icon_512x512.png", pixels: 512),
    IconSize(fileName: "icon_512x512@2x.png", pixels: 1024)
]

func drawIcon(size: Int) -> NSImage {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    bitmap.size = NSSize(width: size, height: size)

    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    defer { NSGraphicsContext.restoreGraphicsState() }

    let scale = CGFloat(size) / 1024
    let canvas = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    canvas.fill()

    let tile = canvas.insetBy(dx: 108 * scale, dy: 108 * scale)
    let tileRadius = 220 * scale

    NSColor(calibratedWhite: 0, alpha: 0.16).setFill()
    NSBezierPath(
        roundedRect: tile.offsetBy(dx: 0, dy: -22 * scale),
        xRadius: tileRadius,
        yRadius: tileRadius
    ).fill()

    let tilePath = NSBezierPath(roundedRect: tile, xRadius: tileRadius, yRadius: tileRadius)
    NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.14, alpha: 1).setFill()
    tilePath.fill()

    let glow = tile.insetBy(dx: 46 * scale, dy: 46 * scale)
    NSColor(calibratedRed: 0.10, green: 0.22, blue: 0.32, alpha: 1).setFill()
    NSBezierPath(roundedRect: glow, xRadius: 164 * scale, yRadius: 164 * scale).fill()

    let card = tile.insetBy(dx: 74 * scale, dy: 78 * scale)
    NSColor(calibratedRed: 0.86, green: 0.94, blue: 0.98, alpha: 1).setFill()
    NSBezierPath(roundedRect: card, xRadius: 132 * scale, yRadius: 132 * scale).fill()

    NSColor(calibratedRed: 0.65, green: 0.82, blue: 0.92, alpha: 1).setStroke()
    let cardStroke = NSBezierPath(roundedRect: card.insetBy(dx: 13 * scale, dy: 13 * scale), xRadius: 116 * scale, yRadius: 116 * scale)
    cardStroke.lineWidth = max(22 * scale, size <= 32 ? 1 : 2)
    cardStroke.stroke()

    let hinge = NSPoint(x: card.minX + 270 * scale, y: card.minY + 205 * scale)

    let basePath = NSBezierPath()
    basePath.lineWidth = max(40 * scale, size <= 32 ? 1.8 : 2.6)
    basePath.lineCapStyle = .round
    NSColor(calibratedWhite: 1, alpha: 0.98).setStroke()
    basePath.move(to: NSPoint(x: hinge.x - 16 * scale, y: hinge.y))
    basePath.line(to: NSPoint(x: card.maxX - 82 * scale, y: hinge.y))
    basePath.stroke()

    let arc = NSBezierPath()
    arc.move(to: NSPoint(x: hinge.x - 188 * scale, y: hinge.y - 30 * scale))
    arc.curve(
        to: NSPoint(x: hinge.x - 104 * scale, y: hinge.y + 134 * scale),
        controlPoint1: NSPoint(x: hinge.x - 192 * scale, y: hinge.y + 32 * scale),
        controlPoint2: NSPoint(x: hinge.x - 152 * scale, y: hinge.y + 112 * scale)
    )
    arc.lineWidth = max(15 * scale, size <= 32 ? 1.3 : 1.8)
    arc.lineCapStyle = .round
    NSColor.controlAccentColor.withAlphaComponent(0.92).setStroke()
    arc.stroke()

    let lidPath = NSBezierPath()
    lidPath.lineWidth = max(54 * scale, size <= 32 ? 2.8 : 3.6)
    lidPath.lineCapStyle = .round
    NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.16, alpha: 1).setStroke()
    lidPath.move(to: hinge)
    lidPath.line(to: NSPoint(x: hinge.x - 168 * scale, y: hinge.y + 300 * scale))
    lidPath.stroke()

    NSColor.controlAccentColor.setFill()
    NSBezierPath(
        ovalIn: NSRect(
            x: hinge.x - 38 * scale,
            y: hinge.y - 38 * scale,
            width: 76 * scale,
            height: 76 * scale
        )
    ).fill()

    let image = NSImage(size: NSSize(width: size, height: size))
    image.addRepresentation(bitmap)
    return image
}

for size in sizes {
    let image = drawIcon(size: size.pixels)
    guard
        let bitmap = image.representations.first as? NSBitmapImageRep,
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        fatalError("Could not render \(size.fileName)")
    }

    try png.write(to: outputURL.appendingPathComponent(size.fileName))
}
