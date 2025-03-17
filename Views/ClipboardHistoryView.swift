import SwiftUI

struct ClipboardHistoryView: View {
    @State private var searchText = ""
    @State private var selectedTabId: Int = 0
    @State private var filteredItems: [ClipboardItem] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                SearchBar(searchText: $searchText)
                    .frame(maxWidth: (NSScreen.main?.frame.width ?? 800) / 3)
                    .padding(.vertical, 0)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        NSApp.keyWindow?.makeFirstResponder(
                            NSApp.keyWindow?.contentView?.descendantViews.first { $0 is NSSearchField }
                        )
                    }
                
                // 只在非默认标签时才显示分隔线
                if selectedTabId != TabStore.defaultTabId {
                    Divider()
                }
                
                // ...existing code...
            }
            // ...existing code...
        }
    }
    
    private var clipboardContent: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            LazyHStack(spacing: 1) {
                if filteredItems.isEmpty {
                    Text("无剪贴板记录")
                        .foregroundColor(.secondary)
                        .frame(width: 250)  // 增加宽度
                        .padding()
                } else {
                    ForEach(filteredItems) { item in
                        ClipboardItemView(item: item)
                            .frame(width: 250)  // 增加宽度
                        if item.id != filteredItems.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.windowBackgroundColor))
    }
}
