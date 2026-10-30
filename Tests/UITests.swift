import AppKit

/// Run the real delegate against an inert model; never modify the user's permissions.
@main
@MainActor
enum UITests {
    static var checks = 0
    static func check(_ condition: Bool, _ message: String) {
        guard condition else { print("FAIL: \(message)"); exit(1) }
        checks += 1
    }

    static func eventually(_ message: String, _ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(3)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        check(condition(), message)
    }

    static func main() {
        let app = NSApplication.shared
        let model = AppModel(preview: true)
        let delegate = AppDelegate(model: model)
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        Task { @MainActor in
            await eventually("Launching must show the control panel.") {
                app.windows.contains { $0.title == "ScrollSplit" && $0.isVisible }
            }
            let window = app.windows.first { $0.title == "ScrollSplit" }!
            check(app.activationPolicy() == .regular, "A visible panel must appear as a normal app.")
            check(app.sendAction(NSSelectorFromString("toggleEnabled:"), to: delegate, from: nil),
                  "Status menu action must be wired.")
            check(model.state == .paused, "Menu pause must reach the shared UI model.")
            _ = app.sendAction(NSSelectorFromString("toggleEnabled:"), to: delegate, from: nil)
            check(model.state == .active, "Menu resume must reach the shared UI model.")

            let menu = app.mainMenu!.item(at: 1)!.submenu!
            menu.performActionForItem(at: 1)
            await eventually("Close command must hide the panel.") { !window.isVisible }
            check(app.activationPolicy() == .accessory, "Closing must retain the menu bar app.")
            check(!delegate.applicationShouldTerminateAfterLastWindowClosed(app), "Closing must not quit.")
            _ = delegate.applicationShouldHandleReopen(app, hasVisibleWindows: false)
            await eventually("Reopening must restore the same panel.") { window.isVisible }
            check(app.windows.filter { $0.title == "ScrollSplit" }.count == 1, "Reopening must reuse one panel.")

            window.miniaturize(nil)
            await eventually("Window should minimize.") { window.isMiniaturized }
            _ = delegate.applicationShouldHandleReopen(app, hasVisibleWindows: false)
            await eventually("Reopening must unminimize and show the window.") {
                !window.isMiniaturized && window.isVisible
            }
            app.hide(nil)
            await eventually("Window should hide with the app.") { app.isHidden }
            _ = delegate.applicationShouldHandleReopen(app, hasVisibleWindows: false)
            await eventually("Reopening must unhide the app.") { !app.isHidden && window.isVisible }
            window.setFrameOrigin(NSPoint(x: 50000, y: -50000))
            _ = delegate.applicationShouldHandleReopen(app, hasVisibleWindows: true)
            await eventually("An offscreen window must return to an available display.") {
                NSScreen.screens.contains { $0.visibleFrame.contains(window.frame) }
            }
            check(!window.isMovableByWindowBackground, "Only the title bar may drag the window.")
            menu.performActionForItem(at: 1)
            menu.performActionForItem(at: 0)
            await eventually("Open menu action must present the panel.") { window.isVisible }

            let suite = "local.scrollsplit.preferences-test.\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suite)!
            defaults.set(false, forKey: "enabled")
            defaults.set(false, forKey: "horizontal")
            let upgraded = AppModel(defaults: defaults)
            upgraded.setShowWindowOnLogin(true)
            upgraded.markVersionPresented()
            let reloaded = AppModel(defaults: defaults)
            check(!reloaded.enabled && !reloaded.horizontal, "Upgrade must preserve the original scrolling preferences.")
            check(reloaded.showWindowOnLogin && reloaded.hasPresentedVersion,
                  "Startup preference and seen version must survive relaunch.")
            defaults.removePersistentDomain(forName: suite)
            print("PASS: \(checks) UI, reopen and preference migration checks.")
            model.stop()
            exit(0)
        }
        withExtendedLifetime(delegate) { app.run() }
    }
}
