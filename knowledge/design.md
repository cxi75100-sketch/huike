# Design：Liquid Glass（TASK-019 工作区）

## TASK-020B Root Switcher（2026-09-27）

中性Glass岛272×64dp，底部viewPadding+16dp；单52dp高capsule连续移动130dp，材质/尺寸/圆角固定。
复用GlassMotion.slow=280ms/enter=easeOutCubic与GlassMetrics.pageTravel=12dp；页面fade同步，无stagger/root横滑。
Reduced复用disableAnimations直接显示目标；活动项再次点击无导航/haptic。FAB仅lift80dp，Today外层保留滚动底部余量。
不改TodayTimeline、Course Block、Preview或Weekly滑周；详情与动态QA见root_switcher报告。

## TASK-026 Launcher Icon（2026-09-27）

App Icon独立于App内Glass：三块实心白色厚圆角课程单元向中心汇聚，冷蓝#3057D5纯底。
中间长20%，上下内倾9°，半径厚度50%，最窄间隙约厚度48%；不使用文字或复杂材质。
Android adaptive现有16% inset与monochrome保持，iOS同符号全幅不透明源图。
此为当前图标，旧朱砂印章候选仅历史资料。48/64px、mask与设备边界见app_icon报告。

## TASK-022B 启动Motion（2026-09-27）

稳定Ambient首帧→初始root一次180ms easeOutCubic、4dp→0、opacity0.92→1，
沿用GlassMotion.standard/enter；内容首帧即能点击，Reduced直接显示。
不做logo/stagger/bounce，不因普通导航/前台恢复重播；初始真实数据未解析时不画错误空状态。
Android背景仅对齐基础色，系统/App固定主题相反时的明暗切换仍存在，见launch_motion报告。

## TASK-022A 普通Motion（2026-09-27）

普通非iOS页面12dp/280ms进180ms退；Dialog8dp/180ms；enter easeOutCubic、exit easeInCubic。
iOS原生交互返回保留、共用时长；Reduced90ms纯opacity。菜单220/180ms连续尺寸变化，
关闭完成隐藏，取消图标旋转；普通Detail无重复stagger。Sheet保持既有合同仅补曲线。
没有新的Motion System/blur层；Preview、Weekly、启动合同保留。审计例外与验收见motion_audit报告。

## TASK-021 Today语义时间轴（2026-09-27）

左侧连续时间轨道保留开始/结束时间、节点与当前时间。课程按实际开始时间排序，未知时间在末尾
依节次稳定排序。卡片最小134dp、依内容自然增高；名称/地点/教师/备注最多两行，周次一行，
完整内容保留语义标签和原预览入口。典型卡1.0字体约134–180dp、1.3字体测试不超过200dp；
duration不影响高度，丰富长文本样例在360dp/1.3下≤290dp，不因长课程增加空白。
课间≤10分钟16dp、≤60分钟24dp、更大空档40dp并显示间隔；当前时间带最多40dp。
上课中标记关联一个当前课程节点，课间位于下一课前，课前/课后分别置首尾；不模拟分钟比例。
22sp日期标题保留，典型四课首屏完整前两课且第三课至少50dp可见；不改变全局Navigation/Motion。

## TASK-020B Weekly / Today职责分离（2026-09-27）

Weekly顶部为学校/页面行（含「今日」文字入口）、周切换器，随后直接接星期/日期栏与七列网格。
不渲染今日课程数量、下一节或Today summary。删除横条及其间距，不留空占位。
「今日」复用现有GlassButton、44dp目标与`/today`路由；Today Timeline本轮未改。

## TASK-020A Weekly 手势约束（2026-09-27）

一次独立拖动最多切一周；新手势须在上次落位/回弹结束后开始。保留1:1跟手及三页布局，
松手时速度≥380px/s优先取速度方向，否则按最终可见位移≥页宽15%判定；不够则回弹。
取消不提交；超长拖动仍限制为相邻周。箭头沿用每次±1路径，标题周次与网格日期同次提交。

## TASK-019 最后视觉收尾（2026-09-26，当前）

