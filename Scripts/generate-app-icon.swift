import AppKit
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let colors = [CGColor(red: 0.14, green: 0.43, blue: 0.43, alpha: 1),
              CGColor(red: 0.03, green: 0.10, blue: 0.18, alpha: 1)]
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 1024, y: 0), options: [])
context.setStrokeColor(CGColor(gray: 1, alpha: 0.08))
context.setLineWidth(2)
context.strokeEllipse(in: CGRect(x: 128, y: 128, width: 768, height: 768))
context.strokeEllipse(in: CGRect(x: 155, y: 155, width: 714, height: 714))
context.setStrokeColor(CGColor(gray: 1, alpha: 0.95))
context.setLineWidth(23)
context.setLineCap(.round)
let glass = CGMutablePath()
glass.move(to: CGPoint(x: 350, y: 746)); glass.addLine(to: CGPoint(x: 674, y: 746))
glass.move(to: CGPoint(x: 350, y: 278)); glass.addLine(to: CGPoint(x: 674, y: 278))
glass.move(to: CGPoint(x: 377, y: 718))
glass.addCurve(to: CGPoint(x: 512, y: 512), control1: CGPoint(x: 377, y: 606), control2: CGPoint(x: 463, y: 554))
glass.addCurve(to: CGPoint(x: 647, y: 306), control1: CGPoint(x: 561, y: 470), control2: CGPoint(x: 647, y: 418))
glass.move(to: CGPoint(x: 647, y: 718))
glass.addCurve(to: CGPoint(x: 512, y: 512), control1: CGPoint(x: 647, y: 606), control2: CGPoint(x: 561, y: 554))
glass.addCurve(to: CGPoint(x: 377, y: 306), control1: CGPoint(x: 463, y: 470), control2: CGPoint(x: 377, y: 418))
context.addPath(glass); context.strokePath()
context.setFillColor(CGColor(red: 0.96, green: 0.79, blue: 0.48, alpha: 1))
let sand = CGMutablePath()
sand.move(to: CGPoint(x: 414, y: 329)); sand.addLine(to: CGPoint(x: 610, y: 329))
sand.addQuadCurve(to: CGPoint(x: 512, y: 434), control: CGPoint(x: 579, y: 404))
sand.addQuadCurve(to: CGPoint(x: 414, y: 329), control: CGPoint(x: 445, y: 404)); sand.closeSubpath()
context.addPath(sand); context.fillPath()
context.fillEllipse(in: CGRect(x: 506, y: 472, width: 12, height: 12))
let upper = CGMutablePath()
upper.move(to: CGPoint(x: 438, y: 635)); upper.addLine(to: CGPoint(x: 586, y: 635))
upper.addQuadCurve(to: CGPoint(x: 512, y: 557), control: CGPoint(x: 550, y: 574))
upper.addQuadCurve(to: CGPoint(x: 438, y: 635), control: CGPoint(x: 474, y: 574)); upper.closeSubpath()
context.addPath(upper); context.fillPath()
let output = URL(fileURLWithPath: "LifeIsShort/LifeIsShort/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
precondition(CGImageDestinationFinalize(destination))
