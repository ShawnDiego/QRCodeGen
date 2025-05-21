import SwiftUI

/// 现代化按钮样式
/// 提供多种统一设计风格的按钮样式，适用于macOS平台
struct ModernButtonStyle {
    
    /// 主操作按钮样式
    /// 用于应用中最主要的操作，如"生成二维码"
    struct Primary: ButtonStyle {
        var isEnabled: Bool = true
        var icon: String? = nil
        
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: 8) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                configuration.label
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    isEnabled ? Color.blue : Color.gray.opacity(0.7),
                                    isEnabled ? Color.blue.opacity(0.8) : Color.gray.opacity(0.5)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.7)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .shadow(color: isEnabled ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
        }
    }
    
    /// 次要按钮样式
    /// 用于普通操作，如"导出"、"关闭"等
    struct Secondary: ButtonStyle {
        var isEnabled: Bool = true
        var icon: String? = nil
        
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: 6) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 12))
                }
                
                configuration.label
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlBackgroundColor))
                    
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }
            )
            .foregroundColor(Color(NSColor.controlTextColor))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
    
    /// 控制按钮样式
    /// 用于功能切换，如"置顶"等
    struct Control: ButtonStyle {
        var isActive: Bool = false
        var icon: String? = nil
        
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: 6) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 12))
                }
                
                configuration.label
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                    
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isActive ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
                }
            )
            .foregroundColor(isActive ? Color.blue : Color(NSColor.controlTextColor))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
    
    /// 危险操作按钮样式
    /// 用于危险操作，如"删除"
    struct Danger: ButtonStyle {
        var icon: String? = nil
        
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: 6) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 12))
                }
                
                configuration.label
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red.opacity(configuration.isPressed ? 0.1 : 0.05))
                    
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                }
            )
            .foregroundColor(Color.red)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

/// 为Button添加便捷修饰符
extension Button {
    /// 应用主操作按钮样式
    func modernPrimary(enabled: Bool = true, icon: String? = nil) -> some View {
        self.buttonStyle(ModernButtonStyle.Primary(isEnabled: enabled, icon: icon))
            .disabled(!enabled)
    }
    
    /// 应用次要按钮样式
    func modernSecondary(enabled: Bool = true, icon: String? = nil) -> some View {
        self.buttonStyle(ModernButtonStyle.Secondary(isEnabled: enabled, icon: icon))
            .disabled(!enabled)
    }
    
    /// 应用控制按钮样式
    func modernControl(isActive: Bool = false, icon: String? = nil) -> some View {
        self.buttonStyle(ModernButtonStyle.Control(isActive: isActive, icon: icon))
    }
    
    /// 应用危险操作按钮样式
    func modernDanger(icon: String? = nil) -> some View {
        self.buttonStyle(ModernButtonStyle.Danger(icon: icon))
    }
} 