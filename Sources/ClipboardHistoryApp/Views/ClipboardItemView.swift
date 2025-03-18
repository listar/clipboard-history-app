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
            NSLog("剪贴板项目被点击")
            // 立即复制到剪贴板
            item.copyToPasteboard()
            
            // 关闭窗口 - 使用AppDelegate的hideClipboardWindow方法
            if let appDelegate = NSApp.delegate as? AppDelegate {
                NSLog("调用hideClipboardWindow")
                appDelegate.hideClipboardWindowPublic()
            } else {
                NSLog("尝试直接关闭窗口")
                // 备用方法：直接找到窗口关闭
                if let window = NSApp.windows.first(where: { $0.isVisible && $0.title == "Clipboard History" }) {
                    window.orderOut(nil)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Group {
                    switch item.type {
                    case .text(let string):
                        VStack(alignment: .leading, spacing: 4) {
                            Text(string)
                                .lineLimit(6)
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
            .frame(width: 300, height: 180)
            .background {
                ZStack {
                    // 底层模糊效果
                    if isHovered {
                        VisualEffectView(material: .popover, blendingMode: .behindWindow)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // 主背景
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(isHovered ? 0.9 : 1))
                    
                    // 边框效果
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isHovered ? Color.accentColor : Color.gray.opacity(0.1), lineWidth: isHovered ? 2 : 1)
                        .shadow(color: isHovered ? Color.accentColor.opacity(0.3) : Color.clear, radius: 4)
                }
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
