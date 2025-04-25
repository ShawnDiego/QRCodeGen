import SwiftUI
import AppKit
import CoreImage.CIFilterBuiltins

/// 二维码生成器视图
struct QRCodeGeneratorView: View {
    @State private var input: String = ""
    @State private var qrCode: Image?
    @State private var history: [QRCodeHistoryItem] = [] // 存储二维码和文字的历史记录
    @State private var showDeleteConfirmation = false // 控制"全部删除"确认对话框
    @State private var isWindowAlwaysOnTop = false // 窗口置顶状态
    
    // 批量生成相关状态变量
    @State private var showAdvancedOptions = false // 控制高级选项区域的显示
    @State private var separator: String = "\n" // 默认分隔符为换行符
    @State private var separatorType: String = "\n" // 分隔符类型选择
    @State private var customSeparator: String = "" // 自定义分隔符
    @State private var useAutoDetectSeparator: Bool = false // 是否使用自动检测分隔符
    @State private var detectedSeparator: String = "" // 自动检测到的分隔符
    @State private var batchGeneratedQRCodes: [(text: String, image: Image)] = [] // 存储批量生成的二维码
    @State private var showBatchView = false // 控制批量生成结果的显示
    @State private var isGenerating = false // 是否正在生成二维码
    @State private var generationMessage = "" // 生成状态消息
    @State private var selectedBatchTimestamp: Date? = nil // 选中的批次时间戳
    @State private var showBatchHistoryView = false // 显示批次历史视图
    @State private var qrCodeSize: CGFloat = 200 // 默认二维码大小
    @State private var batchQRCodeSize: CGFloat = 150 // 批量二维码的默认大小
    @State private var isBatchGenerationEnabled = false // 控制批量生成功能的启用状态
    
