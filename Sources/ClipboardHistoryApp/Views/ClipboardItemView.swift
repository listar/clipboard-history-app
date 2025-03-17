import SwiftUI
import AppKit
import Foundation

struct ClipboardItemView: View {
    let item: ClipboardItem
    @State private var isHovered = false
    @ObservedObject private var store = ClipboardStore.shared
    
    private var characterCount: String? {
        if case .text(let string) = item.type {
            return "\(string.count)个字符"
        }
        return nil
    }
    
    var body: some View {
        Button {
            item.copyToPasteboard()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Group {
                    switch item.type {
                    case .text(let string):
                        VStack(alignment: .leading, spacing: 4) {
                            Text(string)
                                .lineLimit(10) // 增加行数限制
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            
                            Text(characterCount ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    case .image(let image):
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .file(let urls):
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(urls, id: \.self) { url in
                                Text(url.lastPathComponent)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    case .other(let type):
                        Text("[\(type)]")
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
                .foregroundColor(.primary)
                
                Text(RelativeTimeFormatter.format(item.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 300, height: 240)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)  // 使用白色背景
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHovered ? Color.accentColor : Color.clear, lineWidth: 1.5)
                    )
            }
        }
        .buttonStyle(.plain)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hover
            }
            if hover {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .contextMenu {
            ClipboardItemContextMenu(
                item: item,
                onDelete: { store.removeItem(item) }
            )
        }
    }
}

struct MarkdownText: View {
    let content: String
    
    init(_ content: String) {
        self.content = content
    }
    
    var body: some View {
        if let attributedString = try? AttributedString(markdown: content) {
            Text(attributedString)
        } else {
            Text(content)
        }
    }
}
