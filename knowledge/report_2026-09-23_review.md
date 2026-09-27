# 2026-09-23 昨日改动复审报告（TASK-014 + TASK-015）

> 复审日期：2026-09-23  
> 复审对象：工作区中尚未提交的全部改动，重点是 2026-09-22 22:46 ~ 2026-09-23 00:47 的两批工作  
> 复审方式：逐文件读代码 + 独立复跑 `flutter analyze` / `flutter test` + 文档断言逐条对码  
> 复审范围边界：**未修改任何被审代码**；模拟器与 logcat 类证据无法在本机复现，只能核对其自洽性与代码是否支持

---

## 0. 结论

两批改动的**代码主体质量是好的**：`flutter analyze` 无问题、`flutter test` **177/177** 全通过（我独立复跑确认），
玻璃层的分层与「测量即绘制」的高度预算经得起验算，安全边界（无密码/学号/Cookie 落盘与打印）没有破口。
TASK-014 新增的冲突布局纯函数本身算法正确，TASK-015 对行高爆炸（ISSUE-016）的根因分析写得清楚且成立。

**问题集中在两类，都不在「功能能不能跑」，而在「说法与事实是否一致」：**

1. **有 3 个真缺陷需要改**（其中 2 个用户可见）：
   切周提交判据与画面脱钩（`week_swipe.dart`）；冲突 `+N` 计数用整簇聚合导致链式冲突**多算并列出不重叠的课**；
   详情页硬编码「一天十站」与编辑页/网格形成三份节次数定义。
2. **文档漂移是系统性的**：`architecture.md` 仍在教一个已被推翻的并排冲突方案、还列着两个**从未存在过**的
   文件；`GlassMotion` 自称「全 App 唯一来源」而同一批新代码里有 4 处自写的 `Duration`；
   「节次文案唯一来源」`sectionRangeLabel` 的唯一调用者是一个**零消费者的死文件**。
   这正是 `AGENTS.md` 明令禁止的「文档说 A、代码说 B」。

**另外一件必须先说的流程问题**：`HEAD` 仍停在 **2026-09-14 的 `79c9267`**。
09-15（TASK-013）、09-22（TASK-014）、09-23（TASK-015）**三批工作全部未提交**，
而 `pubspec.yaml` 已经升到 `0.1.4+5`、`build/` 里已有对应的 release APK。
也就是说知识库里写的「已完成 / CONFIRMED」目前**没有任何 Git 锚点**，
这也是本次文档漂移能积累三处而无从察觉的直接原因。

---

## 1. 复审范围与归属

用文件 mtime 把工作区改动切成三批（无重叠、边界清晰）：

| 批次 | 时间 | 对应任务 | 代表文件 |
| --- | --- | --- | --- |
| 批 1 | 2026-09-15 16:42–17:32 | TASK-013 整周议程顺序与 UI 细节重构 | `week_agenda.dart`、`course_listing_row.dart`、`course_time_service.dart`、`semester_service.dart`、两份 plan、`week_agenda_test.dart` |
| 批 2 | 2026-09-22 22:46–23:28 | **TASK-014 Weekly Timetable 首页完整重构**（另一 Agent） | `course_collision_layout.dart`（新）、`course_detail_page.dart`、`course_edit_page.dart`、`app_shell_test.dart`、`calendar_exception_ui_test.dart`、`architecture.md` |
| 批 3 | 2026-09-23 00:06–00:47 | **TASK-015 Dynamic Liquid Glass + 课程内容完整显示** | `lib/core/glass/*`（新）、`lib/core/widgets/ambient_backdrop.dart`、`timetable_grid.dart`、`timetable_course_block.dart`、`week_swipe.dart`、`week_navigation.dart`、`weekday_header.dart`、`course_preview_sheet.dart`、`today_courses_sheet.dart`、`timetable_page.dart`、三份新测试、知识库六份文档、`pubspec.yaml` |

