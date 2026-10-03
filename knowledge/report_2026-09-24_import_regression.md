# 2026-09-24 导入流程回归修复报告（TASK-018A）

更新：2026-09-24。工作树未提交。iOS、真实教务系统、真机 GPU 与辅助技术仍是 `UNVERIFIED`。

## 故障表现

实机打开「导入教务课表」：顶部只有标题，正文中间几乎完全空白，
底部一颗 disable 的「确认并进入教务登录」。页面上没有任何可操作控件，
风险确认项根本不在页面上，用户无法满足 CTA 的启用条件，教务导入整条链路走不下去。

widget test 侧的可复现证据：`find.text('学校')`、`导入步骤`、`登录安全提示` 全部找不到，
而 `tester.takeException()` 为 null —— 不是崩溃，是内容被布局挤没了。

## 根因

`GlassButton` 的视觉包装是

```dart
ConstrainedBox(minWidth/minHeight: tapTarget) → Center → GlassSurface
```

`Center`（`RenderPositionedBox`，不带 `widthFactor` / `heightFactor`）在**有界松约束**下
会把自身撑满可用高度。`Scaffold.bottomNavigationBar` 恰好用
`fullWidthConstraints`（宽紧、高松，高度上限等于整屏）布局子项，于是：

- 底部栏实测被撑成 `350×820`（390dp 屏、844dp 高）；
- `_ScaffoldLayout` 的 `contentBottom` 被顶到顶部，body 高度变成 **0**；
- `ListView` 视口高 0 → 一个子项都不构建 → `RiskConfirmTile` 不在树里 →
  `_confirmed` 永远为 `false` → CTA 永远 disabled。

这是 TASK-016/017 的 Liquid Glass 改造引入的回归：改造前这些页面的 CTA 是
`FilledButton`（按内容定高，不会撑满）。同一 bug 还命中**引导页（`创建学校`）**与
**导入预览页**——三个用 `bottomNavigationBar` 放 CTA 的页面同时失效，等于
「建校 + 导入」主链路断掉。

旧测试没发现的原因：`app_shell_test` 的建校用例当时写成

```dart
tester.widget<TextField>(find.byType(TextField, skipOffstage: false).first).controller!.text = '测试大学';
tester.widget<GlassButton>(find.byType(GlassButton, skipOffstage: false).first).onPressed!();
```

即用 `skipOffstage: false` 找到被压成 0 高的控件、直接写 controller、直接调 `onPressed`，
绕过了真实点击与布局断言。控件在 0 高容器里既点不到也不参与正常 layout，
测试于是被改成直调回调，正好把回归掩盖过去（没有任何用例断言 CTA 可被真实点击）。

## 修改内容

| 文件 | 改动 |
| --- | --- |
| `lib/core/glass/glass_button.dart` | `Center` 固定 `heightFactor: 1`：只收缩纵向、保留原有横向占满行为，`tapTarget` 最小尺寸约束不变。一处修好三个页面（DEC-006 口径：一处策略一处定义） |
| `lib/features/import/pages/import_entry_page.dart` | 补齐加载中 / 读取失败+重试 / 未建校三种状态的可见反馈；底部 CTA 追加 `MediaQuery.viewInsetsOf(context).bottom`，键盘弹起时停在键盘上方 |
| `lib/features/import/pages/import_web_page.dart` | 清理回调改为在 `initState` 抓取 `ImportSessionNotifier` 实例，不再在 `dispose` 里用 `ref` |
| `lib/features/import/services/import_session_cleaner.dart` | 清会话推迟到 `Future.microtask`，避开 widget 树 finalize 阶段禁止同步改 provider 的限制 |
| `test/import_flow_regression_test.dart` | 新增 13 例导入流程回归 |
| `test/app_shell_test.dart` | 建校用例改回真实 `enterText` + `tap('创建学校')`，去掉直调回调的绕行写法 |

顺带修掉的第二个缺陷（ISSUE-018）：离开导入 WebView 时 `_cleaner.dispose()` →
`ref.read(importSessionProvider.notifier).reset()` 会抛
`Bad state: Using "ref" when a widget is about to or has been unmounted is unsafe`；
把这条 catch 掉之后紧接着抛 `Tried to modify a provider while the widget tree was building`。
两条异常都发生在 `reset()` 之前/之时，因此**内存里的导入会话实际从未被清掉**——
与 `import_session.dart` 注释宣称的「离开导入页时 reset」不符。

