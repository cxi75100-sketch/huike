# 框架报告 — 主题与视觉令牌

2026-10-02 TASK-LAUNCH-BRAND-01：启动品牌与Android原生splash统一使用Light背景#F5F6F9，即使夜间；目的页面主题仍按用户偏好。下方原生splash与dark palette一致描述为历史。今日状态标签使用accentSoft/ink，课间与结束文字inkSecondary，不增加色板或课程卡渐变。

## 2026-10-01 图标恢复

当前Launcher保留蓝色Flutter标志；2026-10-02 Android adaptive改为安全圆内矢量，启动另用独立矢量；iOS/legacy PNG保持。生成与验证入口见design.md。下方三白块图标相关记录为旧状态；真机/iOS视觉未验证。

## 2026-10-01 单色课程卡

2026-10-02最新：`card`直接使用红橙黄绿青蓝紫粉全色相Light/深色Dark配对（TASK-COURSE-HUES-01），均alpha=1。`onCard` #172033 / #F3F6FA；Light onChip使用Dark配色以保证可读。Today/Weekly共用，原hash和16色索引不变；测试覆盖明暗16色对比度≥4.5与八个色相区间。

## Last Updated

2026-10-02 +08:00 ｜ TASK-COURSE-HUES-01 全色相课程色；下方基线审计为历史

证据来源：2026-09-28 只读代码调研 + `report_2026-09-28_motion_audit_full.md` §3、P1-5。

---

## 1. 边界

**负责**：明暗两套调色板、Material 主题覆盖、课程16色与染色规则、主题偏好的持久化、视觉几何/材质令牌（`GlassMetrics`）。

**不负责**：动效令牌（`GlassMotion` → `framework_motion.md`）、玻璃绘制实现（→ `framework_glass.md`）、设计语言与层级（→ `design.md`）。

---

## 2. 关键文件与入口

| 角色 | 文件 | 说明 |
| --- | --- | --- |
| 调色板（唯一） | `lib/core/theme/app_palette.dart` | 12 字段 × 明暗两套 `static const` |
| 取色入口（唯一） | `lib/core/theme/app_theme.dart` → `AppTheme.paletteOf(context)` | 按 `Theme.of(context).brightness` 二选一 |
| Material 主题 | `lib/core/theme/app_theme.dart` | `AppTheme.light()` / `AppTheme.dark()`，14 个子主题 |
| 课程16色 | `lib/core/theme/course_colors.dart` | 16 组 (浅,深) 色 + 名称散列 + `courseTint()` |
| 偏好枚举 | `lib/core/theme/theme_preference.dart` | `system/light/dark` ↔ 字符串 ↔ `ThemeMode` |
| 偏好持久化 | `lib/core/theme/theme_preference_provider.dart` | `AsyncNotifierProvider<ThemeController, ThemePreference>`，存 `settings.theme_mode` |
| 几何/材质令牌 | `lib/core/glass/glass_metrics.dart` | 见 `framework_glass.md` §3 |
| 挂载点 | `lib/app.dart:41-49` | `theme` / `darkTheme` / `themeMode` / `themeAnimationDuration` |

---

## 3. `AppPalette`（12 字段 × 2 套）

`CONFIRMED`：**不是 `ThemeExtension`**，是普通类 + 两个 `static const` 实例。取值只按 `brightness` 硬分支，**无中间态**（`app_palette.dart:33,48`；`app_theme.dart:178-182`）。

| 字段 | Light | Dark | 语义 |
| --- | --- | --- | --- |
| `background` | `#F5F6F9` | `#111319` | 页面底色（**与原生 splash 逐字节一致**，见 `framework_startup.md`） |
| `surface` | `#FFFFFF` | `#252830` | 玻璃基底 |
| `surfaceAlt` | `#EDEEF2` | `#2E323C` | 次级面 |
| `ink` | `#17191F` | `#F4F5F8` | 主文字 |
| `inkSecondary` | `#5D616C` | `#B8BDC8` | 次文字 |
| `inkTertiary` | `#848995` | `#8D93A1` | 三级文字 |
| `hairline` | `#DDE0E7` | `#363B47` | 分隔线 |
| `hairlineStrong` | `#C3C8D2` | `#555C69` | 强化边线 |
| `accent` | `#007AFF` | `#62A7FF` | 强调色 |
| `onAccent` | `#FFFFFF` | `#071D39` | 强调前景 |
| `accentSoft` | `#DEECFF` | `#1B354F` | 强调柔和底 |
| `danger` | `#D92D3A` | `#FF777F` | 危险色 |

**全库 `Color(0x` 字面量只出现在两处**：`app_palette.dart`（24 处）与 `ambient_backdrop.dart`（4 个环境光常量，`ambient_backdrop.dart:41-44`）。

## 4. `AppTheme` 覆盖面

