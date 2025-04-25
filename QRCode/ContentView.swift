import SwiftUI
import AppKit
import CoreImage.CIFilterBuiltins

/// 主视图容器
struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isWindowAlwaysOnTop = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                #if os(macOS)
                Button {
                    toggleWindowAlwaysOnTop()
                } label: {
                    Label(isWindowAlwaysOnTop ? "取消置顶" : "置顶窗口", systemImage: isWindowAlwaysOnTop ? "pin.slash" : "pin")
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, 6)
                #endif
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            // 主要内容区域使用TabView
            TabView(selection: $selectedTab) {
                // 二维码生成器模块
                QRCodeGeneratorView()
                    .tabItem {
                        Label("二维码生成", systemImage: "qrcode")
                    }
                    .tag(0)
                
                // 变量命名转换器模块
                NameConverterView()
                    .tabItem {
                        Label("变量命名转换", systemImage: "character.textbox")
                    }
                    .tag(1)
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
    
    /// 切换窗口置顶状态（仅限 macOS）
    #if os(macOS)
    func toggleWindowAlwaysOnTop() {
        if let window = NSApp.keyWindow {
            window.level = isWindowAlwaysOnTop ? .normal : .floating
            isWindowAlwaysOnTop.toggle()
        }
    }
    #endif
}

#Preview {
    ContentView()
}
