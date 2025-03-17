import Cocoa

class KeyboardShortcuts {
    static let shared = KeyboardShortcuts()
    private var eventMonitor: Any?
    private var handler: (() -> Void)?
    
    func register(handler: @escaping () -> Void) {
        self.handler = handler
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.keyDown]
        ) { [weak self] event in
            // Check for Cmd+Shift+V (⌘⇧V)
            if event.modifierFlags.contains([.command, .shift]) && 
               event.keyCode == 9 { // V key
                self?.handler?()
            }
            // Check for ESC key
            if event.keyCode == 53 { // ESC key
                self?.handler?()
            }
        }
    }
    
    func unregister() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    deinit {
        unregister()
    }
}