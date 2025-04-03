import Foundation
import AppKit
import Carbon

// MARK: - 快捷键行为枚举
enum ShortcutAction: String, CaseIterable, Identifiable, Codable {
    case toggleClipboard = "显示/隐藏剪贴板"
    case clearHistory = "清空历史记录"
    case openPreferences = "打开首选项"
    
    var id: String { self.rawValue }
    
    var defaultKeyCombo: KeyCombo {
        switch self {
        case .toggleClipboard:
            return KeyCombo(key: .v, modifiers: [.command, .shift])
        case .clearHistory:
            return KeyCombo(key: .delete, modifiers: [.command, .shift])
        case .openPreferences:
            return KeyCombo(key: .comma, modifiers: [.command])
        }
    }
}

// MARK: - 按键组合结构体
struct KeyCombo: Equatable, Codable {
    let key: KeyCode
    let modifiers: ModifierFlags
    
    var displayString: String {
        let modifierSymbols = modifiers.symbolString
        return modifierSymbols + key.symbol
    }
    
    // 检查事件是否匹配此快捷键
    func matchesEvent(_ event: NSEvent) -> Bool {
        let flags = ModifierFlags.from(event.modifierFlags)
        return event.keyCode == key.rawValue && flags == modifiers
    }
}

// MARK: - 修饰键标志
struct ModifierFlags: OptionSet, Equatable, Codable {
    let rawValue: UInt
    
    static let command = ModifierFlags(rawValue: 1 << 0)
    static let shift = ModifierFlags(rawValue: 1 << 1)
    static let option = ModifierFlags(rawValue: 1 << 2)
    static let control = ModifierFlags(rawValue: 1 << 3)
    
    // 从NSEvent修饰键转换
    static func from(_ flags: NSEvent.ModifierFlags) -> ModifierFlags {
        var result: ModifierFlags = []
        if flags.contains(.command) { result.insert(.command) }
        if flags.contains(.shift) { result.insert(.shift) }
        if flags.contains(.option) { result.insert(.option) }
        if flags.contains(.control) { result.insert(.control) }
        return result
    }
    
    // 转换为符号字符串
    var symbolString: String {
        var symbols = ""
        if contains(.control) { symbols += "⌃" }
        if contains(.option) { symbols += "⌥" }
        if contains(.shift) { symbols += "⇧" }
        if contains(.command) { symbols += "⌘" }
        return symbols
    }
}

// MARK: - 按键代码枚举
enum KeyCode: UInt16, Codable, CaseIterable {
    // 字母键
    case a = 0, s = 1, d = 2, f = 3, h = 4, g = 5, z = 6, x = 7, c = 8, v = 9, b = 11
    case q = 12, w = 13, e = 14, r = 15, y = 16, t = 17, u = 32, i = 34, o = 31, p = 35
    case l = 37, j = 38, k = 40, n = 45, m = 46
    
    // 符号键
    case equals = 24, minus = 27, rightBracket = 30, leftBracket = 33
    case quote = 39, semicolon = 41, backslash = 42, comma = 43
    case slash = 44, period = 47, grave = 50
    
    // 功能键
    case `return` = 36, tab = 48, space = 49, delete = 51, escape = 53
    case forwardDelete = 117, home = 115, end = 119, pageUp = 116, pageDown = 121
    case leftArrow = 123, rightArrow = 124, downArrow = 125, upArrow = 126
    
    // 数字键
    case zero = 29, one = 18, two = 19, three = 20, four = 21
    case five = 23, six = 22, seven = 26, eight = 28, nine = 25
    
    // F功能键
    case f1 = 122, f2 = 120, f3 = 99, f4 = 118, f5 = 96, f6 = 97
    case f7 = 98, f8 = 100, f9 = 101, f10 = 109, f11 = 103, f12 = 111
    
    // 根据键码获取KeyCode实例
    static func fromKeyCode(_ keyCode: UInt16) -> KeyCode? {
        return KeyCode(rawValue: keyCode)
    }
    
    // 键的符号表示
    var symbol: String {
        switch self {
        // 字母键
        case .a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m,
             .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z:
            return String(describing: self).uppercased()
            
        // 数字键
        case .zero: return "0"
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
            
        // 特殊键
        case .space: return "空格"
        case .`return`: return "↩"
        case .tab: return "⇥"
        case .delete: return "⌫"
        case .forwardDelete: return "⌦"
        case .escape: return "⎋"
        case .leftArrow: return "←"
        case .rightArrow: return "→"
        case .downArrow: return "↓"
        case .upArrow: return "↑"
        case .home: return "↖"
        case .end: return "↘"
        case .pageUp: return "⇞"
        case .pageDown: return "⇟"
            
        // 符号键
        case .equals: return "="
        case .minus: return "-"
        case .rightBracket: return "]"
        case .leftBracket: return "["
        case .quote: return "'"
        case .semicolon: return ";"
        case .backslash: return "\\"
        case .comma: return ","
        case .slash: return "/"
        case .period: return "."
        case .grave: return "`"
            
        // F键
        case .f1: return "F1"
        case .f2: return "F2"
        case .f3: return "F3"
        case .f4: return "F4"
        case .f5: return "F5"
        case .f6: return "F6"
        case .f7: return "F7"
        case .f8: return "F8"
        case .f9: return "F9"
        case .f10: return "F10"
        case .f11: return "F11"
        case .f12: return "F12"
        }
    }
}

// MARK: - 快捷键管理器
class ShortcutManager: ObservableObject {
    static let shared = ShortcutManager()
    
    @Published var shortcuts: [ShortcutAction: KeyCombo]
    private var handlers: [ShortcutAction: () -> Void] = [:]
    private var eventMonitor: Any?
    
    private init() {
        // 从UserDefaults加载快捷键，如果没有则使用默认值
        if let savedShortcuts = UserDefaults.standard.data(forKey: "keyboardShortcuts"),
           let decoded = try? JSONDecoder().decode([ShortcutAction: KeyCombo].self, from: savedShortcuts) {
            self.shortcuts = decoded
        } else {
            // 使用默认快捷键
            self.shortcuts = [:]
            resetToDefaults()
        }
        
        // 设置全局事件监控
        setupEventMonitor()
    }
    
    func registerHandler(for action: ShortcutAction, handler: @escaping () -> Void) {
        handlers[action] = handler
    }
    
    func unregisterHandler(for action: ShortcutAction) {
        handlers.removeValue(forKey: action)
    }
    
    func unregisterAllHandlers() {
        handlers.removeAll()
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    func setShortcut(for action: ShortcutAction, to combo: KeyCombo) {
        shortcuts[action] = combo
        saveShortcuts()
    }
    
    func resetToDefaults() {
        for action in ShortcutAction.allCases {
            shortcuts[action] = action.defaultKeyCombo
        }
        saveShortcuts()
    }
    
    private func saveShortcuts() {
        if let encoded = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(encoded, forKey: "keyboardShortcuts")
        }
    }
    
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            
            // 检查每个注册的快捷键
            for (action, combo) in self.shortcuts {
                if combo.matchesEvent(event) {
                    // 调用关联的处理函数
                    DispatchQueue.main.async {
                        self.handlers[action]?()
                    }
                    break
                }
            }
        }
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
} 