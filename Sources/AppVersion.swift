import Foundation

enum AppVersion {
    static let identifier = Bundle.main.bundleIdentifier ?? "local.scrollsplit.app"
    static let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.1.0"
    static let display = current.hasSuffix(".0") ? String(current.dropLast(2)) : current
}

enum LaunchRules {
    static func showWindow(isLogin: Bool, hasSeenVersion: Bool, showOnLogin: Bool) -> Bool {
        !isLogin || !hasSeenVersion || showOnLogin
    }
}

enum WindowPlacement {
    /// Fit the full frame, including the draggable title bar, inside the usable display.
    static func restoredFrame(_ frame: CGRect, in visible: CGRect, center: Bool) -> CGRect {
        let size = CGSize(width: min(frame.width, visible.width), height: min(frame.height, visible.height))
        let x = center ? visible.midX - size.width / 2 : min(max(frame.minX, visible.minX), visible.maxX - size.width)
        let y = center ? visible.midY - size.height / 2 : min(max(frame.minY, visible.minY), visible.maxY - size.height)
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }
}
