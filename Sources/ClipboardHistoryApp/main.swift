import AppKit

// 初始化日志
NSLog("应用程序开始启动")

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// 注释掉这些设置，因为它们可能与AppDelegate中的设置冲突
// NSApp.setActivationPolicy(.accessory)
// NSApp.presentationOptions = [.disableHideApplication, .disableProcessSwitching]

// 直接运行应用程序
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)