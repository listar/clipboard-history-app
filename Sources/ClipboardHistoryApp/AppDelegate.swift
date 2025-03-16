import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var statusBarItem: NSStatusItem?
    private var clipboardMonitor: ClipboardMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        clipboardMonitor = ClipboardMonitor()
        clipboardMonitor?.startMonitoring()
    }
    
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem?.button?.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard History")
        
        let contentView = ClipboardHistoryView()
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        statusBarItem?.button?.action = #selector(togglePopover(_:))
        statusBarItem?.button?.target = self
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem?.button {
            let popover = NSPopover()
            popover.contentViewController = NSHostingController(rootView: ClipboardHistoryView())
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}