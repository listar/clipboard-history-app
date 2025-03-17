import SwiftUI
import AppKit

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        NSSearchFieldWrapper(text: $text)
            .frame(maxWidth: .infinity)
    }
}

struct NSSearchFieldWrapper: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSSearchField {
        NSLog("创建搜索框")
        let searchField = NSSearchField()
        searchField.delegate = context.coordinator
        searchField.placeholderString = "搜索"
        searchField.bezelStyle = .roundedBezel
        searchField.target = context.coordinator
        searchField.action = #selector(Coordinator.searchFieldDidChange(_:))
        
        NSLog("搜索框配置: target=%@, delegate=%@", 
              String(describing: searchField.target), 
              String(describing: searchField.delegate))
        return searchField
    }
    
    func updateNSView(_ searchField: NSSearchField, context: Context) {
        NSLog("更新搜索框")
        if searchField.stringValue != text {
            searchField.stringValue = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        NSLog("创建搜索框协调器")
        return Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, NSSearchFieldDelegate {
        var text: Binding<String>
        
        init(text: Binding<String>) {
            self.text = text
            super.init()
            NSLog("协调器初始化完成")
        }
        
        @objc func searchFieldDidChange(_ sender: NSSearchField) {
            NSLog("搜索框内容变化（action）: %@", sender.stringValue)
            text.wrappedValue = sender.stringValue
        }
        
        func controlTextDidBeginEditing(_ obj: Notification) {
            NSLog("开始编辑")
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let searchField = obj.object as? NSSearchField else { return }
            NSLog("搜索框内容变化（delegate）: %@", searchField.stringValue)
            text.wrappedValue = searchField.stringValue
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            NSLog("结束编辑")
        }
    }
}
