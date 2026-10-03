# 框架报告 — 玻璃材质与按压表面

## 2026-10-02 关闭可中断

TASK-PREVIEW-RAPID-01：关闭中的遮罩GestureDetector外加IgnorePointer，面板亦IgnorePointer；新展示generation key使didUpdateWidget在dismiss中重开，stop取消旧TickerFuture，因此旧完成回调不清新展示。自然关闭仍仅一次onDismissed，编辑待执行导航不被普通课程点击取消。下方旧关闭合同仅描述未被中断的周期。

## 2026-10-02 当前Today预览/详情

TASK-TODAY-MOTION-COLOR-01：GlassSheetPanel可选blurSigma默认22；Today预览传0，三个课程预览按钮统一0。Today来源详情的两个GlassSurface与编辑/删除按钮均传0；CourseHeroSurface原本0。今日移动面板/详情不含BackdropFilter，保留现有材质绘制。Weekly父面板22保持，普通按钮默认值不变。下方“Today保留16”和层数表为前轮历史，不能作为新路径profile。

## 2026-10-02 当前Weekly遮罩

TASK-VISUAL-RETURN-01：Weekly backgroundScale=0、maxBlur=0；Host在maxBlur=0分支只画压暗ColoredBox，不创建遮罩BackdropFilter。父面板blur22与Weekly三个按钮blur0保持。下方同屏层数和性能表均为09-28/10-01历史测量，不代表新路径的帧耗时；本轮无设备profile。

## 2026-10-01 课程卡单色例外

`GlassSurface.solidColor` 可选、默认null；非空时 painter 只画一个纯色圆角底，不画渐变/高光/边框。Today blurSigma=0并启用该选项；Weekly使用BoxDecoration.color，无gradient。其他GlassSurface默认材质、前轮Preview按钮blur复用与几何/关闭合同保留。

## Last Updated

2026-10-02 +08:00 ｜ Weekly遮罩仅压暗、背景固定；父面板玻璃保持

证据来源：`report_2026-09-28_motion_audit_full.md` §3、§8（含同屏层数统计与实测几何）。

---

## 1. 边界

**负责**：全 App 的半透明材质表面（填充、方向性照明、触摸高光、发丝边缘、投影）、按压反馈的视觉部分、以及模糊（`BackdropFilter`）的**唯一载体与成本约束**。

**不负责**：时长/曲线/弹簧（→ `framework_motion.md`）、颜色取值（→ `framework_theme.md`）、层级顺序（→ `framework_navigation.md` 与 `design.md`）。

---

## 2. 关键文件与入口

| 角色 | 文件 | 说明 |
| --- | --- | --- |
| **唯一模糊载体** | `lib/core/glass/glass_surface.dart` | `GlassSurface`：五层结构 + PressPhysics 接线 + `_GlassSurfacePainter` |
| 几何/材质常量 | `lib/core/glass/glass_metrics.dart` | 半径、五档模糊、点击目标、位移距离 |
| 按压物理 | `lib/core/glass/press_physics.dart` | 见 `framework_motion.md` §4.1 |
| 按钮封装 | `lib/core/glass/glass_button.dart` | `GlassButton` / `GlassButton.icon`，全 App 按钮类交互入口 |
| 弹窗面板 | `lib/core/glass/glass_dialog.dart` | 面板 sigma = `prominentBlur` |
| Sheet 面板 | `lib/core/glass/glass_sheet.dart` → `GlassSheetPanel` | 面板 sigma 22；圆角随拖动进度 26→20 |
| 表单表面 | `lib/core/glass/glass_form.dart` | `blurSigma: 0`（表单不模糊） |
| 空态 | `lib/core/glass/glass_empty_state.dart` | sigma 12 |
| 环境底色（LEVEL 0） | `lib/core/widgets/ambient_backdrop.dart` | 三段渐变 + 朱砂辉光；提供「有东西可折射」的底 |
| 约束测试 | `test/glass_interaction_test.dart`、`test/week_agenda_ui_test.dart`（「模糊只出现在导航与弹层：课程块本身不含 BackdropFilter」） | 改动必须保持通过 |

---

## 3. 结构：一条玻璃的五个层（`glass_surface.dart`）

自下而上：

1. `BackdropFilter` —— 折射背后真实内容（sigma ≤ 0 时**整层不建**，见 `_maybeBlur()`）
2. 半透明材质底色 —— 左上偏亮、右下偏暗的方向性渐变
3. 方向性照明 —— 极轻白色照明，按压时增强
4. 触摸高光 —— 位置跟随手指，强度跟随按压进度（< 10%）
5. 发丝边缘 —— 1px 边线 + 向外投影（按压时减弱）

