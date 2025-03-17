import Foundation
import SwiftUI

class ClipboardStore: ObservableObject {
    static let shared = ClipboardStore()
    private let maxItems = 50
    
    @Published private(set) var items: [ClipboardItem] = []
    
    private init() {}
    
    func addItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            // 检查是否已存在相同内容
            let isDuplicate = self.items.contains { existingItem in
                switch (existingItem.type, item.type) {
                case (.text(let existing), .text(let new)):
                    return existing == new
                case (.image, .image):
                    return false  // 图片总是添加新条目
                case (.file(let existing), .file(let new)):
                    return existing == new
                case (.other(let existing), .other(let new)):
                    return existing == new
                default:
                    return false
                }
            }
            
            if !isDuplicate {
                self.items.insert(item, at: 0)
                // 限制最大数量
                if self.items.count > self.maxItems {
                    self.items.removeLast()
                }
            }
        }
    }
    
    func removeItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            self.items.removeAll { $0.id == item.id }
        }
    }
    
    func clearItems() {
        DispatchQueue.main.async {
            self.items.removeAll()
        }
    }
    
    var filteredItems: [ClipboardItem] {
        items
    }
}
