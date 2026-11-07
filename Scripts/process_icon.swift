import Cocoa

let inputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/icon_master.jpg"
let outputPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "Resources/icon_1024.png"

guard let sourceImage = NSImage(contentsOfFile: inputPath) else {
    print("Error: Could not load \(inputPath)")
    exit(1)
}

let canvasSize: CGFloat = 1024
let outputImage = NSImage(size: NSSize(width: canvasSize, height: canvasSize))
outputImage.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else {
    print("Error: Could not get CGContext")
    exit(1)
}

// macOS standard icon squircle dimensions (centered in 1024x1024)
let iconRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 185
let squirclePath = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

// 1. Draw subtle ambient drop shadow under the squircle
ctx.saveGState()
ctx.setShadow(
    offset: CGSize(width: 0, height: -14),
    blur: 28,
    color: NSColor.black.withAlphaComponent(0.40).cgColor
)
ctx.setFillColor(NSColor.black.cgColor)
ctx.addPath(squirclePath)
ctx.fillPath()
ctx.restoreGState()

// 2. Draw second contact shadow
ctx.saveGState()
ctx.setShadow(
    offset: CGSize(width: 0, height: -4),
    blur: 10,
    color: NSColor.black.withAlphaComponent(0.25).cgColor
)
ctx.setFillColor(NSColor.black.cgColor)
ctx.addPath(squirclePath)
ctx.fillPath()
ctx.restoreGState()

// 3. Clip to squircle and draw image
ctx.saveGState()
ctx.addPath(squirclePath)
ctx.clip()

// Draw the generated source image into the squircle
if let cgImage = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
    ctx.draw(cgImage, in: iconRect)
} else {
    sourceImage.draw(in: iconRect)
}
ctx.restoreGState()

// 4. Draw refined Apple-style inner highlight / rim border
ctx.saveGState()
ctx.addPath(squirclePath)
ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.25).cgColor)
ctx.setLineWidth(4)
ctx.strokePath()
ctx.restoreGState()

outputImage.unlockFocus()

guard let tiffData = outputImage.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiffData),
      let pngData = rep.representation(using: .png, properties: [:]) else {
    print("Error: Could not encode PNG")
    exit(1)
}

try pngData.write(to: URL(fileURLWithPath: outputPath))
print("Successfully generated masked macOS icon at \(outputPath)")