- 基座 `ThemeData`：`useMaterial3: true`、`brightness`、`colorScheme`（由 palette 组装 12 个字段）、`scaffoldBackgroundColor`、**`splashFactory: NoSplash.splashFactory`**（`app_theme.dart:34-40`）
- 唯一次 `copyWith`（`:42`）覆盖 **14 个子主题**：`appBarTheme:43`、`dividerTheme:68`、`textTheme:69`、`textSelectionTheme:70`、`inputDecorationTheme:75`、`filledButtonTheme:97`、`outlinedButtonTheme:109`、`textButtonTheme:120`、`dialogTheme:127`、`snackBarTheme:140`、`listTileTheme:148`、`switchTheme:153`、`datePickerTheme:164`、`navigationBarTheme:171`
- 圆角常量：`_radiusBlock = 22.0`、`_radiusControl = 14.0`（`:10-11`）
- **`pageTransitionsTheme` 全库零命中** —— 没有任何全局路由过渡配置；路由过渡全部逐条手写（见 `framework_navigation.md` §3）
- `paletteOf()` 的判据是 `Theme.of(context).brightness`，**不是** `MediaQuery.platformBrightness`

## 5. 课程16色（`course_colors.dart`）

| # | 色名（注释） | Light | Dark |
| --- | --- | --- | --- |
| 0 | coral | `#EAB8B8` | `#602E2E` |
| 1 | apricot | `#EACBB8` | `#60412E` |
| 2 | amber | `#EADEB8` | `#60542E` |
| 3 | lemon | `#E4EAB8` | `#5A602E` |
| 4 | lime | `#D1EAB8` | `#47602E` |
| 5 | green | `#BEEAB8` | `#35602E` |
| 6 | mint | `#B8EAC4` | `#2E603B` |
| 7 | sea green | `#B8EAD7` | `#2E604E` |
| 8 | teal | `#B8EAEA` | `#2E6060` |
| 9 | sky | `#B8D7EA` | `#2E4E60` |
| 10 | blue | `#B8C4EA` | `#2E3B60` |
| 11 | indigo | `#BEB8EA` | `#352E60` |
| 12 | violet | `#D1B8EA` | `#472E60` |
| 13 | orchid | `#E4B8EA` | `#5A2E60` |
| 14 | rose | `#EAB8DE` | `#602E54` |
| 15 | berry | `#EAB8CB` | `#602E41` |

- 取色：`_courseColors[colorKey.abs() % 16]`（`:27`）——**无命名 key**，只有行尾注释
- 名称散列：`colorKeyForName` = FNV-1a 32 位（seed `0x811c9dc5`、prime `0x01000193`、掩码 `0x7FFFFFFF`，`:43-50`）
- `courseTint()` 返回 `CourseTint{chip, onChip, card, onCard}`（`:5-13, 26`）
  - **dark**：`chip = Color(dark).withValues(alpha: 0.9)`；`onChip = HSLColor(dark).withLightness(0.82)`；card直接Dark
  - **light**：`chip = light @ alpha 0.13`；`onChip = dark`；card直接Light
- **无任何对比度数值常量**；只有注释声明意图（低饱和、只用于小块面、同一课程恒同色、夜间提亮保可读）。对比度 ≥4.5:1 的结论来自 TASK-019D 的测试与实画，不在本文件重述

## 6. 主题偏好

| 事实 | 位置 |
| --- | --- |
| 枚举 `system / light / dark` | `theme_preference.dart:4` |
| 字符串映射，未知/空 → `system` | `:6-18` |
| `themeModeOf()` → `ThemeMode.*` | `:20-24` |
| 持久化：`settings` 表 key `theme_mode` | `theme_preference_provider.dart:6` |
| provider：`AsyncNotifierProvider<ThemeController, ThemePreference>`，非 autoDispose | `:23-26` |
| 失败回退：**无 try/catch**；DB 异常 → `AsyncError` → `app.dart` 取 `.value` 得 null → `system` | `app.dart:31,46` |
| 首帧前读一次：`container.read(themePreferenceProvider.future)` | `main.dart:11-19`（见 `framework_startup.md`） |

**主题动画时长**：`themeAnimationDuration: _themeSettled ? kThemeAnimationDuration : Duration.zero`（`app.dart:47-49`）。即启动阶段为 0，首帧后经 `addPostFrameCallback` 置真，之后使用框架常量 200ms。**不使用 `GlassMotion`**。

## 7. 视觉令牌现状

- 集中令牌只有两个文件：`GlassMetrics`（几何/材质，见 `framework_glass.md` §3）与 `GlassMotion`（时长/曲线/弹簧，见 `framework_motion.md` §3）。
- **其余数值散落在调用点**（改视觉时逐个检查）。样例：