用户此次要求复审的「昨日改动」= 批 2 + 批 3。批 1 不是昨日范围，但它与批 2/3 共处同一工作区，
且本次发现的多处「文档与代码不一致」源头在批 1（`sectionRangeLabel` 的「唯一来源」就是这么写下的），
因此一并核对。

批 2 的多数文件（`timetable_page.dart`、`timetable_grid.dart`、`week_swipe.dart`、`course_preview_sheet.dart` 等）
已被批 3 重写覆盖，mtime 只保留批 3；**批 2 可直接审查的遗存**为上表 7 个文件，这也决定了本报告对批 2 的判定范围。

工作区其余未跟踪文件：`knowledge/plan_2026-09-15_*.md`（批 1 的计划书）、`.zcodeignore`（批 3 的本地忽略配置）。

---

## 2. 我独立复跑的验证

| 验证 | 命令 | 结果 |
| --- | --- | --- |
| 静态分析 | `subst S: "D:\桌面\汇课"` → `cd /s && flutter analyze` | `No issues found! (ran in 62.1s)` |
| 测试套件 | `cd /s && flutter test` | `+177: All tests passed!` |
| 测试条数交叉核对 | `grep -cE "^\s*(test|testWidgets)\(" test/*.dart` | 174 声明 + 3 条循环生成 = 177，**与文档写的 177 一致** |
| 安全边界 | `grep -rn "print(" lib`；在新目录 grep `password/cookie/token/学号/studentId/session` | lib 内**零** `print`/`debugPrint`；新目录零命中 |

结论：`tasks.md` / `changelog.md` / `current_state.md` 中「analyze 无问题、177/177」的断言**成立**。
`158/158`、`149/149` 的历史基线自洽（149+9=158），无法重跑但无矛盾。

**无法复现的部分**（只能核对自洽性，不能当作已验证）：`ncpu_api36` 实画、logcat 0 命中、
`build/huike-0.1.4-release.apk` 的字节数与 sha256 —— 数值本身与文档完全对得上（子审计用 `aapt2`/`apksigner`
核到 versionCode 5 / minSdk 24 / targetSdk 36 / debug 签名），但都属于**自报证据**。

---

## 3. 缺陷清单

### 3.1 真缺陷（代码级，建议修）

**D1 ［中］切周提交判据用的是累计拖拽像素，与画面位置脱钩** — `week_swipe.dart:210`、`:224`

`_handleDragUpdate` 把原始 delta 无上限累加进 `_dragPixels`（`:210`），而视觉位置 `_offset.value`
被 clamp 在 ±1（`:213`）；松手时 `weekSwipeTarget(dragPixels: _dragPixels, ...)`（`:224`）拿的是**未 clamp 的累计值**。

可复现路径：390dp 屏上向右快甩 500px → 画面停在「上一周完全就位」（offset 被 clamp 到 1.0），
手指不松继续往左拖回 300px → 画面显示**本周已回来大半**（offset ≈ 0.23），松手却按
`_dragPixels = +200 ≥ 0.15×390 ≈ 58.5` **提交切到上一周**——用户看到的是「我明明拖回来了，它还是翻页了」。

修法方向：位置判据改用视觉位置（`_offset.value * width`），或让 `_dragPixels` 与 `_offset` 同步 clamp。
速度判据（380px/s）与弹簧落位（`velocity / _viewportWidth` 的单位换算）本身是对的。

**D2 ［中］冲突 `+N` 计数与冲突列表用「整簇聚合」，链式冲突会多算并列出不重叠的课程** — `course_collision_layout.dart:27` + `timetable_grid.dart:333-336` + `timetable_page.dart:218`

服务按**传递闭包**分簇（`:27` 的 `course.startSection <= clusterEnd`），簇只对外暴露聚合量
（`laneCount` / `courses`，`:68-80`）；网格却把聚合量当成「与我冲突的课」用：
`conflictCount: cluster.laneCount > 1 ? cluster.courses.length - 1 : 0`，`onConflictTap(cluster.courses)`。

