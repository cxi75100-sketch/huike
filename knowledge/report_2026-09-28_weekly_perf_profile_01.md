# 2026-09-28 Weekly / Preview 性能取证报告（TASK-WEEKLY-PERF-PROFILE-01）

## 1. Environment

- 设备：Android Emulator `sdk_gphone64_x86_64`，Android 16 / API 36，1080×2400 px、420 dpi。
- 刷新率：`60.000004 Hz`（本次 AVD 当前模式；按 16.7 ms 作为帧预算）。
- 模式：Flutter **profile**，Impeller / OpenGLES；已连接 Flutter DevTools Performance。
- 工具：Flutter 3.47.2 stable、Dart 3.13.2、DevTools 2.60.0。
- 模拟器，不是真机；本轮没有 Android 真机或 iOS 设备。
- AVD 当前本地数据有 1 个学校/学期、1 门课程和 10 条节次时间配置；没有 12 或 14+ 节的样本。没有为取证改写数据库或加入合成课程。

## 2. Scenarios

| Scenario | Executed | Notes |
| --- | --- | --- |
| Weekly idle | Yes | 启动帧清除后静置约 15 秒；DevTools 未出现持续帧条。 |
| Cold swipe | Yes | 首次从当前周切到下一周一次；记录到 Raster 超预算帧。 |
| Warm swipe | Yes | 返回后再切换；另有一次回访样本出现单帧 UI 峰值。没有足够同路径重复来确认冷/热差异。 |
| Rapid swipe | Yes | 6 次交替左右手势；图表约 59 帧、平均约 56 FPS；未观察到崩溃。每次手势是否都提交无法独立确认。 |
| Preview open | Yes | 普通 blur 路径重复采样 3 次；再用临时 profile-only 开关关闭所有 `GlassSurface`/Sheet blur，重复同样打开 3 次并恢复代码。 |
| Preview close | Partial | Android Back、确定的 backdrop 点按、短拖回弹与长下拖均尝试。X 点击坐标不够精确，不能确认命中关闭按钮。每种路径样本少，不作稳定性统计。 |
| 14+ scroll | No | 当前数据只有 10 条节次时间配置；没有 14+ 节样本，因此普通滚动、fling、滚动后开关 Preview 均未在该布局下测量。 |

## 3. Frame Evidence

60 Hz 下以 16.7 ms 为参考预算。下表是 DevTools 中选中的代表帧，不是完整分布；没有准确取得各路径慢帧总数，因此不报告慢帧频率。图表平均 FPS 仅对应短采样窗口，不代表持续吞吐。

| Scenario | UI | Raster | Evidence |
| --- | ---: | ---: | --- |
| Weekly cold swipe | 12.8 ms | 22.9 ms | 选中 Flutter frame 377；首个切周样本。短图表约 30 帧、平均约 56 FPS。 |
| Weekly warm return | 4.4 ms | 17.1 ms | 选中 frame 453；短图表约 28 帧、平均约 56 FPS。 |
| Weekly warm revisit | 40.8 ms | 25.6 ms | 选中 frame 526；一次 UI build 峰值，同时 Raster 超预算。不能据此推断稳定的 warm-path 退化。 |
| Rapid alternating swipe | 4.7 ms | 27.4 ms | 选中 frame 1060；图表约 59 帧、平均约 56 FPS。只记录选中帧，不推算慢帧比例。 |
| Preview open，blur enabled | 1.5 / 2.3 / 2.0 ms | 35.3 / 34.9 / 37.2 ms | 三次独立短采样，均为 Raster 明显高于 UI；普通路径中反复出现 Raster 超 16.7 ms。另一次 Dark 样本 Raster 37.2 ms。 |
| Preview open，临时关闭 blur | 1.0 / 0.9 / 1.2 ms | 5.9 / 7.2 / 6.1 ms | 三次重复；所选峰值帧均无 jank 标记。UI phases 均较小，Raster 不超预算。 |
| Preview close：Back | 1.0 ms | 25.6 ms | 一次样本，短图表约 17 帧、平均约 52 FPS。 |
| Preview close：backdrop | 0.8 ms | 20.7 ms | 一次样本，短图表约 21 帧、平均约 52 FPS。 |
| Preview close：X attempt | 2.0 ms | 19.0 ms | 关闭后可重新打开，但点位可能落在面板外；不能确认这是 X 按钮路径。 |
| Preview short drag / rebound | 1.5 ms | 24.4 ms | 一次尝试，选中 frame 804；图表约 38 帧、平均约 44 FPS。 |
| Preview long drag / dismiss | 1.9 ms | 29.8 ms | 一次尝试，选中 frame 857；图表约 39 帧、平均约 48 FPS。 |

