import SwiftUI
import AppKit

struct ClipboardHistoryView: View {
    @State private var searchText = ""
    @StateObject private var store = ClipboardStore.shared
    @StateObject private var tabStore = TabStore.shared
    @State private var showingNewTabAlert = false  // 改回使用 Alert
    @State private var newTabName = ""
    @State private var selectedTabId: UUID? = TabStore.defaultTabId
    
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
                                        NSLog("切换到标签: \(tab.name), ID: \(tab.id)")
                                    }
                                    .contextMenu {
                                        Button("删除", role: .destructive) {
                                            tabStore.removeTab(tab)
                                            if selectedTabId == tab.id {
                                                selectedTabId = TabStore.defaultTabId
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
                    ForEach(filteredItems) { item in
                        ClipboardItemView(item: item)
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
        let items = if selectedTabId == TabStore.defaultTabId {
            store.items  // 显示系统剪贴板项目
        } else {
            tabStore.getItems(for: selectedTabId)  // 显示特定标签的项目
        }
        
        if searchText.isEmpty {
            return items
        }
        return items.filter { item in
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
    }
}

// 添加右键菜单支持
struct ClipboardItemContextMenu: View {
    let item: ClipboardItem
    let onDelete: () -> Void
    @ObservedObject private var tabStore = TabStore.shared
    
    var body: some View {
        Button("删除", role: .destructive, action: onDelete)
        
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