具体反例（真实课表形态，非极端构造）：周三有 a(3-4)、b(4-5)、c(5-6)。a∩b={4}、b∩c={5} 都是真冲突，
但 **a∩c=∅**。三者被并成一簇，于是 a 的块顶部显示 **`+2`**，点开列出 a、b、c——其中 c 与 a 毫无重叠。
`course_collision_layout_test.dart` 反而把这个「链式相交属于同一冲突簇」的行为钉住了，却没有测试钉住聚合量与
消费端语义的背离。服务没有提供「谁与我重叠」的查询，消费端只能自己发明，而发明出来的就是错的。

修法方向：服务补一个 per-course 的 `overlapping(course)`（或让 placement 直接带 `conflictPeerIds`），
`+N` 与列表都基于它；簇聚合留给需要「整簇边界」的用途。

**D3 ［中］「一天几节」存在三份定义，>10 节时详情页文案自相矛盾** — `course_detail_page.dart:261,274` / `course_edit_page.dart:53-55` / `timetable_grid.dart:209-220`

- 详情页：硬编码 `'一天十站，课程占用第 … 节'`（`:261`）与 `for (var section = 1; section <= 10; …)`（`:274`）
- 编辑页：`bell!.sections…reduce(max)`，**无 bell 时退化为 12**（`:53-55`）
- 网格：`max(10, bell 最大节次, 课程最大 endSection).clamp(1, 20)`（`:209-220`）

当学校作息被导入为 >10 节（或用户在编辑页选了第 11/12 节）时，网格画 12 行、详情页只画 10 站且**无激活点**，
文案还会输出「一天十站，课程占用第 11 至第 12 节」这种自相矛盾的句子。
TASK-014 的登记范围包含「轻量对齐详情/编辑页」，三份定义被原样留下；
更糟的是 `app_shell_test.dart:146-153` 把「10」写进了断言。
按 `AGENTS.md`「一处策略，一处定义」，这里应抽成一个共享的节次上限来源。

**D4 ［低］长按彩蛋没有轻触觉，而文档写「一次轻触觉」** — `week_navigation.dart:119,129` vs `:126`

长按路径（`:119` 语义层、`:129` 手势层 → `onSemesterProgress`）**没有任何 haptic**；
`HapticFeedback` 在 lib 内只有两处：`timetable_page.dart:300`（切周提交）与 `week_navigation.dart:126`
（那是**tap 回本周**），长按 handler 里没有。
`design.md`/`tasks.md`/changelog 都写了「长按 → 一次轻触觉 + 弹层」。弹层是真的（测试通过），轻触觉是**没接线的**。
这正是 `AGENTS.md`「宣称的能力必须在代码里有接线」所指的情形。

**D5 ［低］`stepRequest` 在 dispose 时未清空** — `week_swipe.dart:133,139,143`

`initState`/`didUpdateWidget` 把 `widget.state.stepRequest = _step` 指向 State 的闭包，
`dispose`（`:143`）只停了 controller，没有把 `stepRequest` 置空。
今天不会炸，因为 `WeekSwipeState` 由页面持有、与 pager 同生共死（`timetable_page.dart:46,55`）；
但 `stepRequest` 是公开可变字段，一旦有新调用方让 state 活得比 pager 久，
`state.step()` 就会打到已 dispose 的 `AnimationController` 上。

**D6 ［低］每帧把同一份冲突布局算两遍** — `timetable_grid.dart:174` 与 `:304`

测量（`_requiredSectionHeight`）与绘制（`_courseWidgets`）各对每天调用一次 `layoutCourseCollisions`，
七天即每帧 14 次；纯函数开销小，但两份结果理论上必须一致，重复计算本身就是不一致的温床。

**D7 ［低］详情页 `weeks` 为空时 `sorted.first` 会抛** — `course_detail_page.dart:88-91`

目前不可达（解析与导入两条路径都在更早处丢弃空 weeks），但同页展示同一字段的
`course_preview_sheet.dart:244` 是有 `weeks.isEmpty` 兜底的，两处不一致。

