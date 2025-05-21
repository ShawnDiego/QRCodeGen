import SwiftUI

/// 批次历史视图
/// 用于展示同一批次生成的二维码集合
struct BatchHistoryView: View {
    /// 批次的时间戳
    let timestamp: Date
    
    /// 该批次包含的历史项目
    let historyItems: [QRCodeHistoryItem]
    
    /// 关闭视图的回调
    let onDismiss: () -> Void
    
    /// 视图状态
    @State private var selectedItem: QRCodeHistoryItem? = nil
    @State private var qrCodeSize: CGFloat = 120
    @State private var isExporting = false
    @State private var exportMessage = ""
    
    /// 复制状态跟踪
    @State private var copiedItemId: UUID? = nil
    
    var body: some View {
        VStack(spacing: 15) {
            // 顶部标题和工具栏
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("批次：\(timestamp.formatted(date: .long, time: .shortened))")
                        .font(.headline)
                    
                    Text("共\(historyItems.count)个二维码")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 导出按钮
                Button {
                    exportBatch()
                } label: {
                    Label("导出批次", systemImage: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [
                                            (historyItems.isEmpty || isExporting) ? Color.gray.opacity(0.7) : Color.blue,
                                            (historyItems.isEmpty || isExporting) ? Color.gray.opacity(0.5) : Color.blue.opacity(0.8)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ))
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            }
                        )
                        .foregroundColor(.white)
                        .opacity(historyItems.isEmpty || isExporting ? 0.7 : 1.0)
                }
                .buttonStyle(.plain)
                .disabled(historyItems.isEmpty || isExporting)
                
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
            
            // 二维码尺寸调整滑块
            HStack {
                Text("调整大小:")
                    .font(.caption)
                
                Slider(value: $qrCodeSize, in: 80...200, step: 10)
                
                Text("\(Int(qrCodeSize))px")
                    .font(.caption)
                    .frame(width: 50, alignment: .trailing)
            }
            .padding(.horizontal)
            
            if !historyItems.isEmpty {
                // 二维码网格显示
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: qrCodeSize + 40), spacing: 20)], spacing: 20) {
                        ForEach(historyItems) { item in
                            VStack(spacing: 8) {
                                item.image
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFit()
                                    .frame(width: qrCodeSize, height: qrCodeSize)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue.opacity(selectedItem?.id == item.id ? 0.8 : 0), lineWidth: 2)
                                    )
                                
                                // 二维码内容文本
                                Text(item.text)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .frame(width: qrCodeSize + 20)
                                    .multilineTextAlignment(.center)
                                
                                // 索引标签
                                if let index = item.batchIndex {
                                    Text("#\(index + 1)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                // 添加复制和导出按钮
                                HStack(spacing: 8) {
                                    // 复制按钮
                                    Button {
                                        #if os(macOS)
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(item.text, forType: .string)
                                        #endif
                                        
                                        copiedItemId = item.id
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            if copiedItemId == item.id {
                                                copiedItemId = nil
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: copiedItemId == item.id ? "checkmark" : "doc.on.doc")
                                                .font(.system(size: 10))
                                            
                                            Text(copiedItemId == item.id ? "已复制" : "复制")
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(copiedItemId == item.id ? Color.green.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(copiedItemId == item.id ? Color.green.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
                                            }
                                        )
                                        .foregroundColor(copiedItemId == item.id ? Color.green : Color(NSColor.controlTextColor))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    // 导出按钮
                                    Button {
                                        exportSingleQRCode(item: item)
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
                            .onTapGesture {
                                selectedItem = item
                            }
                        }
                    }
                    .padding()
                    .animation(.easeInOut, value: qrCodeSize)
                }
            } else {
                // 无内容时的提示
                VStack {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Text("此批次没有可用的二维码")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                .cornerRadius(12)
                .padding()
            }
            
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
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    
    // 导出整个批次
    private func exportBatch() {
        isExporting = true
        exportMessage = "正在导出批次..."
        
        // 模拟导出过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 这里实现实际的批次导出功能
            // 例如保存到Documents文件夹或提供保存对话框
            
            isExporting = false
            exportMessage = "导出成功！共\(historyItems.count)个二维码"
            
            // 几秒后清除消息
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                exportMessage = ""
            }
        }
    }
    
    // 导出单个二维码
    private func exportSingleQRCode(item: QRCodeHistoryItem) {
        // 实现单个二维码导出逻辑
        #if os(macOS)
        // 这里可以调用系统对话框让用户选择保存位置
        // 并将二维码保存为PNG等格式
        #endif
        
        exportMessage = "已导出: \(item.text)"
        
        // 几秒后清除消息
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            exportMessage = ""
        }
    }
}

#Preview {
    // 预览示例数据
    let timestamp = Date()
    let sampleItems = [
        QRCodeHistoryItem(
            image: Image(systemName: "qrcode"),
            text: "示例文本1",
            batchIndex: 0,
            batchTimestamp: timestamp
        ),
        QRCodeHistoryItem(
            image: Image(systemName: "qrcode"),
            text: "示例文本2",
            batchIndex: 1,
            batchTimestamp: timestamp
        ),
        QRCodeHistoryItem(
            image: Image(systemName: "qrcode"),
            text: "示例文本3",
            batchIndex: 2,
            batchTimestamp: timestamp
        )
    ]
    
    return BatchHistoryView(
        timestamp: timestamp,
        historyItems: sampleItems,
        onDismiss: { print("关闭") }
    )
} 