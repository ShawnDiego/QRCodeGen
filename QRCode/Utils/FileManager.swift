import AppKit
import SwiftUI
import CoreImage.CIFilterBuiltins

/// 二维码生成器
/// 提供二维码生成和保存相关功能
class QRCodeGenerator {
    /// 创建二维码图片
    /// - Parameters:
    ///   - content: 二维码内容
    ///   - size: 二维码尺寸
    /// - Returns: 生成的二维码图片，如果生成失败则返回 nil
    static func createQRCodeImage(content: String, size: CGFloat) -> Image? {
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
    
    /// 将二维码内容生成图片并保存到指定路径
    /// - Parameters:
    ///   - content: 二维码内容
    ///   - url: 保存路径
    static func saveQRImageToFile(content: String, url: URL) {
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

/// 文件管理器
/// 提供文件保存和导出相关功能
class FileManager {
    /// 保存单个二维码图片
    /// - Parameters:
    ///   - content: 二维码内容
    ///   - index: 二维码索引
    static func saveQRCodeImage(content: String, index: Int) {
        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "QRCode-\(index+1).png"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                QRCodeGenerator.saveQRImageToFile(content: content, url: url)
            }
        }
        #endif
    }
    
    /// 批量导出二维码
    /// - Parameters:
    ///   - qrCodes: 二维码数组，包含内容和图片
    ///   - timestamp: 生成时间戳
    static func exportAllQRCodes(qrCodes: [(text: String, image: Image)], timestamp: Date? = nil) {
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
                if let timestamp = timestamp {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .medium
                    exportInfo += "生成时间: \(formatter.string(from: timestamp))\n"
                }
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
                    QRCodeGenerator.saveQRImageToFile(content: qrCode.text, url: fileURL)
                    
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
} 