本轮以玻璃优先覆盖019D明显色差策略。保留课程色相与文字策略，整面tint的混色alpha
light为0.10/0.08/0.09，dark为0.16/0.12/0.14；按压仅增加0.015/0.010/0.010。
基底alpha为0.76/0.64/0.70，左上基底混入8%白光；这些是合成参数，不等同于主观视觉强度。
0.9dp等宽中性边框以hairlineStrong混45%白色，仅混6%课程色；极弱glow为0.008/0.015。
不加独立色条，不改文字、固定网格、算法或全局Glass系统。下方019D及更早策略均为历史记录。

## TASK-019D 明显课程色差（2026-09-26，历史）

用户明确要一眼可分的课程颜色，前版的极弱tint不再是目标。Weekly沿用课程色相，
将材质HSL饱和度设为0.70，整块三段透明渐变都带颜色（light混色23–32%，dark20–28%）；
无白色中间段把课程色冲淡。保留3dp间隔、完整边缘、按压增强及无竖条结构。
小字使用palette secondary向ink混合50%的颜色，以保证染色背景下的对比度；字号不变。
下方TASK-019B/C的材质强度属于已被用户否定的历史迭代。

## TASK-019C 轮廓辨识度（2026-09-26）

用户反馈TASK-019B边界太弱、邻卡难区分。compact课块恢复左右各1.5dp空隙（卡间3dp），
以均匀0.9dp中性色混课程色边框和极轻中性投影分离轮廓；提高玻璃基底不透明度与轻 tint，
不恢复竖条、不设独立装饰区。字体和固定网格保持；以下TASK-019B数值为前一版本。

## TASK-019B 完整玻璃课程块（2026-09-26）

Weekly 独立色条明确废弃：不使用进度/选中样式装饰，不预留 accent 横向区域。
完整玻璃面以左上到右下三段透明渐变表现环境 tint，以均匀0.7dp边框及微弱 tinted shadow
保持课程颜色辨识；按压仅轻微增强 tint/边缘。文字直接占用全宽（左右各1dp），
较前一版增加4dp可用宽度。无逐卡 BackdropFilter，原字段层级和固定网格保持。

## TASK-019 Weekly 信息密度（2026-09-26）

普通两节块按「名称 → 地点 → 教师」顶部排列，名称沿用 11.5sp 粗体，辅助字段 10sp。
主题文字样式和 TextScaler 合并后测量，先为所有现有字段留一行，优先补全地点及教师换行，
余量用于名称（最多四行）。只在物理空间不足时依次降级教师、地点，名称长文本可淡出；
固定网格高度不受文本影响。compact 节次栏从 34dp 收到 28dp，课程间隙收紧；色条已由TASK-019B移除。
Weekly-only formatter 移除前导校区；实训中心前的东西南北区也移除，保留建筑和房间。
不修改原始地点；Today/Preview/Detail 继续显示原始信息。课程块仍为轻量玻璃渐变与 tint，
不逐卡 BackdropFilter、不显示时钟时间。下方 TASK-017 辅助字段策略由本段更新。

更新：2026-09-27。本文所描述的 TASK-013～TASK-026 工作区已于 2026-09-27 归档提交
（`f9eccc9`）、推送 Gitee 并随 v0.1.4 发布；TASK-019 已完成有课周模拟器明暗实画。
真机、iOS 与辅助技术仍需单独验收。

## 方向

- Android/iOS 统一采用 Apple 式动态玻璃。浅色是透明白与柔和环境光；深色是 graphite 与低亮度染色。系统字体，不捆绑 Apple 字体。
- `AppPalette` 提供明暗语义色（系统蓝强调色、文字、边缘、错误色）；`AppTheme` 统一 Material 宿主控件样式并关闭 ripple。课程识别色仍来自 `course_colors.dart`，Weekly 只用于玻璃面 tint、均匀细边缘及微弱光晕，不使用独立身份线。
- `AmbientBackdrop` 给玻璃透射提供低对比环境光。`GlassSurface` 使用模糊、半透明材质、方向光、触摸高光、边缘与投影；课程块只用廉价渐变和描边，没有逐卡 `BackdropFilter`。
- `GlassMotion` 集中动画令牌及弹簧；`GlassMetrics` 集中常用尺寸/模糊参数。`PressPhysics` 控制玻璃指针物理，Reduced Motion 直接落到终态。表单与选项也使用共享玻璃控件；系统日期/时间选择器保留平台控件行为，不宣称已迁入 `PressPhysics`。

