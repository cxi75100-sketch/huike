# Testing

## TASK-020B Floating Switcher（2026-09-27）

基线268；root_switcher_test新增15例：360/390/430×明暗×Reduced（font1.3、24/48dp bottom inset）12例，
另测保留State/scroll/week/横滑、子路由与两类Preview/主题和inset重建、active静默haptic/快速反向连续/非逐帧page build。
旧week_agenda_ui与today_timeline断言适配一级入口/HeroMode；未删业务覆盖。最终283/283，analyze无问题、build/diff通过。
API36 emulator-5554，1080×2400/density443约390dp，明暗静态root/双向录屏及15fps capsule、8fps全页抽帧已查。
设备空课QA学校、第2周保留；非空课程状态由widget测试覆盖。iOS/真机/GPU帧耗时、3-button设备仍UNVERIFIED。

## TASK-026（2026-09-27）

tools/verify_icon.py：15Android资源、21iOS文件/25slot尺寸/不透明/无旧红图、mono一致、
XML16% inset、安全圆、三mask×48/64px三独立白块及浅/深模拟壁纸。API36安装最终APK并人工检查
Launcher/Recent Apps/Settings列表。79Flutter文件哈希不变；analyze无问题、268/268、build/diff通过。
iOS设备/Android真机/其它厂商launcher未验，详见app_icon报告。

## TASK-022B（2026-09-27）

基线262，launch_motion_test新增6例：首次保存主题与系统相反、四模式即时可点击/完成/不重播、
未解析学校不画引导。最终268/268、analyze/build/diff check通过。API36模拟器四模式cold/warm
及Home恢复已执行；最终静态画面与Splash→环境背景抽样已查，完整GPU流畅性/真机/iOS/非空课程
设备启动/耗时无回归仍UNVERIFIED，详见launch_motion报告。QA临时产物在系统Temp，不入仓库。

## TASK-022A（2026-09-27）

基线252/252，motion_audit_test新增10例：paint-only child不逐帧重建、反向geometry连续、
Reduced按压正常且不缩放、menu关闭状态、四种明暗/Reduced真实路由旅程、iOS边缘pop两例。
最终analyze无问题、262/262、Debug APK成功、diff check通过。68张widget帧人工检查普通页面、
Dialog/Sheet/Menu/Snackbar，部分测试标题字形占位，不替代字体或设备/GPU验收。无连接设备。
详见report_2026-09-27_motion_audit.md；可选HUIKE_MOTION_QA_DIR导出画面。

## TASK-021（2026-09-27）

基线analyze无问题、232/232通过；新增`today_timeline_test.dart`20例：90分钟/六小时同内容同高度，
丰富内容自然增高但不超长；真实时间排序/大空档压缩；课程中/课间/精确结束/课前/课后位置，
空Today、单课信息/tint/点击、未知时间、嵌套重叠；360/390/430×1.0/1.3×Light/Dark十二例
含真实TodayPage顶部的四课首屏密度、无overflow。原Today预览/详情/Hero测试仍通过。
可选`HUIKE_TODAY_QA_DIR`输出390dp明暗widget截图，指定时加载本机微软雅黑字体；默认测试无磁盘输出。
截图检查布局/文字/材质，不代替设备滑动或GPU验收。最终analyze无问题、252/252、
生产Debug APK成功、git diff --check退出0；新增文件另做空白检查。详见本轮报告。

## TASK-020B（2026-09-27）

真实基线analyze无问题、229/229通过。新增三例360/390/430dp ×1.3字体行为测试，
确认无Today摘要、七列网格仍存在、顶部衔接无空洞、44dp今日入口跳转既有/today，
切到其它周后Today仍取今天课程，返回保留所选周。更新原胶囊入口测试及建校首页断言；
原Today课程预览/详情/Hero测试继续保留。10/12节一屏沿用既有回归；14节测试改为验证真实scroll extent/滚动距离和星期栏位置，不依赖旧header高度假设。
最终analyze无问题、232/232通过、生产Debug APK成功、diff check退出0；详见 `report_2026-09-27_separate_today_from_weekly.md`；无模拟器/真机/iOS实画。

## TASK-020A（2026-09-27）

真实基线 analyze 无问题、217/217。`week_agenda_ui_test.dart`新增12个widget行为测试：
双向普通/高velocity/超长drag，阈值以下回弹、连续独立手势、动画期间按下并继续长拖、
动画中按下等落位后才移动、cancel与箭头、Reduced Motion、第二指cancel不干扰第一指。断言最终周次并核对网格日期。
原实现cancel测试失败（期望第4周、实际第5周），其余最初8例通过；不宣称复现原高速连跳。
最终analyze无问题，全量229/229，生产Debug APK成功，diff check通过；详见 `report_2026-09-27_weekly_swipe_paging.md`。本轮无设备交互验收。

