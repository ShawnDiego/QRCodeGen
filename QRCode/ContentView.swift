import SwiftUI
import AppKit
import CoreImage.CIFilterBuiltins

struct QRCodeHistoryItem: Identifiable {
    let id = UUID()
    let image: Image
    let text: String
}

struct ContentView: View {
    @State private var input: String = ""
    @State private var qrCode: Image?
    @State private var history: [QRCodeHistoryItem] = [] // 存储二维码和文字的历史记录
    @State private var showDeleteConfirmation = false // 控制"全部删除"确认对话框
    @State private var isWindowAlwaysOnTop = false // 窗口置顶状态
    
    // 新增的状态变量
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
                                Text(item.text)
                                    .lineLimit(1)
                                    .truncationMode(.tail) // 文字过长时截断
                            }
                            .onTapGesture {
                                selectHistoryItem(item)
                            }
                            .contextMenu {
                                Button("删除") {
                                    deleteItem(item)
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
                    HStack {
                        // 侧边栏切换按钮（仅在 macOS 显示）
                        #if os(macOS)
                        HStack{
                            Button(action: toggleSidebar) {
                                Label("侧边栏",systemImage: "sidebar.leading")
                            }
                            .padding(.horizontal)
                            Button {
                                toggleWindowAlwaysOnTop()
                            } label: {
                                Label(isWindowAlwaysOnTop ? "取消置顶" : "置顶窗口", systemImage: isWindowAlwaysOnTop ? "pin.slash" : "pin")
                            }
                            .padding(.horizontal)
                        }

                        #endif

                        Spacer()
                    }
                    .padding(.top)

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
                            
                            Text("输入多行内容或使用分隔符，将为每一部分内容生成二维码")
                                .font(.caption)
                                .foregroundColor(.secondary)
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

                    Button("生成二维码") {
                        if showAdvancedOptions {
                            // 如果高级选项打开，执行批量生成（使用设置的分隔符或默认换行符）
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
                            
                            if let newQRCode = createQRCodeImage(content: input, size: 300) {
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
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .keyboardShortcut(.return, modifiers: [.command]) // 添加快捷键Cmd+Return
                    .disabled(input.isEmpty || isGenerating) // 如果输入为空或正在生成则禁用
                    
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
                        qrCode
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 300)
                            .padding()
                    } else {
                        Text("二维码将显示在这里")
                            .foregroundColor(.gray)
                            .padding()
                            .frame(height: 200)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.bottom)
            }
            .navigationTitle("二维码生成器")
            .frame(minWidth: 450, minHeight: 650)
            .sheet(isPresented: $showBatchView) {
                BatchQRCodeDisplayView(qrCodes: batchGeneratedQRCodes) {
                    showBatchView = false
                }
            }
        }
        .frame(minWidth: 700, minHeight: 650)
        .onAppear {
            setupWindow()
        }
    }
    
    // 设置窗口的最小尺寸
    private func setupWindow() {
        #if os(macOS)
        if let window = NSApp.windows.first {
            window.setContentSize(NSSize(width: 700, height: 650))
            window.minSize = NSSize(width: 700, height: 650)
        }
        #endif
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
                            .frame(width: 150, height: 150)
                        
                        Text(batchGeneratedQRCodes[index].text)
                            .font(.caption)
                            .lineLimit(2)
                            .frame(width: 150)
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
        
        var newQRCodes: [(text: String, image: Image)] = []
        
        for text in texts {
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if let qrImage = createQRCodeImage(content: trimmedText, size: 150) {
                newQRCodes.append((text: trimmedText, image: qrImage))
            }
        }
        
        batchGeneratedQRCodes = newQRCodes
        
        if !newQRCodes.isEmpty {
            // 界面更新移到调用方的主线程
            // showBatchView = true
        }
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

        // 设置放大比例，确保输出图像更清晰
        let scaleX = size / ciImage.extent.size.width
        let scaleY = size / ciImage.extent.size.height
        let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // 使用 CIContext 渲染 CIImage 到 CGImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }
        
        // 使用 CGImage 创建 NSImage
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
        
        // 返回 SwiftUI Image
        return Image(nsImage: nsImage)
    }

    /// 切换窗口置顶状态（仅限 macOS）
    #if os(macOS)
    func toggleWindowAlwaysOnTop() {
        if let window = NSApp.keyWindow {
            window.level = isWindowAlwaysOnTop ? .normal : .floating
            isWindowAlwaysOnTop.toggle()
        }
    }
    #endif

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
}

