import SwiftUI

struct PreferencesView: View {
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 50
    
    var body: some View {
        Form {
            Text("Preferences")
        }
        .padding()
        .frame(width: 300)
    }
}