import AppKit
import SwiftUI
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let model: AppModel
    private var statusItem: NSStatusItem!
    private var stateItem: NSMenuItem!
    private var enableItem: NSMenuItem!
    private var window: NSWindow?
    private var ready = false
    private var openRequested = false
    private var presentation: DispatchWorkItem?
    private var handoffTimer: Timer?
    private let openNotification = Notification.Name("local.scrollsplit.show-window")

    init(model: AppModel = AppModel()) {
        self.model = model
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let isLogin = NSAppleEventManager.shared().currentAppleEvent?
            .paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
        openRequested = openRequested || LaunchRules.showWindow(
            isLogin: isLogin, hasSeenVersion: model.hasPresentedVersion, showOnLogin: model.showWindowOnLogin)
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(receiveOpenRequest), name: openNotification,
            object: String(ProcessInfo.processInfo.processIdentifier))
        // UI tests have their own model and must never stop the user's running copy.
        let peers = model.preview ? [] : NSRunningApplication.runningApplications(withBundleIdentifier: AppVersion.identifier)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier && !$0.isTerminated }
        guard !peers.isEmpty else { finishLaunching(); return }
        if isLogin {
            // A background login item must not replace an explicitly opened instance.
            NSApp.terminate(nil)
            return
        }
        // If two launches race, the later process owns the handoff.
        if peers.contains(where: { !$0.isFinishedLaunching && $0.processIdentifier > ProcessInfo.processInfo.processIdentifier }) {
            NSApp.terminate(nil)
            return
        }
        if let newer = peers.first(where: { peer in
            let version = peer.bundleURL.flatMap { Bundle(url: $0) }?
                .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
            return version.compare(AppVersion.current, options: .numeric) == .orderedDescending
        }) {
            DistributedNotificationCenter.default().postNotificationName(
                openNotification, object: String(newer.processIdentifier), userInfo: nil, deliverImmediately: true)
            newer.activate(options: [.activateIgnoringOtherApps])
            NSApp.terminate(nil)
            return
        }
        // 2.0 could redirect the installed app to a hidden copy in a temporary folder.
        // Stop old instances gracefully and wait before starting another scroll tap.
        peers.forEach { _ = $0.terminate() }
        let deadline = Date().addingTimeInterval(5)
        handoffTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if peers.allSatisfy(\.isTerminated) {
                timer.invalidate()
                self.handoffTimer = nil
                self.finishLaunching()
            } else if Date() >= deadline {
                timer.invalidate()
                self.handoffTimer = nil
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                let alert = NSAlert()
                alert.messageText = "请先退出正在运行的 ScrollSplit"
                alert.informativeText = "旧版本没有完成退出。请从旧版菜单栏选择“退出”，然后再次打开新版。"
                alert.addButton(withTitle: "知道了")
                alert.runModal()
                NSApp.terminate(nil)
            }
        }
    }

    private func finishLaunching() {
        guard !ready else { return }
        ready = true
        makeApplicationMenu()
        makeStatusMenu()
        model.onChange = { [weak self] in self?.updateStatus() }
        model.start()
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(didWake), name: NSWorkspace.didWakeNotification, object: nil)
        if openRequested { showWindow(nil) }
    }

    private func makeApplicationMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        add("关于 ScrollSplit", action: #selector(showWindow), key: "", to: appMenu)
        appMenu.addItem(.separator())
        add("隐藏 ScrollSplit", action: #selector(NSApplication.hide(_:)), key: "h", to: appMenu, target: NSApp)
        add("退出 ScrollSplit", action: #selector(quit), key: "q", to: appMenu)
        appItem.submenu = appMenu
        menu.addItem(appItem)
        let windowItem = NSMenuItem(title: "窗口", action: nil, keyEquivalent: "")
        let windowMenu = NSMenu(title: "窗口")
        add("打开控制面板", action: #selector(showWindow), key: "0", to: windowMenu)
        add("关闭窗口", action: #selector(closeWindow), key: "w", to: windowMenu)
        windowItem.submenu = windowMenu
        menu.addItem(windowItem)
        NSApp.mainMenu = menu
    }

    private func makeStatusMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.imagePosition = .imageLeading
        let menu = NSMenu()
        stateItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        menu.addItem(stateItem)
        menu.addItem(.separator())
        add("打开 ScrollSplit…", action: #selector(showWindow), key: "", to: menu)
        enableItem = add("暂停独立滚动", action: #selector(toggleEnabled), key: "", to: menu)
        add("辅助功能权限…", action: #selector(openPermissions), key: "", to: menu)
        menu.addItem(.separator())
        add("退出 ScrollSplit", action: #selector(quit), key: "", to: menu)
        statusItem.menu = menu
    }

    private func updateStatus() {
        guard statusItem != nil else { return }
        let state = model.state
        statusItem.button?.title = " \(state.title)"
        let image = NSImage(systemSymbolName: state.symbol, accessibilityDescription: state.title)
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        statusItem.button?.toolTip = "ScrollSplit · \(state.detail)"
        statusItem.button?.setAccessibilityLabel("ScrollSplit，\(state.title)")
        stateItem.title = "ScrollSplit \(AppVersion.display) · \(state.title)"
        enableItem.title = model.enabled ? "暂停独立滚动" : "恢复独立滚动"
    }

    @discardableResult
    private func add(_ title: String, action: Selector, key: String,
                     to menu: NSMenu, target: AnyObject? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = target ?? self
        menu.addItem(item)
        return item
    }

    @objc private func showWindow(_ sender: Any?) {
        openRequested = true
        guard ready else { return }
        if window == nil {
            let controller = NSHostingController(rootView: MainView(model: model))
            let newWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 980, height: 780),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered, defer: false)
            newWindow.title = "ScrollSplit"
            newWindow.titleVisibility = .hidden
            newWindow.titlebarAppearsTransparent = true
            // Keep native title-bar dragging without dragging from the SwiftUI content.
            newWindow.isMovableByWindowBackground = false
            newWindow.contentViewController = controller
            newWindow.minSize = NSSize(width: 860, height: 600)
            newWindow.setContentSize(NSSize(width: 980, height: 780))
            newWindow.isReleasedWhenClosed = false
            newWindow.delegate = self
            newWindow.backgroundColor = NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.985, alpha: 1)
            newWindow.appearance = NSAppearance(named: .aqua)
            newWindow.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
            newWindow.center()
            window = newWindow
        }
        presentation?.cancel()
        // Dock/activation changes settle on the next run loop. Presenting synchronously
        // from didFinishLaunching could leave an accessory app's window behind other apps.
        NSApp.setActivationPolicy(.regular)
        let work = DispatchWorkItem { [weak self] in self?.presentWindow() }
        presentation = work
        DispatchQueue.main.async(execute: work)
    }

    private func presentWindow() {
        guard openRequested, let window else { return }
        let wasHidden = !window.isVisible || window.isMiniaturized || NSApp.isHidden
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.main {
            window.minSize = NSSize(width: min(860, screen.visibleFrame.width), height: min(600, screen.visibleFrame.height))
            let titleBar = CGRect(x: window.frame.minX, y: window.frame.maxY - 28, width: window.frame.width, height: 28)
            let titleIsVisible = NSScreen.screens.contains { $0.visibleFrame.intersects(titleBar) }
            if wasHidden || !titleIsVisible || !screen.visibleFrame.contains(window.frame) {
                window.setFrame(WindowPlacement.restoredFrame(window.frame, in: screen.visibleFrame,
                                                               center: wasHidden || !titleIsVisible), display: false)
            }
        }
        NSApp.unhide(nil)
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        model.markVersionPresented()
        model.refresh()
    }

    @objc private func receiveOpenRequest(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in self?.showWindow(nil) }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow(nil)
        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) { model.refresh() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func windowWillClose(_ notification: Notification) {
        openRequested = false
        presentation?.cancel()
        NSApp.setActivationPolicy(.accessory)
    }
    @objc private func closeWindow(_ sender: Any?) { window?.performClose(nil) }
    @objc private func toggleEnabled(_ sender: Any?) { model.setEnabled(!model.enabled) }
    @objc private func openPermissions(_ sender: Any?) { model.openPermissions() }
    @objc private func didWake(_ notification: Notification) { model.refresh() }
    @objc private func quit(_ sender: Any?) { NSApp.terminate(nil) }

    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
        presentation?.cancel()
        handoffTimer?.invalidate()
        model.stop()
    }
}

#if !UI_TEST
@main
enum ScrollSplitApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}
#endif
