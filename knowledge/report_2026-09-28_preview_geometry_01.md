# 2026-09-28 Weekly Preview 几何修正实施报告（TASK-PREVIEW-GEOMETRY-01）

日期：2026-09-28  
项目：汇课（huike_timetable）

## 1. 根因

- Weekly Course Block 通过对应 `RenderBox.localToGlobal` 采集点击课程块的 sourceRect。该屏幕全局坐标包含当前纵向滚动后的位置。
- 旧实现用 `MediaQuery.size.height * 0.5` 估算 Preview 高度。Preview 的实际大小受 Host 约束、内容布局、`maxHeightFactor` 和底部 inset 影响，因此估算值不等于最终布局。
- 旧动画对整棵 Preview 子树分别缩放 X/Y 轴，导致内容随容器非等比拉伸或压缩。

## 2. 几何模型

```text
sourceRect      = 点击时 Course Block 的 RenderBox 矩形
destinationRect = Preview 完成正常布局后的实际 RenderBox 矩形
coordinate space = GlassSheetHost Stack-local 逻辑像素坐标
```

sourceRect 起初为屏幕全局坐标；Host 将其转换到自身 Stack-local 坐标。destinationRect 在 Preview 按静止状态布局后测量，并转换到同一坐标系。动画在统一坐标系中插值。

## 3. 修复内容

- Preview 首帧按正常底部约束布局，内容保持透明。布局完成后读取 Host 与 Preview 的 RenderBox；成功测量后才开始过渡，避免先显示错误位置再跳到实测位置。
- 容器使用 `Rect.lerp(source, destination, progress)` 插值，不再对 Preview 子树做非等比缩放。玻璃表面随容器展开，内部内容在进度后段逐渐显现。
- 拖动期间使用原始 progress 驱动矩形，因此容器跟随手势更新；短拖回弹到实测 destination，完成的动画落在精确端点。
- 关闭时通过 GlobalKey 检查 source RenderBox 是否仍挂载、是否位于滚动视口内，并读取其当前位置。若 source 不可用，或 Host 尺寸、MediaQuery 尺寸/insets、文字缩放等几何条件已改变，则回退到底部位移动画。实现不保留 RenderObject。
- Reduced Motion 下仍完成实测布局，随后直接呈现最终 Preview 矩形。

## 4. 关闭状态机兼容

保留 `TASK-PREVIEW-BACK-01` 的 `open → dismissing → dismissed → parent clear` 状态机。Android Back、X、backdrop、drag 和程序化关闭继续经过现有关闭路径。几何测量与动画完成不负责清理父状态，也没有新增第二套关闭状态。

现有 Preview dismissal 测试继续覆盖 dismiss-once、callback-once、清理一次、短拖回弹、关闭时拖动处理及 Reduced Motion 完成语义。

## 5. 变更文件

| 文件 | 用途 |
| --- | --- |
| `lib/core/glass/glass_sheet.dart` | 透明首帧测量、Host-local 矩形插值、内容渐显、source 检查与 fallback |
| `lib/features/timetable/pages/timetable_page.dart` | 保存被点击 source 的 GlobalKey；关闭时查询当前几何及滚动可见性 |
| `lib/features/timetable/widgets/timetable_grid.dart` | 将 source GlobalKey 与矩形传递给 Preview |
| `lib/features/timetable/widgets/timetable_course_block.dart` | 暴露当前课程块 source RenderBox |
| `test/preview_geometry_test.dart` | 新增 10 项几何、滚动、生命周期、拖动、resize 和 Reduced Motion 测试 |
| `knowledge/current_state.md`、`knowledge/tasks.md`、`knowledge/testing.md`、`knowledge/changelog.md` | 记录任务状态和验证结果 |
| `knowledge/framework_motion.md`、`knowledge/framework_index.md`、`knowledge/README.md` | 更新动效约定、审查索引和报告索引 |

工作区已有其他未提交改动，本任务未清理、重置、覆盖、提交或推送它们。

## 6. 测试结果

新增 10 个 `preview_geometry_test.dart` Widget 用例，覆盖：

- 640dp 与 1000dp viewport 下实测 destination
- 动画起点与点击课程块对齐
- 14 节滚动布局中的当前 source 位置
- Reduced Motion 最终矩形
- resize 后的安全 fallback
- 反向关闭及单次回调
- source 失效时的 fallback 几何
- source 移动后的 live 几何
- 拖动插值与短拖回弹

验证结果：几何测试 **10/10 通过**；全量测试从基线 **304/304** 增至 **314/314 并全部通过**。

## 7. 视觉验证

| 场景 | 结果 |
| --- | --- |
| 10 节布局 | Widget 几何覆盖；模拟器实画 `UNVERIFIED` |
| 12 节布局 | 既有布局测试覆盖；专项模拟器实画 `UNVERIFIED` |
| 14 节及以上滚动 | Widget 测试验证当前 source 位置；设备实画 `UNVERIFIED` |
| Light / Dark | 设备实画 `UNVERIFIED` |
| Reduced Motion | Widget 最终布局测试通过；设备实画 `UNVERIFIED` |
| Android 模拟器 / 设备 | `adb devices -l` 未发现连接设备，`UNVERIFIED` |
| iOS | `UNVERIFIED` |

## 8. 验证记录

| 检查 | 结果 |
| --- | --- |
| `flutter analyze --no-pub` | 通过，无问题 |
| `flutter test --no-pub` | 通过，314/314 |
| `flutter build apk --debug --no-pub` | **PENDING（按本批验证计划统一构建）** |
| `git diff --check` | 通过，退出码 0；Git 输出行尾 LF/CRLF 规范化提示 |

## 9. 尚未验证

- Android 真机与 iOS
- Preview 活跃期间旋转及 inset 变化；Widget resize 用例验证了 stale geometry fallback，但设备行为仍 `UNVERIFIED`
- Predictive Back 与几何动画联动
- 极端快速或并发手势
- GPU / 性能 profile 及逐帧视觉检查

## 10. 范围确认

本任务未修改 blur/performance 策略、`PageView`、周预加载/缓存、Today Preview、Today stale snapshot、午夜刷新、DST、JS Adapter、Bridge、NavigationPolicy、Drift schema、签名或 package dependencies。
