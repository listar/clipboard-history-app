import SwiftUI
import AppKit

struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            // 使用两种方式实现搜索框，通过注释切换
            
            // 方式1: 原生TextField
            TextField("搜索", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .disableAutocorrection(true)
                .focused($isFocused)
                .onAppear {
                    NSLog("搜索框出现")
                    isFocused = false
                }
                .onTapGesture {
                    NSLog("搜索框被点击")
                    isFocused = true
                }
                .onChange(of: isFocused) { newValue in
                    NSLog("搜索框焦点状态变化: \(newValue)")
                }
                .onChange(of: text) { newValue in
                    NSLog("搜索文本变化: \(newValue)")
                }
            
            // 方式2: 使用NSTextFieldWrapper
            // NSTextFieldWrapper(text: $text, isFocused: _isFocused, onSubmit: {
            //     NSLog("搜索框提交")
            // })
            // .frame(height: 24)
        }
        .padding(8)
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
        .onTapGesture {
            NSLog("整个搜索栏被点击")
            isFocused = true
        }
    }
}
