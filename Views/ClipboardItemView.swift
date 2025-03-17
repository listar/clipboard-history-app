// ...existing code...

struct ClipboardItemView: View {
    // ...existing properties...
    
    var body: some View {
        Button {
            item.copyToPasteboard()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // ...existing content...
            }
            .padding()
            .frame(width: 250, height: 200)  // 增加高度和宽度
            .background {
                // ...existing background...
            }
        }
        // ...existing modifiers...
    }
}