包裹顺序（性能相关，改动时不要打乱）：

```
RepaintBoundary                        ← 每条玻璃自带，隔离重绘
└ PressPhysics（唯一指针物理）
  └ Transform.scale(1 - pressScale * press)     ← 只动 transform
    └ DecoratedBox（阴影随 press 变化）
      └ ClipRRect(borderRadius)                 ← 圆角裁剪
        └ BackdropFilter(sigma)                 ← 唯一模糊点
          └ CustomPaint(_GlassSurfacePainter)   ← 填充/照明/高光/边缘
            └ Transform.scale(childPressScale)  ← 内容缩放
              └ RepaintBoundary(Padding(child)) ← 内容与材质解耦
```

### `GlassIntensity` → sigma（`glass_surface.dart:97-100`）

| 强度 | sigma | 典型使用者 |
| --- | --- | --- |
| `subtle` | `GlassMetrics.subtleBlur` = 10 | 星期栏（显式 12）、底部切换器 |
| `regular` | `regularBlur` = 16 | `GlassButton` 默认、周导航（显式 18）、顶部图标 |
| `prominent` | `prominentBlur` = 22 | Dialog、Sheet 面板、加课按钮（显式 20）、课程编辑底栏 |

### `GlassMetrics` 全量（`glass_metrics.dart:5-15`）

| 常量 | 值 | 语义 | 使用情况 |
| --- | --- | --- | --- |
| `minimumTarget` | 44.0 | 最小点击目标 | 使用 |
| `controlRadius` | 16.0 | 控件圆角 | 使用 |
| `groupRadius` | 20.0 | 分组/面板圆角 | 使用 |
| `sheetRadius` | 26.0 | Sheet 圆角 | 使用 |
| `subtleBlur` / `regularBlur` / `prominentBlur` | 10 / 16 / 22 | 三档模糊 | 使用 |
| `edgeWidth` | 1.0 | 边缘线宽 | **无调用点**（实际边缘为硬编码 0.9，见 `glass_surface.dart:298`） |
| `pressScale` | 0.03 | 按下压缩比例 | 使用 |
| `pageTravel` | 12.0 | 页面位移 | 使用 |
| `overlayTravel` | 8.0 | 弹层位移 | 使用（Dialog） |

**未进入 `GlassMetrics` 的模糊值**（散落在调用点，改模糊时逐个检查）：`12`（`weekday_header.dart:80`、`glass_empty_state.dart:21`）、`16`（`settings_page.dart:150`）、`18`（`week_navigation.dart:97`）、`20`（`liquid_add_button.dart:88,132`）、`22`（`glass_sheet.dart:335`）。

---

## 4. 全项目模糊点与同屏层数

- **`BackdropFilter` 源码点：2 处** —— `glass_surface.dart:197`（通用载体）与 `glass_sheet.dart:176`（Sheet 全屏遮罩）。`ImageFilter.blur` 也只在这两处。
- **`GlassSurface` 调用点：32 处，分布在 22 个文件**。

### 同屏玻璃层数（含模糊的 `GlassSurface` **实例计数**）

> **已更正**（第二阶段复核 TASK-AUDIT-02 §I）：第一轮漏计周导航岛内部的两个箭头按钮。
> 计数口径是**组件实例数**，**不等于同一像素的多次模糊**；空间重叠是局部的（周导航箭头与其父层、Sheet 按钮与面板），全屏层只有 Sheet 遮罩。全项目**未见 `BackdropGroup`/`BackdropKey`**。每像素实际 overdraw、raster cache 与帧耗时均 `UNVERIFIED`。

| 场景 | 实例数 | 明细 |
| --- | --- | --- |
| Weekly 静止 | **约 8** | 顶部导入 16、顶部设置 16、周导航外层 18、**周导航左箭头 16、右箭头 16**、星期栏 12、加课按钮 20、底部切换器 10 |
| Weekly + 加课菜单展开 | 9 | 上一行 + 菜单容器 20（菜单内 3 个条目 `blurSigma: 0`，不叠加） |
| Weekly + 课程预览（静止） | **约 9 个滤镜** | 下层 7 个 GlassSurface（底部切换器隐藏）+ Sheet 遮罩 14 + 面板 22；Weekly 的 X/详情/编辑三个按钮设 0，Today 保留默认 |
| Today 静止 | 1 | 切换器 10（时间轴卡片刻意 `blurSigma: 0`，`today_timeline.dart:323`） |
| Settings | 2–3 | 分组卡 16 + 行内 `blurSigma: 0` |
| 课程编辑 | 2 | 底栏 22 + 「添加课程」按钮 16 |

