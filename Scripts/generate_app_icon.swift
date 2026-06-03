import AppKit
import CoreGraphics
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetsDirectory = root.appendingPathComponent("assets", isDirectory: true)
let iconsetDirectory = assetsDirectory.appendingPathComponent("SleepGuardIcon.iconset", isDirectory: true)
let icnsURL = assetsDirectory.appendingPathComponent("SleepGuard.icns")
let previewURL = assetsDirectory.appendingPathComponent("sleepguard-icon.png")

try FileManager.default.createDirectory(at: iconsetDirectory, withIntermediateDirectories: true)

let sizes: [(name: String, points: Int, scale: Int)] = [
    ("icon_16x16.png", 16, 1),
    ("icon_16x16@2x.png", 16, 2),
    ("icon_32x32.png", 32, 1),
    ("icon_32x32@2x.png", 32, 2),
    ("icon_128x128.png", 128, 1),
    ("icon_128x128@2x.png", 128, 2),
    ("icon_256x256.png", 256, 1),
    ("icon_256x256@2x.png", 256, 2),
    ("icon_512x512.png", 512, 1),
    ("icon_512x512@2x.png", 512, 2)
]

func drawIcon(pixelSize: Int) -> NSImage {
    let size = NSSize(width: pixelSize, height: pixelSize)
    let image = NSImage(size: size)
    image.lockFocus()

    let rect = NSRect(origin: .zero, size: size)
    let scale = CGFloat(pixelSize) / 1024

    let background = NSGradient(colors: [
        NSColor(calibratedRed: 0.16, green: 0.37, blue: 0.95, alpha: 1),
        NSColor(calibratedRed: 0.36, green: 0.69, blue: 1.0, alpha: 1)
    ])
    let radius = 224 * scale
    let roundedRect = NSBezierPath(roundedRect: rect.insetBy(dx: 48 * scale, dy: 48 * scale), xRadius: radius, yRadius: radius)
    background?.draw(in: roundedRect, angle: 135)

    NSColor(calibratedWhite: 1, alpha: 0.16).setFill()
    NSBezierPath(ovalIn: NSRect(x: 596 * scale, y: 610 * scale, width: 320 * scale, height: 320 * scale)).fill()

    NSColor.white.setFill()
    let bedFrame = NSBezierPath(roundedRect: NSRect(x: 214 * scale, y: 292 * scale, width: 596 * scale, height: 118 * scale), xRadius: 34 * scale, yRadius: 34 * scale)
    bedFrame.fill()

    let headboard = NSBezierPath(roundedRect: NSRect(x: 214 * scale, y: 410 * scale, width: 104 * scale, height: 236 * scale), xRadius: 36 * scale, yRadius: 36 * scale)
    headboard.fill()

    let mattress = NSBezierPath(roundedRect: NSRect(x: 318 * scale, y: 452 * scale, width: 492 * scale, height: 146 * scale), xRadius: 42 * scale, yRadius: 42 * scale)
    mattress.fill()

    NSColor(calibratedRed: 0.16, green: 0.37, blue: 0.95, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 380 * scale, y: 512 * scale, width: 132 * scale, height: 56 * scale), xRadius: 18 * scale, yRadius: 18 * scale).fill()

    let moonRect = NSRect(x: 610 * scale, y: 548 * scale, width: 168 * scale, height: 168 * scale)
    NSColor.white.setFill()
    NSBezierPath(ovalIn: moonRect).fill()
    NSColor(calibratedRed: 0.36, green: 0.69, blue: 1.0, alpha: 1).setFill()
    NSBezierPath(ovalIn: moonRect.offsetBy(dx: 54 * scale, dy: 36 * scale)).fill()

    let zAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 112 * scale, weight: .bold),
        .foregroundColor: NSColor.white
    ]
    NSString(string: "Z").draw(at: NSPoint(x: 708 * scale, y: 704 * scale), withAttributes: zAttributes)

    image.unlockFocus()
    return image
}

func writePNG(image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw CocoaError(.fileWriteUnknown)
    }
    try png.write(to: url, options: .atomic)
}

for icon in sizes {
    let pixels = icon.points * icon.scale
    try writePNG(image: drawIcon(pixelSize: pixels), to: iconsetDirectory.appendingPathComponent(icon.name))
}

try writePNG(image: drawIcon(pixelSize: 1024), to: previewURL)

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDirectory.path, "-o", icnsURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw CocoaError(.fileWriteUnknown)
}
