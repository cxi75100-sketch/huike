# 2026-10-01 Weekly / Preview 性能取证进度报告（TASK-WEEKLY-PERF-PROFILE-01）

**报告日期：** 2026-10-01
**任务：** TASK-WEEKLY-PERF-PROFILE-01
**状态：** 取证与交付已完成；没有实施性能优化。

## 工作范围

本轮在 Android 模拟器 Flutter profile 模式下，对 Weekly 静置、切周、快速切周、Preview 开启/关闭和拖动进行性能取证，并用临时 blur A/B 判断 Preview 开启时的 Raster 高峰是否与模糊效果相关。测试期间未修改课程数据。

## 已完成

- 使用 Android 16 / API 36、60 Hz 模拟器和 Flutter DevTools Performance 面板采集 UI / Raster 帧时间。
- 完成 Weekly idle、首次及回访切周、6 次快速交替切周、Preview 开启、Back/backdrop 关闭、拖动回弹和拖动关闭的样本。
- 对 Preview 开启重复执行 blur A/B：普通路径 3 次，临时关闭 GlassSurface 与 Sheet blur 后 3 次；实验代码随后恢复，没有保留运行时开关。
- 更新了性能报告及知识库中的当前状态、任务、测试和玻璃/动效证据。

## 主要结果

| 场景 | 结果 |
| --- | --- |
| Preview 开启，blur 启用 | 3 次代表帧 Raster 为 **34.9–37.2 ms**，超过 60 Hz 下约 16.7 ms 的帧预算。 |
| Preview 开启，临时绕过 blur | 3 次代表帧 Raster 为 **5.9–7.2 ms**，所选帧无 jank 标记。结果支持 blur 与当前模拟器 Preview 路径的 Raster 高峰相关，但没有分离具体滤镜层。 |
| Weekly 切周 | 观察到超过帧预算的 UI / Raster 代表帧；慢帧频率未可靠统计，也没有确认 cold mount 比 warm 稳定更慢。 |
| Weekly 静置 | 清空采样后静置约 15 秒，没有出现新帧。 |
| 14+ 节滚动 | 未测：模拟器仅有 10 条节次时间配置，没有合适样本。 |

## 验证与交付

- `flutter analyze --no-pub`：通过，无问题。
- `flutter test --no-pub`：通过，**314/314**。
- `flutter build apk --debug --no-pub`：通过；APK 为 `build/app/outputs/flutter-apk/app-debug.apk`，207,132,994 字节。
- `git diff --check`：通过。
- 本任务没有生产行为更改；既有工作区改动保留，未提交或推送。

## 未覆盖与建议

Android 真机、iOS、release mode、其它刷新率、14+ 节布局、重复 repaint 区域和各 blur 图层的独立成本仍未验证。若继续深入，建议另开 `TASK-PERF-BLUR-01`，在目标真机上分别隔离 Sheet 遮罩与 Weekly 玻璃表面，再决定是否提出优化。

详细帧数据与逐项判断见 [完整性能报告](report_2026-09-28_weekly_perf_profile_01.md)。

## 工作区临时文件说明

工作区还留有一个 DevTools 页面截图：`.playwright-mcp/page-2026-09-28T11-17-35-176Z.png`。已检查为 DevTools 页面、不含 App 课程内容，但画面含本轮已停止的本机 VM Service URI。删除命令被环境策略拦截，文件清理仍待处理；截图不属于本次交付。