### 嵌套 `BackdropFilter`（filter 套 filter，已确认 3 处）

| 位置 | 外层 | 内层 |
| --- | --- | --- |
| `week_navigation.dart:94-155` 周导航岛 + 两个箭头 | `GlassSurface` 18 | 左右 `GlassButton.icon`（默认 `regular`）各 16 |
| `glass_sheet.dart` → `GlassSheetPanel` + `GlassButton` | 面板 22 | 通用标题关闭按钮仍默认；Weekly CoursePreviewSheet 的三个按钮为 0，Today 保留 16 |
| `course_edit_page.dart:197` 底栏 + `:209` 按钮 | 22 | 16 |

**已更正**：第一轮把 `ClipRRect` 包住单个滤镜也算作「嵌套」——那是**圆角裁剪成本**，不是 filter 嵌套。`glass_surface.dart:144-169` 的 `ClipRRect → BackdropFilter` 结构意味着每次模糊附带一次裁剪 + saveLayer，但只有一层滤镜。

**刻意不嵌套的正面例子**：加课菜单容器 20 + 条目 0（`liquid_add_button.dart:88,157`）；Settings 分组 16 + 行 0（`settings_page.dart:150,178`）；预览内的 `CourseHeroSurface` 用 `blurSigma: 0`（`course_hero.dart:95`）。

---

## 5. 动画与模糊的相互作用（成本核心）

| 事实 | 位置 |
| --- | --- |
| 全屏遮罩的 sigma 随 Sheet 进度逐帧改写（`maxBlur * value`，maxBlur 14）→ 每帧新建 `ImageFilter` + saveLayer | `glass_sheet.dart:176-189` |
| 同一动画里整个背景被 `Transform.scale` 缩放且**无 RepaintBoundary 隔离** → 被模糊的内容自身每帧在变，模糊结果无法复用 | `glass_sheet.dart:168-171` |
| Sheet 面板圆角与边缘高光随进度变化（`panel(value)` 每帧重建 `GlassSurface`） | `glass_sheet.dart:332-358` |
| 玻璃层**不重建内容子树**（`PressPhysics` 的 `child:` + `RepaintBoundary`），唯一例外是底部切换器每帧重建 2 图标 + 2 文字的 `Color.lerp`（在 `RepaintBoundary` 内） | `press_physics.dart:168-178`、`timetable_root_shell.dart:249-320` |
| 事实：每个 Shell 分支只包一层 `RepaintBoundary`（`timetable_root_shell.dart:152`）。**「因此网格位移会让玻璃逐帧重算模糊」已降级为 PERF-HYPOTHESIS**——边界存在不构成因果证明；BackdropFilter 因背后图像变化重新采样 ≠ Widget rebuild / RenderObject layout / 内容 paint，四个阶段需分别观测 | 复核见 TASK-AUDIT-02 §I |
| 按下时同时改阴影 alpha/blur/offset、渐变 alpha、边缘 alpha（比纯 transform 贵，但面积小且在自带 RepaintBoundary 内） | `glass_surface.dart:130-158, 225-336` |
| 课程块**不模糊**，但按压时整个 `BoxDecoration`（3 段渐变 + 0.9dp 边框 + 2 层阴影）逐帧重建，且**无 RepaintBoundary** | `timetable_course_block.dart:105-157` |

---

## 6. 唯一定义点

| 策略 | 唯一位置 |
| --- | --- |
| 模糊滤镜的创建 | `glass_surface.dart` → `_maybeBlur()`（+ Sheet 全屏遮罩在 `glass_sheet.dart:176`） |
| 玻璃强度 → sigma 映射 | `glass_surface.dart:97-100` → `GlassSurface.sigmaOf()` |
| 玻璃几何/材质常量 | `glass_metrics.dart` |
| 触摸高光的静止位置 | `glass_surface.dart:91` → `GlassSurface.restHighlight` |
| 材质绘制（填充/照明/高光/边缘） | `glass_surface.dart` → `_GlassSurfacePainter` |
| 按压物理 | `press_physics.dart`（不得另写 `AnimatedScale`） |

## 7. 改动时必须同步的位置

