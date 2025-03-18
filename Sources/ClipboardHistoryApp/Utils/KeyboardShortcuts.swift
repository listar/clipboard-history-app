import Cocoa

class KeyboardShortcuts {
    static let shared = KeyboardShortcuts()
    private var eventMonitor: Any?
    private var handler: (() -> Void)?
    private var escHandler: (() -> Void)?
    
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
        }
    }
    
    func registerEscHandler(handler: @escaping () -> Void) {
        self.escHandler = handler
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