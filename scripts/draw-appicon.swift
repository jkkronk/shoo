// draw-appicon.swift — draws the 1024×1024 app icon master (art/AppIcon-1024.png).
//
// An original raised hand (capsule fingers, a palm, an angled thumb) in a blue gradient on a
// light plate laid out on the macOS icon grid (824 pt body, 100 pt margins). It's drawn from
// basic shapes on purpose: Apple emoji and SF Symbols aren't allowed in app icons.
//
// Usage:  swift scripts/draw-appicon.swift art/AppIcon-1024.png && bash scripts/make-appicon.sh
import AppKit
import CoreGraphics

let size: CGFloat = 1024
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(
    data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
    space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
// Work top-down (y grows downward).
ctx.translateBy(x: 0, y: size)
ctx.scaleBy(x: 1, y: -1)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func gradient(_ top: UInt32, _ bottom: UInt32) -> CGGradient {
    CGGradient(colorsSpace: colorSpace, colors: [color(top), color(bottom)] as CFArray, locations: [0, 1])!
}

// Plate: soft shadow and a light vertical gradient.
let plateRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let plate = CGPath(roundedRect: plateRect, cornerWidth: 185, cornerHeight: 185, transform: nil)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: color(0x000000, 0.22))
ctx.addPath(plate)
ctx.setFillColor(color(0xFFFFFF))
ctx.fillPath()
ctx.restoreGState()
ctx.saveGState()
ctx.addPath(plate)
ctx.clip()
ctx.drawLinearGradient(gradient(0xFFFFFF, 0xE4ECF6), start: CGPoint(x: 0, y: 100), end: CGPoint(x: 0, y: 924), options: [])
ctx.restoreGState()

// Hand.
let hand = CGMutablePath()

/// A finger: a capsule standing on `base`, rotated by `degrees` (positive leans right).
func capsule(base: CGPoint, length: CGFloat, width: CGFloat, degrees: CGFloat) {
    var transform = CGAffineTransform(translationX: base.x, y: base.y).rotated(by: degrees * .pi / 180)
    let rect = CGRect(x: -width / 2, y: -length, width: width, height: length)
    hand.addPath(CGPath(roundedRect: rect, cornerWidth: width / 2, cornerHeight: width / 2, transform: &transform))
}

/// The palm: small top corners (hidden under the outer fingers) and large bottom corners. Its
/// sides line up with the outer edges of the little and index fingers where they meet, so the
/// outline runs on without a notch.
func palm(_ rect: CGRect, top: CGFloat, bottom: CGFloat) -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.maxY), radius: top)
    path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: rect.maxY), radius: bottom)
    path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: rect.minY), radius: bottom)
    path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.minY), radius: top)
    path.closeSubpath()
    return path
}

hand.addPath(palm(CGRect(x: 321, y: 500, width: 338, height: 310), top: 20, bottom: 150))
capsule(base: CGPoint(x: 362, y: 620), length: 270, width: 82, degrees: -9)   // little finger
capsule(base: CGPoint(x: 447, y: 620), length: 350, width: 84, degrees: -3)   // ring
capsule(base: CGPoint(x: 533, y: 620), length: 375, width: 86, degrees: 2)    // middle
capsule(base: CGPoint(x: 617, y: 620), length: 330, width: 84, degrees: 7)    // index
capsule(base: CGPoint(x: 600, y: 730), length: 290, width: 100, degrees: 50)  // thumb, rooted inside the palm

// Centre the hand optically on the plate at ~64% of its height.
let box = hand.boundingBoxOfPath
let scale = (plateRect.height * 0.64) / box.height
var fit = CGAffineTransform(translationX: plateRect.midX, y: plateRect.midY + 6)
    .scaledBy(x: scale, y: scale)
    .translatedBy(x: -box.midX, y: -box.midY)
let placed = hand.copy(using: &fit)!

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 18, color: color(0x1F4FB0, 0.28))
ctx.addPath(placed)
ctx.setFillColor(color(0x2F7FF0))
ctx.fillPath()
ctx.restoreGState()
ctx.saveGState()
ctx.addPath(placed)
ctx.clip()
let handBox = placed.boundingBoxOfPath
ctx.drawLinearGradient(gradient(0x4FA8FF, 0x1C5FD8), start: CGPoint(x: 0, y: handBox.minY), end: CGPoint(x: 0, y: handBox.maxY), options: [])
ctx.restoreGState()

let output = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "art/AppIcon-1024.png")
let png = NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
try png.write(to: output)
print("Wrote \(output.path)")
