#!/usr/bin/env swift
import AppKit
import CoreText
import Foundation

enum Palette {
    static let slate = CGColor(srgbRed: 0.102, green: 0.133, blue: 0.165, alpha: 1)
    static let editorInk = CGColor(srgbRed: 0.82, green: 0.86, blue: 0.90, alpha: 1)
    static let paper = CGColor(srgbRed: 0.949, green: 0.957, blue: 0.969, alpha: 1)
    static let copper = CGColor(srgbRed: 0.78, green: 0.38, blue: 0.18, alpha: 1)
    static let pool = CGColor(srgbRed: 0.24, green: 0.49, blue: 0.56, alpha: 1)
    static let ink = CGColor(srgbRed: 0.18, green: 0.24, blue: 0.30, alpha: 0.78)
}

func drawIcon(in ctx: CGContext, size: CGFloat) {
    let rail = max(2, round(size * 0.072))
    let split = round(size * 0.40)
    let contentTop = size - rail

    ctx.setFillColor(Palette.copper)
    ctx.fill(CGRect(x: 0, y: contentTop, width: size, height: rail))

    ctx.setFillColor(Palette.slate)
    ctx.fill(CGRect(x: 0, y: 0, width: split, height: contentTop))

    ctx.setFillColor(Palette.paper)
    ctx.fill(CGRect(x: split, y: 0, width: size - split, height: contentTop))

    let gutter = max(1, round(size * 0.012))
    ctx.setFillColor(Palette.pool)
    ctx.fill(CGRect(x: split - gutter / 2, y: 0, width: gutter, height: contentTop))

    if size >= 32 {
        drawHash(in: ctx, size: size, split: split, contentTop: contentTop)
    }

    if size >= 32 {
        drawLines(in: ctx, size: size, split: split, contentTop: contentTop)
    }
}

func drawHash(in ctx: CGContext, size: CGFloat, split: CGFloat, contentTop: CGFloat) {
    let fontSize = size * (size >= 128 ? 0.42 : 0.36)
    let font = CTFontCreateWithName("SFMono-Medium" as CFString, fontSize, nil)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(cgColor: Palette.editorInk) ?? .white,
    ]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: "#", attributes: attrs))
    let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
    let x = (split - bounds.width) / 2 - bounds.minX
    let y = (contentTop - bounds.height) / 2 - bounds.minY - size * 0.02
    ctx.textPosition = CGPoint(x: round(x), y: round(y))
    CTLineDraw(line, ctx)
}

func drawLines(in ctx: CGContext, size: CGFloat, split: CGFloat, contentTop: CGFloat) {
    let inset = max(4, size * 0.08)
    let left = split + inset
    let maxWidth = size - left - inset
    let lineHeight = max(2, round(size * 0.028))
    let gap = size * 0.052
    let widths: [CGFloat] = size >= 64 ? [0.92, 0.68, 0.84, 0.46] : [0.88, 0.62]
    var y = contentTop - inset - size * 0.06 - lineHeight

    ctx.setFillColor(Palette.ink)
    for width in widths {
        let rect = CGRect(x: left, y: y, width: maxWidth * width, height: lineHeight)
        let path = CGPath(
            roundedRect: rect,
            cornerWidth: lineHeight / 2,
            cornerHeight: lineHeight / 2,
            transform: nil
        )
        ctx.addPath(path)
        ctx.fillPath()
        y -= lineHeight + gap
        if y < size * 0.08 { break }
    }
}

func renderPNG(size: Int, to url: URL) throws {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NSError(domain: "icon", code: 1)
    }
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high
    drawIcon(in: ctx, size: CGFloat(size))
    guard let image = ctx.makeImage() else { throw NSError(domain: "icon", code: 2) }

    let dest = CGDataConsumer(url: url as CFURL)!
    let destImg = CGImageDestinationCreateWithDataConsumer(dest, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destImg, image, nil)
    CGImageDestinationFinalize(destImg)
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let supporting = root.appendingPathComponent("Supporting")
let iconset = supporting.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let names: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (name, size) in names {
    try renderPNG(size: size, to: iconset.appendingPathComponent(name))
}

try renderPNG(size: 1024, to: supporting.appendingPathComponent("AppIcon-1024.png"))
print("Wrote iconset to \(iconset.path)")
