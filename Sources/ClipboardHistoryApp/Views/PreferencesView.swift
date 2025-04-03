import SwiftUI

struct PreferencesView: View {
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 50
    @AppStorage("launchAtLogin") private var launchAtLogin = true
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            TabView(selection: $selectedTab) {
                generalTab
                    .tabItem {
                        Label("常规", systemImage: "gear")
                    }
                    .tag(0)
                
                KeyboardShortcutSettingView()
                    .tabItem {
                        Label("快捷键", systemImage: "keyboard")
                    }
                    .tag(1)
            }
            .padding()
            
            Button("关闭") {
                if let window = NSApp.windows.first(where: { $0.title == "首选项" }) {
                    window.orderOut(nil)
                }
            }
            .padding(.bottom)
        }
        .frame(width: 450, height: 380)
    }
    
    private var generalTab: some View {
        Form {
            Picker("最大历史条目数", selection: $maxHistoryItems) {
                Text("50").tag(50)
                Text("100").tag(100)
                Text("200").tag(200)
                Text("500").tag(500)
            }
            .pickerStyle(MenuPickerStyle())
            
            Toggle("登录时启动", isOn: $launchAtLogin)
        }
    }
}

#Preview {
    PreferencesView()
}