// 批量二维码全屏展示视图
struct BatchQRCodeDisplayView: View {
    let qrCodes: [(text: String, image: Image)]
    let onDismiss: () -> Void
    
    @State private var selectedQRCode: QRCodeDetailWrapper? = nil
    @State private var columns = [GridItem(.adaptive(minimum: 180))]
    @State private var gridSpacing: CGFloat = 20
    
    var body: some View {
        VStack {
            headerView
            controlsView
            qrCodeGridView
        }
        .frame(minWidth: 700, minHeight: 500)
        .sheet(item: $selectedQRCode) { wrapper in
            QRCodeDetailView(
                qrCode: qrCodes[wrapper.id].image,
                text: qrCodes[wrapper.id].text,
                onDismiss: { selectedQRCode = nil }
            )
        }
        .onAppear {
            setupSheetSize()
        }
    }
    
    // 设置Sheet窗口大小
    private func setupSheetSize() {
        #if os(macOS)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.windows.first(where: { $0.isVisible && $0 != NSApp.mainWindow }) {
                window.setContentSize(NSSize(width: 800, height: 600))
                window.minSize = NSSize(width: 700, height: 500)
            }
        }
        #endif
    }
    
    // 顶部标题和按钮
    private var headerView: some View {
        HStack {
            Text("批量生成结果（\(qrCodes.count)个）")
                .font(.headline)
            
            Spacer()
            
            Button("批量导出全部") {
                exportAllQRCodes()
            }
            .buttonStyle(.bordered)
            
            Button("关闭") {
                onDismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding()
    }
    
    // 控制视图 - 调整间距和网格大小
    private var controlsView: some View {
        HStack {
            Slider(value: $gridSpacing, in: 10...50) {
                Text("间距")
            }
            .frame(width: 100)
            
            Text("间距: \(Int(gridSpacing))")
                .font(.caption)
                .frame(width: 60)
            
            Spacer()
            
            Button(action: { columns = [GridItem(.adaptive(minimum: 120))] }) {
                Image(systemName: "square.grid.3x3")
            }
            .buttonStyle(.bordered)
            
            Button(action: { columns = [GridItem(.adaptive(minimum: 180))] }) {
                Image(systemName: "square.grid.2x2")
            }
            .buttonStyle(.bordered)
            
            Button(action: { columns = [GridItem(.adaptive(minimum: 250))] }) {
                Image(systemName: "square.grid.2x2.fill")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
    }
    
    // 二维码网格视图
    private var qrCodeGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: gridSpacing) {
                ForEach(0..<qrCodes.count, id: \.self) { index in
                    qrCodeItemView(index: index)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 单个二维码项视图
    private func qrCodeItemView(index: Int) -> some View {
        VStack {
            qrCodes[index].image
                .resizable()
                .interpolation(.none) // 保持二维码清晰
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding()
            
            Text(qrCodes[index].text)
                .font(.caption)
                .lineLimit(2)
                .padding(.horizontal)
                .padding(.bottom, 5)
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        .cornerRadius(8)
        .shadow(radius: 2)
        .onTapGesture {
            selectedQRCode = QRCodeDetailWrapper(id: index)
        }
        .contextMenu {
            Button("保存图片") {
                saveQRCodeImage(index: index)
            }
            Button("复制内容") {
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(qrCodes[index].text, forType: .string)
                #endif
            }
        }
    }
    
    // 导出所有二维码到一个文件夹
    func exportAllQRCodes() {
        #if os(macOS)
        let openPanel = NSOpenPanel()
        openPanel.title = "选择保存目录"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                // 创建导出信息文本
                var exportInfo = "二维码批量导出信息\n"
                exportInfo += "导出时间: \(Date().formatted(date: .complete, time: .complete))\n"
                exportInfo += "共\(qrCodes.count)个二维码\n\n"
                
                // 批量保存二维码图片
                for (index, qrCode) in qrCodes.enumerated() {
                    // 构建文件名：使用索引和部分内容
                    let shortContent = String(qrCode.text.prefix(20))
                        .replacingOccurrences(of: "/", with: "-")
                        .replacingOccurrences(of: "\\", with: "-")
                        .replacingOccurrences(of: ":", with: "-")
                        .replacingOccurrences(of: "*", with: "-")
                        .replacingOccurrences(of: "?", with: "-")
                        .replacingOccurrences(of: "\"", with: "-")
                        .replacingOccurrences(of: "<", with: "-")
                        .replacingOccurrences(of: ">", with: "-")
                        .replacingOccurrences(of: "|", with: "-")
                    let fileName = "\(index+1)_\(shortContent).png"
                    let fileURL = url.appendingPathComponent(fileName)
                    
                    // 保存二维码图片
                    saveQRImageToFile(content: qrCode.text, url: fileURL)
                    
                    // 添加导出信息
                    exportInfo += "序号: \(index+1)\n"
                    exportInfo += "文件名: \(fileName)\n"
                    exportInfo += "内容: \(qrCode.text)\n\n"
                }
                
                // 保存导出信息文本文件
                let infoFileURL = url.appendingPathComponent("导出信息.txt")
                try? exportInfo.write(to: infoFileURL, atomically: true, encoding: .utf8)
                
                // 打开导出目录
                NSWorkspace.shared.open(url)
            }
        }
        #endif
    }
    
    // 保存二维码图片
    func saveQRCodeImage(index: Int) {
        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "QRCode-\(index+1).png"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                // 重新生成二维码并保存
                let content = qrCodes[index].text
                saveQRImageToFile(content: content, url: url)
            }
        }
        #endif
    }
    
    // 将二维码内容生成图片并保存到指定路径
    private func saveQRImageToFile(content: String, url: URL) {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return }
        let data = content.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // 高纠错级别
        
        if let outputImage = filter.outputImage {
            let size: CGFloat = 1024
            let scaleX = size / outputImage.extent.size.width
            let scaleY = size / outputImage.extent.size.height
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            
            let context = CIContext()
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
                
                if let tiffData = nsImage.tiffRepresentation,
                   let bitmapRep = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                    
                    do {
                        try pngData.write(to: url)
                    } catch {
                        print("保存失败: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

// 用于Sheet展示的包装器
struct QRCodeDetailWrapper: Identifiable {
    let id: Int
}

// 单个二维码详情视图
struct QRCodeDetailView: View {
    let qrCode: Image
    let text: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button("关闭") {
                    onDismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .padding()
            }
            
            Spacer()
            
            qrCode
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(minWidth: 250, maxWidth: 400, maxHeight: 400)
                .padding()
            
            ScrollView {
                Text(text)
                    .font(.body)
                    .padding()
                    .textSelection(.enabled) // 允许选择文本
            }
            .frame(maxHeight: 150)
            .background(Color(NSColor.textBackgroundColor).opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button("保存图片") {
                    saveQRCodeImage()
                }
                .buttonStyle(.bordered)
                
                Button("复制内容") {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    #endif
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .frame(minWidth: 500, minHeight: 600)
        .onAppear {
            setupDetailWindow()
        }
    }
    
    // 设置详情窗口大小
    private func setupDetailWindow() {
        #if os(macOS)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.windows.first(where: { $0.isVisible && !($0.identifier?.rawValue.contains("BatchQRCodeDisplayView") ?? false) }) {
                window.setContentSize(NSSize(width: 500, height: 600))
                window.minSize = NSSize(width: 500, height: 600)
            }
        }
        #endif
    }
    
    // 保存二维码图片
    func saveQRCodeImage() {
        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "QRCode.png"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                // 重新生成二维码并保存
                saveQRImageToFile(content: text, url: url)
            }
        }
        #endif
    }
    
    // 将二维码内容生成图片并保存到指定路径
    private func saveQRImageToFile(content: String, url: URL) {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return }
        let data = content.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // 高纠错级别
        
        if let outputImage = filter.outputImage {
            let size: CGFloat = 1024
            let scaleX = size / outputImage.extent.size.width
            let scaleY = size / outputImage.extent.size.height
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            
            let context = CIContext()
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
                
                if let tiffData = nsImage.tiffRepresentation,
                   let bitmapRep = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                    
                    do {
                        try pngData.write(to: url)
                    } catch {
                        print("保存失败: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
