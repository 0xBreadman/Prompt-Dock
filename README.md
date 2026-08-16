# Prompt Dock

<p align="center">
  <img src="Docs/Brand/AppIcon-master-v3-selected.png" width="128" alt="Prompt Dock icon">
</p>

一个本地优先、始终置顶的 macOS Prompt 快捷面板。它不是笔记软件：后台保存完整 Prompt 库，工作预设决定当前面板、按键转盘和屏幕边缘栏显示哪些内容。

> 当前为用于验证工作流思路的早期原型。欢迎试用、提交问题，并分享你实际复制 Prompt 的方式。

**English:** Prompt Dock is a local-first, always-on-top prompt launcher for macOS. Organize long prompts into work presets, then copy them from a floating panel, a radial keyboard menu, or an edge shelf.

## 为什么做它

在 ChatGPT、Gemini、Grok、Lovart 和 AI 视频工具之间工作时，长 Prompt 往往散落在备忘录或文档中。Prompt Dock 希望把“找到并复制 Prompt”缩短成一次点击，或者一次按住、移动和松开。

## 当前功能

- 始终置顶、可拖动和调整大小的毛玻璃面板
- 分类、标签与全文搜索
- 完整 Prompt 库的新增、编辑、删除和分类管理
- 多套工作预设，分别配置面板、4/6/8 槽位转盘和侧边栏内容
- 每条 Prompt 可独立指定模型图标，并保存兼容模型信息
- 点击卡片复制完整 Prompt，并显示成功反馈
- 按住 `·`、移动到转盘项目、松开即可复制；可选短按复制最近使用
- 左侧或右侧屏幕边缘快捷栏
- `Command + Shift + P` 全局显示或隐藏面板
- 菜单栏常驻、透明度调节、深色模式
- 本地 JSON 存储、每日快照、导入与导出
- 无账号、无广告、无分析 SDK、无服务器依赖

## 我们想验证什么

- 始终置顶的 Prompt 面板是否真的减少了应用切换？
- 工作预设是否比“最近使用”和“收藏”更适合不同工作阶段？
- 按住并松开完成复制的转盘，是否比点击列表更快？
- 屏幕边缘栏能否在不占用画面的前提下保持随手可用？

如果你有类似工作流，欢迎使用 GitHub Issues 分享场景。请勿在 Issue、截图或日志中粘贴私人 Prompt、API Key 或客户数据。

## 系统要求

- macOS 14 或更高版本
- Xcode 16 或更高版本（当前版本已在 Xcode 26.6 验证）

## 本地运行

1. 克隆或下载本仓库。
2. 使用 Xcode 打开 `AIPromptDock.xcodeproj`。
3. 选择 `My Mac`，点击 Run。
4. 如需使用单键 `·` 转盘，在系统提示后前往“系统设置 → 隐私与安全性 → 辅助功能”授权。

App 是菜单栏应用，不会常驻 Dock。关闭面板只会隐藏；可通过菜单栏图标或 `Command + Shift + P` 再次打开。

## 本地数据

App Store 沙盒构建的数据位于：

```text
~/Library/Containers/com.ayu.AIPromptDock/Data/Library/Application Support/AIPromptDock/library.json
```

Prompt 正文、分类和工作预设默认只保存在本机。可以在管理后台导出 JSON 备份或恢复资料库。仓库只包含通用示例 Prompt，不包含开发者的个人资料库。

## 项目结构

- SwiftUI：面板、管理后台、转盘和边缘栏界面
- AppKit：悬浮窗口、菜单栏和屏幕层级
- Codable JSON：本地资料库、迁移与备份
- Carbon / CGEvent：组合快捷键与经授权的单键监听

更详细的说明见 [技术架构](Docs/ARCHITECTURE.md)、[数据模型](Docs/DATA_MODEL.md) 和 [项目结构](Docs/PROJECT_STRUCTURE.md)。

## 当前限制

- 暂无 iCloud 或多设备同步
- 暂无团队共享和 Prompt 市场
- 分类与 Prompt 暂不支持拖动排序
- 本地开发签名更新后，macOS 可能要求重新确认辅助功能权限
- 尚未提供经过公证的安装包，请使用 Xcode 本地构建
- 本机日常更新请运行 `Scripts/install-local.sh`；它会使用稳定的本地签名，避免单键转盘的辅助功能权限在每次更新后失效

## 参与贡献

问题反馈和代码贡献见 [CONTRIBUTING.md](CONTRIBUTING.md)。安全问题见 [SECURITY.md](SECURITY.md)。

## 许可证

[MIT License](LICENSE)
