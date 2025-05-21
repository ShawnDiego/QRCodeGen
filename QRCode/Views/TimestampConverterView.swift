import SwiftUI
import AppKit
import Foundation // 确保导入Foundation

struct TimestampConverterView: View {
    @State private var inputText: String = ""
    @State private var convertedTime: String = ""
    @State private var isMilliseconds: Bool = true
    @State private var errorMessage: String = ""
    @State private var copiedStatus: Bool = false
    @State private var currentDateText: String = ""
    @State private var currentTimestamp: String = ""
    
    // 历史记录相关状态
    @State private var history: [TimestampHistoryItem] = []
    @State private var selectedHistoryItem: TimestampHistoryItem? = nil
    @State private var showHistoryPanel: Bool = false
    @State private var copiedHistoryItemId: UUID? = nil
    @State private var showClearAlert: Bool = false
    
    // 更新当前时间的定时器
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // UserDefaults 键名
    private let historyKey = "timestampConversionHistory"
    
    var body: some View {
        ZStack {
            // 主视图内容
            VStack(alignment: .leading, spacing: 20) {
                // 顶部操作栏
                HStack {
                    // 标题
                    Text("时间戳转换")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    Spacer()
                    
                    // 历史记录按钮
                    Button {
                        showHistoryPanel.toggle()
                    } label: {
                        Label("历史记录", systemImage: "clock.arrow.circlepath")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(showHistoryPanel ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(showHistoryPanel ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
                                }
                            )
                            .foregroundColor(showHistoryPanel ? Color.blue : Color(NSColor.controlTextColor))
                    }
                    .buttonStyle(.plain)
                }
                
                // 当前时间参考
                VStack(alignment: .leading, spacing: 6) {
                    Text("当前时间参考")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 10) {
                        Text(currentDateText)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                        
                        Text(currentTimestamp)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                            
                        Button(action: {
                            copyToClipboard(currentTimestamp)
                        }) {
                            Label("复制时间戳", systemImage: "doc.on.doc")
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            }
                        )
                        .foregroundColor(Color(NSColor.controlTextColor))
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
                
                // 分隔线
                Divider()
                    .padding(.vertical, 5)
                
                // 输入区域
                VStack(alignment: .leading, spacing: 10) {
                    Text("输入时间戳")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("请输入时间戳...", text: $inputText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: inputText) { _ in
                                convertTimestamp()
                            }
                        
                        Button(action: pasteFromClipboard) {
                            Label("粘贴", systemImage: "doc.on.clipboard")
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            }
                        )
                        .foregroundColor(Color(NSColor.controlTextColor))
                        .buttonStyle(.plain)
                        
                        Button(action: clearInput) {
                            Label("清除", systemImage: "xmark.circle")
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.red.opacity(0.05))
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            }
                        )
                        .foregroundColor(Color.red)
                        .buttonStyle(.plain)
                        .disabled(inputText.isEmpty)
                        .opacity(inputText.isEmpty ? 0.5 : 1.0)
                    }
                    
                    // 单位选择器
                    HStack(spacing: 20) {
                        Toggle(isOn: $isMilliseconds) {
                            Text(isMilliseconds ? "毫秒" : "秒")
                        }
                        .toggleStyle(.switch)
                        .onChange(of: isMilliseconds) { _ in
                            convertTimestamp()
                        }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // 转换结果
                if !convertedTime.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("转换结果")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // 添加到历史记录按钮
                            Button {
                                addToHistory()
                            } label: {
                                Label("添加到历史记录", systemImage: "plus.circle")
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text(convertedTime)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            Button(action: {
                                copyToClipboard(convertedTime)
                                copiedStatus = true
                                
                                // 2秒后重置复制状态
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedStatus = false
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: copiedStatus ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 10))
                                    
                                    Text(copiedStatus ? "已复制" : "复制")
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(copiedStatus ? Color.green.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(copiedStatus ? Color.green.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
                                    }
                                )
                                .foregroundColor(copiedStatus ? Color.green : Color(NSColor.controlTextColor))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                updateCurrentTime()
                loadHistory()
            }
            .onReceive(timer) { _ in
                updateCurrentTime()
            }
            
            // 历史记录面板
            if showHistoryPanel {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // 历史记录面板标题栏
                        HStack {
                            Text("历史记录")
                                .font(.headline)
                            
                            Spacer()
                            
                            // 清空历史记录按钮
                            if !history.isEmpty {
                                Button {
                                    showClearAlert = true
                                } label: {
                                    Label("清空", systemImage: "trash")
                                        .font(.system(size: 12, weight: .medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                .alert(isPresented: $showClearAlert) {
                                    Alert(
                                        title: Text("确认清空历史记录"),
                                        message: Text("此操作将清空所有历史记录，且无法恢复。"),
                                        primaryButton: .destructive(Text("清空")) {
                                            clearHistory()
                                        },
                                        secondaryButton: .cancel(Text("取消"))
                                    )
                                }
                            }
                            
                            // 关闭面板按钮
                            Button {
                                showHistoryPanel = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color(NSColor.controlBackgroundColor))
                        
                        // 分隔线
                        Divider()
                        
                        // 历史记录列表
                        if history.isEmpty {
                            VStack {
                                Spacer()
                                Text("暂无历史记录")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        } else {
                            List {
                                ForEach(history.sorted(by: { $0.createTime > $1.createTime })) { item in
                                    HistoryItemRow(
                                        item: item,
                                        isSelected: selectedHistoryItem?.id == item.id,
                                        copiedItemId: $copiedHistoryItemId,
                                        onSelect: {
                                            selectedHistoryItem = item
                                            inputText = item.timestamp
                                            isMilliseconds = item.isMilliseconds
                                            convertedTime = item.convertedTime
                                        },
                                        onCopy: { text in
                                            copyToClipboard(text)
                                            copiedHistoryItemId = item.id
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                if copiedHistoryItemId == item.id {
                                                    copiedHistoryItemId = nil
                                                }
                                            }
                                        },
                                        onDelete: { deleteHistoryItem(item) }
                                    )
                                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                                }
                            }
                        }
                    }
                    .frame(width: min(geometry.size.width * 0.8, 400), height: geometry.size.height * 0.7)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 0)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .background(Color.black.opacity(0.3).edgesIgnoringSafeArea(.all))
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: showHistoryPanel)
            }
        }
    }
    
