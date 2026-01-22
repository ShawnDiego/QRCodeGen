import Foundation

public struct BaseConverter {
    
    /// 将十进制数转换为指定进制
    /// - Parameters:
    ///   - decimal: 十进制数（可以是很大的数字，使用字符串传入）
    ///   - toBase: 目标进制（2-36）
    /// - Returns: 转换后的字符串，如果输入无效则返回空字符串
    public static func decimalToBase(_ decimal: String, toBase: Int) -> String {
        // 验证进制范围
        guard toBase >= 2, toBase <= 36 else { return "" }
        
        // 去掉前后空格
        let trimmed = decimal.trimmingCharacters(in: .whitespaces)
        
        // 验证输入是否为有效的十进制数
        guard !trimmed.isEmpty, let decimalValue = Int64(trimmed) else {
            return ""
        }
        
        // 处理特殊情况：0
        if decimalValue == 0 {
            return "0"
        }
        
        // 处理负数
        let isNegative = decimalValue < 0
        var number = abs(decimalValue)
        
        let digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var result = ""
        
        while number > 0 {
            let remainder = Int(number % Int64(toBase))
            result = String(digits[digits.index(digits.startIndex, offsetBy: remainder)]) + result
            number /= Int64(toBase)
        }
        
        return isNegative ? "-\(result)" : result
    }
    
    /// 将任意进制数转换为十进制
    /// - Parameters:
    ///   - value: 进制数字符串
    ///   - fromBase: 源进制（2-36）
    /// - Returns: 十进制数字符串，如果输入无效则返回空字符串
    public static func baseToDecimal(_ value: String, fromBase: Int) -> String {
        // 验证进制范围
        guard fromBase >= 2, fromBase <= 36 else { return "" }
        
        // 去掉前后空格
        let trimmed = value.uppercased().trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "" }
        
        // 处理负数
        let isNegative = trimmed.hasPrefix("-")
        let numberString = isNegative ? String(trimmed.dropFirst()) : trimmed
        
        // 验证输入字符的有效性
        let validChars = String("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ".prefix(fromBase))
        guard numberString.allSatisfy({ validChars.contains(String($0)) }) else {
            return ""
        }
        
        // 转换为十进制
        var decimalValue: Int64 = 0
        for char in numberString {
            decimalValue *= Int64(fromBase)
            
            if let digit = Int64(String(char), radix: 10) {
                decimalValue += digit
            } else if let digit = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".firstIndex(of: char) {
                let position = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".distance(from: "ABCDEFGHIJKLMNOPQRSTUVWXYZ".startIndex, to: digit)
                decimalValue += Int64(position + 10)
            }
        }
        
        let result = String(decimalValue)
        return isNegative ? "-\(result)" : result
    }
    
    /// 在两个任意进制之间转换
    /// - Parameters:
    ///   - value: 源数字
    ///   - fromBase: 源进制
    ///   - toBase: 目标进制
    /// - Returns: 转换后的字符串
    public static func convert(_ value: String, fromBase: Int, toBase: Int) -> String {
        // 先转换为十进制，再转换为目标进制
        let decimal = baseToDecimal(value, fromBase: fromBase)
        guard !decimal.isEmpty else { return "" }
        
        return decimalToBase(decimal, toBase: toBase)
    }
    
    /// 验证字符串是否为有效的指定进制数
    /// - Parameters:
    ///   - value: 要验证的字符串
    ///   - base: 进制数
    /// - Returns: 是否有效
    public static func isValidBase(_ value: String, base: Int) -> Bool {
        guard base >= 2, base <= 36 else { return false }
        
        let trimmed = value.uppercased().trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        
        // 处理负数
        let numberString = trimmed.hasPrefix("-") ? String(trimmed.dropFirst()) : trimmed
        guard !numberString.isEmpty else { return false }
        
        let validChars = String("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ".prefix(base))
        return numberString.allSatisfy({ validChars.contains(String($0)) })
    }
    
    /// 检测字符串最可能的进制（自动检测）
    /// - Parameter value: 要检测的字符串
    /// - Returns: 检测到的进制（默认为10）
    public static func detectBase(_ value: String) -> Int {
        let trimmed = value.uppercased().trimmingCharacters(in: .whitespaces)
        let numberString = trimmed.hasPrefix("-") ? String(trimmed.dropFirst()) : trimmed
        
        guard !numberString.isEmpty else { return 10 }
        
        // 检查是否包含无效的十进制数字
        let hasNonDecimal = numberString.contains { char in
            !char.isNumber
        }
        
        if !hasNonDecimal {
            // 全部是数字，可能是任何进制
            // 检查是否看起来像二进制（只有0和1）
            if numberString.allSatisfy({ $0 == "0" || $0 == "1" }) {
                return 2
            }
            // 否则默认为十进制
            return 10
        }
        
        // 包含字母，找出最高的字母代表的进制
        var maxBase = 2
        for char in numberString {
            if let digit = Int(String(char), radix: 10) {
                maxBase = max(maxBase, digit + 1)
            } else if char >= "A" && char <= "Z" {
                let position = Int(char.asciiValue! - 65) + 10
                maxBase = max(maxBase, position + 1)
            }
        }
        
        return maxBase
    }
    
    /// 获取进制的描述
    /// - Parameter base: 进制数
    /// - Returns: 进制的描述
    public static func baseDescription(_ base: Int) -> String {
        switch base {
        case 2: return "二进制"
        case 8: return "八进制"
        case 10: return "十进制"
        case 16: return "十六进制"
        default: return "\(base)进制"
        }
    }
}
