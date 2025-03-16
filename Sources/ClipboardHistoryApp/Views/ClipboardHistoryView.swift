import SwiftUI

struct ClipboardHistoryView: View {
    @StateObject private var viewModel = ClipboardHistoryViewModel()
    
    var body: some View {
        List {
            Text("Clipboard History")
        }
        .frame(width: 300, height: 400)
    }
}