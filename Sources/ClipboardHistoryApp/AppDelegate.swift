import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarItem: NSStatusItem?
    private var clipboardMonitor: ClipboardMonitor?
    private var clipboardWindow: NSWindow?  // 替换 popover
    private var globalHotKey: Any?
    private var aboutWindow: NSWindow?  // 添加窗口引用
    private var preferencesWindow: NSWindow?  // 添加 preferences 窗口引用
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupGlobalHotKey()
        clipboardMonitor = ClipboardMonitor()
        clipboardMonitor?.startMonitoring()
    }
    
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem?.button?.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard History")
        
        // Create menu
        let menu = NSMenu()
        
        // Add menu items
        menu.addItem(NSMenuItem(title: "Show Clipboard List", action: #selector(togglePopover), keyEquivalent: "V"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About Clipboard History", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        // Attach menu to status item
        statusBarItem?.menu = menu
        
        // 设置剪贴板窗口
        clipboardWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: NSScreen.main?.frame.width ?? 800, height: 300),
            styleMask: [.fullSizeContentView], // 只保留 fullSizeContentView
            backing: .buffered,
            defer: false
        )
        
        clipboardWindow?.title = "Clipboard History"
        clipboardWindow?.titlebarAppearsTransparent = true
        clipboardWindow?.titleVisibility = .hidden
        clipboardWindow?.standardWindowButton(.closeButton)?.isHidden = true
        clipboardWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        clipboardWindow?.standardWindowButton(.zoomButton)?.isHidden = true
        clipboardWindow?.contentViewController = NSHostingController(
            rootView: ClipboardHistoryView()
                .environment(\.colorScheme, .light)
        )
        clipboardWindow?.delegate = self
        
        // 设置窗口级别为浮动窗口
        clipboardWindow?.level = .floating
        
        // 窗口默认隐藏
        clipboardWindow?.isReleasedWhenClosed = false
        
        // 禁止窗口移动
        clipboardWindow?.isMovable = false
        
        // 设置背景色
        clipboardWindow?.backgroundColor = .windowBackgroundColor
    }
    
    private func setupGlobalHotKey() {
        // 注册本地事件监听器（当应用程序活跃时）
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil // 事件被处理，不再传递
            }
            return event // 继续传递事件
        }
        
        // 注册全局事件监听器（当应用程序不活跃时）
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            _ = self?.handleKeyEvent(event) // 使用 _ = 显式忽略返回值
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        // 检查是否是 Cmd+Shift+V
        if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 9 { // V key
            DispatchQueue.main.async { [weak self] in
                self?.togglePopover(nil)
            }
            return true
        }
        
        // 检查 ESC 键
        if event.keyCode == 53 && clipboardWindow?.isVisible == true { // ESC key
            DispatchQueue.main.async { [weak self] in
                self?.hideClipboardWindow()
            }
            return true
        }
        
        return false
    }
    
    @objc private func togglePopover(_ sender: Any?) {
        if clipboardWindow?.isVisible == true {
            hideClipboardWindow()
        } else {
            showClipboardWindow()
        }
    }
    
    private func showClipboardWindow() {
        guard let window = clipboardWindow,
              let screen = NSScreen.main else { return }
        
        // 计算窗口位置（底部居中）
        let screenFrame = screen.frame
        let windowFrame = NSRect(
            x: 0,
            y: 0, // 底部
            width: screenFrame.width, // 全宽
            height: 300 // 固定高度
        )
        
        // 设置窗口框架
        window.setFrame(windowFrame, display: true)
        
        // 显示窗口并激活
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func hideClipboardWindow() {
        clipboardWindow?.orderOut(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 移除所有事件监听器
        if let localMonitor = localEventMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        if let globalMonitor = globalEventMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        clipboardMonitor?.stopMonitoring()
    }
    
    @objc private func clearHistory() {
        ClipboardStore.shared.clearItems()
    }
    
    @objc private func showPreferences() {
        // 如果窗口已经存在，就把它带到前面
        if let window = preferencesWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // 创建新窗口
        preferencesWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        preferencesWindow?.title = "Preferences"
        preferencesWindow?.contentViewController = NSHostingController(rootView: PreferencesView())
        preferencesWindow?.center()
        preferencesWindow?.delegate = self
        
        // 显示窗口（非模态）
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func showAbout() {
        // 如果窗口已经存在，就把它带到前面
        if let window = aboutWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // 创建新窗口
        aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        aboutWindow?.title = "About"
        aboutWindow?.contentViewController = NSHostingController(
            rootView: AboutView()
        )
        aboutWindow?.center()
        aboutWindow?.setContentSize(aboutWindow?.contentViewController!.view.fittingSize ?? NSSize(width: 300, height: 200))
        aboutWindow?.delegate = self
        
        // 显示窗口（非模态）
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// 更新窗口代理方法
extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        switch window {
        case clipboardWindow:
            hideClipboardWindow()  // 不关闭窗口，只是隐藏
        case aboutWindow:
            aboutWindow = nil
        case preferencesWindow:
            preferencesWindow = nil
        default:
            break
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender == clipboardWindow {
            hideClipboardWindow()  // 隐藏而不是关闭
            return false
        }
        return true
    }
    
    // 添加窗口框架监听
    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window == clipboardWindow,
              let screen = NSScreen.main else { return }
        
        // 保持窗口宽度等于屏幕宽度
        var frame = window.frame
        frame.size.width = screen.frame.width
        frame.size.height = 300
        frame.origin.y = 0
        window.setFrame(frame, display: true)
    }
}