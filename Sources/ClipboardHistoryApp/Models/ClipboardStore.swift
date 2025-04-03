import Foundation
import SwiftUI

class ClipboardStore: ObservableObject {
    static let shared = ClipboardStore()
    private let maxItems = 100 // 修改为100条
    private let saveKey = "clipboard.default.history"
    
    @Published private(set) var items: [ClipboardItem] = []
    
    private init() {
        loadItems() // 初始化时加载存储的历史记录
    }
    
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
                
                // 保存到本地存储(不包括第一条)
                self.saveItems()
            }
        }
    }
    
    func removeItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            self.items.removeAll { $0.id == item.id }
            self.saveItems() // 更新本地存储
        }
    }
    
    func clearItems() {
        DispatchQueue.main.async {
            self.items.removeAll()
            self.saveItems() // 更新本地存储
        }
    }
    
    var filteredItems: [ClipboardItem] {
        items
    }
    
    // 保存剪贴板历史到本地，排除第一条
    private func saveItems() {
        // 如果只有一条或没有内容，不需要保存
        if items.count <= 1 {
            return
        }
        
        // 从索引1开始(排除第一条)，最多保存99条(加上系统剪贴板的第一条正好是100条)
        let itemsToSave = Array(items.dropFirst().prefix(99))
        let encodableItems = itemsToSave.map { EncodableClipboardItem(from: $0) }
        
        if let data = try? JSONEncoder().encode(encodableItems) {
            UserDefaults.standard.set(data, forKey: saveKey)
            NSLog("保存了 \(itemsToSave.count) 条剪贴板历史记录")
        }
    }
    
    // 从本地加载剪贴板历史
    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            NSLog("没有找到本地存储的剪贴板历史")
            return
        }
        
        guard let encodedItems = try? JSONDecoder().decode([EncodableClipboardItem].self, from: data) else {
            NSLog("解码本地存储的剪贴板历史失败")
            return
        }
        
        // 转换为ClipboardItem类型，并添加到历史记录中
        let loadedItems = encodedItems.compactMap { $0.toClipboardItem() }
        if !loadedItems.isEmpty {
            items = loadedItems
            NSLog("加载了 \(loadedItems.count) 条剪贴板历史记录")
        }
    }
}
