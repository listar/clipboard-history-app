import Foundation

class ClipboardStore {
    static let shared = ClipboardStore()
    private let maxItems = 50
    
    @Published private(set) var items: [ClipboardItem] = []
    
    private init() {
        loadItems()
    }
    
    func addItem(_ item: ClipboardItem) {
        items.insert(item, at: 0)
        if items.count > maxItems {
            items.removeLast()
        }
        saveItems()
    }
    
    private func loadItems() {
        // Implementation for loading items from UserDefaults or file
    }
    
    private func saveItems() {
        // Implementation for saving items to UserDefaults or file
    }
}