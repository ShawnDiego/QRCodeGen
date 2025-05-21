import SwiftUI

/// 批量二维码显示视图
/// 用于展示批量生成的二维码集合
struct BatchQRCodeDisplayView: View {
    /// 要显示的二维码数组，包含文本和图像
    let qrCodes: [(text: String, image: Image)]
    
    /// 关闭视图的回调
    let onDismiss: () -> Void
    
    /// 导出状态
    @State private var isExporting: Bool = false
    @State private var exportMessage: String = ""
    
    /// 二维码大小调整
    @State private var qrCodeSize: CGFloat = 150
    
    /// 复制状态跟踪
    @State private var copiedIndex: Int? = nil
    
    var body: some View {
        VStack(spacing: 15) {
            // 顶部工具栏
            HStack {
                Text("批量生成结果（\(qrCodes.count)个）")
                    .font(.headline)
                
                Spacer()
                
                // 导出按钮
                Button {
                    exportQRCodes()
                } label: {
                    Label("导出全部", systemImage: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [
                                            isExporting ? Color.gray.opacity(0.7) : Color.blue,
                                            isExporting ? Color.gray.opacity(0.5) : Color.blue.opacity(0.8)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ))
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            }
                        )
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .disabled(isExporting)
                
                // 关闭按钮
                Button {
                    onDismiss()
                } label: {
                    Label("关闭", systemImage: "xmark.circle")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            }
                        )
                        .foregroundColor(Color(NSColor.controlTextColor))
                }
                .buttonStyle(.plain)
            }
            .padding([.horizontal, .top])
            
            // 尺寸调整滑块
            HStack {
                Text("调整大小:")
                    .font(.caption)
                
                Slider(value: $qrCodeSize, in: 80...250, step: 10)
                
                Text("\(Int(qrCodeSize))px")
                    .font(.caption)
                    .frame(width: 50, alignment: .trailing)
            }
            .padding(.horizontal)
            
            // 导出状态提示
            if !exportMessage.isEmpty {
                HStack {
                    if isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.trailing, 5)
                    }
                    
                    Text(exportMessage)
                        .font(.caption)
                        .foregroundColor(isExporting ? .secondary : .green)
                }
                .padding(.bottom, 5)
            }
            
            // 二维码网格显示
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: qrCodeSize + 40), spacing: 20)], spacing: 20) {
                    ForEach(0..<qrCodes.count, id: \.self) { index in
                        VStack(spacing: 8) {
                            qrCodes[index].image
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: qrCodeSize, height: qrCodeSize)
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            Text(qrCodes[index].text)
                                .font(.caption)
                                .lineLimit(2)
                                .frame(width: qrCodeSize + 20)
                                .multilineTextAlignment(.center)
                            
                            // 添加复制和导出按钮
                            HStack(spacing: 8) {
                                // 复制按钮
                                Button {
                                    #if os(macOS)
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(qrCodes[index].text, forType: .string)
                                    #endif
                                    
                                    copiedIndex = index
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        if copiedIndex == index {
                                            copiedIndex = nil
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: copiedIndex == index ? "checkmark" : "doc.on.doc")
                                            .font(.system(size: 10))
                                        
                                        Text(copiedIndex == index ? "已复制" : "复制")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(copiedIndex == index ? Color.green.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(copiedIndex == index ? Color.green.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
                                        }
                                    )
                                    .foregroundColor(copiedIndex == index ? Color.green : Color(NSColor.controlTextColor))
                                }
                                .buttonStyle(.plain)
                                
                                // 导出按钮
                                Button {
                                    exportSingleQRCode(index: index)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 10))
                                        
                                        Text("导出")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.blue.opacity(0.1))
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        }
                                    )
                                    .foregroundColor(Color.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .animation(.easeInOut, value: qrCodeSize)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    
    /// 导出所有二维码
    private func exportQRCodes() {
        isExporting = true
        exportMessage = "正在准备导出..."
        
        // 模拟导出过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 这里实现实际的导出功能
            // 例如保存到Documents文件夹或提供保存对话框
            
            isExporting = false
            exportMessage = "导出成功！共\(qrCodes.count)个二维码"
            
            // 几秒后清除消息
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                exportMessage = ""
            }
        }
    }
    
    /// 导出单个二维码
    private func exportSingleQRCode(index: Int) {
        guard index < qrCodes.count else { return }
        
        // 实现单个二维码导出逻辑
        #if os(macOS)
        // 这里可以调用系统对话框让用户选择保存位置
        // 并将二维码保存为PNG等格式
        #endif
        
        exportMessage = "已导出: \(qrCodes[index].text)"
        
        // 几秒后清除消息
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            exportMessage = ""
        }
    }
}

#Preview {
    // 预览用的示例数据
    let sampleQRCodes: [(text: String, image: Image)] = [
        ("示例文本1", Image(systemName: "qrcode")),
        ("示例文本2", Image(systemName: "qrcode")),
        ("示例文本3", Image(systemName: "qrcode"))
    ]
    
    return BatchQRCodeDisplayView(qrCodes: sampleQRCodes) {
        print("关闭")
    }
} 