## 周课表

- 顶部学校行包含独立「今日」入口，周导航后直接接网格星期栏；不展示Today摘要。今日按钮跳转既有 `/today` 路由。
- 七日固定七列，周一至周日自然顺序。手机 10/12 节由剩余视口高度均分 section；超过 12 节网格可滚动，星期栏仍固定。轴按两节一组显示。
- 课程块显示名称、compact 地点与教师；实际空间不足时降级，首页不重复起止时间。宽度、高度和字体比例决定换行预算；原始完整信息在预览、Today 与详情里可查。课程块保留完整语义标签。
- 课程冲突保持一门全宽课程和 `+N`。`+N` 与列表只统计直接重叠课程，链式冲突的非重叠成员不计入。`course_collision_layout.dart` 的簇/lane 仍服务稳定布局；UI 不分列宽。
- 水平切周的判据来自当前可见位置和松手速度。三页同场移动；成功切周时触觉反馈，取消时不震动。
- 点击课程时，`GlassSheetHost` 使用课程源矩形作为预览 Sheet 的起始几何，和背景缩放、模糊、压暗共用一个进度，形成连续的放大过渡。预览进入详情时，预览与详情共用 Flutter `Hero`，共享 `CourseHeroTag` 和 `CourseHeroSurface`；课程、学校、学期及来源上下文共同确定标签。详情返回时沿同一 Hero 回到预览。

## 今日与操作

- `/today` 独立展示日期、紧凑语义时间轴、内容高度课程节点和当前时间状态。页面可纵向滚动，课程高度不按时长/节次放大。课程卡展示名称、时间、节次、地点、教师、周次和备注；缺失的数据不补造字段。点课程进入透明 PageRoute 承载的玻璃预览面板，Today 课程卡 → 预览 → 详情均参与 Hero；详情返回预览后可关闭回时间轴。
- 右下角 `+` 展开紧凑玻璃菜单：添加课程、导入课表、添加事件。事件进入复用的 `CourseEditPage(isEvent: true)`，默认当前星期与当前周，仍保存为现有手动 Course；不新增表或迁移。
- 设置页改为环境背景、分组玻璃、无 ripple 的行与外观选择。输入、单选、勾选、选项、选择器和确认框使用共享玻璃构件；确认删除、重置等危险操作有明确文案和危险色。系统日期/时间选择器保留平台交互。其余页面通过共享主题获得统一颜色、圆角和浮动 Snackbar 基线。

## 可访问性与边界

- 玻璃按钮语义与触控目标以 `GlassButton` 和 `GlassSurface` 为基础；课程块读屏保留课程名、星期、节次、时间、地点和教师。
- 10/12 节的一屏约束优先于周概览中的辅助字段。1.3 倍字体、玻璃文本输入、选项语义、确认框与 Reduced Motion Hero 均有 widget test；360/390/430dp 有布局覆盖。TalkBack/VoiceOver、iOS 和真机 GPU 性能标 `UNVERIFIED`。
- WebView 内网页和社区脚本不属于视觉重构范围。教务桥、导航策略、数据 schema 不变。

## 控件尺寸与键盘（TASK-018A 补充）

- `GlassButton` 的尺寸契约是「内容定高、横向占满可用宽度，且不小于 `tapTarget`」。
  实现上 `Center` 必须带 `heightFactor: 1`：`Scaffold.bottomNavigationBar` /
  `floatingActionButton` 这类槽位用松约束布局，未收缩的 `Center` 会纵向撑满整屏，
  把页面 body 挤成 0 高。改动该封装前先读 ISSUE-017。
- 用 `bottomNavigationBar` 放页面 CTA 时，`Scaffold` 只让 body 避开键盘、底部栏本身
  不移动；需要 CTA 停在键盘上方就自己加 `MediaQuery.viewInsetsOf(context).bottom`。
- 三种非正常状态必须可分辨：加载中给加载态，读取失败给可理解文案 + 重试，
  确实没有配置给空态；不允许三者都渲染成空白页。

## 历史设计说明

TASK-011/013/014/015 的朱砂历书、七日纵向议程、Today Sheet 和“周块内所有字段完整显示”是历史方案，已由用户本次 Master Prompt 覆盖。相应历史变更日志保留为时间记录，不代表当前实现。
