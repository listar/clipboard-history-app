import Cocoa

class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let store: ClipboardStore
    
    init(store: ClipboardStore = ClipboardStore.shared) {
        self.lastChangeCount = pasteboard.changeCount
        self.store = store
    }
    
    func startMonitoring() {
        // 更频繁地检查剪贴板变化
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        
        // 确保定时器在主线程运行
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func checkForChanges() {
        let currentCount = pasteboard.changeCount
        guard currentCount > lastChangeCount else { return }
        
        lastChangeCount = currentCount
        
        if let text = pasteboard.string(forType: .string) {
            DispatchQueue.main.async {
                let item = ClipboardItem(content: text)
                self.store.addItem(item)
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
}