**D8 ［低］详情页首帧把 loading 显示成「课程不存在或已删除」** — `course_detail_page.dart:22,25-30`

`ref.watch(...).value` 在首个值到达前为 null，直接渲染了「不存在」文案。属既有问题（HEAD 同形），
但页面这轮刚被改过，顺手修的成本很低；测试用 `pumpAndSettle` 等掉了流，所以测不出来。

### 3.2 文档与代码不一致（知识库同步）

| 编号 | 文档断言 | 代码事实 | 判定 |
| --- | --- | --- | --- |
| **C1** | `architecture.md:119`「两 lane 并排，超过两 lane 折叠为 `+N` 入口」；同行还写「贪心复用 lane…Widget 只消费结果」 | `timetable_grid.dart:311-312` **只画 lane 0**，lane 从不用来分列宽；`design.md:88`/`current_state.md:104-106`/ISSUE-016 说的是相反的 | **错**（文档教了一个已被推翻的方案） |
| **C2** | `architecture.md:71-72` 列了 `widgets/glass_add_button.dart` 与 `widgets/timetable_motion.dart # 120/180/280ms 统一动效常量` | 两个文件**从未存在**（`git log --all` 为空，实际是 `liquid_add_button.dart`；动效令牌在 `lib/core/glass/glass_motion.dart` 且是 **110**/180/280）。同一清单还漏掉了 `lib/core/glass/`、`ambient_backdrop.dart`、`week_swipe.dart`、`week_navigation.dart`、`today_courses_sheet.dart`、`today_glass_shortcut.dart`、`models/course_block_layout.dart` | **错**（文件清单整块失真） |
| **C3** | `architecture.md:73` 称 `course_listing_row.dart`「仅供非网格消费方保留」 | `CourseListingRow` 类在 lib/test 内**零引用**（只有它自己的定义），该文件里唯一被用的是 `EmptyDayPlate` | **错** |
| **C4** | `design.md:64-65`、`current_state.md:92`、`tasks.md:40`「`GlassMotion` 是全 App 唯一一份时长与弹簧参数，禁止在 Widget 里各写 `Duration`」 | 同批新代码里有 4 处自写时长：`liquid_add_button.dart:47,51`（220ms）、`weekday_header.dart:38`（460ms）、`week_navigation.dart:177`（260ms）、`week_navigation.dart:303-304`（直接写 280/180，而 `GlassMotion.slow`/`standard` 就在旁边）；同时 `GlassMotion.standard`/`returnSpring`/`exit`/`emphasized` **零调用点**（只被 `glass_interaction_test.dart:204-219` 断言） | **错**（规则由声明它的那批代码自己违反） |
| **C5** | `tasks.md:80`、`changelog.md:179`、`current_state.md:300`「节次文案统一为 `sectionRangeLabel` 一种写法」 | `sectionRangeLabel`（`course_time_service.dart:34-37`）只有**一个**调用者 `course_listing_row.dart:72`，而该文件是死代码；用户可见的文案来自私有副本 `course_preview_sheet.dart:239-241`（用 en dash `–`），语义文案是第三种写法 `timetable_course_block.dart:142-144`（`第3至第4节`）。`CourseTimeService.formatRange` 同样只剩单测在用，时间区间在四处内联拼 | **错**（「唯一来源」是死代码，实际有 2–3 份） |
| **C6** | `design.md:98-99`、`current_state.md:113`「`RouteBackground` 现仅用于设置页与课程详情页」 | 同一批改动**刚把**它从详情页删掉（改用 `palette.background`），全仓只剩 `settings_page.dart:22` 一个调用点 | **错** |
| **C7** | `testing.md:54`「课程跨度、两路并排、三路 `+N`」 | 没有任何测试测「并排」；现有测试锁的是相反行为（`week_agenda_ui_test.dart:187-224` 折叠为一门完整课 + `+1`） | **错**（TASK-014 的残留文本） |
| **C8** | `tasks.md:52-54`、`changelog.md:24-26`、`current_state.md:314-319` 称 `week_agenda_ui_test` 新增「6 条」 | 该文件本次实际新增 **8** 条（运行日志 `+169…+176`）；文档自己的算术 149+9+6+5+6=**175** 对不上真实的 177，差值正好是这 2 条 | **错（计数）** |
| **C9** | `design.md:94`「4dp 进度条」 | `week_navigation.dart:353` 是 `minHeight: 6`（4 是 `ClipRRect` 的圆角） | **错（数值）** |
| **C10** | `design.md:42-43`、`current_state.md:94`「所有按压反馈都来自 `PressPhysics`、全部交互不再使用 InkWell / splash」（作为全 App 规则） | `InkWell` 仍在 `onboarding_page.dart:235`、`bell_settings_page.dart:78`、`semester_settings_page.dart:36`、`settings_page.dart:162`、`course_listing_row.dart:37`；`app_theme.dart:42` 还全局装了 `splashFactory` | **夸大**（在玻璃层内为真，作为全 App 规则不成立；测试只覆盖了 `GlassSurface`） |
| **C11** | `current_state.md:110-111`「Reduced Motion 下取消位移、缩放、模糊与弹簧式过渡」 | 降级的是**动画过程**：`glass_sheet.dart:94-97,134-138` 直接跳到目标值，但终态的缩放 0.982 / 模糊 14 / 压暗 0.16 照旧生效；按压仍瞬时置 1 并压缩 | **夸大** |
| **C12** | 注释与代码不符：`glass_sheet.dart:15` 写「背景缩放 1 → 0.985」，实参 `backgroundScale = 0.018`（→0.982，`design.md` 反而是对的）；`week_navigation.dart:155` 写「12dp 的小位移」，代码 `:227,235` 用的是 **14** | — | **错（注释）** |
| **C13** | ISSUE-015 的 Evidence 引用测试名「360dp 窄屏与 1.3 倍字体下整周不溢出」（已不存在，现在是 390dp）、`design.md:33` 举例的「今日无课」字样 | lib 内已无此字符串（只有 `本周暂无课程`，`timetable_grid.dart:633`） | **错** |

