import SwiftUI

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 64))
            
            Text("Clipboard History")
                .font(.title)
            
            Text("Version 1.0")
                .foregroundColor(.secondary)
            
            Text("Build ID: \(BundleInfo.buildId)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("© 2025 星辉集团")
                .font(.caption)
                
            Button("关闭") {
                guard let window = NSApplication.shared.windows.first(where: { $0.title == "About" }) else {
                    return
                }
                window.orderOut(nil)
            }
            .padding(.top, 10)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
    }
}