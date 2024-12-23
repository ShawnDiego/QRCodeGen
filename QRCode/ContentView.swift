import SwiftUI
import AppKit
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var input: String = ""
    @State private var qrCode: Image?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 输入框
                TextField("请输入内容", text: $input)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // 生成按钮
                Button("生成 QR Code") {
                    qrCode = createQRCodeImage(content: input, size: 300)
                }
                .buttonStyle(.borderedProminent)

                // 展示二维码
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
            .navigationTitle("QR Code 生成器")
        }
    }

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
}

#Preview {
    ContentView()
}
