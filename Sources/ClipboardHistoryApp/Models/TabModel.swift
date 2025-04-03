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
    @Published var selectedTabId: UUID? = defaultTabId
    private let saveKey = "clipboard.tabs"
    static let defaultTabId = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
    
    private var tabItems: [UUID: [ClipboardItem]] = [:]
    private let itemsKey = "clipboard.tab.items"
    
    private init() {
        // 创建默认标签
        let defaultTab = TabItem(id: Self.defaultTabId, name: "默认", isDefault: true)
        tabs = [defaultTab]
        loadTabs()
        loadTabItems() // 加载标签项目数据
        
        // 确保默认标签始终存在，并且ID是固定的
        if !tabs.contains(where: { $0.isDefault }) {
            tabs.insert(defaultTab, at: 0)
            saveTabs()
        } else {
            // 确保默认标签的ID始终是defaultTabId
            for i in 0..<tabs.count {
                if tabs[i].isDefault && tabs[i].id != Self.defaultTabId {
                    NSLog("修复默认标签ID")
                    tabs.removeAll { $0.isDefault }
                    tabs.insert(defaultTab, at: 0)
                    saveTabs()
                    break
                }
                
                // 确保默认标签名称为"默认"
                if tabs[i].isDefault && tabs[i].name != "默认" {
                    NSLog("修复默认标签名称")
                    var fixedTab = tabs[i]
                    fixedTab.name = "默认"
                    tabs[i] = fixedTab
                    saveTabs()
                    break
                }
            }
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
        
        // 检查是否已存在相同内容的项目
        if let index = tabItems[tabId]?.firstIndex(where: { $0.hasSameContent(as: item) }) {
            // 如果已存在，将其移动到最前面
            if index > 0 {
                var items = tabItems[tabId]!
                let existingItem = items.remove(at: index)
                items.insert(existingItem, at: 0)
                tabItems[tabId] = items
                saveTabItems()
                objectWillChange.send() // 通知UI更新
            }
            NSLog("项目内容已存在于标签中，已移至最前")
        } else {
            // 不存在则添加到最前面
            tabItems[tabId]?.insert(item, at: 0)
            saveTabItems()
            objectWillChange.send() // 通知UI更新
            NSLog("新项目已添加到标签")
        }
    }
    
    func getItemsForTab(_ tabId: UUID) -> [ClipboardItem] {
        return tabItems[tabId] ?? []
    }
    
    // 移动项目位置（拖拽排序）
    func moveItem(in tabId: UUID, from source: IndexSet, to destination: Int) {
        guard !isDefaultTab(tabId),
              var items = tabItems[tabId],
              !items.isEmpty else {
            return
        }
        
        items.move(fromOffsets: source, toOffset: destination)
        tabItems[tabId] = items
        saveTabItems()
        objectWillChange.send() // 通知UI更新
    }
    
    // 判断是否为默认标签（系统剪贴板）
    func isDefaultTab(_ tabId: UUID) -> Bool {
        return tabId == Self.defaultTabId
    }
    
    // 从标签中移除项目
    func removeItemFromTab(_ item: ClipboardItem, tabId: UUID) {
        guard var items = tabItems[tabId] else { return }
        
        items.removeAll { $0.id == item.id }
        tabItems[tabId] = items
        saveTabItems()
        objectWillChange.send() // 通知UI更新
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
        // 如果是默认标签ID或者没有指定ID，返回系统剪贴板项目
        if tabId == Self.defaultTabId || tabId == nil {
            NSLog("返回默认标签(系统剪贴板)项目")
            return ClipboardStore.shared.items
        } else {
            // 返回自定义标签的项目
            NSLog("返回自定义标签项目: \(tabId?.uuidString ?? "nil")")
            return tabItems[tabId!] ?? []
        }
    }
    
    // 在指定标签中搜索内容
    func searchInTab(_ tabId: UUID?, searchText: String) -> [ClipboardItem] {
        guard !searchText.isEmpty else {
            return getItems(for: tabId)
        }
        
        // 获取要搜索的项目列表
        let itemsToSearch: [ClipboardItem]
        if tabId == Self.defaultTabId || tabId == nil {
            // 在默认标签（系统剪贴板）中搜索时，使用ClipboardStore的搜索方法
            return ClipboardStore.shared.filteredItems(with: searchText)
        } else if let items = tabItems[tabId!] {
            itemsToSearch = items
        } else {
            return []
        }
        
        // 执行搜索
        let filtered = itemsToSearch.filter { item in
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
        
        NSLog("在标签中搜索 '\(searchText)' 找到 \(filtered.count) 个结果")
        return filtered
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
    
    // 添加一个方法用于重置所有标签数据（用于调试）
    func resetAllTabs() {
        UserDefaults.standard.removeObject(forKey: saveKey)
        UserDefaults.standard.removeObject(forKey: itemsKey)
        
        tabs = [TabItem(id: Self.defaultTabId, name: "默认", isDefault: true)]
        tabItems = [:]
        saveTabs()
        objectWillChange.send()
    }
}
