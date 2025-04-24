import Foundation

public enum NamingConvention {
    case camelCase        // 小驼峰: userName
    case pascalCase       // 大驼峰: UserName
    case snakeCase        // 下划线: user_name
    case kebabCase        // 连字符: user-name
    case upperSnakeCase   // 大写下划线: USER_NAME
    case spacedCase       // 空格命名: user name
    case unknown
    
    public var description: String {
        switch self {
        case .camelCase: return "小驼峰命名法 (camelCase)"
        case .pascalCase: return "大驼峰命名法 (PascalCase)"
        case .snakeCase: return "下划线命名法 (snake_case)"
        case .kebabCase: return "连字符命名法 (kebab-case)"
        case .upperSnakeCase: return "大写下划线命名法 (UPPER_SNAKE_CASE)"
        case .spacedCase: return "空格命名法 (spaced case)"
        case .unknown: return "未知命名法"
        }
    }
}

// 为 NamingConvention 添加 CaseIterable
extension NamingConvention: CaseIterable {
    public static var allCases: [NamingConvention] {
        return [.camelCase, .pascalCase, .snakeCase, .kebabCase, .upperSnakeCase, .spacedCase, .unknown]
    }
}

public struct NameConverter {
    
    // 识别命名规范
    public static func detectNamingConvention(_ input: String) -> NamingConvention {
        // 空字符串或仅有一个单词的情况
        if input.isEmpty || !input.contains(where: { $0.isUppercase || $0 == "_" || $0 == "-" || $0 == " " }) {
            return .unknown
        }
        
        // 检查是否有连字符
        if input.contains("-") {
            return .kebabCase
        }
        
        // 检查是否有空格
        if input.contains(" ") {
            return .spacedCase
        }
        
        // 检查是否有下划线
        if input.contains("_") {
            // 检查是否全部是大写
            if input.filter({ $0.isLetter }).allSatisfy({ $0.isUppercase }) {
                return .upperSnakeCase
            }
            return .snakeCase
        }
        
        // 检查首字母是否大写
        if let firstChar = input.first, firstChar.isUppercase {
            return .pascalCase
        }
        
        // 检查是否包含大写字母（不在首位）
        if input.dropFirst().contains(where: { $0.isUppercase }) {
            return .camelCase
        }
        
        return .unknown
    }
    
    // 获取单词数组（将不同命名格式的字符串分解为单词）
    public static func getWords(from input: String) -> [String] {
        let convention = detectNamingConvention(input)
        
        switch convention {
        case .camelCase, .pascalCase:
            // 使用正则表达式分割驼峰命名
            let pattern = "(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])"
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(input.startIndex..., in: input)
            let matches = regex?.matches(in: input, range: range) ?? []
            
            // 构建分割后的单词
            var words: [String] = []
            var lastEnd = 0
            
            for match in matches {
                let start = lastEnd
                let end = match.range.location
                
                if let wordRange = Range(NSRange(location: start, length: end - start), in: input) {
                    let word = String(input[wordRange])
                    words.append(word)
                }
                
                lastEnd = end
            }
            
            // 添加最后一个单词
            if let lastWordRange = Range(NSRange(location: lastEnd, length: input.count - lastEnd), in: input) {
                words.append(String(input[lastWordRange]))
            }
            
            return words
            
        case .snakeCase, .upperSnakeCase:
            return input.components(separatedBy: "_").filter { !$0.isEmpty }
            
        case .kebabCase:
            return input.components(separatedBy: "-").filter { !$0.isEmpty }
            
        case .spacedCase:
            return input.components(separatedBy: " ").filter { !$0.isEmpty }
            
        case .unknown:
            // 对于未知格式，返回原始字符串
            return [input]
        }
    }
    
    // 转换为小驼峰命名法
    public static func toCamelCase(_ input: String) -> String {
        let words = getWords(from: input).map { $0.lowercased() }
        guard !words.isEmpty else { return input }
        
        return words.enumerated().map { index, word in
            if index == 0 {
                return word.lowercased()
            } else {
                return word.prefix(1).uppercased() + word.dropFirst().lowercased()
            }
        }.joined()
    }
    
    // 转换为大驼峰命名法
    public static func toPascalCase(_ input: String) -> String {
        let words = getWords(from: input)
        guard !words.isEmpty else { return input }
        
        return words.map { word in
            word.prefix(1).uppercased() + word.dropFirst().lowercased()
        }.joined()
    }
    
    // 转换为下划线命名法
    public static func toSnakeCase(_ input: String) -> String {
        let words = getWords(from: input)
        guard !words.isEmpty else { return input }
        
        return words.map { $0.lowercased() }.joined(separator: "_")
    }
    
    // 转换为大写下划线命名法
    public static func toUpperSnakeCase(_ input: String) -> String {
        let words = getWords(from: input)
        guard !words.isEmpty else { return input }
        
        return words.map { $0.uppercased() }.joined(separator: "_")
    }
    
    // 转换为连字符命名法
    public static func toKebabCase(_ input: String) -> String {
        let words = getWords(from: input)
        guard !words.isEmpty else { return input }
        
        return words.map { $0.lowercased() }.joined(separator: "-")
    }
    
    // 转换为空格命名法
    public static func toSpacedCase(_ input: String) -> String {
        let words = getWords(from: input)
        guard !words.isEmpty else { return input }
        
        return words.map { $0.lowercased() }.joined(separator: " ")
    }
    
    // 将一个字符串转换为所有命名方式
    public static func convertToAllFormats(_ input: String) -> [NamingConvention: String] {
        guard !input.isEmpty else { return [:] }
        
        return [
            .camelCase: toCamelCase(input),
            .pascalCase: toPascalCase(input),
            .snakeCase: toSnakeCase(input),
            .kebabCase: toKebabCase(input),
            .upperSnakeCase: toUpperSnakeCase(input),
            .spacedCase: toSpacedCase(input)
        ]
    }
} 