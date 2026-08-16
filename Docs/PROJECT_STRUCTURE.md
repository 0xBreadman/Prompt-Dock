# 项目结构

```text
AIPromptDock.xcodeproj/       原生 macOS App 工程
Package.swift                 无完整 Xcode 时的编译与测试入口
Sources/AIPromptDock/
├── App/
│   ├── AIPromptDockApp.swift
│   ├── AppDelegate.swift
│   ├── FloatingPanel.swift
│   ├── FloatingPanelController.swift
│   ├── RadialMenuController.swift
│   ├── EdgeShelfController.swift
│   ├── OnboardingWindowController.swift
│   ├── ManagementWindowController.swift
│   └── GlobalHotKey.swift
├── Models/
│   ├── DockPreset.swift
│   ├── HotKeyOption.swift
│   ├── PromptCategory.swift
│   ├── PromptItem.swift
│   └── PromptLibrary.swift
├── Services/
│   ├── PromptRepository.swift
│   ├── JSONPromptRepository.swift
│   ├── PromptStore.swift
│   └── DockSettings.swift
├── Utilities/
│   ├── AppNotifications.swift
│   └── VisualEffectView.swift
└── Views/
    ├── ContentView.swift
    ├── ManagementView.swift
    ├── PresetEditorView.swift
    ├── PromptEditorView.swift
    ├── InteractionSettingsView.swift
    ├── LibrarySettingsView.swift
    ├── OnboardingView.swift
    ├── RadialMenuView.swift
    ├── EdgeShelfView.swift
    └── PromptCardView.swift
Docs/                          架构、模型、目录和阶段说明
```

下一阶段建议新增：

```text
Features/PromptEditor/         新增与编辑
Features/LibraryManager/       分类、排序、导入导出
Services/BackupService.swift   定时本地备份
Services/MigrationService.swift
```
