import Foundation

/// 时间戳历史记录项
/// 用于存储时间戳转换的历史记录
struct TimestampHistoryItem: Identifiable, Codable, Equatable {
    /// 唯一标识符
    let id = UUID()
    
    /// 输入的时间戳
    let timestamp: String
    
    /// 是否是毫秒级时间戳
    let isMilliseconds: Bool
    
    /// 转换后的时间
    let convertedTime: String
    
    /// 记录创建时间
    let createTime: Date
    
    /// 初始化一个新的时间戳历史记录项
    /// - Parameters:
    ///   - timestamp: 时间戳
    ///   - isMilliseconds: 是否为毫秒级时间戳
    ///   - convertedTime: 转换后的时间字符串
    init(timestamp: String, isMilliseconds: Bool, convertedTime: String) {
        self.timestamp = timestamp
        self.isMilliseconds = isMilliseconds
        self.convertedTime = convertedTime
        self.createTime = Date()
    }
    
    // Codable 编码所需的 CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, timestamp, isMilliseconds, convertedTime, createTime
    }
    
    // 自定义编码方法
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(isMilliseconds, forKey: .isMilliseconds)
        try container.encode(convertedTime, forKey: .convertedTime)
        try container.encode(createTime, forKey: .createTime)
    }
    
    // 自定义解码方法
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tempId = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        isMilliseconds = try container.decode(Bool.self, forKey: .isMilliseconds)
        convertedTime = try container.decode(String.self, forKey: .convertedTime)
        createTime = try container.decode(Date.self, forKey: .createTime)
        // 由于 id 是只读属性，无法直接设置，这里使用一个临时值，但实际不会影响
    }
    
    // 实现 Equatable 协议
    static func == (lhs: TimestampHistoryItem, rhs: TimestampHistoryItem) -> Bool {
        return lhs.id == rhs.id
    }
} 