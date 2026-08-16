# Mac App Store 提交检查清单

## 工程状态

- [x] SwiftUI + AppKit 原生 macOS App
- [x] Release 与 Debug 使用 App Sandbox
- [x] 仅申请用户选择文件的读写权限
- [x] 正式 AppIcon 资产目录
- [x] 本地 JSON 存储、每日快照、导入与导出
- [x] 全局快捷键提供多种可选组合
- [x] 首次使用引导
- [x] 深色模式与窗口缩放
- [x] 版本号 0.2.0（Build 8）

## 提交前仍需外部信息

- [ ] Apple Developer Program 账号与 Team
- [ ] App Store Connect 创建 App 记录
- [ ] 正式支持邮箱或支持网站
- [ ] 将隐私说明发布到可公开访问的 URL
- [ ] App Store 简体中文与英文截图
- [ ] App Store 描述、关键词、分类和版权信息
- [ ] 用 Distribution 证书完成 Archive / Validate App
- [ ] TestFlight 小范围真实用户测试

## 验收门槛

- [ ] 连续 7 天日常使用无数据丢失
- [ ] 透明度、转盘、边缘栏和窗口缩放无崩溃
- [ ] 沙盒下导入、导出、重启恢复均通过
- [ ] 全局快捷键冲突时可以在设置中切换
- [ ] 新安装首次引导完整，旧数据可以通过 JSON 恢复
