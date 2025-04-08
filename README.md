# QRCode 生成器

一个功能强大的二维码生成器应用，支持单个和批量生成二维码，并提供丰富的自定义选项。

## 功能特点

- 单个二维码生成
- 批量二维码生成
- 自动检测分隔符
- 自定义分隔符
- 二维码尺寸调整
- 历史记录管理
- 批量导出功能
- 窗口置顶（仅 macOS）
- 快捷键支持

## 项目结构

```
QRCode/
├── Models/                 # 数据模型
│   ├── QRCodeHistoryItem.swift
│   └── QRCodeDetailWrapper.swift
├── Views/                  # 视图组件
│   ├── ContentView.swift
│   ├── BatchQRCodeDisplayView.swift
│   ├── QRCodeDetailView.swift
│   └── BatchHistoryView.swift
├── Utils/                  # 工具类
│   ├── QRCodeGenerator.swift
│   └── FileManager.swift
└── QRCodeApp.swift         # 应用入口
```

## 使用说明

### 单个二维码生成
1. 在输入框中输入要生成二维码的内容
2. 点击"生成二维码"按钮
3. 生成的二维码会显示在输入框上方

### 批量二维码生成
1. 打开"高级功能"
2. 启用"批量生成"功能
3. 选择或自动检测分隔符
4. 输入多行内容或使用分隔符分隔的内容
5. 点击"生成二维码"按钮

### 历史记录
- 点击历史记录中的项目可以重新使用
- 右键点击可以查看更多操作
- 支持删除单条记录或清空所有记录

### 批量导出
- 支持导出单个二维码
- 支持批量导出所有二维码
- 导出时自动生成信息文件

## 开发环境

- Xcode 15.0+
- Swift 5.9+
- macOS 13.0+

## 安装说明

1. 克隆项目
2. 使用 Xcode 打开项目
3. 编译并运行

## 贡献指南

欢迎提交 Issue 和 Pull Request 来帮助改进项目。

## 许可证

MIT License 