# 框架报告 — 启动与首帧

## Last Updated

2026-10-03 +08:00 ｜ TASK-DEFER-SCHOOL-01 空库进入首页

启动readiness、品牌退场和数据库错误重试机制保持。学校状态settle后，空库显示首页导入CTA，不再跳建校表单，也不播种学校/学期。主动导入时填写学校与网址；既有学校直接原课表。

最新：Android values/values-night launch_background均#F5F6F9，四种LaunchTheme均浅色系统栏；LaunchReveal使用AppPalette.light背景和FlutterLogo矢量、汇课文字，ready后GlassMotion.slow=280ms品牌退场，首页全程不透明且可点击，首pointer立即结束装饰；Reduced直接落位/不重播。品牌最前景独立AnnotatedRegion覆盖下方AppBar，状态栏图标依据混合底亮度切换，导航栏保持浅底深图标直到退场。原生iOS白底未改，未做iOS/真机验证；旧“夜间原生底与dark palette一致”已失效。

当前增补：数据库beforeOpen等待只读旧库事务导入，主题与课表provider首读不会先看到空数据。HuikeApp在既有themePreferenceProvider.hasError时返回读取失败界面，不创建router；点重试invalidate(databaseProvider)重新开库。根组件不增加学校状态直接订阅，避免无关WebView重建。原main首帧解锁保留，错误时解锁用于显示失败提示。正常LaunchReveal与ready链保持；见TASK-LEGACY-UPGRADE-01报告。

证据来源：`report_2026-09-28_motion_audit_full.md` §10、§11（含模拟器 profile 实测）+ 2026-09-28 只读调研。

---

## 1. 边界

**负责**：从进程启动到首帧绘制完成的连续性——原生启动底色、首帧门控、就绪判定、一次性揭示动画、边到边配置时机。

**不负责**：启动之后的动效（→ `framework_motion.md`）、图标资源生成（→ `framework_dependencies.md` §7）、数据库初始化细节（→ `framework_data.md`）。

---

## 2. 关键文件与入口

| 角色 | 文件 | 说明 |
| --- | --- | --- |
| 进程入口 | `lib/main.dart` | `deferFirstFrame` → 读主题 → `allowFirstFrame` → `runApp` |
| 应用外壳 | `lib/app.dart` | `MaterialApp.router`、主题模式、`themeAnimationDuration`、`builder` 包 `LaunchReveal` |
| 就绪判定（唯一） | `lib/core/widgets/launch_readiness.dart` → `launchReadinessProvider` | 汇总主题/学校/学期/作息/课程/校历的 settle 状态 |
| 揭示动画（唯一） | `lib/core/widgets/launch_reveal.dart` | 一次性 180ms / 4dp / 始终不透明；`_revealed` 保证全树只播一次 |
| 环境底色 | `lib/core/widgets/ambient_backdrop.dart` | 首帧可见的 LEVEL 0 |
| Android 启动主题 | `android/app/src/main/res/values{,-night}/styles.xml`、`values{,-night}-v31/styles.xml` | `LaunchTheme` / `NormalTheme` |
| Android 启动底色 | `android/app/src/main/res/values{,-night}/launch_colors.xml`、`drawable{,-v21}/launch_background.xml` | `@color/launch_background` |
| 平台检查清单 | `knowledge/testing.md` | 启动相关验证命令 |

---

## 3. 启动时序（`CONFIRMED`）

```
[Android/iOS 原生窗口]
  底部颜色 = @color/launch_background（Light #F5F6F9 / Dark #111319）
  Android 12+ 另设 windowSplashScreenBackground 同值
        ↓
main()（lib/main.dart:10-23）
  1. WidgetsFlutterBinding.ensureInitialized()
  2. binding.deferFirstFrame()          ← 首帧被门控
  3. ProviderContainer()（未走 ProviderScope）
  4. container.read(themePreferenceProvider.future)
       → 成功或失败都 allowFirstFrame()（失败也放行，不卡启动）
  5. SystemChrome.setEnabledSystemUIMode(edgeToEdge)   ← 未 await
  6. runApp(UncontrolledProviderScope(child: HuikeApp()))
        ↓
HuikeApp.build（lib/app.dart:27-49）
  ready = ref.watch(launchReadinessProvider)
  _launched = _launched || ready            ← 只前进不回退
  preference = ref.watch(themePreferenceProvider).value
  首次拿到偏好 → addPostFrameCallback → _themeSettled = true（把主题动画时长从 0 切到 200ms）
        ↓
MaterialApp.router.builder
  AnnotatedRegion<SystemUiOverlayStyle>（边到边透明状态栏/导航栏）
  LaunchReveal(ready: _launched)
      ready == false → AmbientBackdrop + SizedBox.expand   ← 只画环境底色，不画 loading
      ready == true  → AmbientBackdrop + 一次性 reveal（Transform.translate 4dp，内容始终不透明）
        ↓
router（appRouterProvider）→ StatefulShellRoute → Weekly（默认分支）
```

### `launchReadinessProvider` 的判定链（`launch_readiness.dart:10-32`）