## TASK-019 最后视觉收尾（2026-09-26）

基线及最终 `flutter analyze --no-pub` 无问题；`flutter test --no-pub` **217/217通过**，
含八色明暗静止/按压小字对比度≥4.5:1、无独立色条、固定网格及布局回归；未新增测试。
`flutter build apk --debug --no-pub` 生产main.dart成功；`git diff --check`通过。
API36 emulator-5554 / 1080×2400内存QA七色周明暗实画，检查英语/马原/线代，玻璃底色占主导，
课程色轻微融入。截图为当前Codex visualization目录light.png及dark.png。
QA复用仓库外入口，不修改数据库实现或持久化数据；真机/iOS/实际光学折射未验证。


## TASK-019D 验证（2026-09-26）

最终analyze无问题、217/217、生产Debug APK成功、diff check通过。
新增2例遍历8色、两主题、静止/按压，检查实际教师Text颜色与真实gradient各stop合成到
background/surfaceAlt上的对比度≥4.5:1；地点与教师使用同一辅助文字样式。
API36约390dp有课周Light/Dark实画：整卡色差明显，小字可读；截图color-light.png / color-dark.png
位于本轮visualization/task019目录。QA使用内存数据，最终安装回生产main.dart构建。

## TASK-019C 验证（2026-09-26）

加强邻卡分隔后analyze无问题、215/215、生产Debug APK成功、diff check通过。
跨节/冲突位置断言精确匹配1.5dp inset；三份相关测试44/44复审通过。
API36约390dp相邻七门匿名课程Light/Dark实画检查；无竖条，卡间3dp，完整边缘清楚。

## TASK-019B 验证（2026-09-26）

删除Weekly色条后，analyze无问题、全量215/215、生产Debug APK成功、diff check通过。
新增2例明暗课程色/真实按压测试；明暗字段测试验证无独立Row/Container且文字宽度增加4dp。
API36约390dp七色匿名有课周Light/Dark实画通过，临时内存QA入口已删除。
详情见 `report_2026-09-26_weekly_glass_surface.md`；不将模拟器结论扩大为真机/iOS。

## TASK-019 验证（2026-09-26）

真实 baseline：analyze 无问题，207/207 通过（此前记录的两项 overflow 本次未复现）。
新增 formatter 2 例、明暗课块/极短降级/缺失地点 4 例；修改原有 13 例 viewport 测试，
在 360/390/430dp × 1.0/1.3 × 10/12 节检查三项字段、地点与教师未超过 maxLines、
文本实际边界、不显示时间。14 节继续检查可滚动。最终 analyze 无问题、213/213 通过、
默认生产入口 Debug APK 构建成功、diff check 通过（仅 LF/CRLF 提示）。
API 36 `ncpu_api36`：1080×2400、density 443（约 390dp），匿名内存课程 Light/Dark 实画。
未使用真实用户课程；临时 QA 入口已移除，最终构建使用生产 main.dart。
已记录既有加号遮挡右下角课块问题，不在本轮修复；360/430dp 与 1.3 字体为 widget 验证。

## 历史基线（2026-09-24，TASK-018A 工作树）

- 中文路径下先运行 `subst S: "D:\桌面\汇课"`，在 `S:\` 执行 Flutter 命令。
- `flutter analyze --no-pub`：No issues found。
- `flutter test --no-pub`：**207 个用例，205 通过**。固定失败的 2 例是
  `course_block_content_test.dart` 的「430.0 dp / 1.0 text / 10|12 sections fit viewport」
  （课程块内一行 `RenderFlex overflowed by 3.5 pixels`）。**这两例与本轮改动无关**：
  临时把 `GlassButton` 的修复回退后重跑，两例同样失败；它们属周课表范围，留待
  周课表任务处理。本轮改动前的基线是 194 个用例、同样这 2 例失败（新增 13 例后共 207）。
- `flutter build apk --debug --no-pub`：成功。`git diff --check`：无空白错误（仅有
  Git 的 CRLF 提示）。
- 既有 `flutter_inappwebview_android` 本地 override 保留。sqlite3 构建 hook 所需缓存已经在本机可用。
- 注意：`flutter_inappwebview` 在 widget test 中没有平台实现，构建 WebView 页会抛
  `InAppWebViewPlatform.instance != null` 断言。`import_flow_regression_test.dart` 明确
  消费这条预期内断言，再用页面 widget 断言路由参数（host / initialUrl）。

```powershell
Set-Location S:\
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

