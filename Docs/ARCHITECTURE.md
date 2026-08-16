# Prompt Dock 技术架构

## 1. 产品边界

Prompt Dock 是面向高频复制工作流的 macOS 快捷面板，不是笔记数据库。它将“完整 Prompt 库”和“当前悬浮面板”分开：后台保存所有内容，工作预设决定面板当前显示哪些 Prompt。

当前版本已实现管理后台与多工作预设；暂不实现拖动排序、iCloud、市场、团队共享和 AI Agent 调用，但数据模型与存储接口为它们保留升级路径。

## 2. 分层结构

```text
AppKit 窗口层
  FloatingPanel / RadialMenu / EdgeShelf / StatusItem / GlobalHotKey
                  │
SwiftUI 展示层    │
  ContentView / PromptCardView / RadialMenuView / EdgeShelfView / ManagementView
                  │
状态与业务层      │
  PromptStore ─── Clipboard
                  │
存储抽象层        │
  PromptRepository
        │
  JSONPromptRepository（MVP）
```

- AppKit 负责 macOS 特有能力：始终置顶、跨桌面、菜单栏、窗口位置、全局快捷键、按键转盘和屏幕边缘感应。
- SwiftUI 负责可组合界面、深色模式和动态状态。
- `PromptStore` 是单一 UI 状态来源，执行预设筛选、分类筛选、复制、CRUD 与持久化。
- `PromptRepository` 隔离存储实现。后续可以新增 `SwiftDataPromptRepository` 或 `CloudKitPromptRepository`，而不影响 UI。

## 3. 数据流

1. App 启动时从 `Application Support/AIPromptDock/library.json` 读取数据。
2. 首次启动自动写入一份示例库，用户数据完全保存在本机。
3. 点击 Prompt 后写入系统剪贴板，更新 `lastUsedAt` 与 `useCount`。
4. 每次变更使用原子写入，避免中途退出造成半个 JSON 文件。
5. 工作预设只保存 Prompt UUID 引用，同一 Prompt 可以显示在多个预设中而不重复正文。
6. JSON 顶层带 `schemaVersion`，旧版数据会迁移并自动创建“全部提示词”预设。
7. 工作预设分别保存面板、转盘和侧边栏引用；转盘支持 4/6/8 槽位与独立排序，为空时使用预设前若干项。
8. 每条 Prompt 自己保存主模型图标；未指定模型时回退到分类图标，不再由预设替 Prompt 决定模型身份。

## 4. 扩展路线

- 管理后台：现已通过独立窗口提供 Prompt、分类和工作预设 CRUD，以及转盘槽位排序。
- 导入/导出：管理后台已接入完整 JSON 备份与恢复。
- iCloud：用 SwiftData + CloudKit 实现新的 Repository，并保留 JSON 备份。
- 团队与市场：引入“库来源、所有者、只读状态、远端版本”等元数据；远端数据先同步到本地缓存，日常复制仍不依赖网络。
- Agent 调用：将 Prompt 内容作为独立领域对象传给 Provider Adapter，不把供应商逻辑写入视图。

## 5. MVP 技术选择

| 项目 | 选择 | 原因 |
|---|---|---|
| UI | SwiftUI | 原生深色模式、组件迭代快 |
| 窗口 | AppKit `NSPanel` | 精确控制浮层、层级与 Space 行为 |
| 存储 | Codable JSON | 易备份、易检查、无迁移负担 |
| 设置 | UserDefaults | 适合透明度和窗口位置 |
| 快捷键 | Carbon Hot Key API + CGEvent Tap | 组合键不需要额外权限；单键转盘经用户授权后监听 |
| 最低系统 | macOS 14 | 使用现代 SwiftUI API，同时覆盖近年设备 |
