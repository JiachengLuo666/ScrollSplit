import AppKit
import ApplicationServices
import Combine
import ServiceManagement

final class AppModel: ObservableObject {
    @Published private(set) var enabled: Bool
    @Published private(set) var horizontal: Bool
    @Published private(set) var trusted = false
    @Published private(set) var running = false
    @Published private(set) var natural: Bool?
    @Published private(set) var loginEnabled = false
    @Published private(set) var loginNeedsApproval = false
    @Published private(set) var showWindowOnLogin: Bool
    @Published var errorMessage: String?
    var onChange: (() -> Void)?
    private let defaults: UserDefaults
    private let engine = ScrollEngine()
    private var timer: Timer?
    let preview: Bool
    var hasPresentedVersion: Bool { defaults.string(forKey: "lastPresentedVersion") == AppVersion.current }
    var isInstalled: Bool {
        let path = Bundle.main.bundleURL.standardizedFileURL.path
        let userApps = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        return path.hasPrefix("/Applications/") || path.hasPrefix(userApps + "/")
    }

    var state: ScrollState {
        .resolve(enabled: enabled, trusted: trusted, running: running, natural: natural)
    }

    init(preview: Bool = false, defaults: UserDefaults = .standard) {
        self.preview = preview
        self.defaults = defaults
        enabled = defaults.object(forKey: "enabled") as? Bool ?? true
        horizontal = defaults.object(forKey: "horizontal") as? Bool ?? true
        showWindowOnLogin = defaults.bool(forKey: "showWindowOnLogin")
        if preview { enabled = true; horizontal = true; trusted = true; running = true; natural = true }
    }

    func start() {
        guard !preview else { return }
        refresh()
        timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in self?.refresh() }
        timer?.tolerance = 0.5
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    func refresh() {
        guard !preview else { onChange?(); return }
        engine.enabled = enabled
        engine.horizontal = horizontal
        engine.recover()
        let newTrust = AXIsProcessTrusted()
        let newRunning = engine.running
        let newNatural = CFPreferencesCopyValue(
            "com.apple.swipescrolldirection" as CFString, kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser, kCFPreferencesAnyHost
        ) as? Bool
        let login = SMAppService.mainApp.status
        if trusted != newTrust { trusted = newTrust }
        if running != newRunning { running = newRunning }
        if natural != newNatural { natural = newNatural }
        if loginEnabled != (login == .enabled) { loginEnabled = login == .enabled }
        if loginNeedsApproval != (login == .requiresApproval) { loginNeedsApproval = login == .requiresApproval }
        onChange?()
    }

    func setEnabled(_ value: Bool) {
        enabled = value
        if !preview { defaults.set(value, forKey: "enabled") }
        refresh()
    }

    func setHorizontal(_ value: Bool) {
        horizontal = value
        if !preview { defaults.set(value, forKey: "horizontal") }
        refresh()
    }

    func setShowWindowOnLogin(_ value: Bool) {
        showWindowOnLogin = value
        if !preview { defaults.set(value, forKey: "showWindowOnLogin") }
    }

    func markVersionPresented() {
        if !preview { defaults.set(AppVersion.current, forKey: "lastPresentedVersion") }
    }

    func revealApplication() {
        guard !preview else { return }
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }

    func setLogin(_ value: Bool) {
        guard !preview else { loginEnabled = value; return }
        do {
            if value {
                guard !Bundle.main.bundlePath.hasPrefix("/Volumes/") else {
                    errorMessage = "请先把 ScrollSplit 拖到“应用程序”，再从那里打开并设置登录启动。"
                    return
                }
                try SMAppService.mainApp.register()
            } else { try SMAppService.mainApp.unregister() }
            if SMAppService.mainApp.status == .requiresApproval { openLoginSettings() }
        } catch { errorMessage = "登录启动设置未完成：\(error.localizedDescription)" }
        refresh()
    }

    func openPermissions() {
        guard !preview else { return }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    func openTrackpadSettings() {
        guard !preview else { return }
        open("x-apple.systempreferences:com.apple.Trackpad-Settings.extension")
    }

    func openLoginSettings() {
        guard !preview else { return }
        SMAppService.openSystemSettingsLoginItems()
    }

    func reconnect() {
        guard !preview else { return }
        engine.stop()
        refresh()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        engine.stop()
    }

    func configurePreview(_ state: String) {
        guard preview else { return }
        if state == "permission" { trusted = false; running = false }
        if state == "paused" { enabled = false; running = false }
        if state == "system" { natural = false }
        if state == "unavailable" { running = false }
    }

    private func open(_ address: String) {
        if let url = URL(string: address) { NSWorkspace.shared.open(url) }
    }
}
