import AppKit

struct ScreenUtils {
    static func getPopoverPosition() -> NSPoint {
        guard let screen = NSScreen.main else { return .zero }
        let screenFrame = screen.visibleFrame
        
        // 将弹窗放在屏幕底部中间位置
        let x = screenFrame.origin.x + (screenFrame.width / 2)
        let y = screenFrame.origin.y // 底部
        
        return NSPoint(x: x, y: y)
    }
}