# 2026-10-01 修改教务网址关闭红屏：原因与修复（TASK-SCHOOL-URL-DIALOG-01）

日期：2026-10-01 +08:00；任务：TASK-SCHOOL-URL-DIALOG-01；问题：ISSUE-020。

## 结论

`CONFIRMED`：学校管理的 `_editLoginUrl` 在弹窗 pop 后立即销毁输入框控制器，而弹窗退出动画尚未结束。仍存活的 TextField 在焦点变化/退出阶段重建时访问已销毁控制器，首先触发 `A TextEditingController was used after being disposed`，随后 `_FocusInheritedScope` 触发 `framework.dart:6281:12 _dependents.isEmpty`。回归测试复现了与用户第二张截图完全一致的文件、行号和断言。

这是弹窗输入资源的生命周期错误。保存与取消都执行了 await 后同一段 dispose，故两条入口均可触发；遮罩和系统返回也走同一关闭路径。

## 证据链

1. `school_manage_page.dart` 原实现创建 TextEditingController，传入 GlassTextField，await showGlassDialog 后读取 text 并立即 dispose。
2. `glass_dialog.dart` 的 showGlassDialog 直接返回 Navigator.push；本机 Flutter `navigator.dart` 明确说明 popped 在 pop 时完成，路由可在 dispose 前执行退出动画。
3. 本机 Flutter `routes.dart:114-121` 区分 popped 与 completed：后者在退出动画结束、overlay 移除后完成。当前代码 await 的是前者。
4. `glass_form.dart` 将 controller 传给 TextField；焦点变化会 setState，退出阶段仍可能触发重建。
5. 修复前 `flutter test --no-pub test/school_login_url_dialog_test.dart` 为6项失败；最早异常为已销毁控制器，在同轮测试日志中随后捕获用户截图中的焦点继承组件断言。日志使用合成学校与 example.edu.cn 地址，无账号或会话数据。

## 修复

只调整学校管理修改网址方法：移除外部控制器，使用现有 GlassTextField.onChanged 记录输入，由 Flutter TextField 内部 State 创建/释放控制器，生命周期跟随输入框实际卸载。保存前检查 context.mounted，避免页面离开后访问 ref。

继续复用 checkLoginUrl(required: true) 与 SchoolRepository.updateLoginUrl：有效 HTTP/HTTPS 地址更新，已确认主机仍追加；取消/null结果不写入；无效地址保持旧数据并提示。没有改弹窗动画时长，没有用固定延时释放资源。

## 验证

- `CONFIRMED`：新增6项真实 HuikeApp 路由、Riverpod 和 Drift 内存数据库回归，修复后6/6通过。
- 覆盖取消后重复打开与输入、HTTPS保存、HTTP保存、空值保存、非法协议保存、遮罩及系统返回；关闭开始帧、50ms动画中间帧和最终卸载均检查异常，核对网址与已确认主机是否写入。
- `CONFIRMED`：全量332/332通过；独立只读代码复审未发现实质问题。
- `CONFIRMED`：`flutter analyze --no-pub` 无问题；`flutter build apk --debug --no-pub` 成功，`git diff --check` 通过（仅已有 CRLF 提示）。
- `UNVERIFIED`：用户真机复测、iOS、真实教务登录/导入。本轮测试与构建不能替代这些验收。

## 交付边界

保留开工前全部未提交改动，包括此前学校管理移除添加入口的修改。未提交、未推送。源码修复、回归测试、问题记录、当前状态、任务、测试与变更日志已同步。

用户随后追加旧图标与兼容覆盖升级，最终APK与341/341验证结果统一见report_2026-10-01_legacy_upgrade.md；本报告332/332是仅弹窗修复阶段的快照。