C1–C13 的共同根因只有一个：**批 3 推翻了批 2 的若干设计，但 `architecture.md`/`design.md`/`testing.md`
里批 2 写下的句子没有被回头改写**。而因为三批都没有提交，`git diff` 无法提供「哪句话属于哪一轮」的锚点，
读者只能靠 mtime 猜。AGENTS.md 要求的「知识库同步属于同一笔提交」在这三批里都没有落实。

### 3.3 死代码与未接线

- `CourseListingRow`（`course_listing_row.dart:14`）：**零消费者**。批 1 为整周议程引入，批 2/3 改成二维网格后失去用途，
  但节次文案的唯一来源 `sectionRangeLabel` 只被它调用 → **一条「唯一来源」链整体吊在死代码上**。
- `CourseTimeService.formatRange`：仅 `course_time_service_test.dart:43` 在用。
- `TimetableCollisionCluster.startSection/endSection`（`course_collision_layout.dart:70-77`）：生产代码不读，只有单测读。
- `GlassMotion.standard` / `returnSpring` / `exit` / `emphasized`：零调用点，只在测试里被断言。
- `_ConflictSheet.operator ==` 用 `courses.first.id`（`timetable_page.dart:359-360`）：当前不可达（簇内至少一课），
  但空列表会抛 `StateError`。

以上都不是「必须删」，但按 `AGENTS.md`「宣称的能力必须在代码里有接线」，
**要么补消费者，要么把文档里「唯一来源 / 保留供非网格消费方」的说法删掉**——现在的状态是两头都不成立。

### 3.4 测试质量