    // 自定义生成二维码按钮视图
    private var generateQRCodeButton: some View {
        Button {
            if showAdvancedOptions && isBatchGenerationEnabled {
                // 如果高级选项打开且批量生成已启用，执行批量生成
                isGenerating = true
                generationMessage = "正在批量生成二维码..."
                
                // 使用异步操作避免界面卡顿
                DispatchQueue.global(qos: .userInitiated).async {
                    generateBatchQRCodes()
                    
                    DispatchQueue.main.async {
                        isGenerating = false
                        generationMessage = "生成完成！共\(batchGeneratedQRCodes.count)个二维码"
                    }
                }
            } else {
                // 否则执行单个二维码生成
                isGenerating = true
                generationMessage = "正在生成二维码..."
                
                if let newQRCode = createQRCodeImage(content: input, size: qrCodeSize) {
                    qrCode = newQRCode
                    let newItem = QRCodeHistoryItem(image: newQRCode, text: input)
                    history.insert(newItem, at: 0) // 将新记录添加到历史顶部
                    isGenerating = false
                    generationMessage = "生成成功！"
                } else {
                    isGenerating = false
                    generationMessage = "生成失败，请检查输入内容"
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title2)
                
                Text("生成二维码")
                    .font(.headline)
                
                if isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.leading, 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.blue.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            )
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isGenerating ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isGenerating)
        }
        .buttonStyle(.plain)
        .disabled(input.isEmpty || isGenerating)
        .keyboardShortcut(.return, modifiers: [.command])
    }
    
    var body: some View {
        NavigationView {
            // 侧边栏显示历史二维码和文字
            VStack {
                List {
                    Section(header: Text("历史记录")) {
                        ForEach(history) { item in
                            HStack {
                                item.image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50) // 调整二维码缩略图大小
                                    .padding(5)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.text)
                                        .lineLimit(1)
                                        .truncationMode(.tail) // 文字过长时截断
                                    
                                    HStack(spacing: 4) {
                                        if item.isBatchGenerated {
                                            Image(systemName: "rectangle.on.rectangle")
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                            
                                            Text("批量生成")
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Text(item.createTime.formatted(date: .numeric, time: .shortened))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .onTapGesture {
                                selectHistoryItem(item)
                            }
                            .contextMenu {
                                Button("使用此内容") {
                                    selectHistoryItem(item)
                                }
                                
                                Button("删除") {
                                    deleteItem(item)
                                }
                                
                                if item.isBatchGenerated {
                                    Divider()
                                    
                                    Button("查看同批次项目") {
                                        viewBatchItems(timestamp: item.batchTimestamp!)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(SidebarListStyle())

                // 全部删除按钮
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Label("全部删除", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain) // 移除默认背景样式
                .padding()
                .confirmationDialog("确定要删除所有历史记录吗？", isPresented: $showDeleteConfirmation) {
                    Button("删除所有", role: .destructive) {
                        history.removeAll()
                    }
                    Button("取消", role: .cancel) { }
                }
            }
            .frame(minWidth: 220) // 设置侧边栏宽度

            // 主界面
            ScrollView {
                VStack(spacing: 20) {
                    // 二维码显示区域
                    if !batchGeneratedQRCodes.isEmpty {
                        Button("查看批量生成结果 (\(batchGeneratedQRCodes.count)个)") {
                            showBatchView = true
                        }
                        .buttonStyle(.bordered)
                    }

                    if showBatchView && !batchGeneratedQRCodes.isEmpty {
                        // 批量生成的二维码展示区域
                        batchQRCodeView
                    } else if let qrCode = qrCode {
                        VStack(spacing: 10) {
                            qrCode
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: qrCodeSize, height: qrCodeSize)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .transition(.scale.combined(with: .opacity))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: qrCodeSize)
                            
                            // 单个二维码尺寸快速调整按钮
                            HStack(spacing: 15) {
                                Button(action: { qrCodeSize = max(qrCodeSize - 50, 100) }) {
                                    Image(systemName: "minus.magnifyingglass")
                                }
                                .buttonStyle(.bordered)
                                .disabled(qrCodeSize <= 100)
                                
                                Text("\(Int(qrCodeSize))×\(Int(qrCodeSize))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button(action: { qrCodeSize = min(qrCodeSize + 50, 400) }) {
                                    Image(systemName: "plus.magnifyingglass")
                                }
                                .buttonStyle(.bordered)
                                .disabled(qrCodeSize >= 400)
                            }
                        }
                    } else {
                        Text("二维码将显示在这里")
                            .foregroundColor(.gray)
                            .padding()
                            .frame(width: qrCodeSize, height: qrCodeSize)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.5))
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }

                    // 使用TextEditor替代TextField提供更好的多行输入体验
                    VStack(alignment: .leading) {
                        Text("输入内容:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        
                        TextEditor(text: $input)
                            .frame(minHeight: 100, maxHeight: 200)
                            .font(.system(size: 16))
                            .padding(4)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: input) { newValue in
                                // 在输入内容变化时，如果启用了自动检测，则自动分析分隔符
                                if useAutoDetectSeparator && !newValue.isEmpty {
                                    detectedSeparator = detectSeparator(in: newValue)
                                }
                            }
                    }
                    .padding(.horizontal)

                    // 高级选项切换按钮
                    DisclosureGroup("高级功能", isExpanded: $showAdvancedOptions) {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("批量生成功能")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // 二维码尺寸设置
                            VStack(alignment: .leading, spacing: 5) {
                                Text("二维码尺寸调整")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 5)
                                
                                HStack {
                                    Text("单个:")
                                        .font(.caption)
                                    Slider(value: $qrCodeSize, in: 100...400, step: 10)
                                        .frame(width: 120)
                                    Text("\(Int(qrCodeSize))px")
                                        .font(.caption)
                                        .frame(width: 50, alignment: .trailing)
                                }
                                
                                HStack {
                                    Text("批量:")
                                        .font(.caption)
                                    Slider(value: $batchQRCodeSize, in: 80...250, step: 10)
                                        .frame(width: 120)
                                    Text("\(Int(batchQRCodeSize))px")
                                        .font(.caption)
                                        .frame(width: 50, alignment: .trailing)
                                }
                            }
                            
                            Text("输入多行内容或使用分隔符，将为每一部分内容生成二维码")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 5)
                            
                            // 修改批量生成开关
                            Toggle("启用批量生成", isOn: $isBatchGenerationEnabled)
                                .toggleStyle(.switch)
                                .padding(.bottom, 5)
                            
                            HStack(alignment: .top, spacing: 20) {
                                VStack(alignment: .leading) {
                                    Text("分隔符设置:")
                                        .font(.subheadline)
                                    
                                    Toggle("自动检测分隔符", isOn: $useAutoDetectSeparator)
                                        .toggleStyle(.switch)
                                        .padding(.vertical, 5)
                                        .onChange(of: useAutoDetectSeparator) { newValue in
                                            // 切换到自动检测时，立即检测分隔符
                                            if newValue && !input.isEmpty {
                                                detectedSeparator = detectSeparator(in: input)
                                            } else {
                                                // 关闭自动检测时，清空检测结果
                                                detectedSeparator = ""
                                            }
                                        }
                                    
                                    ZStack(alignment: .topLeading) {
                                        // 自动检测模式UI
                                        if useAutoDetectSeparator {
                                            VStack(alignment: .leading, spacing: 6) {
                                                if !detectedSeparator.isEmpty {
                                                    HStack(spacing: 3) {
                                                        Text("检测到:")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                        
                                                        Text("\(displaySeparatorName(detectedSeparator))")
                                                            .font(.caption.bold())
                                                            .foregroundColor(.green)
                                                        
                                                        let itemCount = getItemCount(using: detectedSeparator)
                                                        Text("(可分割成\(itemCount)项)")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    .padding(.vertical, 5)
                                                } else {
                                                    Text("等待输入内容...")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .padding(.vertical, 5)
                                                }
                                            }
                                        }
                                        
                                        // 手动选择模式UI
                                        if !useAutoDetectSeparator {
                                            VStack(alignment: .leading) {
                                                Picker("分隔符类型", selection: $separatorType) {
                                                    Text("换行符").tag("\n")
                                                    Text("逗号").tag(",")
                                                    Text("分号").tag(";")
                                                    Text("空格").tag(" ")
                                                    Text("自定义").tag("custom")
                                                }
                                                .pickerStyle(.menu)
                                                
                                                if separatorType == "custom" {
                                                    TextField("自定义分隔符", text: $customSeparator)
                                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                                        .frame(width: 150)
                                                }
                                            }
                                        }
                                    }
                                    .frame(height: 70) // 固定高度防止布局跳动
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("提示：")
                                        .font(.subheadline)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("· 使用换行符时，请每行输入一个内容\n· 使用其他分隔符时，请在内容之间插入分隔符\n· 空白内容将被自动跳过")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        if useAutoDetectSeparator {
                                            Text("自动检测将分析内容中最常见的分隔符（如换行、逗号等），然后自动应用。")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                                .padding(.top, 5)
                                        }
                                    }
                                    .frame(minHeight: 80, alignment: .top) // 确保高度统一
                                }
                            }
                        }
                        .padding()
                        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)

                    generateQRCodeButton
                    
                    if isGenerating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.trailing, 5)
                            Text(generationMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 5)
                    } else if !generationMessage.isEmpty {
                        Text(generationMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 5)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.bottom)
            }
            .navigationTitle("二维码生成器")
            .sheet(isPresented: $showBatchView) {
                BatchQRCodeDisplayView(qrCodes: batchGeneratedQRCodes) {
                    showBatchView = false
                }
            }
            .sheet(isPresented: $showBatchHistoryView) {
                if let timestamp = selectedBatchTimestamp {
                    BatchHistoryView(
                        timestamp: timestamp,
                        historyItems: history.filter { $0.batchTimestamp == timestamp },
                        onDismiss: { showBatchHistoryView = false }
                    )
                }
            }
        }
    }
    
    // 批量生成的二维码展示视图
    var batchQRCodeView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                ForEach(0..<batchGeneratedQRCodes.count, id: \.self) { index in
                    VStack {
                        batchGeneratedQRCodes[index].image
                            .resizable()
                            .scaledToFit()
                            .frame(width: batchQRCodeSize, height: batchQRCodeSize)
                        
                        Text(batchGeneratedQRCodes[index].text)
                            .font(.caption)
                            .lineLimit(2)
                            .frame(width: batchQRCodeSize)
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .frame(maxHeight: 400)
    }
    
    // 批量生成二维码的函数
    func generateBatchQRCodes() {
        // 确定实际使用的分隔符
        let actualSeparator: String
        
        if useAutoDetectSeparator {
            // 如果启用了自动检测，先检测分隔符
            detectedSeparator = detectSeparator(in: input)
            actualSeparator = detectedSeparator
        } else if separatorType == "custom" {
            actualSeparator = customSeparator.isEmpty ? "\n" : customSeparator
        } else {
            actualSeparator = separatorType
        }
        
        let texts = input.components(separatedBy: actualSeparator)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // 如果没有有效内容，直接返回
        if texts.isEmpty {
            return
        }
        
        var newQRCodes: [(text: String, image: Image)] = []
        let batchTimestamp = Date() // 为整个批次创建一个时间戳
        
        for (index, text) in texts.enumerated() {
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if let qrImage = createQRCodeImage(content: trimmedText, size: batchQRCodeSize) {
                newQRCodes.append((text: trimmedText, image: qrImage))
                
                // 创建带有批量信息的历史记录项
                let newItem = QRCodeHistoryItem(
                    image: qrImage,
                    text: trimmedText,
                    batchIndex: index,
                    batchTimestamp: batchTimestamp
                )
                
                // 检查是否已存在相同内容的记录，避免重复
                if !history.contains(where: { $0.text == trimmedText }) {
                    history.insert(newItem, at: 0) // 将新记录添加到历史顶部
                }
            }
        }
        
        batchGeneratedQRCodes = newQRCodes
    }

    // 自动检测输入内容中可能的分隔符
    private func detectSeparator(in text: String) -> String {
        // 常见分隔符及其出现的次数
        var separatorCounts: [String: Int] = [
            "\n": 0,
            ",": 0,
            ";": 0,
            "\t": 0,
            " ": 0,
            "|": 0,
            "-": 0
        ]
        
        // 统计各种分隔符在文本中的出现次数
        for (separator, _) in separatorCounts {
            separatorCounts[separator] = text.components(separatedBy: separator).count - 1
        }
        
        // 寻找出现最多的分隔符（只有当划分后能得到多个非空内容时才考虑）
        var bestSeparator = "\n" // 默认使用换行符
        var maxCount = 0
        
        for (separator, count) in separatorCounts {
            // 忽略出现次数过少的分隔符（需要能划分成至少两个部分）
            if count <= 0 {
                continue
            }
            
            // 检查使用此分隔符划分后，能得到的有效内容数量
            let validParts = text.components(separatedBy: separator)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            // 只有当能获得多个有效内容时，才考虑使用此分隔符
            if validParts.count >= 2 && count > maxCount {
                bestSeparator = separator
                maxCount = count
            }
        }
        
        // 空格作为分隔符的特殊处理（只有当没有其他更好的分隔符时才使用）
        if bestSeparator == " " {
            // 检查使用空格分隔后，是否有合理数量的有效内容
            let spaceParts = text.components(separatedBy: " ")
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            // 如果空格分隔后的内容过多，可能不适合作为分隔符（比如普通文本）
            if spaceParts.count > 10 {
                bestSeparator = "\n" // 退回到使用换行符
            }
        }
        
        return bestSeparator
    }

    /// 删除单条历史记录
    func deleteItem(_ item: QRCodeHistoryItem) {
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history.remove(at: index)
        }
    }

    /// 选择历史记录条目
    func selectHistoryItem(_ item: QRCodeHistoryItem) {
        qrCode = item.image
        input = item.text
    }

    /// 创建二维码图片
    func createQRCodeImage(content: String, size: CGFloat) -> Image? {
        let filter = CIFilter.qrCodeGenerator()
        let data = content.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        guard let ciImage = filter.outputImage else {
            return nil
        }

        // 直接设置输出图像的大小
        let scaleX = size / ciImage.extent.size.width
        let scaleY = size / ciImage.extent.size.height
        let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // 使用 CIContext 渲染 CIImage 到 CGImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: CGRect(x: 0, y: 0, width: size, height: size)) else {
            return nil
        }
        
        // 使用 CGImage 创建 NSImage，确保大小完全一致
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
        
        // 返回 SwiftUI Image
        return Image(nsImage: nsImage)
    }

    /// 切换侧边栏显示/隐藏（仅限 macOS）
    #if os(macOS)
    func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar), with: nil)
    }
    #endif

    // 根据分隔符返回其对应的显示名称
    private func displaySeparatorName(_ separator: String) -> String {
        switch separator {
        case "\n": return "换行符"
        case ",": return "逗号"
        case ";": return "分号"
        case " ": return "空格"
        case "\t": return "制表符"
        default: return "'\(separator)'"
        }
    }

    // 获取分隔后的项目数
    private func getItemCount(using separator: String) -> Int {
        if input.isEmpty {
            return 0
        }
        
        let texts = input.components(separatedBy: separator)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return texts.count
    }

    // 查看同批次项目
    func viewBatchItems(timestamp: Date) {
        selectedBatchTimestamp = timestamp
        showBatchHistoryView = true
    }
} 