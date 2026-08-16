# 数据模型

## PromptCategory

| 字段 | 类型 | 用途 |
|---|---|---|
| `id` | UUID | 稳定主键 |
| `name` | String | 分类名称 |
| `symbolName` | String | SF Symbols 图标 |
| `sortOrder` | Int | 手动排序位置 |
| `parentID` | UUID? | 父分类；支持“分类 > 子分类” |

## PromptItem

| 字段 | 类型 | 用途 |
|---|---|---|
| `id` | UUID | 稳定主键 |
| `title` | String | 快捷面板标题 |
| `content` | String | 完整长 Prompt |
| `categoryID` | UUID | 所属分类 |
| `tags` | [String] | 搜索与未来筛选 |
| `primaryModelBadgeID` | String? | 此 Prompt 日常显示的独立模型图标；为空时继承分类图标 |
| `compatibleModelBadgeIDs` | [String] | 兼容模型信息，不挤占主卡片视觉 |
| `sortOrder` | Int | 分类内排序 |
| `createdAt` / `updatedAt` | Date | 生命周期与同步冲突判断 |
| `lastUsedAt` | Date? | 内部使用记录，不作为界面入口 |
| `useCount` | Int | 内部统计，不作为面板排序依据 |

## DockPreset

| 字段 | 类型 | 用途 |
|---|---|---|
| `id` | UUID | 稳定主键 |
| `name` | String | 工作预设名称 |
| `symbolName` | String | 面板切换器图标 |
| `sortOrder` | Int | 预设排列顺序 |
| `promptIDs` | [UUID] | 此预设要显示的 Prompt 引用 |
| `quickPromptIDs` | [UUID] | 转盘固定槽位，按数组顺序排列 |
| `edgePromptIDs` | [UUID] | 侧边栏单独显示的 Prompt 引用 |
| `radialSlotCount` | Int | 此预设的转盘槽位数：4、6 或 8 |
| `copiesLastPromptOnQuickTap` | Bool | 短按转盘键时是否复制该预设最近使用的 Prompt |

预设不复制 Prompt 内容。因此修改一条 Prompt 后，所有引用它的预设会同时获得最新正文。

## PromptLibrary

JSON 文件的顶层快照：

```json
{
  "schemaVersion": 6,
  "categories": [],
  "prompts": [],
  "presets": []
}
```

`schemaVersion` 只描述本地数据结构，不与 App 版本绑定。未来如果切换 SQLite/SwiftData，UUID 继续作为跨设备与导入导出的稳定标识。

## 一致性约束

- `PromptItem.categoryID` 必须指向一个有效分类。
- 同一分类内 `sortOrder` 可重复；重复时按标题稳定排序。
- 删除分类前必须先移动或显式删除其 Prompt。
- 导入时拒绝高于当前 App 支持版本的数据，避免静默丢字段。
- 预设中的 Prompt UUID 必须存在；加载时自动清理失效和重复引用。
- 转盘与侧边栏引用必须同时属于预设；转盘加载时按当前 4/6/8 槽位数裁剪。
