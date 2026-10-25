import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Foundation

let context = CGContext(data: nil, width: 1200, height: 900, bitsPerComponent: 8, bytesPerRow: 4800,
                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let colors = [CGColor(red: 0.92, green: 0.76, blue: 0.55, alpha: 1), CGColor(red: 0.35, green: 0.62, blue: 0.69, alpha: 1)]
context.drawLinearGradient(CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!,
                           start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 900), options: [])
context.setFillColor(CGColor(red: 1, green: 0.9, blue: 0.65, alpha: 1))
context.fillEllipse(in: CGRect(x: 760, y: 545, width: 160, height: 160))
for (points, color) in [
    ([CGPoint(x: 0,y: 250), CGPoint(x: 340,y: 650), CGPoint(x: 700,y: 200), CGPoint(x: 1000,y: 600), CGPoint(x: 1200,y: 340)], CGColor(red: 0.31,green: 0.45,blue: 0.48,alpha: 1)),
    ([CGPoint(x: 0,y: 90), CGPoint(x: 280,y: 420), CGPoint(x: 640,y: 120), CGPoint(x: 900,y: 380), CGPoint(x: 1200,y: 120)], CGColor(red: 0.10,green: 0.28,blue: 0.31,alpha: 1))
] {
    let path = CGMutablePath(); path.move(to: CGPoint(x: 0,y: 0))
    points.forEach { path.addLine(to: $0) }; path.addLine(to: CGPoint(x: 1200,y: 0)); path.closeSubpath()
    context.setFillColor(color); context.addPath(path); context.fillPath()
}
let output = URL(fileURLWithPath: ".build/fixtures/mountain.png")
try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
precondition(CGImageDestinationFinalize(destination))
