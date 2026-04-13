#!/usr/bin/env swift
// Generates the Hum app icon as an .icns file using only AppKit.

import AppKit

let size = 1024
let img = NSImage(size: NSSize(width: size, height: size))

img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// -- Background: rounded rect with warm gradient --
let bounds = CGRect(x: 0, y: 0, width: size, height: size)
let cornerRadius: CGFloat = CGFloat(size) * 0.22
let path = CGPath(roundedRect: bounds.insetBy(dx: 4, dy: 4),
                  cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

let colors = [
    NSColor(red: 0.18, green: 0.15, blue: 0.28, alpha: 1.0).cgColor,  // deep purple-grey
    NSColor(red: 0.12, green: 0.10, blue: 0.22, alpha: 1.0).cgColor   // darker base
]
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: colors as CFArray,
                          locations: [0.0, 1.0])!

ctx.saveGState()
ctx.addPath(path)
ctx.clip()
ctx.drawLinearGradient(gradient,
                       start: CGPoint(x: 0, y: CGFloat(size)),
                       end: CGPoint(x: CGFloat(size), y: 0),
                       options: [])
ctx.restoreGState()

// -- Draw sound wave bars (centered, simple visualizer style) --
let barColor = NSColor(red: 0.55, green: 0.45, blue: 0.85, alpha: 1.0)  // soft purple
let barHighlight = NSColor(red: 0.75, green: 0.60, blue: 1.0, alpha: 1.0) // lighter

let barCount = 5
let barWidth: CGFloat = 60
let barGap: CGFloat = 40
let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barGap
let startX = (CGFloat(size) - totalWidth) / 2.0
let centerY = CGFloat(size) / 2.0

// Heights as ratios of max height
let barHeights: [CGFloat] = [0.3, 0.6, 1.0, 0.7, 0.4]
let maxBarHeight: CGFloat = 400

for i in 0..<barCount {
    let x = startX + CGFloat(i) * (barWidth + barGap)
    let h = barHeights[i] * maxBarHeight
    let y = centerY - h / 2.0
    let barRect = CGRect(x: x, y: y, width: barWidth, height: h)
    let barPath = CGPath(roundedRect: barRect, cornerWidth: barWidth / 2, cornerHeight: barWidth / 2, transform: nil)

    // Gradient on each bar
    ctx.saveGState()
    ctx.addPath(barPath)
    ctx.clip()

    let barColors = [barHighlight.cgColor, barColor.cgColor]
    let barGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                             colors: barColors as CFArray,
                             locations: [0.0, 1.0])!
    ctx.drawLinearGradient(barGrad,
                           start: CGPoint(x: x, y: y + h),
                           end: CGPoint(x: x, y: y),
                           options: [])
    ctx.restoreGState()
}

img.unlockFocus()

// -- Save as 1024x1024 PNG --
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let resourcesDir = scriptDir.appendingPathComponent("Resources")
let iconsetDir = resourcesDir.appendingPathComponent("Hum.iconset")

try FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

let tiffData = img.tiffRepresentation!
let bitmap = NSBitmapImageRep(data: tiffData)!
let pngData = bitmap.representation(using: .png, properties: [:])!

// Generate all required icon sizes
let iconSizes: [(String, Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for (name, px) in iconSizes {
    let resized = NSImage(size: NSSize(width: px, height: px))
    resized.lockFocus()
    img.draw(in: NSRect(x: 0, y: 0, width: px, height: px),
             from: NSRect(x: 0, y: 0, width: 1024, height: 1024),
             operation: .copy, fraction: 1.0)
    resized.unlockFocus()

    let tiff = resized.tiffRepresentation!
    let bmp = NSBitmapImageRep(data: tiff)!
    let png = bmp.representation(using: .png, properties: [:])!
    let path = iconsetDir.appendingPathComponent("\(name).png")
    try png.write(to: path)
}

print("Iconset created at \(iconsetDir.path)")
print("Run: iconutil -c icns \(iconsetDir.path) -o \(resourcesDir.path)/Hum.icns")
