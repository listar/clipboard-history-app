import Cocoa

class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> NSEvent?
    private let isGlobal: Bool
    
    init(mask: NSEvent.EventTypeMask, isGlobal: Bool = true, handler: @escaping (NSEvent?) -> NSEvent?) {
        self.mask = mask
        self.handler = handler
        self.isGlobal = isGlobal
    }
    
    deinit {
        stop()
    }
    
    func start() {
        if isGlobal {
            monitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
                _ = self?.handler(event)
            }
        } else {
            monitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
                return self?.handler(event) ?? event
            }
        }
    }
    
    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}