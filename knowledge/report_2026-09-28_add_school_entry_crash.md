# 2026-09-28 点「添加学校」红屏诊断报告（Navigator 重复 pageKey 断言，ISSUE-019）

## 0. 状态

| 项 | 值 |
| --- | --- |
| 日期 | 2026-09-28（证据采集 16:22–16:33 +08:00） |
| 基线 | master `7bc4f10` + 工作区在飞改动（导入一致性任务，见 `report_2026-09-28_data_integrity_01.md`） |
| 本轮性质 | **只诊断与复现，未修任何代码**（唯一一次临时改动用于验证修法，已还原） |
| 关联问题 | `issues.md` ISSUE-019（Open，待修） |
| 报障来源 | 用户真机截图（2026-09-28 16:15，debug 构建）：整屏红 + `navigator.dart` 第 4096 行 `'!keyReservation.contains(key)'` 断言 |

**一句话结论**：`app_router.dart` 的 redirect 把 `/onboarding`（含 `?add=1`）当成「首次启动门」，
有学校时点「添加学校」会被改写成 `/`；这个「push 一个被 redirect 回当前 shell 地址」的组合
让 go_router 把**同一个 `StatefulShellRoute` 的副本**追加进根 Navigator 的页面列表，
两个 Page 撞了同一个 key，Flutter 断言失败。

---

## 1. 现象

- 断言原文（用户截图）：`'package:flutter/src/widgets/navigator.dart': Failed assertion: line 4096 pos 18: '!keyReservation.contains(key)': is not true.`
- 该行（Flutter 3.47.2）就是 `NavigatorState._debugCheckDuplicatedPageKeys()`
  （`packages/flutter/lib/src/widgets/navigator.dart`）：它只做一件事——检查**同一个 Navigator 的 `pages`
  列表里有没有两个 key 相同的 Page**。调用点在 `_updatePages`（4162–4165），
  本次是从 `didUpdateWidget`（4080）进来的，即同一个 Navigator 拿到了新的 pages 数组。
- 之后同树继续抛第二条断言 `framework.dart:6281 '_dependents.isEmpty'`，
  说明第一次失败已经把整棵树的依赖关系留在不一致状态；用户侧表现就是**整屏红、无法操作**。
- 用户描述的触发动作：点「添加学校」。

## 2. 触发入口

全仓库只有一处「添加学校」按钮，标签与跳转如下：

| 位置 | 代码 | 说明 |
| --- | --- | --- |
| `lib/features/settings/pages/school_manage_page.dart:121` | `onPressed: () => context.push('/onboarding?add=1')` | 学校管理页底部 GlassButton，标签「添加学校」 |
| `lib/features/onboarding/pages/onboarding_page.dart:88` | `title: Text(widget.isAddingSchool ? '添加学校' : '欢迎使用汇课')` | 该入口的目标页标题 |
| `lib/features/import/pages/import_entry_page.dart:197` | `context.push('/onboarding')`（无 `add` 参数） | 未建校态的「去创建学校」，与本 bug 无关（见 §6） |

## 3. 复现（`CONFIRMED`）

