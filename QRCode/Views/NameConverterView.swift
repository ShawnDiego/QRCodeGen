import SwiftUI
import AppKit

struct NameConverterView: View {
    @State private var inputText: String = ""
    @State private var detectedConvention: NamingConvention = .unknown
    @State private var conversions: [NamingConvention: String] = [:]
    @State private var showPasteButton: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            Text("变量命名转换")
                .font(.headline)
                .padding(.bottom, 5)
            
            // 输入区域
            HStack {
                TextField("输入变量名...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: inputText) { _ in
                        updateConversions()
                    }
                
                if showPasteButton {
                    Button(action: pasteFromClipboard) {
                        Label("粘贴", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(.bordered)
                }
                
                Button(action: clearInput) {
                    Label("清除", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
            }
            
            // 检测到的命名规范
            if detectedConvention != .unknown && !inputText.isEmpty {
                HStack {
                    Text("检测到: ")
                        .foregroundColor(.secondary)
                    Text(detectedConvention.description)
                        .fontWeight(.medium)
                }
                .font(.callout)
                .padding(.vertical, 4)
            }
            
            // 转换结果
            if !inputText.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach([NamingConvention.camelCase, .pascalCase, .snakeCase, .kebabCase, .upperSnakeCase, .spacedCase], id: \.self) { convention in
                        if let conversion = conversions[convention] {
                            HStack {
                                // 命名法标签
                                Text(convention.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 160, alignment: .leading)
                                
                                // 转换后的文本
                                Text(conversion)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                                
                                Spacer()
                                
                                // 复制按钮
                                Button(action: {
                                    copyToClipboard(conversion)
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            } else {
                // 空状态提示
                Text("请输入一个变量名进行命名格式转换")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
    
    // 更新转换结果
    private func updateConversions() {
        guard !inputText.isEmpty else {
            detectedConvention = .unknown
            conversions = [:]
            return
        }
        
        detectedConvention = NameConverter.detectNamingConvention(inputText)
        conversions = NameConverter.convertToAllFormats(inputText)
    }
    
    // 从剪贴板粘贴
    private func pasteFromClipboard() {
        #if os(macOS)
        if let clipboardString = NSPasteboard.general.string(forType: .string) {
            inputText = clipboardString
            updateConversions()
        }
        #endif
    }
    
    // 清除输入
    private func clearInput() {
        inputText = ""
        detectedConvention = .unknown
        conversions = [:]
    }
    
    // 复制到剪贴板
    private func copyToClipboard(_ text: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }
}

// 预览
struct NameConverterView_Previews: PreviewProvider {
    static var previews: some View {
        NameConverterView()
    }
} 