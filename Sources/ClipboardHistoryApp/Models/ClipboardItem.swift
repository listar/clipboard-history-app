import Foundation
import AppKit

enum ClipboardType {
    case text(String)
    case image(NSImage)
    case file([URL])
    case other(String) // 其他类型只显示类型描述
    
    var description: String {
        switch self {
        case .text(let string): return string
        case .image: return "图片"
        case .file(let urls): return urls.map { $0.lastPathComponent }.joined(separator: ", ")
        case .other(let type): return "[\(type)]"
        }
    }
    
    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        case .file: return "doc"
        case .other: return "doc.questionmark"
        }
    }
}

struct ClipboardItem: Identifiable {
    let id = UUID()
    let type: ClipboardType
    let timestamp: Date
    
    func copyToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch type {
        case .text(let string):
            pasteboard.setString(string, forType: .string)
        case .image(let image):
            pasteboard.writeObjects([image])
        case .file(let urls):
            pasteboard.writeObjects(urls as [NSURL])
        case .other:
            break // 不支持复制其他类型
        }
    }
}