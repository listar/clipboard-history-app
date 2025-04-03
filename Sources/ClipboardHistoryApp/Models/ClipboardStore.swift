import Foundation
import SwiftUI

class ClipboardStore: ObservableObject {
    static let shared = ClipboardStore()
    @AppStorage("maxHistoryItems") private var maxItems = 500 // 增加最大条目数
    private let saveKey = "clipboard.default.history"
    private let pageSize = 20 // 每页加载的条目数
    
    @Published private(set) var items: [ClipboardItem] = []
    @Published var isLoading = false
    @Published var loadedPages = 0 // 已加载的页数
    @Published var hasMoreData = true // 标记是否还有更多数据可加载
    
    // 所有存储的条目(未分页)
    private var allItems: [ClipboardItem] = []
    
    private init() {
        loadAllItems() // 初始化时加载所有存储的历史记录到allItems
        loadNextPage() // 加载第一页数据到items
    }
    
    func addItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            // 检查是否已存在相同内容
            let isDuplicate = self.allItems.contains { existingItem in
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
                // 添加到所有条目中
                self.allItems.insert(item, at: 0)
                
                // 添加到当前显示的条目中
                self.items.insert(item, at: 0)
                
                // 限制最大数量
                if self.allItems.count > self.maxItems {
                    self.allItems.removeLast()
                }
                
                // 保存到本地存储
                self.saveItems()
            }
        }
    }
    
    func removeItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            self.items.removeAll { $0.id == item.id }
            self.allItems.removeAll { $0.id == item.id }
            self.saveItems() // 更新本地存储
        }
    }
    
    func clearItems() {
        DispatchQueue.main.async {
            self.items.removeAll()
            self.allItems.removeAll()
            self.loadedPages = 0
            self.hasMoreData = false
            self.saveItems() // 更新本地存储
        }
    }
    
    // 加载下一页数据
    func loadNextPage() {
        guard !isLoading && hasMoreData else { return }
        
        isLoading = true
        
        // 模拟延迟，给UI更新提供时间
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            let startIndex = self.loadedPages * self.pageSize
            let endIndex = min(startIndex + self.pageSize, self.allItems.count)
            
            // 检查是否还有数据可加载
            if startIndex < self.allItems.count {
                let newItems = Array(self.allItems[startIndex..<endIndex])
                self.items.append(contentsOf: newItems)
                self.loadedPages += 1
                
                // 检查是否加载完所有数据
                self.hasMoreData = endIndex < self.allItems.count
            } else {
                self.hasMoreData = false
            }
            
            self.isLoading = false
        }
    }
    
    // 重置分页并重新加载第一页
    func resetAndReload() {
        DispatchQueue.main.async {
            self.items.removeAll()
            self.loadedPages = 0
            self.hasMoreData = true
            self.loadNextPage()
        }
    }
    
    // 根据搜索文本过滤结果
    func filteredItems(with searchText: String) -> [ClipboardItem] {
        if searchText.isEmpty {
            return items
        }
        
        // 从所有项目中搜索，而不仅仅是当前显示的项目
        let filteredFromAll = allItems.filter { item in
            switch item.type {
            case .text(let string):
                return string.localizedCaseInsensitiveContains(searchText)
            case .file(let urls):
                return urls.map { $0.lastPathComponent }
                    .joined(separator: ", ")
                    .localizedCaseInsensitiveContains(searchText)
            case .image:
                return "图片".localizedCaseInsensitiveContains(searchText)
            case .other(let type):
                return type.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 更新当前显示的项目
        // 注意：这段代码只会在搜索时更新items，不影响正常的分页加载
        if !filteredFromAll.isEmpty {
            NSLog("搜索找到 \(filteredFromAll.count) 个结果")
            return filteredFromAll
        }
        
        // 如果未找到结果，返回空数组
        return []
    }
    
    // 保存剪贴板历史到本地
    private func saveItems() {
        if allItems.isEmpty {
            return
        }
        
        // 最多保存maxItems条
        let itemsToSave = Array(allItems.prefix(maxItems))
        let encodableItems = itemsToSave.map { EncodableClipboardItem(from: $0) }
        
        if let data = try? JSONEncoder().encode(encodableItems) {
            UserDefaults.standard.set(data, forKey: saveKey)
            NSLog("保存了 \(itemsToSave.count) 条剪贴板历史记录")
        }
    }
    
    // 从本地加载所有剪贴板历史到allItems
    private func loadAllItems() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            NSLog("没有找到本地存储的剪贴板历史")
            return
        }
        
        guard let encodedItems = try? JSONDecoder().decode([EncodableClipboardItem].self, from: data) else {
            NSLog("解码本地存储的剪贴板历史失败")
            return
        }
        
        // 转换为ClipboardItem类型，并添加到所有条目中
        self.allItems = encodedItems.compactMap { $0.toClipboardItem() }
        
        if !self.allItems.isEmpty {
            NSLog("加载了 \(self.allItems.count) 条剪贴板历史记录")
        }
    }
}