环境：`S:\`，`flutter test --no-pub`（widget 测试默认开启断言），Flutter 3.47.2 stable，
go_router 18.0.1（`C:\Users\ninan\AppData\Local\Pub\Cache\hosted\pub.dev\go_router-18.0.1`）。
用一次性脚本挂载真实 `HuikeApp`（内存 Drift 库建校 + 学期 + `setActiveSchool`，
沿用 `test/root_switcher_test.dart` 的 fixture 口径），然后**按用户路径用真实点击**走：

1. `router.push('/settings')` → 设置页；
2. 点「学校管理、切换与导入配置」→ `/settings/schools`；
3. 点「添加学校」。

每一步 dump 根 Navigator 的 match 树（`RouteMatchList.matches`，打印 `runtimeType` 与 `pageKey.value`）：

```
STEP1: uri=/ :: ShellRouteMatch<StatefulShellRoute>key=442881096 {RouteMatch<GoRoute>key=/} , ImperativeRouteMatch<GoRoute>key=jZk]cftwfmeZp^pfn_vpsuZ^vkpwyndu
STEP2: uri=/ :: ShellRouteMatch<StatefulShellRoute>key=442881096 {RouteMatch<GoRoute>key=/} , ImperativeRouteMatch<GoRoute>key=jZk]cftwfmeZp^pfn_vpsuZ^vkpwyndu , ImperativeRouteMatch<GoRoute>key=qZttsZgZgcfi[vcqxlpxvkjhnbo[jgus
STEP3: uri=/ :: ShellRouteMatch<StatefulShellRoute>key=442881096 {RouteMatch<GoRoute>key=/} , ImperativeRouteMatch<GoRoute>key=jZk]cftwfmeZp^pfn_vpsuZ^vkpwyndu , ImperativeRouteMatch<GoRoute>key=qZttsZgZgcfi[vcqxlpxvkjhnbo[jgus , ShellRouteMatch<StatefulShellRoute>key=442881096 {ImperativeRouteMatch<GoRoute>key=exY`j`tbjjwlepgYwtjqYpf]Yi_gjt`[}
exception: 'package:flutter/src/widgets/navigator.dart': Failed assertion: line 4096 pos 18: '!keyReservation.contains(key)': is not true.
添加学校 title hits: 0
```

要点：

- STEP3 里出现了**第二个 `ShellRouteMatch`**，`key=442881096` 与第一个完全相同
  （`ValueKey(StatefulShellRoute 实例的 hashCode)`，见 `match.dart:177`）→ 根 Navigator 的 pages 里
  两个 Page 同 key → 断言。
- `添加学校 title hits: 0`：**表单从未出现**。也就是说即使不看断言，这个入口在有学校时也是坏的。
- 断言与用户截图完全一致（同为 `navigator.dart:4096`）。

## 4. 机制（`CONFIRMED`，可逐行追）

1. 点「添加学校」→ `context.push('/onboarding?add=1')`。解析阶段先跑顶层 redirect
   （`lib/core/router/app_router.dart:52-62`）：
   ```dart
   final hasSchool = ref.read(activeSchoolIdProvider).value != null;
   final onOnboarding = state.matchedLocation == '/onboarding';
   if (!hasSchool && !onOnboarding) return '/onboarding';
   if (hasSchool && onOnboarding) return '/';   // ← 有学校时把 add=1 也吞掉
   ```
   有学校 → `hasSchool == true`、`matchedLocation == '/onboarding'` → 返回 `'/'`。
2. 因此这次 push 携带的目标 match 列表变成 `/` 的列表：
   `[ShellRouteMatch(StatefulShellRoute, matches: [RouteMatch(/)])]`。
   push 本身仍会造一个带**随机唯一 key** 的 `ImperativeRouteMatch`
   （`lib/src/parser.dart:262-270`，`_getUniqueValueKey()` 取 32 个随机字符），
   所以冲突不来自 push 的 key，而来自它携带的 shell。
3. `RouteMatchList.push`（`lib/src/match.dart:607-614`）调用
   `_createNewMatchUntilIncompatible(currentMatches, otherMatches, match)`（616 起）：
   - `currentMatches` = `[Shell{[/]}, Imp(/settings), Imp(/settings/schools)]`；
   - `otherMatches` = `[Shell{[/]}]`；
   - 判据（626-628）：`otherMatches.last is ShellRouteMatch && otherMatches.last.route == newMatches.last.route`
     —— 左边为真，**右边为假**：`newMatches.last` 是 `/settings/schools` 的 imperative match，
     它的 `route` 是那条 GoRoute，不等于 `StatefulShellRoute`；
   - 于是走 `newMatches.add(_cloneBranchAndInsertImperativeMatch(otherMatches.last, match))`（639）。
4. `_cloneBranchAndInsertImperativeMatch`（643-651）遇到 `ShellRouteMatch` 时会
   `branch.copyWith(matches: [...])` —— **`copyWith` 保留 `pageKey`**（`match.dart:407-417`），
   即返回一个「内容不同、key 相同」的 shell 复制品；而栈底那个原有 shell **没有被替换**。
   → 同一 shell 在列表里出现两次。
5. 根 Navigator 依据该列表构造 pages，两个 Page 的 `key` 都是 `ValueKey('442881096')`
   → `_debugCheckDuplicatedPageKeys` 断言失败 → 红屏。

补充：单次 `push('/settings/schools')`（不先推 `/settings`）同样复现，
所以触发条件只是「当前栈顶不是那个 shell」，与推了几层无关。

## 5. 为什么现在才炸（时间线）

- `git log -S` 佐证：`add=1`（`school_manage_page.dart`）与这条 redirect（`app_router.dart`）
  都出自初版提交 `e81ad44`（2026-09-13，0.1.0）——**「添加学校」在有学校时从 0.1.0 起就打不开**
  （被重定向回首页，且没有任何提示）。
- `StatefulShellRoute` 是 `f9eccc9`（2026-09-27 归档提交，TASK-020B，随 0.1.4 发布）引入的：
  `f9eccc9^` 的 `app_router.dart` 里 `/` 还是普通 GoRoute（第 50 行），全文件无
  `StatefulShellRoute` / `StatefulShellBranch`。
- 组合起来：**0.1.0–0.1.3 期间是「静默弹回首页」，0.1.4 之后升级为红屏**。
  `INFERRED`：旧版没有 shell，被改写的 push 只会追加一个 imperative 页（key 随机唯一），
  不会重复 key；未在旧版构建上实测。
- release 构建会剥离 `assert`（`INFERRED`，Flutter 的断言只在 debug/profile 生效）：
  不会红屏，但页面栈里仍多出一个重复 shell 页，且「添加学校」依旧不可达。
- 用户设备上是 debug 构建——能显示出红屏本身即可判定。

## 6. 建议修法（已临时验证，未保留代码）

`lib/core/router/app_router.dart` 的 redirect 放行 `add=1`：

```dart
final hasSchool = ref.read(activeSchoolIdProvider).value != null;
final onOnboarding = state.matchedLocation == '/onboarding';
// 添加学校（?add=1）是有学校时的合法入口，不能被首次启动门拦掉
final addingSchool = state.uri.queryParameters['add'] == '1';
if (!hasSchool && !onOnboarding) return '/onboarding';
if (hasSchool && onOnboarding && !addingSchool) return '/';
return null;
```

验证（`CONFIRMED`）：把上述两行临时打上后跑同一条用户路径复现脚本——
match 树变为 `[Shell{[/]}, Imp(/settings), Imp(/settings/schools), Imp(/onboarding)]`，
所有 key 互异；`tester.takeException()` 为 `null`；onboarding 页真的出现
（AppBar 标题「添加学校」命中 1 次）。验证后已 `git checkout -- lib/core/router/app_router.dart`
还原，并删除临时脚本，工作区无本轮遗留。

`UNVERIFIED`：修复后的真机 debug 走查、release 包走查、以及「加完第二所学校后回退栈是否正确」。

## 7. 入口盘点（`add=1` 相关）

| 入口 | 现状 |
| --- | --- |
| `school_manage_page.dart:121` `push('/onboarding?add=1')` | 本 bug 命中入口；有学校时不可达（红屏 / 弹回首页） |
| `import_entry_page.dart:197` `push('/onboarding')`（无 `add`） | 只在无学校态可达，redirect 本就放行；仅读码，未单独跑用例 |
| 其他 | `grep 添加学校\|增加学校\|add=1` 全仓库无第三条路径 |

后续若再放宽/收紧 onboarding 的准入，按 `AGENTS.md` 要求先更新本清单。

## 8. 修复时的待办清单

1. 改 redirect（§6）。
2. 回归测试：把 §3 的复现脚本转成正式用例（建议 `test/add_school_entry_test.dart`
   或并入 `test/root_switcher_test.dart`）。最小断言集：
   有学校 → `/settings/schools` → 点「添加学校」→ `takeException() == null`
   且出现 onboarding 表单（AppBar「添加学校」）；返回后仍在学校管理页。
   当前测试套件（290 例）**没有任何一条覆盖这个入口**，这正是它能在 0.1.0 起长期坏掉的原因。
3. 文档同步（同一笔提交）：`knowledge/framework_navigation.md` §3 的 redirect 行与 §7 已知问题、
   `knowledge/issues.md` ISSUE-019 状态、`knowledge/tasks.md`、`knowledge/current_state.md`
   顶部 Last Updated。
4. 设备验收：真机 debug 走一遍「添加学校 → 填表 → 建第二所学校」；release 包走一遍同路径。
5. 顺带决定：`add=1` 进入 onboarding 后，页面是否应显示「取消/返回」语义
   （当前是从学校管理页 push 进去的，返回栈天然可回退，未实测）。

## 9. 证据与环境

- 本机 Flutter 3.47.2 stable（`D:\Tools\flutter`，framework revision `d3b14c87…`），
  go_router 18.0.1。
- 两次复现运行（单次 push 与用户真实两次 push）均为一次性脚本，已删除；
  `git status --short lib/ test/` 只剩工作区原有改动（导入一致性任务的 4 个文件）。
- 本轮**未运行**完整 `flutter test` 与 `flutter analyze`（只跑了两条单文件复现），
  因此不对全量基线做任何声明；修复轮必须补跑。
- 本轮的知识库登记：新增本报告；`issues.md` 新增 ISSUE-019（Status: Open）；
  `tasks.md` Now 新增 `TASK-NAV-ADD-SCHOOL-01`；`framework_navigation.md` §3 redirect 行与
  §7 已知问题各加一条；`README.md` 任务报告索引加本报告。
  **未改** `knowledge/current_state.md`（本轮无代码/策略变更，且该文件当天另有在飞改动）。
