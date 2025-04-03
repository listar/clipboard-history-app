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
    
    // 判断两个剪贴板项目的内容是否相同
    func hasSameContent(as other: ClipboardItem) -> Bool {
        switch (self.type, other.type) {
        case (.text(let text1), .text(let text2)):
            return text1 == text2
        case (.image, .image):
            // 对于图片，由于无法直接比较像素数据，暂时仅比较ID
            return self.id == other.id
        case (.file(let urls1), .file(let urls2)):
            // 比较文件URL是否完全相同
            guard urls1.count == urls2.count else { return false }
            return Set(urls1.map { $0.path }) == Set(urls2.map { $0.path })
        case (.other(let type1), .other(let type2)):
            return type1 == type2
        default:
            // 不同类型的内容肯定不相同
            return false
        }
    }
}