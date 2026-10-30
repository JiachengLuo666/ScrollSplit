import AppKit

if CommandLine.arguments.dropFirst().first == "--require-app-closed" {
    let target = CommandLine.arguments.count > 2 ? URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL : nil
    if NSRunningApplication.runningApplications(withBundleIdentifier: "local.scrollsplit.app")
        .contains(where: { target == nil || $0.bundleURL?.standardizedFileURL == target }) {
        fputs("请先退出目标路径中的 ScrollSplit，然后重新运行构建。\n", stderr)
        exit(1)
    }
    exit(0)
}

func image(width: Int, height: Int, drawing: () -> Void) -> NSBitmapImageRep {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    drawing()
    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

func text(_ string: String, at point: NSPoint, size: CGFloat, color: NSColor, weight: NSFont.Weight = .regular) {
    (string as NSString).draw(at: point, withAttributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color
    ])
}

let output = CommandLine.arguments[1]
let version = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "2.1"
let purple = NSColor(calibratedRed: 0.38, green: 0.34, blue: 0.88, alpha: 1)
let icon = image(width: 1024, height: 1024) {
    let rect = NSRect(x: 76, y: 76, width: 872, height: 872)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    shadow.shadowBlurRadius = 32
    shadow.shadowOffset = NSSize(width: 0, height: -15)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    NSColor.white.setFill()
    NSBezierPath(roundedRect: rect, xRadius: 198, yRadius: 198).fill()
    NSGraphicsContext.restoreGraphicsState()
    let path = NSBezierPath(roundedRect: rect, xRadius: 198, yRadius: 198)
    NSGradient(starting: NSColor(calibratedRed: 0.57, green: 0.50, blue: 1, alpha: 1), ending: purple)!
        .draw(in: path, angle: -65)
    NSColor.white.withAlphaComponent(0.17).setStroke()
    let border = NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), xRadius: 198, yRadius: 198)
    border.lineWidth = 4
    border.stroke()
    for (x, up) in [(CGFloat(370), true), (CGFloat(654), false)] {
        let arrow = NSBezierPath()
        arrow.lineWidth = 64
        arrow.lineCapStyle = .round
        arrow.lineJoinStyle = .round
        arrow.move(to: NSPoint(x: x, y: up ? 295 : 729))
        arrow.line(to: NSPoint(x: x, y: up ? 729 : 295))
        arrow.move(to: NSPoint(x: x - 95, y: up ? 634 : 390))
        arrow.line(to: NSPoint(x: x, y: up ? 729 : 295))
        arrow.line(to: NSPoint(x: x + 95, y: up ? 634 : 390))
        (up ? NSColor.white : NSColor(calibratedRed: 0.81, green: 0.94, blue: 1, alpha: 1)).setStroke()
        arrow.stroke()
    }
}
try icon.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output + "/AppIcon-1024.png"))

let background = image(width: 1280, height: 1000) {
    NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.99, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: 1280, height: 1000).fill()
    let panel = NSBezierPath(roundedRect: NSRect(x: 55, y: 400, width: 1170, height: 365), xRadius: 42, yRadius: 42)
    NSGradient(starting: NSColor(calibratedRed: 0.91, green: 0.9, blue: 0.99, alpha: 1),
               ending: NSColor(calibratedRed: 0.93, green: 0.95, blue: 1, alpha: 1))!.draw(in: panel, angle: 0)
    text("ScrollSplit", at: NSPoint(x: 65, y: 865), size: 53, color: .darkGray, weight: .bold)
    text(version, at: NSPoint(x: 355, y: 875), size: 24, color: purple, weight: .semibold)
    text("先退出旧版，再拖入右侧文件夹并选择“替换”。", at: NSPoint(x: 69, y: 810), size: 24, color: .gray)
    let arrow = NSBezierPath()
    arrow.lineWidth = 6
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    arrow.move(to: NSPoint(x: 575, y: 613))
    arrow.line(to: NSPoint(x: 709, y: 613))
    arrow.move(to: NSPoint(x: 684, y: 638))
    arrow.line(to: NSPoint(x: 709, y: 613))
    arrow.line(to: NSPoint(x: 684, y: 588))
    purple.withAlphaComponent(0.6).setStroke()
    arrow.stroke()
    text("复制完成后，双击下方图标打开已安装版本", at: NSPoint(x: 255, y: 342),
         size: 28, color: .darkGray, weight: .medium)
    text("滚动设置会保留。首次打开新版如提示授权，请按界面指引操作。", at: NSPoint(x: 159, y: 47), size: 22, color: .gray)
}
try background.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output + "/dmg-background.png"))
