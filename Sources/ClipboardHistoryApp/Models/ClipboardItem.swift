import Foundation

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: String
    let timestamp: Date
    let type: ItemType
    
    enum ItemType: String, Codable {
        case text
        case image
        case file
    }
    
    init(content: String, type: ItemType, id: UUID = UUID(), timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.type = type
    }
}