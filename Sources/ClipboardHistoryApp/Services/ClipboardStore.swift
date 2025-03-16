import Foundation
import Combine

class ClipboardStore: ObservableObject {
    static let shared = ClipboardStore()
    
    private let maxItems = 50
    private let defaults = UserDefaults.standard
    private let itemsKey = "clipboardItems"
    
    @Published private(set) var items: [ClipboardItem] = []
    
    private init() {
        loadItems()
    }
    
    func addItem(_ item: ClipboardItem) {
        if let firstItem = items.first, firstItem.content == item.content {
            return
        }
        
        DispatchQueue.main.async {
            self.items.insert(item, at: 0)
            if self.items.count > self.maxItems {
                self.items.removeLast()
            }
            self.saveItems()
        }
    }
    
    func clearItems() {
        items.removeAll()
        saveItems()
    }
    
    private func loadItems() {
        if let data = defaults.data(forKey: itemsKey),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decoded
        }
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            defaults.set(encoded, forKey: itemsKey)
        }
    }
}