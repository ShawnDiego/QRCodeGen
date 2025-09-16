import Foundation
import CoreData
import SwiftUI
import CoreImage.CIFilterBuiltins
import AppKit

/// 二维码历史记录 CoreData 实体
@objc(QRCodeHistoryEntity)
public class QRCodeHistoryEntity: NSManagedObject {
    
}

extension QRCodeHistoryEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<QRCodeHistoryEntity> {
        return NSFetchRequest<QRCodeHistoryEntity>(entityName: "QRCodeHistoryEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var text: String
    @NSManaged public var isBatchGenerated: Bool
    @NSManaged public var batchIndex: Int32
    @NSManaged public var batchTimestamp: Date?
    @NSManaged public var createTime: Date
}

// MARK: - 计算属性
extension QRCodeHistoryEntity {
    
    /// 生成二维码图片
    var image: Image? {
        return createQRCodeImage(content: text, size: 200)
    }
    
    /// 转换为QRCodeHistoryItem（用于兼容现有代码）
    var toHistoryItem: QRCodeHistoryItem? {
        guard let image = self.image else { return nil }
        
        if isBatchGenerated, let batchTimestamp = batchTimestamp {
            return QRCodeHistoryItem(
                image: image,
                text: text,
                batchIndex: Int(batchIndex),
                batchTimestamp: batchTimestamp,
                id: id,
                createTime: createTime
            )
        } else {
            return QRCodeHistoryItem(
                image: image,
                text: text,
                id: id,
                createTime: createTime
            )
        }
    }
    
    /// 从QRCodeHistoryItem创建实体
    static func from(_ item: QRCodeHistoryItem, context: NSManagedObjectContext) -> QRCodeHistoryEntity {
        let entity = QRCodeHistoryEntity(context: context)
        entity.id = item.id
        entity.text = item.text
        entity.isBatchGenerated = item.isBatchGenerated
        entity.batchIndex = Int32(item.batchIndex ?? 0)
        entity.batchTimestamp = item.batchTimestamp
        entity.createTime = item.createTime
        return entity
    }
    
    /// 创建二维码图片
    private func createQRCodeImage(content: String, size: CGFloat) -> Image? {
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
}

// MARK: - Identifiable conformance
extension QRCodeHistoryEntity : Identifiable {

} 