**真实的强项**（不是同义反复，我逐条看过）：
- `course_collision_layout_test.dart` 4 条锁住分簇切分、输入序颠倒后 id 稳定性、链式合簇、3 lane 上报；
- `week_agenda_ui_test.dart` 新增的 8 条是**真实行为**断言：拖拽跟手 1:1、邻周同时在树、反向拖拽中断动画、
  未达阈值回位、`weekSwipeTarget` 纯函数四分支、换周标签新旧同时在树、按压→预览 Sheet、
  BackdropFilter 只出现在导航与弹层（`lessThan(10)`）；
- `course_block_content_test.dart` 5 条（3 声明 + 宽度循环）锁住「块内无 `ellipsis`/非空 `maxLines`」、
  文字落在块矩形内、1.3 倍字体不裁切——这是本次硬约束的正确测法。

**被削弱或失真的断言：**
1. `app_shell_test.dart`：HEAD 有「今日目标 InkWell 高度 ≥ 48」的断言，改动后整块换成语义标签存在性检查
   （`:61-66`），净断言 19 → 18。被删的控制项确实随「今日/整周」切换一起消失，删除是诚实的，
   但**新控件没有任何尺寸断言**（实际是 56dp 的 `liquid_add_button`，所以没有真实回归）。
2. `calendar_exception_ui_test.dart:80`：`expect(find.text('今日无课'), findsNothing)` 现在是**永真**——
   该字符串在 lib 内已不存在。同一 hunk 里的正向断言是换过名的（`今天停课` → `停课`），说明作者本意是保留不变量，
   只是指向了一个应用不再渲染的短语。当前正确目标应是 `本周暂无课程` / `今天停课` / `今天没有课`。
3. **链式冲突无覆盖**：D2 那个 a(3-4)/b(4-5)/c(5-6) 的形态，没有任何测试断言 `+N` 的数字与列表成员。
   `week_agenda_ui_test.dart:187-249` 的两条冲突用例里三门课都落在 1-2 节，掩盖了这个偏差。

### 3.5 流程与工程治理

1. **三批工作全部未提交**，`HEAD` 仍是 2026-09-14 的 `79c9267`；而 `pubspec.yaml` 已 `0.1.4+5`，
   `build/` 里已有对应 APK。改动规模：19 个已跟踪文件 +1068/-1051，加 22 条未跟踪路径。
   这是本次最该先处理的一项——**它同时是 C1–C13 得以积累的原因**。
2. **「已完成」没有可复核的落点**：TASK-013/014/015 的 Done 记录都写着「已完成、analyze 无问题、N/N 通过」，
   但没有任何一次 commit。`AGENTS.md` 说知识库同步属于同一笔提交——现在连「一笔」都不存在。
3. 模拟器/logcat 证据在 `current_state.md` 里以 `CONFIRMED` 记录。这类证据本身合理，
   但既不可复现、也没有 commit 锚定，接手者无法判断它对应哪一版代码。
4. `changelog.md` 的条目顺序已经乱了：顶部是 `0.1.4+5`，下面跟着 `0.1.3+4 追加（09-22）`，
   再往下才是 `0.1.0+1`，而 `0.1.3+4 追加（09-15）` 落在文件最底部。不是最新在前的排序。

### 3.6 无法验证、只能标注的部分

`ncpu_api36` 实画（日间 390dp / 夜间 / 360dp / 今日 Sheet / 预览 Sheet）、logcat 0 命中、
ISSUE-016 的「每节 160dp → 整周 1600dp / 回到 250dp」、release APK 的装机冒烟，均为**自报**。
文档对 iOS、真机 GPU 性能、TalkBack/VoiceOver 的 `UNVERIFIED` 标注是诚实且合规的——这一点做得好。

---

## 4. 值得保留的强项

1. **「测量即绘制」是可以证明的**：`CourseBlockContent.requiredHeight` 用与渲染完全相同的
   `TextStyle` + `TextScaler` 测量，`textWidth()`（`blockWidth - 3 - 2.5 - 4`）与渲染处的
   Row 实际留给文字的宽度**逐项相等**；栅格取 `max(下限, 铺满, 需求/span)` 后，
   可推出每块高度 ≥ 内容高度 + 2px 余量。硬约束「禁止省略号」是靠构造保证的，不是靠调参。
   `DecoratedBox` 不内缩子节点这一点也恰好让边框不会偷走 2px 宽度。