| 位置 | 魔数 |
| --- | --- |
| `settings_page.dart:28,31,149-150,179` | `EdgeInsets(18,8,18,32)`、radius 22 / 20 / 18、blurSigma 16 |
| `school_manage_page.dart:39,42` | radius 12、tint alpha 0.1 |
| `calendar_exception_page.dart:257-263` | 3×34 色条 + radius 2 |
| `ambient_backdrop.dart:41-44,59-89` | 4 个环境光常量 + 6 组 alpha |
| `timetable_course_block.dart:114,117-137,139,145` | `Color.lerp(surface, white, 0.08)`、alpha 0.76/0.64/0.70、`lerp(hairlineStrong, white, 0.45)`、阴影 alpha 0.20/0.06 |
| `glass_form.dart:145,209,376` | radius 12 / 12 / 18 |
| `glass_empty_state.dart:19`、`liquid_add_button.dart:86,130,158` | radius 20 / 20 / 19 / 13 |

（`GlassMetrics.edgeWidth` 定义存在但无调用点。）

## 8. 明暗一致性（关键缺口）

- **全库无 `ThemeExtension` 实现、无自定义 `lerp` 覆写**（grep 仅命中 `app_theme.dart:178` 的说明性注释）。
- 因此明暗切换时：进入 `ColorScheme` 的字段随框架 `ThemeData.lerp` 在 200ms 内过渡（`INFERRED`，未在测试中验证），而**所有自绘取色瞬间跳变**——`paletteOf()` 与 `courseTint()` 都只按 `brightness` 二选一。
- 走 `paletteOf` 的地方包括：`AmbientBackdrop` 环境底色、`GlassSurface` 填充与照明、课程块渐变/边框、星期栏、周导航、各级文字色。**即"玻璃与环境底立即变色、Material 控件渐变"的混合状态**。
- 现有 `Color.lerp` 调用**都不是主题过渡**：`press_physics.dart:111-112`（Alignment）、`timetable_root_shell.dart:284,299`（分段控件进度）、`timetable_course_block.dart:72,114,139`（材质取色）。

## 9. 唯一定义点

| 策略 | 唯一位置 |
| --- | --- |
| 全部颜色字面量 | `app_palette.dart`（+ `ambient_backdrop.dart` 的 4 个环境光常量） |
| 取调色板 | `AppTheme.paletteOf(context)` |
| 明暗判断 | `Theme.of(context).brightness`（**不得改用 `MediaQuery.platformBrightness`**） |
| 课程色映射与散列 | `course_colors.dart` |
| 主题偏好读写 | `theme_preference_provider.dart` + `settings.theme_mode` |
| 几何/材质令牌 | `glass_metrics.dart` |
| 涟漪禁用 | `app_theme.dart:39` → `NoSplash.splashFactory` |

## 10. 改动时必须同步的位置

- 改任一颜色 → `app_palette.dart` + 检查 `ambient_backdrop.dart` 的 4 个环境光常量是否仍协调 + 本文件 §3 表
- 改主题子主题覆盖 → 本文件 §4 清单（逐项确认数量）
- 加/改课程色 → `course_colors.dart` + 本文件 §5 表 + 课程块与预览的染色调用点
- 改圆角/间距 → 优先收进 `GlassMetrics`；否则更新本文件 §7 表
- 做主题过渡动画 → 必须同时处理 `paletteOf` 的取值方式（见本文件 §8）+ `app.dart:47-49`
- 加新页面 → 用 `AppTheme.paletteOf`，不要新建第三套取色

---

## 11. 已知问题与技术债

- **P1-5 / 索引表 F**：主题明暗切换只动一半——`AppPalette` 无 lerp，自绘颜色瞬时跳变而 Material 控件 200ms 渐变。**两套节奏同时出现在一帧画面里**。
- `themeAnimationDuration` 用框架常量 `kThemeAnimationDuration`（200ms），不在 `GlassMotion` 体系内——若统一节奏需一并处理。
- 明暗偏好读取失败静默回退到 `system`，**无用户可见提示**（`app.dart:31,46` 取 `.value`）。
- `GlassMetrics.edgeWidth` 无调用点（索引表 L）。
- 课程16色无非命名 key，只有行尾注释；`colorKey` 为 `int` 落库，改色序会改变既有课程的显示色（`colorKey % 16` 语义）。
- `Color(0x` 之外的明暗数值（玻璃填充 alpha、边框 alpha 等）散落在 `glass_surface.dart:225-336`，与明暗分支耦合，改色需同步。

---

## 12. 未验证边界

- `ColorScheme` 字段在明暗切换时的实际插值表现：`INFERRED`（未在测试或设备上验证）。
- 八色在教学楼投影/强光下的可辨识度：`UNVERIFIED`（TASK-019 系列只验证过模拟器实画与对比度测试）。
- iOS 上 `brightness` 与系统外观切换的联动：`UNVERIFIED`。

---

## 13. 更新记录

| 日期 | 变更 | 依据 |
| --- | --- | --- |
| 2026-09-28 | 首次建立：12 字段双套色值、14 个子主题、八色表、明暗缺口 | 2026-09-28 只读调研 + TASK-MOTION-AUDIT-01 |
