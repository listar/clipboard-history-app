import Foundation

class ClipboardHistoryViewModel: ObservableObject {
    @Published var clipboardItems: [String] = []
}