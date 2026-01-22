import SwiftUI
import AppKit

struct BaseConverterView: View {
    @State private var inputText: String = ""
    @State private var inputBase: Int = 10
    @State private var outputBase: Int = 2
    @State private var outputText: String = ""
    @State private var errorMessage: String = ""
    @State private var copiedIndex: Int? = nil
    @State private var autoDetect: Bool = true
    
    // 常用进制选项
    let commonBases = [2, 8, 10, 16]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 标题
            Text("进制转换")
                .font(.system(size: 24, weight: .bold))
            
            // 自动检测开关
            Toggle("自动检测源进制", isOn: $autoDetect)
                .onChange(of: autoDetect) { _ in
                    if autoDetect && !inputText.isEmpty {
                        inputBase = BaseConverter.detectBase(inputText)
                    }
                    updateConversion()
                }
                .font(.system(size: 16))
            
            // ===== 源数据区域 =====
            VStack(alignment: .leading, spacing: 12) {
                // 标题
                HStack(spacing: 12) {
                    Text("源数据")
                        .font(.system(size: 16, weight: .semibold))
                    
                    // 进制选择 - 紧邻标题
                    HStack(spacing: 6) {
                        Text("进制:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        // 快速选择按钮
                        ForEach(commonBases, id: \.self) { base in
                            Button(action: {
                                inputBase = base
                                autoDetect = false
                                updateConversion()
                            }) {
                                Text("\(base)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(minWidth: 36, minHeight: 32)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(inputBase == base ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    )
                                    .foregroundColor(inputBase == base ? Color.blue : Color(NSColor.controlTextColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(inputBase == base ? Color.blue.opacity(0.6) : Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // 自定义进制输入
                        TextField("其他", value: $inputBase, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 13))
                            .frame(width: 60)
                            .onChange(of: inputBase) { _ in
                                validateInputBase()
                                autoDetect = false
                                updateConversion()
                            }
                        
                        Spacer()
                    }
                }
                
                // 输入框
                HStack(spacing: 10) {
                    TextField("输入数字...", text: $inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 16, design: .monospaced))
                        .onChange(of: inputText) { _ in
                            updateConversion()
                        }
                    
                    Button(action: clearInput) {
                        Label("清除", systemImage: "xmark.circle.fill")
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.red.opacity(0.08))
                    )
                    .foregroundColor(Color.red)
                    .buttonStyle(.plain)
                    .disabled(inputText.isEmpty)
                    .opacity(inputText.isEmpty ? 0.5 : 1.0)
                }
            }
            .padding(14)
            .background(Color.gray.opacity(0.04))
            .cornerRadius(10)
            
            // ===== 源进制信息 =====
            if !inputText.isEmpty && errorMessage.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("源进制信息")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("\(BaseConverter.baseDescription(inputBase)) (\(inputBase)进制)")
                            .font(.system(size: 14, design: .monospaced))
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
                .padding(10)
                .background(Color.blue.opacity(0.06))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
            }
            
            // ===== 错误提示 =====
            if !errorMessage.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(12)
                .background(Color.red.opacity(0.08))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
            }
            
            // ===== 转换结果区域 =====
            VStack(alignment: .leading, spacing: 12) {
                // 标题
                HStack(spacing: 12) {
                    Text("转换结果")
                        .font(.system(size: 16, weight: .semibold))
                    
                    // 进制选择 - 紧邻标题
                    HStack(spacing: 6) {
                        Text("进制:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        // 快速选择按钮
                        ForEach(commonBases, id: \.self) { base in
                            Button(action: {
                                outputBase = base
                                updateConversion()
                            }) {
                                Text("\(base)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(minWidth: 36, minHeight: 32)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(outputBase == base ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                                    )
                                    .foregroundColor(outputBase == base ? Color.green : Color(NSColor.controlTextColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(outputBase == base ? Color.green.opacity(0.6) : Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // 自定义进制输入
                        TextField("其他", value: $outputBase, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 13))
                            .frame(width: 60)
                            .onChange(of: outputBase) { _ in
                                validateOutputBase()
                                updateConversion()
                            }
                        
                        Spacer()
                    }
                }
                
                // 输出框
                HStack(spacing: 10) {
                    TextField("转换结果", text: $outputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 16, design: .monospaced))
                        .onChange(of: outputText) { newValue in
                            // 反向转换
                            if !newValue.isEmpty && errorMessage.isEmpty {
                                let detected = autoDetect ? BaseConverter.detectBase(inputText) : inputBase
                                if let decimal = BaseConverter.baseToDecimal(newValue, fromBase: outputBase) as String?, !decimal.isEmpty {
                                    // 验证输出值是否有效
                                    if BaseConverter.isValidBase(newValue, base: outputBase) {
                                        inputText = BaseConverter.decimalToBase(decimal, toBase: detected)
                                    }
                                }
                            }
                        }
                    
                    Button(action: {
                        copyToClipboard(outputText)
                        copiedIndex = 0
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            if copiedIndex == 0 {
                                copiedIndex = nil
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: copiedIndex == 0 ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12, weight: .semibold))
                            
                            Text(copiedIndex == 0 ? "已复制" : "复制")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(copiedIndex == 0 ? Color.green.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                        )
                        .foregroundColor(copiedIndex == 0 ? Color.green : Color(NSColor.controlTextColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(copiedIndex == 0 ? Color.green.opacity(0.4) : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(outputText.isEmpty)
                }
            }
            .padding(14)
            .background(Color.gray.opacity(0.04))
            .cornerRadius(10)
            
            // ===== 目标进制信息 =====
            if !outputText.isEmpty && errorMessage.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("目标进制信息")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("\(BaseConverter.baseDescription(outputBase)) (\(outputBase)进制)")
                            .font(.system(size: 14, design: .monospaced))
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
                .padding(10)
                .background(Color.green.opacity(0.06))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
            }
            
            Spacer()
        }
        .padding(20)
        .frame(minWidth: 650, minHeight: 500)
    }
    
    private func validateInputBase() {
        if inputBase < 2 || inputBase > 36 {
            inputBase = max(2, min(36, inputBase))
        }
    }
    
    private func validateOutputBase() {
        if outputBase < 2 || outputBase > 36 {
            outputBase = max(2, min(36, outputBase))
        }
    }
    
    private func updateConversion() {
        guard !inputText.isEmpty else {
            outputText = ""
            errorMessage = ""
            return
        }
        
        // 自动检测源进制
        let sourceBase = autoDetect ? BaseConverter.detectBase(inputText) : inputBase
        
        // 验证输入
        if !BaseConverter.isValidBase(inputText, base: sourceBase) {
            errorMessage = "输入值在\(sourceBase)进制中无效"
            outputText = ""
            return
        }
        
        // 执行转换
        let result = BaseConverter.convert(inputText, fromBase: sourceBase, toBase: outputBase)
        
        if result.isEmpty {
            errorMessage = "转换失败，请检查输入"
            outputText = ""
        } else {
            errorMessage = ""
            outputText = result
        }
    }
    
    private func clearInput() {
        inputText = ""
        outputText = ""
        errorMessage = ""
    }
    
    private func copyToClipboard(_ text: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }
}

// 预览
struct BaseConverterView_Previews: PreviewProvider {
    static var previews: some View {
        BaseConverterView()
    }
}
