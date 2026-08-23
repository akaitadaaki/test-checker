#!/usr/bin/env swift
import AppKit
import Foundation

enum Palette {
    static let slate = CGColor(srgbRed: 0.102, green: 0.133, blue: 0.165, alpha: 1)
    static let editorInk = CGColor(srgbRed: 0.82, green: 0.86, blue: 0.90, alpha: 1)
    static let paper = CGColor(srgbRed: 0.949, green: 0.957, blue: 0.969, alpha: 1)
    static let copper = CGColor(srgbRed: 0.78, green: 0.38, blue: 0.18, alpha: 1)
    static let pool = CGColor(srgbRed: 0.24, green: 0.49, blue: 0.56, alpha: 1)
    static let ink = CGColor(srgbRed: 0.18, green: 0.24, blue: 0.30, alpha: 0.78)
    static let pass = CGColor(srgbRed: 0.20, green: 0.62, blue: 0.38, alpha: 1)
    static let fail = CGColor(srgbRed: 0.80, green: 0.27, blue: 0.25, alpha: 1)
}

func drawIcon(in ctx: CGContext, size: CGFloat) {
    // 背景: スレート。上端にコッパーのレール(md-reader 由来の家族感)
    let rail = max(2, round(size * 0.072))
    ctx.setFillColor(Palette.slate)
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
    ctx.setFillColor(Palette.copper)
    ctx.fill(CGRect(x: 0, y: size - rail, width: size, height: rail))

    // 紙のカード
    let inset = size * 0.12
    let card = CGRect(x: inset, y: inset * 0.9, width: size - inset * 2, height: size - rail - inset * 1.7)
    let radius = size * 0.05
    ctx.setFillColor(Palette.paper)
    ctx.addPath(CGPath(roundedRect: card, cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.fillPath()

    guard size >= 32 else {
        // 極小サイズは緑チェック1つだけ
        drawCheck(in: ctx, box: card.insetBy(dx: card.width * 0.2, dy: card.height * 0.2), color: Palette.pass, lineWidth: max(2, size * 0.1))
        return
    }

    // 行: [状態ボックス] [テキスト線]
    let rows: [(status: Status, width: CGFloat)] = [(.pass, 0.9), (.fail, 0.62), (.pass, 0.78), (.empty, 0.5)]
    let rowCount = size >= 64 ? rows.count : 3
    let padding = card.width * 0.1
    let rowHeight = (card.height - padding * 2) / CGFloat(rowCount)
    let box = rowHeight * 0.6
    let lineHeight = max(2, round(size * 0.03))

    for (i, row) in rows.prefix(rowCount).enumerated() {
        let centerY = card.maxY - padding - rowHeight * (CGFloat(i) + 0.5)
        let boxRect = CGRect(x: card.minX + padding, y: centerY - box / 2, width: box, height: box)
        drawBox(in: ctx, rect: boxRect, status: row.status, size: size)

        let lineX = boxRect.maxX + padding * 0.8
        let maxWidth = card.maxX - padding - lineX
        let lineRect = CGRect(x: lineX, y: centerY - lineHeight / 2, width: maxWidth * row.width, height: lineHeight)
        ctx.setFillColor(Palette.ink)
        ctx.addPath(CGPath(roundedRect: lineRect, cornerWidth: lineHeight / 2, cornerHeight: lineHeight / 2, transform: nil))
        ctx.fillPath()
    }
}

enum Status { case pass, fail, empty }

func drawBox(in ctx: CGContext, rect: CGRect, status: Status, size: CGFloat) {
    let radius = rect.width * 0.22
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    let stroke = max(1.5, size * 0.02)
    switch status {
    case .pass:
        ctx.setFillColor(Palette.pass)
        ctx.addPath(path); ctx.fillPath()
        drawCheck(in: ctx, box: rect, color: Palette.paper, lineWidth: stroke * 1.4)
    case .fail:
        ctx.setFillColor(Palette.fail)
        ctx.addPath(path); ctx.fillPath()
        drawCross(in: ctx, box: rect, color: Palette.paper, lineWidth: stroke * 1.4)
    case .empty:
        ctx.setStrokeColor(Palette.ink)
        ctx.setLineWidth(stroke)
        ctx.addPath(CGPath(roundedRect: rect.insetBy(dx: stroke / 2, dy: stroke / 2), cornerWidth: radius, cornerHeight: radius, transform: nil))
        ctx.strokePath()
    }
}

func drawCheck(in ctx: CGContext, box: CGRect, color: CGColor, lineWidth: CGFloat) {
    ctx.setStrokeColor(color)
    ctx.setLineWidth(lineWidth)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.move(to: CGPoint(x: box.minX + box.width * 0.24, y: box.minY + box.height * 0.5))
    ctx.addLine(to: CGPoint(x: box.minX + box.width * 0.43, y: box.minY + box.height * 0.3))
    ctx.addLine(to: CGPoint(x: box.minX + box.width * 0.77, y: box.minY + box.height * 0.7))
    ctx.strokePath()
}

func drawCross(in ctx: CGContext, box: CGRect, color: CGColor, lineWidth: CGFloat) {
    ctx.setStrokeColor(color)
    ctx.setLineWidth(lineWidth)
    ctx.setLineCap(.round)
    let r = box.insetBy(dx: box.width * 0.28, dy: box.height * 0.28)
    ctx.move(to: CGPoint(x: r.minX, y: r.minY)); ctx.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
    ctx.move(to: CGPoint(x: r.minX, y: r.maxY)); ctx.addLine(to: CGPoint(x: r.maxX, y: r.minY))
    ctx.strokePath()
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
