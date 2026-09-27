# TASK-016 全 App Liquid Glass 重构报告

日期：2026-09-23  
状态：实现与本机验证完成，保留未提交工作区；按用户要求没有创建 commit。

## 交付摘要

为汇课建立共享玻璃视觉基础，并将其应用到周课表、课程预览、Today、设置、学期/作息、课程详情/编辑、引导、学校管理和导入入口。主题支持浅色与深色，系统字体与系统栏 edge-to-edge；GlassMotion / GlassMetrics 统一常用动画和材质尺寸，Reduced Motion 跳过动画过程。教务脚本、桥协议、NavigationPolicy 与 Drift schema 均未改动，没有新增 package 或数据库表。

## 页面与交互

- 周课表采用周一至周日固定七列。10/12 节按剩余视口均分且禁止纵向滚动；超过 12 节只让网格滚动，星期栏保持固定。课程块按空间优先显示名称，信息不足时省略地点或教师；详细信息仍可在预览、Today 和详情页查看。课程块不创建逐卡 `BackdropFilter`。
- 冲突维持完整宽度主课程与 `+N` 入口；冲突数和列表仅包含与当前课程实际区间重叠的课程。链式相交时不会把间接相连但不重叠的课程列入。
- `/today` 是独立时间轴页面，显示课程节次、时间、地点、教师、周次与备注。课程按压预览弹层；弹层从来源课程块几何连续展开，并与背景模糊/缩放/压暗共用进度。此处实现为同页共享元素式过渡，尚未使用跨路由 Flutter `Hero`。
- 右下角加号展开添加课程、导入课表、添加事件。单周事件复用 Course 模型和课程编辑页，默认当前周与星期，不新增表。
- 课程详情改为玻璃主视觉，错误、加载、已删除状态分开处理；空周次安全展示。节次数统一来自 `SectionCountResolver`。
- 冲突计算每次 build 每天只执行一次；切周提交以当前画面偏移及松手速度为准，动画销毁时解除 `stepRequest`；周标题长按补轻触觉反馈。

## D1–D8 复审问题

| 项 | 处理 |
| --- | --- |
| D1 切周累计拖拽与屏幕位置脱节 | 使用渲染偏移作为距离判据，并增加超拖后反向拉回测试。 |
| D2 冲突簇把非重叠课程算入 `+N` | 增加课程级直接重叠查询，数字和弹层列表共用该结果。 |
| D3 节次数多处定义 | 新增共享 `SectionCountResolver`，网格、编辑、详情统一使用。 |
| D4 长按未触觉 | 周标题长按处理增加轻触觉。 |
| D5 dispose 后仍可调用 step 闭包 | 状态变化及 dispose 时解除 `stepRequest`。 |
| D6 每帧重复算冲突 | 同一 build 预计算并让测量与绘制共用布局结果。 |
| D7 空 weeks 访问 `first` 崩溃 | 空周次显示“未设置周次”。 |
| D8 首帧 loading 显示不存在 | 加入独立 Loading / Error / Data / Not Found 处理。 |

## C1–C13 文档漂移收敛

更新 `architecture.md`、`design.md`、`testing.md`、`current_state.md`、`tasks.md`、`changelog.md`、`issues.md` 与知识库索引：

- C1/C2：修正冲突呈现与实际文件清单；旧 lane 并排说明改为主课程 + `+N`。
- C3/C6：移除无消费者的 `CourseListingRow` 和 `RouteBackground`。
- C4/C5：动画参数与节次/时间文案改用实际接线的共享来源；业务重试延迟仍属于导入时序，不作为动效令牌。
- C7/C8：更新冲突覆盖说明及测试数，当前测试基线写为 189。
- C9/C12：重写旧进度条尺寸与位移注释，删除失真的数值描述。
- C10/C11：文档将 PressPhysics 的适用范围限定在玻璃交互；明确 Reduced Motion 跳过动画过程但保留最终视觉状态。
- C13：修正已经不存在的测试名称和旧空状态文案引用。

## 验证结果

- `flutter analyze --no-pub`：通过，`No issues found!`。
- `flutter test --no-pub`：通过，`189/189`。
- `flutter build apk --debug --no-pub`：成功。
- Android API 36 `ncpu_api36`：用本轮重构 APK 在隔离 QA 用户实画检查匿名测试学校的空周首页；七天列同屏，玻璃导航、星期栏、课程网格与添加按钮正常显示。截图存于 Codex visualization 输出目录。临时 QA Android 用户已移除，主用户的应用数据没有清理。最终两处动效令牌接线后重新运行了完整 analyze/test/build。
- 最终 APK：`build/app/outputs/flutter-apk/app-debug.apk`，174,748,085 字节，SHA-256 `3651ABB919A29D1299AA7928B49A1944895B08C2E2A7443DB46B2F49259BB3DF`。
- `git diff --check`：通过；Git 仅报告 CRLF/LF 转换提示。

## 未验证范围与交付边界

- iOS 构建、真实手机 GPU 帧率、TalkBack/VoiceOver 完整人工遍历、真实教务登录与导入仍为 `UNVERIFIED`。
- Today、课程预览与设置页的交互由 widget tests 覆盖；本轮 API 36 实画仅核了空周首页，没有宣称这些页面均完成实体设备视觉验收。
- 仍有少量 Material 表单控件与确认对话框沿用主题化实现，不属于 GlassSurface 自定义触摸物理。跨路由 Hero 尚未接入。
- 当前工作树含本任务和此前已有的多批未提交改动；本轮没有 reset、clean、覆盖他人文件或创建 commit。
