import Foundation

// 用于存储的可编码剪贴板项目
struct EncodableClipboardItem: Codable {
    let id: UUID
    let type: String
    let content: String
    let timestamp: Date
    
    init(from item: ClipboardItem) {
        self.id = item.id
        self.timestamp = item.timestamp
        
        switch item.type {
        case .text(let string):
            self.type = "text"
            self.content = string
        case .image:
            self.type = "image"
            self.content = "" // 图片暂不支持存储
        case .file(let urls):
            self.type = "file"
            self.content = urls.map { $0.path }.joined(separator: "\n")
        case .other(let type):
            self.type = "other"
            self.content = type
        }
    }
    
    func toClipboardItem() -> ClipboardItem? {
        let clipboardType: ClipboardType
        switch type {
        case "text":
            clipboardType = .text(content)
        case "file":
            let urls = content.split(separator: "\n").map { URL(fileURLWithPath: String($0)) }
            clipboardType = .file(urls)
        case "other":
            clipboardType = .other(content)
        case "image":
            // 图片无法从字符串恢复，只能跳过
            return nil
        default:
            return nil
        }
        
        return ClipboardItem(type: clipboardType, timestamp: timestamp)
    }
}
