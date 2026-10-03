# 2026-10-01 Weekly Preview 模糊性能取证与局部优化报告（TASK-PERF-BLUR-01）

## 1. Environment

**EMULATOR PROFILE EVIDENCE**。2026-10-01，既有 `ncpu_api36` AVD，
`emulator-5554` / `sdk_gphone64_x86_64`，Android 16 / API 36，1080×2400，420 dpi，
60.000004 Hz；Flutter 3.47.2 / Dart 3.13.2，profile，Impeller OpenGLES。
无连接 Android 真机。未修改数据库，使用已有 QA 样本和 10 节配置；不是 14+ 节性能样本。

本轮使用 VM Service 的临时 profile-only 扩展控制 A/B，
`WidgetsBinding.addTimingsCallback` 收集完整短窗口 FrameTiming。
没有使用 DevTools 图表或读取其 jank marker；Flutter 提供 DevTools 2.60.0。
UI = buildDuration，Raster = rasterDuration；并保留 totalSpan。阈值为 1000/60 ms。
超过阈值是数值判定，不能写成“已读取 DevTools jank marker”。

每个 variant 先恢复关闭态，切换后静置 1.8 秒；一次 open/Back-close 预热不入表，
随后记录三次。每次操作后等 1.8 秒以等待动画、异步 timing 批次和静置。
脚本使用已由内存截图和脱敏 RenderBox 位置核对的课程点位；扩展确认 open/close 状态。
隔离 A–G 同一进程；H 和紧邻生产前 baseline 同一重建进程；最终生产复测是同设备、
同模式、同 renderer、同路径的新 profile 进程。未测持续吞吐。

基线：`S:\` analyze 无问题、314/314；最初中文路径 analyze 出现已知 LSP FormatException，
转 `S:\` 后通过。开工时已有 15 个修改文件及既有未跟踪批次，全部保留。

## 2. Blur Layer Map

代码结构（不是所有滤镜覆盖同一像素的声明）：

```text
Root shell（Preview 时切换器隐藏；独立于下方 Host）
└ Weekly Scaffold → AmbientBackdrop → GlassSheetHost Stack
  ├ Transform.scale(Weekly background)
  │ ├ 顶部图标按钮 GlassSurface（默认 sigma 16）
  │ ├ 周导航 GlassSurface 18 → 两个箭头 GlassSurface 16
  │ ├ 星期栏 GlassSurface 12
  │ ├ 周课程网格（课程块 blur=0）
  │ └ LiquidAddButton GlassSurface 20
  ├ Positioned.fill → IgnorePointer → RepaintBoundary
  │ → BackdropFilter(sigma = 14 × progress)
  │ → ColoredBox(scrim alpha = 0.16 × progress)
  ├ Positioned.fill → 背景关闭手势
  └ GlassSheetScope → 实测几何容器 → CoursePreviewSheet
    └ GlassSheetPanel → ClipRRect / GlassSurface(sigma 22)
      ├ CourseHeroSurface（blur=0）
      ├ 内文、信息行
      └ X / 完整详情 / 编辑 GlassButton
        → 原 sigma 16；最终仅 Weekly 设为 0
