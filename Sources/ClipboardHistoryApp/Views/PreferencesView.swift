import SwiftUI

struct PreferencesView: View {
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 50
    @AppStorage("launchAtLogin") private var launchAtLogin = true
    
    var body: some View {
        Form {
            Picker("Maximum History Items", selection: $maxHistoryItems) {
                ForEach([20, 50, 100, 200], id: \.self) { number in
                    Text("\(number)").tag(number)
                }
            }
            Toggle("Launch at Login", isOn: $launchAtLogin)
            Text("Keyboard Shortcut: ⌘⇧V")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .frame(width: 300)
    }
}