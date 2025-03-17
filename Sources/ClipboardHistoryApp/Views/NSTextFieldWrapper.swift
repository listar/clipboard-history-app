import SwiftUI
import AppKit

struct NSTextFieldWrapper: NSViewRepresentable {
    @Binding var text: String
    @FocusState var isFocused: Bool
    var onSubmit: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: _isFocused, onSubmit: onSubmit)
    }
    
    func makeNSView(context: Context) -> NSTextField {
        NSLog("创建标签输入框")
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.placeholderString = "新标签名称"
        textField.focusRingType = .none
        textField.bezelStyle = .roundedBezel
        textField.isBordered = true
        textField.isEditable = true
        textField.isSelectable = true
        
        NSLog("标签输入框配置完成")
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        
        if isFocused {
            NSLog("标签输入框请求焦点")
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>
        var isFocused: FocusState<Bool>
        var onSubmit: () -> Void
        
        init(text: Binding<String>, isFocused: FocusState<Bool>, onSubmit: @escaping () -> Void) {
            self.text = text
            self.isFocused = isFocused
            self.onSubmit = onSubmit
            super.init()
        }
        
        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else { return }
            NSLog("标签输入变化: %@", textField.stringValue)
            text.wrappedValue = textField.stringValue
        }
        
        func controlTextDidBeginEditing(_ notification: Notification) {
            NSLog("标签输入开始编辑")
            isFocused.wrappedValue = true
        }
        
        func controlTextDidEndEditing(_ notification: Notification) {
            NSLog("标签输入结束编辑")
            isFocused.wrappedValue = false
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                NSLog("标签输入回车提交")
                onSubmit()
                return true
            }
            return false
        }
    }
}
