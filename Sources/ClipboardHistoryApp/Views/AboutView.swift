import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 64))
            
            Text("Clipboard History")
                .font(.title)
            
            Text("Version 1.2")
                .foregroundColor(.secondary)
            
            Text("Build ID: \(BundleInfo.buildId)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("© 2025 星辉集团")
                .font(.caption)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
    }
}