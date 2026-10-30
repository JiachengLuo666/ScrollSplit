import AppKit
import SwiftUI

@main
enum Preview {
    @MainActor static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let output = CommandLine.arguments[1]
        let state = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "active"
        let page = CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : "control"
        let model = AppModel(preview: true)
        model.configurePreview(state)
        let view = MainView(model: model, initialPage: page == "preferences" ? .preferences : page == "guide" ? .guide : .control)
            .frame(width: 980, height: 780)
        let hosting = NSHostingView(rootView: view)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 980, height: 780),
            styleMask: [.titled, .fullSizeContentView], backing: .buffered, defer: false)
        window.contentView = hosting
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.appearance = NSAppearance(named: .aqua)
        window.center()
        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            hosting.layoutSubtreeIfNeeded()
            guard let bitmap = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else { exit(1) }
            hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
            do {
                try bitmap.representation(using: .png, properties: [:])!
                    .write(to: URL(fileURLWithPath: output))
                print("Rendered \(page) / \(state): \(output)")
                exit(0)
            } catch { print(error); exit(1) }
        }
        app.run()
    }
}