- 改 sigma 档位 → `glass_metrics.dart` + 本文件 §3 表 + 检查 §3 末尾的「未进入 GlassMetrics 的模糊值」清单
- 改 `GlassSurface` 结构 → 本文件 §3 包裹顺序 + 跑 `test/glass_interaction_test.dart`（含「每块玻璃有独立重绘边界」「五层里有模糊层」断言）
- 新增玻璃表面 → 本文件 §4 层数表 + `framework_motion.md` §6
- 给课程块加模糊 → **必须先看** `test/week_agenda_ui_test.dart` 的「课程块本身不含 BackdropFilter」断言；这是刻意的性能约定
- 改 `GlassIntensity` 枚举 → `glass_surface.dart:12` + 全部使用点 + `framework_theme.md`（强度与明暗填充分支耦合）

---

## 8. 已知问题与技术债

**TASK-PERF-BLUR-01（2026-10-01）最新证据**：EMULATOR PROFILE EVIDENCE。
单关 Sheet/Preview 面板没有明显稳定下降；下层 Weekly glass 和 Preview 三个嵌套按钮
各为组级 CONTRIBUTOR；Weekly/Preview glass 同时关闭而 Sheet 保留为 6.162–7.947 ms。
仅保留 Weekly 三按钮 blur=0（父面板 sigma22 保留），最终 open 峰值中位数
22.202→18.205 ms，仍有超预算帧。单个下层控件归因与真机外推 UNVERIFIED。
详见 `report_2026-10-01_perf_blur_01.md`；以下 09-28 整组观察属于历史证据。

> **证据更新**：第一轮 P0 评级已由 TASK-AUDIT-02 撤回。TASK-WEEKLY-PERF-PROFILE-01 随后在 Android API 36 模拟器的 Preview-open profile 中做了临时 blur A/B：启用时代表 Raster 34.9–37.2 ms，绕过全部 `GlassSurface` 与 Sheet blur 后为 5.9–7.2 ms。此证据把 blur 与该模拟器路径的 Raster 峰值关联起来，但未隔离具体滤镜层，不能外推到真机或其它页面。

- **Profile finding（模拟器限定）**：Preview open 的 Raster 超预算在三次原始采样中复现；临时关闭全部玻璃 blur 后三次代表帧均低于预算。Sheet 遮罩、Weekly 下层 GlassSurface 与局部重叠 filter 未分别隔离；后续需在目标真机复测并分层归因。详见 `report_2026-09-28_weekly_perf_profile_01.md`。
- **已解决（TASK-PREVIEW-BACK-01）**：Host 已使用统一 dismiss 状态和正常弹簧完成回调；
  取消不清理，重复关闭/拖动在 dismissing 期间忽略。原 `whenCompleteOrCancel` 描述已过期。
- **P2-1**：课程块与 `+N` 签按压未接 Reduced Motion（`timetable_course_block.dart:101-102,329`）。
- **P2-6**：Dialog 无玻璃遮罩，Preview 有全屏模糊 + 压暗——同为「层 5」两种遮罩语言。
- **P2-8**：每个交互面 2 个 `AnimationController`；一周约 25 课块 + 约 10 玻璃控件 ≈ 70 控制器 / 140 ticker（空闲不 tick）。
- **L（索引表）**：`GlassMetrics.edgeWidth` 无调用点。
- 全项目未见 `BackdropGroup`/`BackdropKey`（无跨玻璃的模糊分组优化）。

---

## 9. 未验证边界

- 单个下层玻璃与三个按钮分别排名、GPU overdraw / saveLayer 的独立开销：`UNVERIFIED`；
  已有 2026-10-01 组级/面板/Sheet/按钮隔离，不能宣称单个图层 GPU 分摊已确认。
- 真机上的 Impeller backdrop blur 代价与其它页面表现：`UNVERIFIED`。
- 同屏 11 层玻璃在真机上的可接受程度：`UNVERIFIED`。
- iOS 上 `BackdropFilter` 的表现与成本：`UNVERIFIED`。

---

## 10. 更新记录

| 日期 | 变更 | 依据 |
| --- | --- | --- |
| 2026-10-01 | 分层 profile，Weekly 三按钮复用父模糊，更新滤镜计数与未验证边界 | `report_2026-10-01_perf_blur_01.md` |
| 2026-09-28 | 补入 Preview-open blur A/B 的模拟器 profile 证据及设备/图层归因边界 | `report_2026-09-28_weekly_perf_profile_01.md` |
| 2026-09-28 | 首次建立：结构、包裹顺序、层数统计、嵌套清单、成本事实 | TASK-MOTION-AUDIT-01 |
