import SwiftUI
import AppKit

struct KeyboardShortcutSettingView: View {
    @StateObject private var shortcutManager = ShortcutManager.shared
    @State private var editingAction: ShortcutAction? = nil
    @State private var listeningForShortcut = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("键盘快捷键设置")
                .font(.headline)
                .padding(.bottom, 12)
                .padding(.top, 10)

            
            ForEach(ShortcutAction.allCases) { action in
                HStack {
                    Text(action.rawValue)
                        .frame(width: 120, alignment: .leading)
                    
                    Spacer()
                    
                    if editingAction == action && listeningForShortcut {
                        ShortcutRecorderView(action: action) { newCombo in
                            shortcutManager.setShortcut(for: action, to: newCombo)
                            editingAction = nil
                            listeningForShortcut = false
                        }
                    } else {
                        Button(action: {
                            editingAction = action
                            listeningForShortcut = true
                        }) {
                            Text(shortcutManager.shortcuts[action]?.displayString ?? "未设置")
                                .frame(width: 100, height: 28)
                                .padding(.horizontal, 8)
                                .background(Color(.textBackgroundColor))
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Button(action: {
                        shortcutManager.setShortcut(for: action, to: action.defaultKeyCombo)
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("恢复默认快捷键")
                }
                .padding(.vertical, 8)
            }
            
            Divider()
                .padding(.vertical, 12)
            
            HStack {
                Spacer()
                Button("重置全部") {
                    shortcutManager.resetToDefaults()
                }
                .buttonStyle(.link)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding(20)
        .frame(width: 350)
    }
}

struct ShortcutRecorderView: View {
    let action: ShortcutAction
    let onShortcutSet: (KeyCombo) -> Void
    @State private var currentEvent: NSEvent?
    @State private var lastEventKeyCode: UInt16 = 0
    @State private var lastEventModifiers: NSEvent.ModifierFlags = []
    
    var body: some View {
        ZStack {
            Text("按下键盘快捷键...")
                .frame(width: 150, height: 28)
                .padding(.horizontal, 8)
                .background(Color.accentColor.opacity(0.2))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor, lineWidth: 1)
                )
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    startListening()
                }
                .onDisappear {
                    stopListening()
                }
        }
    }
    
    private func startListening() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            self.lastEventKeyCode = event.keyCode
            self.lastEventModifiers = event.modifierFlags
            
            if let keyCode = KeyCode.fromKeyCode(event.keyCode) {
                let modifiers = ModifierFlags.from(event.modifierFlags)
                let combo = KeyCombo(key: keyCode, modifiers: modifiers)
                
                DispatchQueue.main.async {
                    onShortcutSet(combo)
                }
            }
            
            return nil  // 吞掉事件，不传递
        }
    }
    
    private func stopListening() {
        // 不需要实际实现，因为View会自动销毁
    }
}

#Preview {
    KeyboardShortcutSettingView()
} 