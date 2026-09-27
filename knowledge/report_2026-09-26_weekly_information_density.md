# TASK-019 Weekly Timetable Information Density Report

日期：2026-09-26。当前 working tree 增量，未创建 commit。

## Root Cause

TASK-016 固定 viewport 后，`_BlockBody` 使用 40dp / 54dp 内容宽度门槛与
48×scale / 72×scale 高度门槛决定辅助字段。七列手机卡片扣除色条与留白通常达不到
门槛，尤其教师始终被隐藏。旧注释仍描述内容驱动行高，与真实固定网格实现不一致。

## Layout

课程名 → compact 地点 → 教师，全部顶部对齐。compact 名称保留 11.5sp 粗体，
辅助字段 10sp、palette secondary 色。课程色仍仅用于轻量渐变、描边与身份线；
无逐卡 BackdropFilter。没有把时钟时间塞进课程块；读屏仍保留完整原始信息。

TextPainter 合并 DefaultTextStyle 与现有排印 token，并使用真实 TextScaler 与可用宽度。
先给各现有字段留一行；补足地点/教师换行后，余量给名称（最多四行）。
物理空间不足时按名称、地点、教师优先级降级，长名称可淡出；不缩到 7/8sp，
不让文字决定网格行高。减少色条留白、字段间距及课块外间隙，节次轴 34→28dp。

## Location Formatting

新增纯函数 `compactWeeklyLocation`，仅在 Weekly widget 调用，不修改 Course 或保存值。

- 九龙湖校区明志楼404 → 明志楼404
- 九龙湖校区致远楼A512 → 致远楼A512
- 九龙湖校区明志楼223 → 明志楼223
- 九龙湖校区西区实训中心3-A010 → 实训中心3-A010

移除开头「…校区」及其空格；只有后面是实训中心时才移除紧接的东西南北区。
无校区标记、仅有校区名或未知区域结构保持原文（除首尾空白）。不盲删其它建筑前缀。
课程名没有人为换行；地点按实际宽度自然折行。Today/Preview/Detail 保留原始 location。

## 10 / 12 / 14 Sections

10/12：固定七列、无横向滚动、可用 viewport 均分、网格不纵向滚动。
14：保持原有网格纵向滚动与固定星期栏。
SectionCountResolver、冲突算法、`+N` 与周切换算法未修改。

## Tests

真实 baseline：`flutter analyze --no-pub` 无问题，`flutter test --no-pub` 207/207。
知识库旧快照中的两例 overflow 本次 baseline 未复现，不采用历史总数。

增强原有 13 例 viewport 测试：360/390/430dp × 1.0/1.3 × 10/12 节检查
三字段、位置边界、地点/教师 `didExceedMaxLines == false`、无时间字符串；14 节滚动。
新增 formatter 2 例；新增明暗课块可读性、20dp 极短降级、缺失地点 4 例。
原有跨节与冲突宽度两例改为精确检查新外间隙（0.5dp），未删除或放宽断言。
最终全量 **213/213 通过**，比 baseline 新增 6 例。独立复审无遗留问题，相关四份测试 44/44 通过。

## Visual QA

API 36 `ncpu_api36` / emulator-5554，1080×2400 px、443 dpi，约 390×867dp。
已实际查看 Light/Dark 的大学英语III、工程力学、工程材料、大学物理II、
马克思主义基本原理、线性代数A、艺术鉴赏；七列与 12 节一屏，地点房间及教师可读。
使用临时 QA 入口和 NativeDatabase.memory，仅匿名演示值；QA 入口已删除。
截图保存到 Codex visualization/task019 目录，未把用户数据或 QA 数据落盘到数据库。
Flutter logcat 未命中 E/flutter / overflow / Exception。

发现既有加号浮层遮挡右下角课块：首次艺术鉴赏放在周日11–12节时被挡，
随后将 QA 艺术鉴赏移到3–4节检查完整文本；保留另一个左侧12节边界块证明一屏。
加号及导航不属于本轮，未修复遮挡。360/430dp、1.3 字体与14节为 widget 验证，
不是本轮设备实画。真机、iOS、人工辅助技术验证仍 UNVERIFIED。

## Validation

- `flutter analyze --no-pub`：No issues found。
- `flutter test --no-pub`：213/213 通过。
- `flutter build apk --debug --no-pub`：成功，默认 main.dart。
- `git diff --check`：通过（仅 LF/CRLF 提示）。
最终 APK：`build/app/outputs/flutter-apk/app-debug.apk`，生产入口，非 QA 内存入口。

## Scope

只修改 Weekly 卡片、对应排印/布局常量、纯展示 formatter、测试和知识库。
没有修改 Today / Preview / Hero / Navigation / Import / WebView / adapter / Detail / Settings。
不修改 Drift schema、原始 location、导入结果、冲突/周切换算法，不新增 package。
既有未提交改动完整保留。

## Git

未创建 commit、未 push、未 reset、未 clean、未 checkout 覆盖工作树。