    // MARK: - 历史记录相关方法
    
    /// 添加当前转换结果到历史记录
    private func addToHistory() {
        guard !inputText.isEmpty && !convertedTime.isEmpty else { return }
        
        // 创建新的历史记录项
        let newItem = TimestampHistoryItem(
            timestamp: inputText,
            isMilliseconds: isMilliseconds, 
            convertedTime: convertedTime
        )
        
        // 检查是否已存在相同的记录（相同时间戳和单位）
        if !history.contains(where: { 
            $0.timestamp == newItem.timestamp && $0.isMilliseconds == newItem.isMilliseconds 
        }) {
            // 添加到历史记录
            history.append(newItem)
            selectedHistoryItem = newItem
            
            // 保存到 UserDefaults
            saveHistory()
        }
    }
    
    /// 加载历史记录
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey) {
            do {
                let decoder = JSONDecoder()
                history = try decoder.decode([TimestampHistoryItem].self, from: data)
            } catch {
                print("加载历史记录失败: \(error)")
                history = []
            }
        }
    }
    
    /// 保存历史记录
    private func saveHistory() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("保存历史记录失败: \(error)")
        }
    }
    
    /// 清空历史记录
    private func clearHistory() {
        history = []
        selectedHistoryItem = nil
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
    
    /// 删除单个历史记录
    private func deleteHistoryItem(_ item: TimestampHistoryItem) {
        if selectedHistoryItem?.id == item.id {
            selectedHistoryItem = nil
        }
        history.removeAll(where: { $0.id == item.id })
        saveHistory()
    }
    
    // MARK: - 时间戳转换相关方法
    
    // 将时间戳转换为日期时间
    private func convertTimestamp() {
        errorMessage = ""
        guard !inputText.isEmpty else {
            convertedTime = ""
            return
        }
        
        guard let timestamp = Double(inputText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = "无效的时间戳格式"
            convertedTime = ""
            return
        }
        
        // 判断时间戳是秒还是毫秒
        let timeInterval: TimeInterval
        if isMilliseconds {
            timeInterval = timestamp / 1000.0
        } else {
            timeInterval = timestamp
        }
        
        // 验证时间戳是否在合理范围内（1970年到2100年）
        let minTimestamp: TimeInterval = 0
        let maxTimestamp: TimeInterval = 4102444800 // 2100-01-01 00:00:00
        
        if timeInterval < minTimestamp || timeInterval > maxTimestamp {
            errorMessage = "时间戳超出合理范围"
            convertedTime = ""
            return
        }
        
        let date = Date(timeIntervalSince1970: timeInterval)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone.current
        
        convertedTime = formatter.string(from: date)
    }
    
    // 从剪贴板粘贴
    private func pasteFromClipboard() {
        #if os(macOS)
        if let clipboardString = NSPasteboard.general.string(forType: .string) {
            inputText = clipboardString
            convertTimestamp()
        }
        #endif
    }
    
    // 清除输入
    private func clearInput() {
        inputText = ""
        convertedTime = ""
        errorMessage = ""
        selectedHistoryItem = nil
    }
    
    // 复制到剪贴板
    private func copyToClipboard(_ text: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }
    
    // 更新当前时间
    private func updateCurrentTime() {
        let now = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.timeZone = TimeZone.current
        
        currentDateText = dateFormatter.string(from: now)
        
        // 当前时间戳（毫秒）
        let timestamp = UInt64(now.timeIntervalSince1970 * 1000)
        currentTimestamp = "\(timestamp)"
    }
}

// MARK: - 历史记录项行视图
struct HistoryItemRow: View {
    let item: TimestampHistoryItem
    let isSelected: Bool
    @Binding var copiedItemId: UUID?
    let onSelect: () -> Void
    let onCopy: (String) -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 时间信息
            HStack {
                Text(item.createTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.createTime, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 删除按钮
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                        .padding(4)
                }
                .buttonStyle(.plain)
            }
            
            // 主要内容
            HStack(alignment: .top, spacing: 12) {
                // 时间戳和转换结果
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(item.timestamp)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(1)
                        
                        Text(item.isMilliseconds ? "毫秒" : "秒")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Text("→")
                            .foregroundColor(.secondary)
                        
                        Text(item.convertedTime)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1)
                )
                .onTapGesture {
                    onSelect()
                }
                
                // 操作按钮
                VStack(spacing: 8) {
                    // 复制时间戳按钮
                    Button {
                        onCopy(item.timestamp)
                    } label: {
                        Image(systemName: (copiedItemId == item.id) ? "checkmark" : "doc.on.doc")
                            .frame(width: 24, height: 24)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    
                    // 复制转换结果按钮
                    Button {
                        onCopy(item.convertedTime)
                    } label: {
                        Image(systemName: (copiedItemId == item.id) ? "checkmark" : "doc.on.doc")
                            .frame(width: 24, height: 24)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.textBackgroundColor))
        )
    }
}

// 预览
struct TimestampConverterView_Previews: PreviewProvider {
    static var previews: some View {
        TimestampConverterView()
    }
} 