## 修复后的完整用户操作路径

1. 建校（引导页）：填学校名 → 点「创建学校」→ 进入首页。
2. 首页右上「导入教务课表」→ 导入入口页：学校卡、导入步骤、教务网址输入、
   登录安全提示与风险确认项全部可见可操作。
3. 填教务网址（可留空/非法：CTA 会给出 SnackBar 提示并停在原地）。
4. 勾选「我确认以上地址是我学校自己的教务系统」→ 底部 CTA 由 disabled 变 enabled。
5. 点 CTA → 玻璃确认弹窗（显示将打开的 host，明文 HTTP 额外警示）→「继续」。
6. 候选地址写入该学校确认主机 → 进入 `/import/web`，WebView 载入登录页，
   右上「执行导入」按原有机制自动逐个尝试内置适配器。
7. 返回：Android 系统返回 / iOS pop 正常回上一级；离开时清空内存导入会话。

## 安全边界

本轮**没有**修改：适配器 JS（`assets/adapters/*.js`）、桥 handler 名与 payload
（`adapter_bridge.dart`）、`NavigationPolicy`、WebView 登录流程、Cookie / session 策略、
Drift schema 与任何数据库迁移。没有登录任何真实教务账号（验证用的是不存在的占位域名）。
唯一涉及清理逻辑的改动是让「离开导入页清空内存会话」这条既有承诺真正生效。

## 测试

- 改动前基线：194 个用例，其中 `course_block_content_test.dart` 的
  「430.0 dp / 1.0 text / 10|12 sections fit viewport」2 例固定失败
  （课程块内一行 `RenderFlex overflowed by 3.5 pixels`）。把本轮 `GlassButton`
  修复临时回退后重跑，这 2 例同样失败 → **与本轮改动无关，属周课表范围**。
- 新增 `test/import_flow_regression_test.dart`（13 例）：正文非空白且 body 高度可用、
  CTA 前置条件未满足时 disabled、真实点勾选后启用、点击 CTA 进入 `/import/web`
  且 `host` / `initialUrl` 传参正确并写入确认主机、取消弹窗与非法地址不跳转、
  学校信息加载中 / 读取失败 / 未建校三态各自可见、390dp 与 1.3 倍字号无 overflow、
  键盘弹起时 CTA 停在键盘上方且正文可滚动、系统返回回上一级、
  离开导入 WebView 后内存会话被清空。
- 回归价值已验证：把 `ref` 修复回退 → 该用例报 `Bad state` 且 `rawCourses` 仍非空；
  把 microtask 修复回退 → 报 `Tried to modify a provider while the widget tree was building`。
  两条修复各自都被测试锁定。
- 修复后：207 个用例、205 通过（仅剩上述 2 例既有失败）。

## 验证

- `flutter analyze --no-pub`：No issues found。
- `flutter test --no-pub`：207 个用例 / 205 通过（2 例既有失败，见上）。
- `flutter build apk --debug --no-pub`：成功。
- `git diff --check`：无空白错误（仅 Git 的 CRLF 提示）。
- API 36 `ncpu_api36` 实机（Debug APK）：
  - 引导页正文完整（此前同样是 0 高空白），真实输入 + 点击「创建学校」成功建校；
  - 导入页正文完整：学校卡 / 导入步骤 / 网址输入 / 登录安全提示 / 风险确认项；
  - 勾选后 CTA 从 `enabled=false` 变 `enabled=true`（可点击）；
  - CTA → 确认弹窗 →「继续」→ 进入教务 WebView（标题为学校名，右上「执行导入」），
    地址为占位域名，页面显示加载失败（未接触任何真实教务系统）；
  - 键盘弹起时 CTA 停在键盘上方、正文可滚动、无 overflow；
  - 退出导入页前后 logcat 无 `E/flutter` / provider 异常（修复前此处稳定出现两条 dispose 期异常）。
  - 验证用的 QA 学校 `QA Univ` 留在该 AVD 的应用数据里，未清理；主设备未受影响。

## 未覆盖 / 边界

- 真实教务系统登录与导入仍为 `USER`/`UNVERIFIED`（TASK-006），本轮不涉及。
- iOS 构建与真机 GPU、TalkBack/VoiceOver 未验证。
- `course_block_content_test.dart` 的 2 例 430dp 失败按用户要求不在本轮范围内（周课表）。
- 未创建 commit / push，工作树保持原样。
