import SwiftUI

struct ClipboardHistoryView: View {
    @StateObject private var store = ClipboardStore.shared
    
    var body: some View {
        VStack {
            List {
                ForEach(store.items) { item in
                    ClipboardItemView(item: item)
                        .onTapGesture {
                            pasteItem(item)
                        }
                }
            }
            .listStyle(.sidebar)
            
            Divider()
            
            HStack {
                Button("Clear All") {
                    store.clearItems()
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Text("\(store.items.count) items")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(width: 300, height: 400)
    }
    
    private func pasteItem(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
    }
}

struct ClipboardItemView: View {
    let item: ClipboardItem
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.content)
                .lineLimit(2)
                .font(.system(.body, design: .monospaced))
            
            Text(item.timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.content, forType: .string)
        }
    }
}