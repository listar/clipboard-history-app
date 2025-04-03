import SwiftUI
import AppKit

struct ClipboardHistoryView: View {
    @State private var searchText = ""
    @StateObject private var store = ClipboardStore.shared
    @StateObject private var tabStore = TabStore.shared
    @State private var showingNewTabAlert = false  // 改回使用 Alert
    @State private var newTabName = ""
    @State private var selectedTabId: UUID? = TabStore.defaultTabId
    @State private var draggingItem: ClipboardItem? = nil
    
    init() {
        // 确保TabStore的selectedTabId与View中的同步
        TabStore.shared.selectedTabId = TabStore.defaultTabId
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 16)  // 顶部间距
            
            HStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText)
                    .frame(width: (NSScreen.main?.frame.width ?? 800) / 3)
                    .padding(.horizontal, 16)
                    .onTapGesture {
                        NSLog("搜索栏容器被点击")
                        // 不执行任何获取焦点的代码
                    }
                    .onAppear {
                        NSLog("搜索栏出现")
                        // 不执行任何获取焦点的代码
                    }
                
                // 修改分隔线逻辑，只在非默认标签时显示
                if selectedTabId != TabStore.defaultTabId {
                    Divider()
                        .frame(height: 30) // 限制分隔线高度
                }
                
                // 分类标签区域
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tabStore.tabs) { tab in
                            if (!tab.isDefault) {
                                Text(tab.name)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(selectedTabId == tab.id ? Color.accentColor : Color(.windowBackgroundColor))
                                    .foregroundColor(selectedTabId == tab.id ? .white : .primary)
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        selectedTabId = tab.id
                                        tabStore.selectedTabId = tab.id
                                        NSLog("切换到标签: \(tab.name), ID: \(tab.id)")
                                    }
                                    .contextMenu {
                                        Button("删除", role: .destructive) {
                                            tabStore.removeTab(tab)
                                            if selectedTabId == tab.id {
                                                selectedTabId = TabStore.defaultTabId
                                                tabStore.selectedTabId = TabStore.defaultTabId
                                                NSLog("标签被删除，切换到默认标签")
                                            }
                                        }
                                    }
                            } else {
                                Text(tab.name)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(selectedTabId == tab.id ? Color.accentColor : Color(.windowBackgroundColor))
                                    .foregroundColor(selectedTabId == tab.id ? .white : .primary)
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        selectedTabId = tab.id
                                        tabStore.selectedTabId = tab.id
                                        NSLog("切换到默认标签, ID: \(tab.id)")
                                    }
                            }
                        }
                        
                        // 改回使用加号按钮和弹窗
                        Button(action: {
                            showingNewTabAlert = true
                        }) {
                            Image(systemName: "plus")
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: UIConstants.topSectionHeight)
            .background(Color(hex: "E7E7E7"))
            
            // 移除分隔线
            
            // 剪贴板内容
            clipboardContent
                .padding(.vertical, 16)  // 增加内容区域的上下间距
        }
        .background(Color(hex: "E7E7E7"))
        .onAppear {
            NSLog("剪贴板历史视图出现，当前标签ID: \(selectedTabId?.uuidString ?? "nil")")
            
            // 确保TabStore的selectedTabId与View中的同步
            tabStore.selectedTabId = selectedTabId
            
            // 重置并加载第一页数据
            if selectedTabId == TabStore.defaultTabId {
                store.resetAndReload()
            }
        }
        .onChange(of: selectedTabId) { newValue in
            // 同步TabStore的selectedTabId
            tabStore.selectedTabId = newValue
            
            // 切换标签时，重置并加载数据
            if newValue == TabStore.defaultTabId {
                store.resetAndReload()
            }
        }
        .alert("新建标签", isPresented: $showingNewTabAlert) {
            TextField("标签名称", text: $newTabName)
                .frame(width: 200)  // 设置输入框宽度
                .onChange(of: newTabName) { newValue in
                    NSLog("弹窗输入框文本变化: \(newValue)")
                }
            Button("取消", role: .cancel) {
                NSLog("弹窗取消按钮点击")
                newTabName = ""
            }
            Button("确定") {
                NSLog("弹窗确定按钮点击")
                if (!newTabName.isEmpty) {
                    tabStore.addTab(name: newTabName)
                    newTabName = ""
                }
            }
        } message: {
            EmptyView()  // 移除标题下方的提示信息区域
        }
        .interactiveDismissDisabled()  // 防止点击外部关闭
    }
    
    private var clipboardContent: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            LazyHStack(spacing: 8) {
                if filteredItems.isEmpty {
                    Text("无剪贴板记录")
                        .foregroundColor(.secondary)
                        .frame(width: 300, height: 180)
                        .background(Color.white)
                        .cornerRadius(8)
                        .padding()
                } else {
                    // 根据是否为自定义标签决定是否启用拖拽功能
                    if let selectedId = selectedTabId, !tabStore.isDefaultTab(selectedId) && searchText.isEmpty {
                        // 自定义标签且非搜索状态时使用可拖拽的视图
                        ForEach(filteredItems) { item in
                            ClipboardItemView(item: item)
                                .opacity(draggingItem?.id == item.id ? 0.5 : 1.0)
                                .onDrag {
                                    // 设置正在拖拽的项目
                                    self.draggingItem = item
                                    return NSItemProvider(object: item.id.uuidString as NSString)
                                }
                                .onDrop(of: [.text], delegate: ItemDropDelegate(item: item, 
                                                                               items: filteredItems, 
                                                                               draggingItem: $draggingItem, 
                                                                               tabId: selectedId, 
                                                                               tabStore: tabStore))
                        }
                    } else {
                        // 默认标签或搜索状态使用普通视图
                        ForEach(filteredItems) { item in
                            ClipboardItemView(item: item)
                        }
                        
                        // 仅在默认标签且未进行搜索时添加加载更多功能
                        if selectedTabId == TabStore.defaultTabId && searchText.isEmpty {
                            loadMoreView
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(hex: "E7E7E7")) // 使用相同的背景色
    }
    
    private func submitNewTab() {
        if !newTabName.isEmpty {
            tabStore.addTab(name: newTabName)
            newTabName = ""
        }
    }
    
    private var filteredItems: [ClipboardItem] {
        if selectedTabId == TabStore.defaultTabId {
            return searchText.isEmpty ? store.items : store.filteredItems(with: searchText)
        } else {
            let items = tabStore.getItems(for: selectedTabId)
            
            if searchText.isEmpty {
                return items
            }
            
            // 在标签中的所有项目中搜索，而不仅限于当前显示的项目
            return tabStore.searchInTab(selectedTabId, searchText: searchText)
        }
    }
    
    // 加载更多视图
    private var loadMoreView: some View {
        Group {
            if store.isLoading {
                // 加载中状态显示加载指示器
                ProgressView()
                    .frame(width: 100, height: 180)
                    .background(Color.white)
                    .cornerRadius(8)
            } else if store.hasMoreData {
                // 还有更多数据时显示加载按钮
                Button(action: {
                    store.loadNextPage()
                }) {
                    VStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                        Text("加载更多")
                            .font(.caption)
                    }
                    .frame(width: 100, height: 180)
                    .background(Color.white)
                    .cornerRadius(8)
                    .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
                .onAppear {
                    // 当视图出现在屏幕上时自动加载
                    if !store.isLoading && store.hasMoreData {
                        store.loadNextPage()
                    }
                }
            }
        }
    }
}

// EnvironmentKey扩展 - 用于在环境中传递选中的标签ID
private struct SelectedTabIdKey: EnvironmentKey {
    static let defaultValue: UUID? = TabStore.defaultTabId
}

extension EnvironmentValues {
    var selectedTabId: UUID? {
        get { self[SelectedTabIdKey.self] }
        set { self[SelectedTabIdKey.self] = newValue }
    }
}

// 添加右键菜单支持
struct ClipboardItemContextMenu: View {
    let item: ClipboardItem
    let onDelete: () -> Void
    @ObservedObject private var tabStore = TabStore.shared
    
    var body: some View {
        Button("删除", role: .destructive, action: onDelete)
        
        if let selectedTabId = tabStore.selectedTabId, !tabStore.isDefaultTab(selectedTabId) {
            Button("从当前标签移除") {
                tabStore.removeItemFromTab(item, tabId: selectedTabId)
            }
        }
        
        if !tabStore.tabs.isEmpty {
            Divider()
            Menu("存储到...") {
                ForEach(tabStore.tabs.filter { !$0.isDefault }) { tab in
                    Button(tab.name) {
                        tabStore.addItemToTab(item, tabId: tab.id)
                    }
                }
            }
        }
    }
}

// 更新常量
enum UIConstants {
    static let topSectionHeight: CGFloat = 40  // 恢复原来的高度
    static let tabSectionWidth: CGFloat = 200
}

// 颜色扩展
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        self.init(
            .sRGB,
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgbValue & 0x0000FF) / 255.0,
            opacity: 1
        )
    }
}

// 添加毛玻璃效果视图
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    }
}

// 帮助函数来查找子视图
extension NSView {
    var descendantViews: [NSView] {
        return subviews + subviews.flatMap { $0.descendantViews }
    }
}

#Preview {
    ClipboardHistoryView()
}

// 拖放委托处理
struct ItemDropDelegate: DropDelegate {
    let item: ClipboardItem
    let items: [ClipboardItem]
    @Binding var draggingItem: ClipboardItem?
    let tabId: UUID
    let tabStore: TabStore
    
    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // 确保有正在拖拽的项目
        guard let draggingItem = draggingItem,
              let fromIndex = items.firstIndex(where: { $0.id == draggingItem.id }),
              let toIndex = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        
        // 如果项目位置没有变，则不做任何操作
        if fromIndex == toIndex {
            return
        }
        
        // 处理重新排序
        tabStore.moveItem(in: tabId, from: IndexSet(integer: fromIndex), to: toIndex > fromIndex ? toIndex + 1 : toIndex)
    }
}