# TASK-019B Weekly Glass Surface

## TASK-019 最后视觉收尾（2026-09-26，当前版本）

本轮以用户最新“第一眼玻璃、第二眼课程色”要求覆盖下方019D明显色差策略。
唯一代码文件为 `lib/features/timetable/widgets/timetable_course_block.dart`，仅调整材质参数：

- fill三段tint：light由32/23/30%降为10/8/9%，dark由28/20/24%降为16/12/14%；按压增量1.5/1/1%。
- 中性基底alpha 76/64/70%，左上混8%白光，保留透明整面渐变；未增加逐卡模糊或光学折射机制。
- border保持0.9dp等宽，中性hairlineStrong混45%白色，课程色混入量70%降为6%；最终alpha light72%/dark38%。
- tinted glow由1.5%/2.5%降为0.8%/1.5%，按压增加0.5%；保留既有中性轻投影。
- 无独立竖条、顶部色条或装饰区。课程名/地点/教师、compact地点、字体测量/空间分配、字号、网格高度、10/12/14节、冲突/切周均未改。

基线及最终analyze无问题、217/217测试通过；生产main.dart Debug APK成功；diff check通过。
独立只读代码复审无发现。API36 emulator-5554 / 1080×2400复用仓库外内存QA入口，
检查七色周Light/Dark，英语/马原/线代保持淡红/淡紫/淡绿，浅色乳白玻璃基底更明显。
截图：`C:/Users/ninan/.codex/visualizations/2026/09/26/01a0dc0f-2fa3-7573-96ca-9b336cbf1614/light.png`
与同目录`dark.png`。真机/iOS为UNVERIFIED；不把模拟器观感等同平台原生光学折射。
所有禁止范围未修改，右下角加号遮挡仅记录；保留已有未提交修改，未commit/push/reset/clean，未开始TASK-020。

## TASK-019D 后续修正：明显整卡色差（2026-09-26，历史版本）

用户指出前轮只是加强轮廓，实际要的是明显课程色差。本轮保留色相、将Weekly材质HSL饱和度
提升到0.70，light/dark亮度分别0.46/0.58，三段渐变全部染色，混色alpha分别23–32%/20–28%。
无白色中段冲淡底色；保留透明渐变、无竖条与3dp间距。前版低强度染色已被此要求替代。
复审发现原辅助文字对比度不足，已将其由palette secondary向ink混合50%；八色/明暗/按压
状态、各gradient stop与background/surfaceAlt合成的小字对比度均≥4.5:1，新增两条测试。
API36约390dp七色周Light/Dark已实画：color-light.png、color-dark.png，匿名内存QA。
最终analyze无问题、217/217、生产Debug APK成功、diff check通过；复审无遗留问题。
仍未commit，真机/iOS未验证；其它页面和数据语义不变。

## TASK-019C 后续修正：分隔辨识度（2026-09-26）

用户反馈019B过于轻淡，邻卡难区分。compact卡间空隙由1dp增加到3dp；完整边框由0.7dp
改为0.9dp，以中性色混课程色加强对比，增加微弱中性投影及玻璃基底不透明度。
仍不使用独立竖条/装饰区、不扩网格行高。下方019B数值属于历史版本。
API36约390dp相邻七门课Light/Dark已实看；截图位于visualization/task019/separation-light.png
和separation-dark.png。QA用内存数据库和仓库外入口，生产APK恢复main.dart。
analyze无问题、215/215、生产Debug APK成功、diff check通过；独立复审相关44/44，无遗留发现。

2026-09-26；未提交工作区。在 TASK-019 信息密度增量上完成用户新的视觉要求。

## 实现

彻底删除左侧 Container 竖条、装饰 Row、色条占位与未使用的 marker 常量/textWidth helper。
内容直接占全卡宽度，左右各1dp padding，较前版增加4dp；名称/compact地点/教师优先级不变。
课程主题色仅融入整面三段透明 gradient、均匀0.7dp translucent border 和极弱 tinted shadow。
按压复用 PressPhysics，略增强 tint、边缘及光晕；不新增 BackdropFilter 或 package。
边框四边一致，没有左侧较粗/更亮的连续色线。10/12/14节、冲突与切周保持原行为。

## 实画

API36 ncpu_api36 / emulator-5554，1080×2400、density443（约390dp），
内存匿名QA数据库，七门课并排且colorKey各不同；实看Light/Dark。
课程名自然折行、地点/教师可读，竖条消失，完整玻璃面轻 tint 可区分，12节一屏。
截图：Codex visualization/task019/weekly-glass-light.png 与 weekly-glass-dark.png。
临时QA入口删除，最终构建恢复生产main.dart；未触碰原持久化课表数据库。
真机/iOS/人工读屏验收仍UNVERIFIED。

## 验证

原明暗字段测试新增：内部不存在Row/Container、48dp课块的文字区域为46dp。
新增2例：明暗课程色gradient/border不同、四边等宽且≤1dp、真实按下后gradient变化。
既有360/390/430dp及1.3倍字体矩阵仍通过；独立复审相关3份测试44/44，无遗留发现。
最终 `flutter analyze --no-pub` 无问题，`flutter test --no-pub` **215/215通过**，
`flutter build apk --debug --no-pub` 生产main.dart构建成功；`git diff --check`通过。

## 范围

仅Weekly外观及其模型死常量、测试、知识库。未改Today/Preview/Import/Navigation/数据库。
未commit/push/reset/clean；保留已有未提交修改。
