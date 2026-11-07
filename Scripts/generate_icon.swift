import Cocoa

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else {
    exit(1)
}

// Draw modern macOS Squircle Background with gradient
let rect = CGRect(x: 100, y: 100, width: 824, height: 824)
let path = CGPath(roundedRect: rect, cornerWidth: 180, cornerHeight: 180, transform: nil)

ctx.saveGState()
ctx.addPath(path)
ctx.clip()

// Vibrant Orange-to-Deep-Amber Gradient for XAMPP
let colorSpace = CGColorSpaceCreateDeviceRGB()
let colors = [
    NSColor(calibratedRed: 0.98, green: 0.45, blue: 0.12, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.88, green: 0.25, blue: 0.05, alpha: 1.0).cgColor
] as CFArray
let locations: [CGFloat] = [0.0, 1.0]
if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 100, y: 924), end: CGPoint(x: 924, y: 100), options: [])
}
ctx.restoreGState()

// Subtle inner border
ctx.saveGState()
ctx.addPath(path)
ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.25).cgColor)
ctx.setLineWidth(12)
ctx.strokePath()
ctx.restoreGState()

// Draw subtle drop shadow for icon elements
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 24, color: NSColor.black.withAlphaComponent(0.35).cgColor)

// Draw "X" and Server symbol
let text = "X"
let font = NSFont.systemFont(ofSize: 420, weight: .heavy)
let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.alignment = .center

let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
    .paragraphStyle: paragraphStyle
]

let attrString = NSAttributedString(string: text, attributes: attrs)
let textSize = attrString.size()
let textRect = CGRect(
    x: (size - textSize.width) / 2,
    y: (size - textSize.height) / 2 + 20,
    width: textSize.width,
    height: textSize.height
)
attrString.draw(in: textRect)
ctx.restoreGState()

// Draw green indicator dot on bottom right of the icon to symbolize "Active / Helper"
let dotRect = CGRect(x: 710, y: 220, width: 140, height: 140)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 14, color: NSColor.black.withAlphaComponent(0.3).cgColor)
ctx.setFillColor(NSColor(calibratedRed: 0.18, green: 0.80, blue: 0.44, alpha: 1.0).cgColor)
ctx.fillEllipse(in: dotRect)
ctx.setStrokeColor(NSColor.white.cgColor)
ctx.setLineWidth(10)
ctx.strokeEllipse(in: dotRect)
ctx.restoreGState()

image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiffData),
      let pngData = rep.representation(using: .png, properties: [:]) else {
    exit(1)
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"
try? pngData.write(to: URL(fileURLWithPath: outputPath))
print("Generated 1024x1024 master icon at \(outputPath)")

