import SwiftUI

/// 二维码历史记录项
/// 用于存储生成的二维码及其相关信息
struct QRCodeHistoryItem: Identifiable {
    /// 唯一标识符
    let id = UUID()
    
    /// 二维码图片
    let image: Image
    
    /// 二维码内容
    let text: String
    
    /// 是否为批量生成的一部分
    let isBatchGenerated: Bool
    
    /// 在批量生成中的索引，可选
    let batchIndex: Int?
    
    /// 批量生成的时间戳，用于将同一批次的项目关联起来
    let batchTimestamp: Date?
    
    /// 生成时间
    let createTime: Date
    
    /// 简便初始化方法，默认为非批量生成
    /// - Parameters:
    ///   - image: 二维码图片
    ///   - text: 二维码内容
    init(image: Image, text: String) {
        self.image = image
        self.text = text
        self.isBatchGenerated = false
        self.batchIndex = nil
        self.batchTimestamp = nil
        self.createTime = Date()
    }
    
    /// 批量生成项目的初始化方法
    /// - Parameters:
    ///   - image: 二维码图片
    ///   - text: 二维码内容
    ///   - batchIndex: 在批量生成中的索引
    ///   - batchTimestamp: 批量生成的时间戳
    init(image: Image, text: String, batchIndex: Int, batchTimestamp: Date) {
        self.image = image
        self.text = text
        self.isBatchGenerated = true
        self.batchIndex = batchIndex
        self.batchTimestamp = batchTimestamp
        self.createTime = Date()
    }
} 
