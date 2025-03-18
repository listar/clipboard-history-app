import Foundation

struct TabItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var isDefault: Bool
    
    init(id: UUID = UUID(), name: String, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
    }
}

class TabStore: ObservableObject {
    static let shared = TabStore()
    @Published var tabs: [TabItem] = []
    private let saveKey = "clipboard.tabs"
    static let defaultTabId = UUID()  // 默认标签的固定 ID
    
    private var tabItems: [UUID: [ClipboardItem]] = [:]
    private let itemsKey = "clipboard.tab.items"
    
    private init() {
        // 创建默认标签
        let defaultTab = TabItem(id: Self.defaultTabId, name: "默认", isDefault: true)
        tabs = [defaultTab]
        loadTabs()
        loadTabItems() // 加载标签项目数据
        
        // 确保默认标签始终存在
        if (!tabs.contains(where: { $0.isDefault })) {
            tabs.insert(defaultTab, at: 0)
            saveTabs()
        }
    }
    
    func addTab(name: String) {
        let tab = TabItem(name: name)
        tabs.append(tab)
        saveTabs()
    }
    
    func removeTab(_ tab: TabItem) {
        // 不允许删除默认标签
        guard !tab.isDefault else { return }
        
        // 删除标签及其关联的项目
        tabs.removeAll { $0.id == tab.id }
        tabItems.removeValue(forKey: tab.id)
        saveTabs()
    }
    
    func addItemToTab(_ item: ClipboardItem, tabId: UUID) {
        if tabItems[tabId] == nil {
            tabItems[tabId] = []
        }
        tabItems[tabId]?.append(item)
        saveTabItems()
        objectWillChange.send() // 通知UI更新
    }
    
    func getItemsForTab(_ tabId: UUID) -> [ClipboardItem] {
        return tabItems[tabId] ?? []
    }
    
    private func saveTabs() {
        if let data = try? JSONEncoder().encode(tabs) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private func loadTabs() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let loadedTabs = try? JSONDecoder().decode([TabItem].self, from: data) else {
            return
        }
        tabs = loadedTabs
    }
    
    // 获取指定标签或默认标签的项目
    func getItems(for tabId: UUID?) -> [ClipboardItem] {
        if let tabId = tabId {
            return tabItems[tabId] ?? []
        } else {
            // 返回默认标签的项目（即系统剪贴板项目）
            return ClipboardStore.shared.items
        }
    }
    
    private func saveTabItems() {
        // 将 tabItems 转换为可编码的格式
        var encodableItems: [String: [EncodableClipboardItem]] = [:]
        for (key, items) in tabItems {
            encodableItems[key.uuidString] = items.map { EncodableClipboardItem(from: $0) }
        }
        
        if let data = try? JSONEncoder().encode(encodableItems) {
            UserDefaults.standard.set(data, forKey: itemsKey)
        }
    }
    
    private func loadTabItems() {
        guard let data = UserDefaults.standard.data(forKey: itemsKey),
              let encodedItems = try? JSONDecoder().decode([String: [EncodableClipboardItem]].self, from: data) else {
            return
        }
        
        tabItems = [:]
        for (key, items) in encodedItems {
            if let uuid = UUID(uuidString: key) {
                tabItems[uuid] = items.compactMap { $0.toClipboardItem() }
            }
        }
    }
}

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
        default:
            return nil
        }
        
        return ClipboardItem(type: clipboardType, timestamp: timestamp)  // 移除 id 参数
    }
}