2. `PressPhysics` 确实是**唯一一份**指针物理（`glass_surface.dart:117`、`timetable_course_block.dart:82,262` 都走它），
   `BackdropFilter` 全仓只有 2 处（`glass_surface.dart:196`、`glass_sheet.dart:174`），
   `blurSigma: 0 → 不建 BackdropFilter` 有测试锁。玻璃层的分层（LEVEL 0–5）与「模糊只在导航与弹层」执行得住。
3. `GlassSheetHost` 用**一个** `AnimationController.progress` 同时驱动位移/背景缩放/模糊/压暗，
   方向一致、不会脱节；Reduced Motion 有统一降级入口。
4. ISSUE-016 的根因写法（「这是模型问题，不是排版参数问题」+ 51dp 列宽下的实测数字）是知识库里质量最高的一段记录，
   直接可以拿来当后续布局决策的判据。
5. 安全边界无破口：lib 内无 `print`/`debugPrint`，新目录无密码/学号/Cookie/Token 字样，
   没有新增依赖（`pubspec.yaml` 只动了版本行）。
6. 纯函数 + 单测的组合（`layoutCourseCollisions`、`weekSwipeTarget`、`buildWeekAgenda`、`readingProgress`）
   把可测性做对了，D1/D2 正是这种结构下**可以低成本修掉**的缺陷。

---

## 5. 建议处置顺序

| 优先级 | 事项 | 理由 |
| --- | --- | --- |
| P0 | C1 + C2 + C3（重写 `architecture.md` 的文件清单与冲突布局段） | 文档在**教一个已被推翻的方案**并列出不存在的文件，接手 Agent 会照它写代码 |
| P0 | D2（冲突 `+N` 的成员集合） | 唯一一条**用户能看见的错误信息**：数字多算、列表里有不重叠的课 |
| P1 | D1（切周提交判据改用视觉位置） | 用户可见的手感缺陷，修一行判据即可 |
| P1 | D3（节次上限抽一处）+ C4/C5（要么接线要么改文档） | 都是 `AGENTS.md` 明写规则的违反项 |
| P1 | 提交这三批工作（或明确宣告「暂存不提交」） | 不解这一条，后面每一轮复审都要靠 mtime 考古 |
| P2 | C6–C13（逐条改文档或补测试）；死代码二选一（补消费者或删文档说法） | 不影响运行，影响可接手性 |
| P2 | D4（长按补 haptic 或改文档）、D5、D6、D7、D8 | 小修，可合并进下一次改动 |
| P3 | 修 `changelog.md` 的条目顺序；给模拟器证据补一个「对应哪个 commit/工作区指纹」的字段 | 治理类，长期收益 |

---

## 6. 复审方法与可复现命令

```bash
# 归属：用 mtime 切批次
find . -path ./.git -prune -o -type f -newermt "2026-09-22 00:00" ! -newermt "2026-09-23 00:00" -print

# 文档漂移：只看新增文本
git diff -- knowledge/

# 验证（中文路径需 subst，见 AGENTS.md）
subst S: "D:\桌面\汇课" && cd /s && flutter analyze && flutter test

# 断言计数交叉核对
grep -rhE "^\s*(test|testWidgets)\(" test/*.dart | wc -l   # 174 声明 + 3 循环生成 = 177

# 单一定义规则核查
grep -rn "sectionRangeLabel\|formatRange\|CourseListingRow" lib test --include=*.dart
grep -rn "Duration(milliseconds" lib --include=*.dart | grep -v glass_motion.dart
grep -rn "GlassMotion\." lib --include=*.dart
grep -rn "HapticFeedback\|onLongPress" lib --include=*.dart
```

未修改任何被审代码。本报告本身新增于 `knowledge/report_2026-09-23_review.md`，并在 `knowledge/README.md`
索引中登记；连同前三批改动一起，仍处于**未提交**状态。
