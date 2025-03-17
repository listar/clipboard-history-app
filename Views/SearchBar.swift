// ...existing code...

struct NSSearchFieldWrapper: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField()
        searchField.delegate = context.coordinator
        searchField.placeholderString = "搜索"
        searchField.focusRingType = .none
        searchField.bezelStyle = .roundedBezel
        searchField.isBordered = false
        searchField.isEditable = true  // 确保可编辑
        searchField.isSelectable = true // 确保可选择
        
        // 自定义外观
        if let cell = searchField.cell as? NSSearchFieldCell {
            cell.searchButtonCell = nil
            cell.cancelButtonCell = nil
            cell.placeholderAttributedString = NSAttributedString(
                string: "搜索",
                attributes: [
                    .foregroundColor: NSColor.placeholderTextColor,
                    .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
                ]
            )
        }
        
        return searchField
    }
    
    // ...existing code...
}