```

Sheet sigma、scrim 和背景 scale 随同一 progress 变化；Preview 面板 sigma 固定 22，
其容器矩形与圆角在开合/拖动时变化。source/destination 继续实测并 Rect.lerp。
未另行测量 GPU filter bounds 或 saveLayer/overdraw；不从面积或层数推断具体成本。

## 3. Isolation Results

下表全部是三次**整个 open 窗口的峰值**，按重复顺序列出，单位 ms。
A 是生产修改前最后一次 baseline；早期 A 恢复复测另保留在 JSON 的 A_return。

| Variant | UI peaks | Raster peaks | Raster >16.67 ms / sampled frames | Result |
| --- | --- | --- | --- | --- |
| A Baseline | 4.127 / 2.840 / 3.084 | 21.026 / 22.202 / 24.841 | 17/45, 22/44, 22/42 | 重复超预算 |
| B Sheet blur off | 3.109 / 7.173 / 2.882 | 25.705 / 30.138 / 22.064 | 26/40, 25/38, 16/44 | 无稳定改善 |
| C Preview panel blur off | 2.973 / 3.073 / 2.834 | 21.025 / 24.271 / 22.049 | 16/44, 17/44, 19/44 | 峰值与 baseline 重叠 |
| D Weekly blur off | 2.657 / 2.894 / 3.117 | 18.640 / 18.116 / 17.750 | 7/46, 7/46, 8/46 | CONTRIBUTOR（整组） |
| E All relevant blur off | 1.678 / 1.638 / 1.590 | 6.350 / 6.495 / 6.011 | 0/46, 0/46, 0/46 | 整体差异复现 |
| F All Preview surface blur off | 2.964 / 2.882 / 3.037 | 18.255 / 18.630 / 18.458 | 8/46, 11/46, 11/46 | CONTRIBUTOR（整组） |
| G Weekly + Preview glass off; Sheet retained | 2.967 / 2.995 / 2.835 | 6.162 / 7.947 / 6.749 | 0/46, 0/46, 0/46 | 组合成本明确 |
| H Preview buttons only off; panel retained | 2.685 / 3.113 / 3.588 | 18.777 / 18.637 / 18.329 | 7/46, 11/46, 12/46 | CONTRIBUTOR（3 个嵌套按钮） |

B 用 `BackdropFilter.enabled=false`，保留 scrim。C 仅绕过 GlassSheetScope 内 sigma 22，
保留三个按钮；D 仅绕过 TimetablePage 下且不在 GlassSheetScope 内的 GlassSurface。
E 绕过所有 GlassSurface 与 Sheet filter；F 绕过 Scope 内所有 GlassSurface；
G 绕过 Weekly/Preview GlassSurface，保留 Sheet；H 仅绕过 Scope 内非 22 的有 blur 表面，
本样本对应三个按钮。Root switcher 属于 Host 外，D 未单独改变它。
临时逻辑全部仅在 profile 生效，采样后移除。不是生产策略。

所有表内样本 UI 均未超过预算。A_return 三次 Raster 峰值 25.354 / 22.266 / 22.707，
说明恢复原滤镜后成本回升。早期首次 baseline 的三次峰值 29.180 / 24.897 / 22.367
仅作探索记录；未保存那一次全帧数组，不拿它计算分布。
本轮数值与 09-28 的 34.9–37.2 ms 不是同一轮、同一取样法，不声称绝对差异的原因已确定。

## 4. Contribution Findings

### Sheet backdrop blur

Status: **MINOR / NOT OBSERVED**（独立关闭的可重复收益未观察到）。
Evidence: B 与 A 的峰值区间重叠；G 保留 Sheet 仍达到 6.162–7.947 ms。
不能据此说 Sheet 没有 GPU 成本；只是不支持优先降低它。

### Preview surface blur

Status: 面板 sigma 22 **MINOR / NOT OBSERVED**；三个嵌套按钮整体 **CONTRIBUTOR**。
Evidence: C 单关面板无明显稳定峰值下降；H 保留面板，只关按钮，三次均降至 18.329–18.777 ms。
F 的整组关闭没有进一步明显下降。没有单独排序 X、详情、编辑的贡献。

### Underlying Weekly glass

Status: **CONTRIBUTOR**（组级）；单个导航/箭头/星期栏/顶部按钮/FAB **UNVERIFIED**。
Evidence: D 三次 17.750–18.640 ms，但仍超预算。没有证明可保持视觉的背景冻结策略；本轮不改它。

### Overlapping filters

Status: Weekly/Preview 玻璃组合 **MAJOR CONTRIBUTOR**（组合级）；
Preview 按钮套面板的局部重叠 **CONTRIBUTOR**。
Evidence: G 与 E 接近，而 D/F 单组关闭后仍有约 18 ms 峰值。
收益不能按每层相加；没有证明所有滤镜对同一像素采样，或量出各层 GPU 分摊。
H 的按钮位于已模糊的面板内；Light 对比仍保留玻璃底色、发丝边缘、阴影与交互。

Scrim/overlay：B 保留 scrim 和 scale，证明仅取消 blur 与取消遮罩不是混同实验。
没有额外 scrim-off、固定 filter 区域或独立 scale-off 对照；其独立贡献 **UNVERIFIED**。
drag/open/close filter 范围变化由代码和抽帧确认，GPU bounds 因果仍 **UNVERIFIED**。

## 5. Production Optimization

只改两个生产文件：GlassButton 透传既有 GlassSurface 的可选 `blurSigma`（默认 null）；
CoursePreviewSheet 用既有 `heroSource == weeklyTimetable` 限定三个按钮的 `blurSigma=0`。
Today 仍传 null，所有普通按钮默认逻辑保持。保留 Sheet 动态 sigma 14、Preview 面板 sigma 22。

这是局部避免冗余重叠 blur：三个按钮继续绘制完整材质与按压反馈，复用父面板背景折射。
开合、拖动、静止均相同，不在运动结束时切换滤镜，因此没有引入质量档位 pop。
明暗材质分支、Reduced Motion、几何插值、关闭状态机均不改。
审查曾发现共享组件会影响 Today，已用上述已有来源语义修正，最终审查无问题。

## 6. Before / After

同一模拟器、profile/renderer/path，每轮一次预热加三次。
Before = evidence JSON 的 A；After = after（最终 guard 的生产路径；只残留 timing 采集，随后也移除）。

| Measurement | Before: three peaks (ms) | After: three peaks (ms) |
| --- | --- | --- |
| Preview open UI | 4.127 / 2.840 / 3.084 | 2.728 / 1.761 / 2.429 |
| Preview open Raster | 21.026 / 22.202 / 24.841 | 18.205 / 17.553 / 18.441 |
| Preview Back close Raster | 22.024 / 21.618 / 22.971 | 21.966 / 18.256 / 17.910 |

open 峰值中位数 22.202 → 18.205 ms（约 18.0% 下降）；完整短窗口合并 Raster p95
21.335 → 17.529 ms（nearest-rank）。open 超预算帧 61/131 → 29/138，UI 超预算均为 0。
这些是三次受控窗口，不是长期掉帧率；帧数不同，不把每个索引当作严格配对帧。
**优化后仍有 Raster 超预算，不能宣称已回到 60 Hz 帧预算内。**

close 合并 Raster p95 18.656 → 17.578 ms，但超预算数 32/135 → 36/134；
不声称所有关闭指标改善。探索生产首轮与测试执行重叠，出现一次 close 30.588 ms，
保存在 after_pilot，不能悄悄删除。独立复测未重现，但其成因并未确认。
核心 open 改善跨 H、生产初测、最终独立复测复现，未把成本转成可见 UI 超预算。

## 7. Visual Result

设备均为上述模拟器。通过内存截图人工对比，不保存 App 内容截图/录像。

| Item | Result |
| --- | --- |
| Open / Close | 正常路径抽查中间和落位画面；保留玻璃与真实 source 飞行 |
| Drag | 长拖关闭，扩展确认 parent sheet 已清空；未另采三次 timing |
| Short drag rebound | 中间画面和回弹后检查；扩展确认仍 open |
| Light | baseline/H/最终静态对比，材质、边缘、文字与按钮保留 |
| Dark | 最终面板与按钮检查通过 |
| Reduced Motion | Light/Dark 打开及 Back/背景关闭；扩展确认实际 MediaQuery.disableAnimations=true |
| Continuous 60 Hz visual judgment | UNVERIFIED；稀疏抽帧不能证明每帧无闪动或所有复杂手势平滑 |

未在采样画面观察到新增“塑料”材质、blur 档位突变或亮度跳变；此为抽查边界，非真机视觉验收。
系统 night mode、transition_animation_scale、animator_duration_scale 已恢复开工值。

## 8. State Machine Regression

现有 preview_dismiss 9 项与 preview_geometry 10 项最终通过，覆盖 Back、double Back、
X/Back 交叉、backdrop/其他入口交叉、drag/短拖回弹、programmatic close、callback-once、
cleanup/reopen、Reduced Motion、source 失效与 resize fallback。新 8 项覆盖两种来源、明暗、
Reduced/default 的父滤镜保留、普通按钮默认滤镜与 X/详情/编辑三个动作。
设备手动检查 Back、X、背景关闭、长拖和短拖回弹；double Back / callback-once 的确定性结论来自测试。
Host 与几何代码哈希未变，不把 Widget 验证扩大成真机 predictive back 验收。

## 9. Files Changed

- `lib/core/glass/glass_button.dart`：可选 blurSigma 参数透传，默认行为保留。
- `lib/features/timetable/widgets/course_preview_sheet.dart`：仅 Weekly 的三个按钮复用父层 blur。
- `test/preview_blur_test.dart`：新增 8 项来源/主题/Reduced/动作及滤镜边界检查。
- 本报告与 `evidence_2026-10-01_blur_profile.json`：11 组、2,956 条脱敏帧记录，含探索离群样本。
- `knowledge/current_state.md`、`tasks.md`、`testing.md`、`changelog.md`、`README.md`、
  `framework_glass.md`、`framework_motion.md`：任务、证据、状态与边界同步。

**临时 A/B instrumentation 已完全移除**。main.dart / glass_surface.dart / glass_sheet.dart
与开工备份 SHA-256 完全相同；lib 下无实验扩展/flag。
没有清理既有 `.playwright-mcp/` 或其它用户文件；没有 reset、commit、push。

## 10. Tests

- 原 Preview dismiss：9/9；原 geometry：10/10；新增 blur/scope：8/8；专项合计 **27/27**。
- 开工全量 **314/314**；最终全量 **322/322**。
- 新 fixture 最初遗漏 MediaQuery.size 导致按钮不可点击，补实际测试 viewport 后通过；未掩盖失败。

## 11. Validation

| Check | Result |
| --- | --- |
| flutter analyze --no-pub | Passed（S:\，No issues found） |
| flutter test --no-pub | Passed，322/322 |
| flutter build apk --debug --no-pub | Passed，S:\build\app\outputs\flutter-apk\app-debug.apk |
| git diff --check | Passed，最终知识库同步后复验 |

Debug APK：207,134,152 字节；SHA-256
`BA45FBBEE6698820E272FE95E60F2DC3CB66F01D652386B00713B336D62661EB`。
已用 `adb install -r` 安装干净 Debug 构建，替换带实验接线的 profile 构建，保留设备数据库；
这不是 Debug 性能测量。profile 实验进程已停止。

## 12. Unverified

Android 真机、iOS、老旧设备、高刷新率、14+ section 性能、长时间 soak、release mode，
predictive back、复杂连续手势、真机连续视觉与 GPU 逐层 bounds/overdraw，均 **UNVERIFIED**。
Weekly 各单个玻璃的贡献、独立 scrim/scale 成本及最终残余慢帧归因未验证。
不制造业务数据，不从模拟器结果增加设备型号降级。

## 13. Scope

未改 PageView、preload、layout cache、RepaintBoundary、Today Preview 行为、导航架构、
Preview geometry model、dismiss 状态机、data model、JS Adapter / Bridge / NavigationPolicy、
WebView、Import、SemesterService、签名或 package dependencies。
没有顺手优化 Weekly swipe / DST / midnight refresh / 全 App motion。
本轮仅保留已证实有收益的 Weekly 三按钮局部改动，完成验证后停止。
