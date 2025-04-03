import AppKit
import Carbon
import Cocoa

class KeyboardShortcuts {
    static let shared = KeyboardShortcuts()
    
    private var shortcutManager = ShortcutManager.shared
    
    private init() {
        // 此类现在仅作为与ShortcutManager的兼容层
        // 保留此类以兼容现有代码，避免大量修改
    }
    
    func register(handler: @escaping () -> Void) {
        // 注册到新的ShortcutManager
        shortcutManager.registerHandler(for: .toggleClipboard, handler: handler)
    }
    
    func registerEscHandler(handler: @escaping () -> Void) {
        // ESC处理现在由AppDelegate中的localEventMonitor处理
        // 不再需要在此处实现
    }
    
    func unregisterEventMonitor() {
        // 由ShortcutManager处理
    }
    
    deinit {
        // 不再需要手动清理
    }
}