Idle 清空图表后静置约 15 秒，没有新帧，因此没有可报告的 UI/Raster 数值。各 close/drag 样本数量不足，且手势起点与命中路径有不确定性，不比较其快慢排名。

## 4. Findings

### Weekly swipe

**Finding:** 切周期间观察到超过 16.7 ms 的 UI/Raster 帧。  
**Status:** `CONFIRMED`（存在超预算帧）；持续掉帧频率 `UNVERIFIED`。  
**Evidence:** cold、warm return、warm revisit 选中帧的 Raster 分别为 22.9、17.1、25.6 ms；warm revisit 的 UI 为 40.8 ms。快速交替手势另选中一个 27.4 ms Raster 帧。  
**Interpretation:** 慢帧不只出现在 cold 样本；单次 40.8 ms UI 帧是孤立观察，不能归因为邻周首次挂载。短窗口平均约 54–56 FPS 不能替代慢帧频率或整段帧时间分布。

### Preview open / close

**Finding:** blur enabled 时 Preview open 的选中帧重复表现为 Raster-heavy；若干关闭/拖动样本也有 Raster 超预算帧。  
**Status:** open `CONFIRMED`；具体 close 路径的慢帧表现 `SUSPECTED`。  
**Evidence:** 三次 open 为 UI 1.5–2.3 ms、Raster 34.9–37.2 ms；Back/backdrop/drag 代表帧 Raster 为 20.7–29.8 ms。  
**Interpretation:** Preview open 的滤镜 A/B 见下节。关闭路径没有足够同路径重复，X 命中目标也未确认；不能据这些样本认定所有关闭入口稳定超预算或彼此相同。

### Blur / BackdropFilter

**Finding:** 当前模拟器 profile 下，Preview open 的 Raster 峰值与 blur 开关有强关联。  
**Status:** `CONFIRMED`（仅限本次 AVD、profile、Preview-open 条件）。  
**Evidence:** 原始路径三次 Raster 为 35.3、34.9、37.2 ms。临时 profile-only A/B 绕过 `GlassSurface` 与 `GlassSheet` 的 blur、保留其余几何与动画，再测三次为 5.9、7.2、6.1 ms；三帧均无 jank 标记，UI 仍在 0.9–1.2 ms。实验开关已经移除。  
**Interpretation:** 结果支持 blur/filter 工作是这个模拟器 Preview-open Raster 峰值的主要相关成本。A/B 一次同时绕过多个玻璃表面和 Sheet 遮罩，尚未区分究竟是哪一层或哪一种重叠贡献最大；不外推到真机或所有页面。静止页面没有观察到持续帧产生。

### Neighbor-week cold mount

**Finding:** 没有可重复的 cold 比 warm 更慢证据。  
**Status:** `NOT OBSERVED`。  
**Evidence:** 仅一次 cold 转换 UI 12.8/Raster 22.9 ms；warm return UI 4.4/Raster 17.1 ms；之后一次 warm revisit 出现 UI 40.8/Raster 25.6 ms。  
**Interpretation:** 数据不足以建立稳定冷/热差异，也不支持预挂载结论。

### 14+ section scroll

**Finding:** 本轮无法评价 14+ 节滚动及滚动状态下的 Preview source geometry。  
**Status:** `UNVERIFIED`。  
**Evidence:** 可用 AVD 数据只有 10 条节次时间配置，没有安全样本可用于更高节数布局。  
**Interpretation:** 不根据静态实现推断 14+ 节滚动性能。

