import Cocoa

class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        if lastChangeCount == pasteboard.changeCount { return }
        lastChangeCount = pasteboard.changeCount
        
        NSLog("=========== 剪贴板变化检测 ===========")
        NSLog("可用类型: \(pasteboard.types?.map { $0.rawValue } ?? [])")
        
        // 首先检查是否有文本，因为几乎所有类型都会包含文本
        if let string = pasteboard.string(forType: .string) {
            // 如果只有文本类型，则作为文本处理
            if pasteboard.types?.count == 1 || 
               (pasteboard.types?.count == 2 && pasteboard.types?.contains(.rtf) == true) {
                NSLog("检测到纯文本: \(string.prefix(50))...")
                ClipboardStore.shared.addItem(ClipboardItem(type: .text(string), timestamp: Date()))
                return
            }
        }
        
        // 然后检查图片
        if let image = pasteboard.readObjects(forClasses: [NSImage.self]) as? [NSImage],
           let first = image.first {
            NSLog("检测到图片")
            ClipboardStore.shared.addItem(ClipboardItem(type: .image(first), timestamp: Date()))
            return
        }
        
        // 最后检查文件
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
           !urls.isEmpty,
           urls.allSatisfy({ $0.isFileURL }) {
            NSLog("检测到文件: \(urls)")
            ClipboardStore.shared.addItem(ClipboardItem(type: .file(urls), timestamp: Date()))
            return
        }
        
        // 如果前面都没有匹配，但有文本，则作为文本处理
        if let string = pasteboard.string(forType: .string) {
            NSLog("检测到富文本: \(string.prefix(50))...")
            ClipboardStore.shared.addItem(ClipboardItem(type: .text(string), timestamp: Date()))
            return
        }
        
        // 其他类型
        if let types = pasteboard.types {
            let typeNames = types.map { $0.rawValue }.joined(separator: ", ")
            NSLog("检测到其他类型: \(typeNames)")
            ClipboardStore.shared.addItem(ClipboardItem(type: .other(typeNames), timestamp: Date()))
        }
    }
}