## 当前测试覆盖

- 数据与安全：周次、学期、作息、导入解析和差异、数据库隔离、导航白名单、地址校验、校历例外及 WebView 桥契约。
- 周课表：360/390/430dp、文字缩放 1.0/1.3 下，10/12 节七天同屏且网格不竖向滚动；14 节可在固定星期栏下滚动。空周、加载态、Dark Mode、Reduced Motion 和大屏也有 widget 覆盖。
- 课程块：普通两节块显示课程名、compact 地点与教师；极短空间按优先级降级。原始完整字段在预览/详情页可读。课程块不逐卡模糊，玻璃导航和弹层受独立测试约束。
- 冲突：两路、三路折叠；链式 A∩B、B∩C、A∩C=∅ 时，A 的 `+N` 及弹层成员仅取直接重叠课程。
- 动效：切周拖动与邻周跟手，超拖再回拉以画面位置决定提交，速度判据、箭头切周、课程预览弹层、玻璃按压和高光；weekly 与 Today 的预览/详情 Hero 身份配对、Today 返回预览、Reduced Motion 跳过 Hero；加号菜单进入单周事件编辑。
- 玻璃表单：原生 TextField 输入、单选/勾选语义、节次玻璃选择器、危险操作确认框及 1.3 倍字号布局。
- App 壳与校历例外：新建学校（真实 `enterText` + 点 `创建学校`）、课程详情删除确认、设置外观选项、停课/调休状态及设置入口。
- 导入流程回归（`import_flow_regression_test.dart`，13 例）：导入页正文非空白且 body 高度可用、CTA 在未勾选确认时 disabled、真实点勾选后启用并可进入 `/import/web`（断言传参 host/initialUrl 与写入的确认主机）、取消弹窗与非法地址不跳转、学校信息加载中/读取失败/未建校三态各自可见、390dp 与 1.3 倍字号无 overflow、键盘弹起时 CTA 停在键盘上方且正文可滚动、系统返回回上一级、离开导入 WebView 后内存会话被清空。

## 实画与设备边界

- 2026-09-23 TASK-016 在 API 36 `ncpu_api36` 的隔离测试用户中，用匿名学校检查了空周、七天同屏、导航与玻璃层级。该设备验收属于 TASK-016，不代表 TASK-017 的 Hero/表单实画。
- 2026-09-23 TASK-017：`adb devices -l` 未发现连接设备，故本轮 Hero/弹窗/表单仅有 widget test 与构建验证；没有安装 APK 或更改模拟器状态。
- 2026-09-24 TASK-018A：在 API 36 `ncpu_api36` 上安装本轮 Debug APK 走通
  「引导页建校(QA Univ) → 首页 → 导入教务课表 → 勾选风险确认 → CTA 由 disabled 变 enabled →
  确认弹窗 → 进入教务 WebView（页面标题为学校名，URL 为占位地址）→ 返回」。
  键盘弹起时 CTA 停在键盘上方、正文可滚动。退出导入页前后 logcat 均无
  `E/flutter` / `Unavailable` / provider 异常（修复前此处稳定出现两条 dispose 期异常）。
  **没有对任何真实教务系统登录**（地址用的是不存在的占位域名，WebView 显示加载失败页）。
  验证用的 QA 学校 `QA Univ` 留在该 AVD 的应用数据里，未清理；主设备未受影响。
- 模拟器截图与 widget test 不等于真机、iOS 或真人辅助技术验收。iOS 构建、真实教务登录/导入、真机 GPU 帧率、TalkBack/VoiceOver 全流程均为 `UNVERIFIED`。
- 下列历史实画记录对应 TASK-013/014/015/016 的当时工作树，不证明 TASK-017 当前 UI 已经在设备实画。

## 历史快照

- 2026-09-23 TASK-015：177/177；API 36 模拟器曾用匿名课程检查长名称、夜间、360/390dp、预览弹层。其「内容驱动每节高度」策略已被 TASK-016 的 viewport 几何替代。
- 2026-09-22 TASK-014：158/158；二维周网格与 Compact 双节视觉分组。旧「两路并排」说明已撤销，当前采用完整主卡和 `+N`。
- 2026-09-15 TASK-013：149/149；历史整周议程 UI。该 UI 已不再是首页。
- 2026-09-14 TASK-010：当时的 release Android 构建和模拟器冒烟记录；不代表当前 APK。
