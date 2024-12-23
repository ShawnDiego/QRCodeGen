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
    @State private var showDeleteConfirmation = false // 控制“全部删除”确认对话框
    @State private var isWindowAlwaysOnTop = false // 窗口置顶状态

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
            .frame(minWidth: 250) // 设置侧边栏宽度

            // 主界面
            VStack(spacing: 20) {
                HStack {
                    // 侧边栏切换按钮（仅在 macOS 显示）
                    #if os(macOS)
                    HStack{
                        Button(action: toggleSidebar) {
                            Label("侧边栏",systemImage: "sidebar.leading")
                        }
                        .padding()
                        Button {
                            toggleWindowAlwaysOnTop()
                        } label: {
                            Label(isWindowAlwaysOnTop ? "取消置顶" : "置顶窗口", systemImage: isWindowAlwaysOnTop ? "pin.slash" : "pin")
                        }
                        .padding()
                    }

                    #endif

                    Spacer()
                }

                TextField("请输入内容", text: $input)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("生成二维码") {
                    if let newQRCode = createQRCodeImage(content: input, size: 300) {
                        qrCode = newQRCode
                        let newItem = QRCodeHistoryItem(image: newQRCode, text: input)
                        history.insert(newItem, at: 0) // 将新记录添加到历史顶部
                    }
                }
                .buttonStyle(.borderedProminent)

                if let qrCode = qrCode {
                    qrCode
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .padding()
                } else {
                    Text("二维码将显示在这里")
                        .foregroundColor(.gray)
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("二维码生成器")
        }
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
}

#Preview {
    ContentView()
}