| 阶段 | 依赖 | 未 settle 时 |
| --- | --- | --- |
| 主题 | `themePreferenceProvider` | 未就绪 |
| 学校列表 / 当前校 id | `schoolsProvider`、`activeSchoolIdProvider` | 未就绪 |
| 无学校 | —— | 直接返回就绪（进引导页） |
| 学期列表 / 已选学期 / 作息 | `semestersForSchoolProvider`、`settingValueProvider(activeSemesterKey)`、`sectionTimesProvider` | 未就绪；**且在拿到已选学期前不查 fallback 学期**（`:24-25`） |
| 课程 / 校历 | `coursesForProvider`、`calendarExceptionsProvider` | 未就绪 |

设计要点：**错误也会 settle**（`AsyncValue.isLoading` 为假即算就绪），因此 DB 故障不会把 App 卡在启动画面。

---

## 4. 原生底色一致性（`CONFIRMED`）

| 资源 | 值 | 对应 |
| --- | --- | --- |
| `values/launch_colors.xml` → `launch_background` | `#F5F6F9` | `AppPalette.light.background`（`app_palette.dart:34`） |
| `values-night/launch_colors.xml` → `launch_background` | `#111319` | `AppPalette.dark.background`（`app_palette.dart:49`） |
| `values-v31`、`values-night-v31` | 同色 + `windowSplashScreenBackground` | Android 12+ 系统 splash |

**逐字节一致**，因此不存在「原生 splash → Flutter 首帧」的底色跳变。二者都会随系统暗色设置变化，所以当系统主题与 App 内固定主题相反时，仍会有一次预期的颜色切换（TASK-022B 已记录该边界）。

---

## 5. 唯一定义点

| 策略 | 唯一位置 |
| --- | --- |
| 首帧门控 | `main.dart` → `deferFirstFrame()` / `allowFirstFrame()` |
| 启动就绪判定 | `launch_readiness.dart` → `launchReadinessProvider`（**不得在别处再写一套「是否准备好」**） |
| 揭示动画与「只播一次」 | `launch_reveal.dart` → `_revealed` |
| 启动底色 | `launch_colors.xml`（+ `launch_background.xml`） |
| 主题动画时长切换 | `app.dart` → `_themeSettled` |
| 系统 UI 样式 | `app.dart:50-63` 的 `AnnotatedRegion<SystemUiOverlayStyle>` |

## 6. 改动时必须同步的位置

- 改 `AppPalette.background` → **必须同时改 `values/launch_colors.xml` 与 `values-night/launch_colors.xml`**（否则启动底色跳变）+ 本文件 §4 表
- 加新的启动期 Provider 依赖 → `launchReadinessProvider` + 本文件 §3 表
- 改 reveal 的时长/位移/透明度 → `launch_reveal.dart` + `framework_motion.md` §3
- 改 `themeAnimationDuration` 逻辑 → 本文件 §3 + `framework_theme.md` §6
- 引入 loading 态 UI → 注意首帧前**不应**出现 loading（当前设计是「等就绪再画」）

---

## 7. 已知问题与技术债

- **首帧被一次数据库读取门控**：`deferFirstFrame` 要等 `themePreferenceProvider`（读 `settings.theme_key`）完成。这是为消除主题闪烁的有意取舍，但把首帧推后了一次 DB 往返。`CONFIRMED` 模拟器 profile 实测 `Displayed … +1s894ms`。
- **`setEnabledSystemUIMode(edgeToEdge)` 未 await**（`main.dart:19`）：可能在本帧之后才生效；原生主题用同色 `windowBackground` 覆盖，视觉影响有限，但严格说「首帧后才设置 system UI」这一条成立。
- 2026-10-02已移除启动全屏Opacity；保留平移，无新的全屏透明合成。Android12+启动图引用独立splash_mark矢量，不复用launcher低分辨率PNG。真机冷启动改善尚未量化。
- **`_themeSettled` 造成一次额外 `setState`**（`app.dart:32-37`），仅为切换主题动画时长；不改变布局。
- `CONFIRMED` 运行时观察（**仅模拟器 + profile**）：启动日志出现 `I/Choreographer: Skipped 31 frames!`。
- 启动期唯一的写库逻辑 `presetVariantRepairProvider` 失败无 UI 提示、无重试入口（`INFERRED`，见 `framework_data.md` §8）。

---

## 8. 未验证边界

- **真机冷启动耗时与首帧掉帧**：`UNVERIFIED`。`+1s894ms` 与 `Skipped 31 frames` 都来自模拟器 + profile 模式，**不得当作真机结论**。
- iOS 启动画面（LaunchScreen storyboard）与 `AppPalette.background` 的一致性：`UNVERIFIED`（本次未检查 `ios/Runner/Base.lproj/LaunchScreen.storyboard`）。
- Android 各厂商 ROM 上 splash 的实际表现：`UNVERIFIED`。
- sqlite3 原生 hook 首次下载对启动的影响：`UNVERIFIED`。

---

## 9. 更新记录

| 日期 | 变更 | 依据 |
| --- | --- | --- |
| 2026-09-28 | 首次建立：启动时序、就绪判定链、底色一致性、reveal 代价 | TASK-MOTION-AUDIT-01 + 只读调研 |
