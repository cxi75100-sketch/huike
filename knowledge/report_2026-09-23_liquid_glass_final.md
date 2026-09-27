# TASK-017 Liquid Glass 最终收尾报告

日期：2026-09-23

状态：实现与代码验证完成，保留未提交工作区；按要求未创建 commit。

## 交付内容

- 新增 `CourseHeroTag`，以课程 ID、学校 ID、学期 ID、来源页面和详情目标形成稳定身份；预览与详情共用 `CourseHeroSurface`。Weekly 预览 → 详情使用 Flutter 跨 PageRoute Hero；Today 课程卡 → 透明页面路由承载的玻璃预览面板 → 详情也连续使用 Hero。详情返回预览、关闭预览回 Today 的往返均有 widget 覆盖。
- Today 预览由 `showModalBottomSheet` 改为透明 `CustomTransitionPage`，因为 Flutter HeroController 只在 PageRoute 之间配对 Hero。底部玻璃面板保留背景遮罩和明确关闭按钮。Reduced Motion 下不创建 Hero，详情页使用 90ms 淡入。
- 新增 `GlassDialog` / `showGlassDialog`、`GlassDialogAction`、`GlassTextField`、`GlassSelectionRow`、`GlassToggleRow`、`GlassChoiceChip` 和 `GlassPickerRow`。引导、课程编辑、学校管理、校历例外、导入入口/预览/WebView 桥、作息恢复、设置外观和确认弹窗均使用共享玻璃控件。删除与作息重置操作以危险色和文案标识。
- 校历例外删除新增二次确认。Today 课程预览补充显式关闭按钮，避免透明页面路由没有平台 BottomSheet 拖动/关闭 affordance。
- 一致性扫描：业务 UI 内不再直接使用 Material `TextField`、`RadioListTile`、`CheckboxListTile`、`ChoiceChip`、`IconButton`、常规按钮或 `AlertDialog`。Flutter `TextField` 与 `showDialog` 只保留在共享玻璃封装内部；学校/校历溢出菜单保留 `PopupMenuButton` 系统菜单，日期/时间选择器继续使用平台控件。
- 没有新增 dependency、数据库字段或迁移；教务适配脚本、桥、导航策略和课程数据语义未变。

## 验证

- `flutter analyze --no-pub`：通过，No issues found。
- `flutter test --no-pub`：194/194 通过。新增/扩展覆盖包括输入和 onChanged、选择/勾选/节次选择器、危险确认框、1.3 倍字号、设置项持久化、Weekly/Today Hero 标签唯一性与往返、Reduced Motion。
- `flutter build apk --debug --no-pub`：成功。
- APK：`build/app/outputs/flutter-apk/app-debug.apk`，207,085,563 字节，SHA-256 `B41FED2C23A339F7332B72BE2C6533F98A60DE1C3A9B7BD25C4D7B1B02E010ED`。
- `adb devices -l`：没有连接设备。本轮没有进行模拟器或真机实画，也没有安装 APK 或改变模拟器状态。
- `git diff --check`：通过；Git 输出的只有工作区 CRLF/LF 转换提示。

## 未验证与工作区边界

- iOS 页面转场/交互式返回、真机 GPU 性能、TalkBack/VoiceOver 完整人工遍历、真实教务登录/导入仍为 `UNVERIFIED`。
- 工作区在 TASK-016 前已有多项未提交改动；TASK-017 在其上增量完成。没有 reset、clean、提交或推送。