### Repaint behavior

**Finding:** 未收集 repaint/highlight 区域、重复绘制范围或 widget rebuild 计数证据。  
**Status:** `UNVERIFIED`。  
**Evidence:** 没有启用额外 rebuild 追踪；本轮仅读取 frame chart 与 UI/Raster timing。  
**Interpretation:** 不建议按 `RepaintBoundary` 数量或缺失位置做改动。

## 5. PERF-HYPOTHESIS 判定

| Hypothesis | Result | Evidence |
| --- | --- | --- |
| BackdropFilter 是 Preview-open 主要 Raster 成本 | `CONFIRMED`（当前模拟器与路径） | 同条件重复 A/B：启用时 34.9–37.2 ms；绕过 blur 后 5.9–7.2 ms。具体贡献图层未隔离。 |
| 邻周首次挂载造成明显慢帧 | `NOT OBSERVED` | cold 没有比 warm 稳定更慢；warm revisit 有单次 UI 峰值。 |
| RepaintBoundary 缺失造成主要成本 | `UNVERIFIED` | 没有 repaint 范围或隔离对照数据。 |
| Preview geometry transition 本身 Raster 过重 | `NOT OBSERVED`（在本次无 blur A/B 的 Preview-open 帧中） | geometry/动画保留时代表 Raster 峰值 5.9–7.2 ms；并未单独分解其它工作。 |
| 14+ scroll 存在持续 jank | `UNVERIFIED` | 无 14+ 节可用样本。 |
| Weekly 主页面静止时持续产生 Raster frame | `NOT OBSERVED` | 清空图表静置约 15 秒未产生新帧。 |

## 6. Recommended Next Engineering Task

建议后续独立任务：**`TASK-PERF-BLUR-01`**。仅针对已测得的 Preview-open Raster 差异，在目标真机/profile 条件下分别隔离 Sheet 全屏遮罩与 Weekly 玻璃表面，重复对照并记录全帧分布，再据结果决定是否提出具体优化。当前任务没有保留任何优化策略改动。

## 7. Files Changed

- 新增本报告；更新 `knowledge/current_state.md`、`tasks.md`、`testing.md`、`changelog.md`、`README.md` 与玻璃/动效专题文档中的性能证据和未验证边界。
- **No production behavior changes.** 临时 profile-only blur A/B 代码已恢复；没有留下 `WEEKLY_PERF_DISABLE_GLASS_BLUR` 开关。
- 既有 working tree 改动均保留；未提交、未推送。
- 清理边界：一个由早期 DevTools 页面操作生成的截图仍留在 `.playwright-mcp/page-2026-09-28T11-17-35-176Z.png`。检查确认它只有 DevTools 页面，没有 App 课程内容；页面内含本轮已停止的本机 VM Service URI。删除命令被环境策略拦截，因此未绕过策略；该临时文件不属于交付，需手动删除。

## 8. Validation

| Check | Result |
| --- | --- |
| `flutter analyze --no-pub` | Passed — No issues found |
| `flutter test --no-pub` | Passed — 314/314 |
| `flutter build apk --debug --no-pub` | Passed — `build/app/outputs/flutter-apk/app-debug.apk`, 207,132,994 bytes; SHA-256 `26A9A567F23B84C12EA1F13B589406D42265BEE6887B6E2CF94A45163EBBA6EE` |
| `git diff --check` | Passed — no whitespace errors |

## 9. Unverified

- Android 真机、其它刷新率、旧设备、iOS、release mode 和长时间 soak。
- 14+ 节的慢速滚动、fling、滚动后打开/关闭 Preview。
- 每个 close/drag 路径的多次重复；X 按钮精确命中路径。
- 慢帧总数/频率、shader/texture 首次成本、独立 repaint 区域，以及 blur 的具体贡献图层。
- 其他手势极限与高速连续切周的状态提交次数。

## 10. Scope

没有实施 blur 优化、预挂载、缓存、`RepaintBoundary` 调整、`PageView`、Preview geometry 重设计、Today Preview 修改、导航重构或依赖修改。
