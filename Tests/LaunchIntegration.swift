import AppKit

/// Launch two actual bundles under an isolated identifier; no real ScrollSplit process is touched.
@main
@MainActor
enum LaunchIntegration {
    static var checks = 0
    static var testIdentifier = ""

    static func finish(_ status: Int32) -> Never {
        NSRunningApplication.runningApplications(withBundleIdentifier: testIdentifier).forEach { _ = $0.terminate() }
        exit(status)
    }

    static func check(_ condition: Bool, _ message: String) {
        guard condition else { print("FAIL: \(message)"); finish(1) }
        checks += 1
    }

    static func eventually(_ message: String, _ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(10)
        while !condition() && Date() < deadline { try? await Task.sleep(nanoseconds: 50_000_000) }
        check(condition(), message)
    }

    static func open(_ path: String) async -> NSRunningApplication? {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        return await withCheckedContinuation { continuation in
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: path), configuration: configuration) { app, error in
                if let error { print("Launch error:", error.localizedDescription) }
                continuation.resume(returning: app)
            }
        }
    }

    static func visiblePanel(_ pid: pid_t) -> Bool {
        let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
        return windows.contains {
            ($0[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value == pid
                && ((($0[kCGWindowBounds as String] as? [String: Any])?["Height"] as? NSNumber)?.intValue ?? 0) > 100
        }
    }

    static func main() {
        let application = NSApplication.shared
        testIdentifier = CommandLine.arguments[1]
        let legacyPath = CommandLine.arguments[2]
        let currentPath = CommandLine.arguments[3]
        Task { @MainActor in
            guard let old = await open(legacyPath) else { finish(1) }
            await eventually("Legacy copy should be running.") { old.isFinishedLaunching && !old.isTerminated }
            check(!visiblePanel(old.processIdentifier), "Legacy fixture must reproduce a hidden background instance.")
            guard let upgraded = await open(currentPath) else { finish(1) }
            await eventually("New version must gracefully replace the hidden legacy process.") { old.isTerminated }
            await eventually("Installed new version must show a real window after handoff.") { visiblePanel(upgraded.processIdentifier) }
            check(NSRunningApplication.runningApplications(withBundleIdentifier: testIdentifier).count == 1,
                  "Only one scroll application may remain after handoff.")
            let configuration = NSWorkspace.OpenConfiguration()
            do {
                _ = try await NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: currentPath), configuration: configuration)
            } catch { print("Reopen error:", error.localizedDescription); finish(1) }
            await eventually("Reopening must keep the new window available.") { visiblePanel(upgraded.processIdentifier) }
            check(NSRunningApplication.runningApplications(withBundleIdentifier: testIdentifier).count == 1,
                  "Normal reopen must not create another process.")
            print("PASS: \(checks) real bundle launch and upgrade checks.")
            finish(0)
        }
        application.run()
    }
}
