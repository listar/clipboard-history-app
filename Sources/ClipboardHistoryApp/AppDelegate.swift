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
    private var keyboardShortcuts: KeyboardShortcuts?
    
    @AppStorage("launchAtLogin") private var launchAtLogin = true
    
    override init() {
        super.init()
        // 确保在应用程序启动前就设置为菜单栏应用程序
        NSApp.setActivationPolicy(.accessory)
        NSLog("应用程序初始化：设置为菜单栏应用程序")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusItem()
        setupClipboardWindow()
        
        // 初始化快捷键管理器并注册处理函数
        setupKeyboardShortcuts()
        
        // 设置剪贴板监控
        clipboardMonitor = ClipboardMonitor()
        clipboardMonitor?.startMonitoring()
        
        if launchAtLogin {
            // 处理登录启动逻辑
            // 如果需要此功能，请引入相关框架，例如ServiceManagement
        }
        
        // 添加日志
        NSLog("应用已启动")
        
        // 确认菜单栏图标是否已创建
        if statusBarItem?.button?.image == nil {
            NSLog("警告: 菜单栏图标未能正确创建")
            // 再次尝试设置图标
            let systemIcon = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard History")
            systemIcon?.size = NSSize(width: 18, height: 18) 
            statusBarItem?.button?.image = systemIcon
        }
    }
    
    private func setupStatusItem() {
        NSLog("开始设置状态栏")
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // 直接使用系统图标作为菜单栏图标
        NSLog("使用系统图标")
        let systemIcon = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard History")
        systemIcon?.size = NSSize(width: 18, height: 18)
        statusBarItem?.button?.image = systemIcon
        
        // 检查是否成功设置图标
        if statusBarItem?.button?.image == nil {
            NSLog("警告: 图标设置失败!")
        } else {
            NSLog("图标设置成功!")
        }
        
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
    }
    
    private func setupClipboardWindow() {
        // 设置剪贴板窗口
        clipboardWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: NSScreen.main?.frame.width ?? 800, height: 300),
            styleMask: [.fullSizeContentView, .titled], // 添加titled样式以支持键盘输入
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
        
        // 确保窗口可以接收键盘输入
        clipboardWindow?.acceptsMouseMovedEvents = true
        
        // 设置背景色
        clipboardWindow?.backgroundColor = .windowBackgroundColor
    }
    
    func setupKeyboardShortcuts() {
        // 使用ShortcutManager注册全局快捷键
        registerGlobalShortcuts()
        
        // 本地快捷键监控（ESC键）
        localEventMonitor = EventMonitor(mask: .keyDown, isGlobal: false) { [weak self] event in
            if event?.keyCode == 53 { // ESC key
                self?.hideClipboardWindow()
                return nil
            }
            return event
        }
        (localEventMonitor as? EventMonitor)?.start()
    }
    
    private func registerGlobalShortcuts() {
        ShortcutManager.shared.registerHandler(for: .toggleClipboard) { [weak self] in
            self?.togglePopover(nil)
        }
        
        ShortcutManager.shared.registerHandler(for: .clearHistory) { [weak self] in
            self?.clearHistory()
        }
        
        ShortcutManager.shared.registerHandler(for: .openPreferences) { [weak self] in
            self?.showPreferences(nil)
        }
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
        
        NSLog("显示剪贴板窗口")
        
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
        
        // 注释掉搜索框自动聚焦代码，不需要自动聚焦
    }
    
    // 将私有方法修改为内部方法，允许从其他地方调用
    func hideClipboardWindowPublic() {
        NSLog("hideClipboardWindowPublic被调用")
        hideClipboardWindow()
    }
    
    private func hideClipboardWindow() {
        NSLog("隐藏剪贴板窗口")
        clipboardWindow?.orderOut(nil)
    }
    
    deinit {
        NSLog("AppDelegate deinit")
        
        // 注销KeyboardShortcuts
        keyboardShortcuts?.unregisterEventMonitor()
        
        clipboardMonitor?.stopMonitoring()
        
        // 销毁前取消快捷键注册
        ShortcutManager.shared.unregisterAllHandlers()
        (localEventMonitor as? EventMonitor)?.stop()
    }
    
    @objc private func clearHistory() {
        ClipboardStore.shared.clearItems()
    }
    
    @objc private func showPreferences(_ sender: Any?) {
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
        preferencesWindow?.isReleasedWhenClosed = false  // 窗口关闭时不释放
        
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
        aboutWindow?.isReleasedWhenClosed = false  // 窗口关闭时不释放
        
        // 显示窗口（非模态）
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // 添加应用程序激活和失活的处理方法
    func applicationDidBecomeActive(_ notification: Notification) {
        NSLog("应用程序变为活跃状态")
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        NSLog("应用程序变为非活跃状态")
    }
}

// 更新窗口代理方法
extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        NSLog("windowWillClose被调用：\(window.title)")
        
        switch window {
        case clipboardWindow:
            hideClipboardWindow()  // 不关闭窗口，只是隐藏
        case aboutWindow:
            // 不设置为nil，只是隐藏
            aboutWindow?.orderOut(nil)
            NSLog("关于窗口被隐藏")
        case preferencesWindow:
            // 不设置为nil，只是隐藏
            preferencesWindow?.orderOut(nil)
            NSLog("设置窗口被隐藏")
        default:
            break
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSLog("windowShouldClose被调用：\(sender.title)")
        
        if sender == clipboardWindow {
            hideClipboardWindow()  // 隐藏而不是关闭
            return false
        }
        
        // 关于和设置窗口关闭时不退出应用
        if sender == aboutWindow {
            sender.orderOut(nil)  // 隐藏而不是关闭
            return false
        }
        
        if sender == preferencesWindow {
            sender.orderOut(nil)  // 隐藏而不是关闭
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

// 添加NSView扩展，用于查找TextField
extension NSView {
    func findTextField() -> NSTextField? {
        // 先检查自身是否是NSTextField
        if let textField = self as? NSTextField {
            return textField
        }
        
        // 递归查找子视图
        for subview in subviews {
            if let textField = subview.findTextField() {
                return textField
            }
        }
        
        return nil
    }
}