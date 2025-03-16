import Foundation
import AppKit

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
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkForChanges() {
        let currentCount = pasteboard.changeCount
        guard currentCount > lastChangeCount else { return }
        
        lastChangeCount = currentCount
        
        if let text = pasteboard.string(forType: .string) {
            let item = ClipboardItem(content: text, type: .text)
            store.addItem(item)
        }
    }
}