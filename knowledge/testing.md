# Testing

## TASK-RELEASE-100（2026-10-03）

- `flutter test --no-pub`全量395/395；学校切换/新增后返回导入与旧URL保留专项7/7；新增route-current隔离修复后专项重跑7/7、analyze无问题、复审APPROVE。
- Release首次构建发现生成registrant引用dev插件integration_test，编译范围不含该插件。修复与最终构建证据见release_1.0.0.md。
- 发布核验：两远端v1.0.0解引用均为57a59ea；Gitee发行页重新打开后显示最新版、正确源码提交与Release/校验下载链接。未因文档收口重新构建APK，下载核验见release_1.0.0.md。

## TASK-LOGIN-RESET-01（2026-10-03）

全量394/394；服务/policy/UI专项10/10。自动仅可信主frame401/TOO_MANY_REDIRECTS一次，403/连接/子资源/未知域不清，手动确认取消/忙态/旧桥及旧确认交错回归通过。真实Android服务集成1/1与实际ImportWebPage自动恢复集成1/1均通过，API36/WebView133.0.6943.137：精确Cookie含前缀删除核验、origin存储/其他host保留、scope外current partial；实际旧Cookie401→自动清理→login-webview-1→200/导入就绪，无点击。代码/安全复审APPROVE。命令及APK见report_2026-10-03_login_recovery.md；真实学校/截图连接中止/真机/iOS仍UNVERIFIED。

## TASK-DEFER-SCHOOL-01 / TASK-IMPORT-RELIABILITY-02（2026-10-03）

- 最终全量`flutter test --no-pub --concurrency 2 --reporter expanded` 385/385；`flutter analyze --no-pub`无问题；UI29/29、框架10/10、Today密度25/25。UI空库320×568/字体1.3、无学校写入、今日导入入口、建校后继续导入与真实router.pop回首页。旧密度fixture补齐合成学校，不改原布局断言。
- 本地synthetic真实Android WebView组件：`flutter test integration_test/import_webview_test.dart --flavor huike -d emulator-5554 --no-pub` 1/1通过。API36、WebView133.0.6943.137；POST302/307方法、Cookie、严格CSP、动态同源frame/URP解析/attempt完成、跨源不可读、旧timer/bridge、headers后流式body abort。复审修复Function/CSP与取消body缺口后APPROVE。
- 仍未验证完整ImportWebPage跨host确认UI/真实CAS、新窗口、真实学校、真机、iOS；四脚本只有URP本轮实跑synthetic，不能宣称全校可用。新增integration_test SDK开发依赖；APK证据见report_2026-10-03_import_reliability_startup.md。

## TASK-WEBVIEW-FRAMEWORK-01（2026-10-03）

全量381/381（--no-pub --concurrency 2 --reporter expanded）；入口/导航/错误模型专项34/34，最终import_web_loading_test+web_load_failure_test 4/4，analyze无问题。fake控制器覆盖主frame连接失败/403、子资源不覆盖、失败后loadStop不启用导入、手动reload、CANCELLED回调、旧bootstrap异步完成不能启用新页。JDK17执行实际共享Java解释器14/14；复审APPROVE、Release/Debug成功。adb为空，非真实内核/设备/学校/iOS验收；命令与产物详见report_2026-10-03_webview_framework.md。

## TASK-ADAPTER-GENERAL-01（2026-10-02）

Adapter专测覆盖schema 1兼容/schema 2 profile解析、精确别名/host/path、同family不同profile的字段alias、候选优先级和未知页面兼容回退；四类synthetic页面特征与bridge payload fixture均不含真实账号/页面数据。另覆盖课程规范化、当前attempt成功门槛、迟到attempt回调隔离及诊断JSON不泄露原始异常。最终全量`flutter test --no-pub --reporter expanded --concurrency 2`：377/377；`flutter analyze --no-pub`无问题；`git diff --check`通过。APK使用明确的`flutter build apk --flavor huike --debug --no-pub`构建，并检查包内catalog确为schema 2；无flavor命令报告成功但留下旧schema 1产物，不计作本轮构建证据。首轮全量中calendar exception测试出现一次未复现失败，单项5/5后低并发全量通过；不归因于本改动。真实WebView/教务、设备和iOS未验。详见`report_2026-10-02_adapter_framework.md`。

## TASK-LOGIN-REPAIR-01（2026-10-02）

专项18/18、最终全量367/367（concurrency2）、analyze无问题、复审APPROVE。新增retired_login_url_repair测试首读修旧入口/幂等/字段与数据保留/学校身份/自定义不动；import_flow新增自动预填与WebView参数、确认候选保存/取消保持。强listen保持真实provider订阅，避免仅read.future的测试暂停；原生WebView缺失仅验证路由参数。真实登录/真机/iOS未验，见report_2026-10-02_login_repair.md。

## 全量完成度复验（2026-10-02，TASK-PROGRESS-REPORT-01）

S盘执行`flutter test --no-pub --reporter compact`：362/362通过，日志`build/completion_report_test.log`；`flutter analyze --no-pub`无问题，diff-check通过。写报告期间三项UI任务另行最终收口，证据分别保留。没有采集代码覆盖率/重建/设备测试；现存rapid及light-launch-status两组APK哈希与对应报告一致。见`report_2026-10-02_project_completion.md`。

## TASK-TODAY-STATUS-01 / TASK-LAUNCH-BRAND-01 / TASK-ROOT-SWIPE-01（2026-10-02）

最终全量362/362（`flutter test --no-pub --concurrency=2`），analyze无问题、复审APPROVE、verify_icon.py通过。Today专项25/25并生成明暗进行中/课间/结束合成实画，launch专项8/8含深色AppBar系统栏/浅底/Reduced/首触摸/不重播；Root普通/Reduced局部滑动/区域外不切/取消/点按/分支保留通过。初次默认并发全量运行import_flow worker未完成，该文件随后单独13/13，低并发全量最终通过；未确认首次worker退出原因，不归因业务回归。APK/边界见report_2026-10-02_today_launch_root.md，设备/GPU/iOS未验。

## TASK-PREVIEW-RAPID-01（2026-10-02）

全量355/355，analyze无问题，代码复审APPROVE。预览新回归先在旧实现失败（40ms点击被遮罩截获），修后专项31/31（dismiss/geometry/blur）；preview_dismiss与week_agenda_ui专项56/56，新增首末周边界单项通过后最终全量通过。覆盖普通/Reduced关闭40ms换课、同课重开、旧回调、连续箭头、新手势接管、长拖单次提交/取消/多指/第一末周；不把widget交互验证视为GPU真机流畅度验收。

## TASK-COURSE-HUES-01（2026-10-02）

`flutter test --no-pub --dart-define=HUIKE_CAPTURE_VISUAL=true test/course_colors_test.dart test/weekly_now_indicator_test.dart`：8/8通过。新增明暗八个色相区间覆盖回归，保留16色唯一/不透明/稳定映射/正文对比度≥4.5与轴内提示测试。重新生成并检查明暗360/430dp合成静态截图。本轮全量未重跑，前轮349/349为基线；设备/GPU/iOS未验证。代码复审APPROVE，构建和analyze结果见report_2026-10-02_course_hues.md。

## TASK-TODAY-MOTION-COLOR-01（2026-10-02）

全量349/349、analyze无问题；实画/交互专项47/47。新增当前节次提示明暗360/430dp轴内/不遮课程/非本周隐藏/文字对比度回归；Today预览中途固定宽度/完整正文/固定遮罩/无BackdropFilter与Hero/详情返回/Reduced/入场中立即Back连续性。静态合成数据截图用`flutter test --no-pub --dart-define=HUIKE_CAPTURE_VISUAL=true test/weekly_now_indicator_test.dart`生成build/today-color-{light,dark}-{360,430}.png（仅capture模式载本地字体），普通测试不落PNG。测试默认Ahem字体不能当中文视觉验收；载字体后重新渲染。Release/Debug包见本轮报告，无设备连接，GPU流畅度仍UNVERIFIED。

## TASK-VISUAL-RETURN-01（2026-10-02）

`S:\`：专项36/36（course_colors、launch_motion、preview_geometry、preview_dismiss、preview_blur），全量342/342、analyze无问题。覆盖明暗16色对比度≥4.5、启动全不透明/Reduced、Weekly动画中宽度不变/课程位置不动、14节滚动、完整详情返回后固定大小下滑关闭，以及既有单次关闭/编辑/下拖。tools/verify_icon.py检查fallback/iOS字节与槽位、矢量接线及adaptive安全圆；本轮无设备连接，真机/iOS启动/图标和返回帧耗时UNVERIFIED。APK详见report_2026-10-02_visual_return.md。

## TASK-LEGACY-UPGRADE-01（2026-10-01）

最终`S:\`全量341/341、analyze无问题，导入与启动重试定向14/14；图标及diff-check通过，Debug产物实测证书/包名/版本/debuggable符合兼容契约。未在设备覆盖安装；见报告。

`legacy_database_import_test.dart`8项合成SQLite文件回归：全部字段/多学期/Unix秒、作息/主题/学期名、源文件字节不变、幂等不复活、已有学校跳过、事务失败回滚后重试、无源、未知schema与孤儿课程。`legacy_upgrade_startup_test.dart`覆盖失败提示阻断建校、用户重试、新数据库实例与迁移恢复。

Widget测试数据库流清理：ref.onDispose记录实例；卸载并dispose容器后，在tester.runAsync中首次启动并逐个await close，避免在fake zone预启动close造成暂停stream/Timer.run挂起。所有功能断言保留，清理不吞错误。

图标verify_icon.py只读校验15 Android/15 iOS资源、槽位、adaptive引用。构建改用`flutter build apk --debug --no-pub --flavor huike`或`--flavor legacyUpgrade`；兼容签名配置由外部properties显式提供。APK需aapt核对应用ID/版本/debuggable，apksigner核对旧包与新包证书一致；设备安装不能由签名与测试结论替代。最终结果见本轮报告。

## TASK-SCHOOL-URL-DIALOG-01（2026-10-01）

新增 `school_login_url_dialog_test.dart` 6 项真实应用路由 + 内存数据库测试：取消并重复打开、HTTP/HTTPS 保存、空值/非法协议保存、遮罩/系统返回。逐步 pump 退出动画并检查异常与最终地址/已确认主机。修复前6项失败，捕获 controller disposed 以及 `framework.dart:6281 _dependents.isEmpty`；修复后专项6/6、全量332/332。真机/iOS仍未验证；详情见专项报告。

## TASK-UI-COMPACT-COLOR-01（2026-10-01）

`S:\` analyze无问题，全量326/326；新增16色明暗唯一性/不透明/对比度2例、360dp与2倍字号长信息完整显示2例。更新旧Today高度与Weekly渐变断言；Weekly16色按压前后对比度≥4.5，颜色恒定。360/390/430dp × 1.0/1.3 × Light/Dark矩阵、原Preview回归通过。中文字体合成数据Light/Dark画面已查看；Debug APK成功。真机/iOS/Release未验证。

## TASK-PERF-BLUR-01（2026-10-01）

开工 314/314，最终 `S:\` analyze 无问题、全量 **322/322**；Preview dismiss 9、geometry 10、
新增 blur 8，专项 **27/27**。新测试覆盖 Weekly/Today × Light/Dark × Reduced/default，
保留父滤镜、普通按钮默认滤镜与三个动作；不改变 Today。
API 36 AVD / 60 Hz / profile / Impeller OpenGLES 通过 FrameTiming 与临时 VM 扩展逐层采样，
每组 1 次预热 + 3 次 open/Back-close。最终 open Raster 峰值 17.553–18.441 ms，
比同轮原始 21.026–24.841 ms 稳定下降，但仍超预算；UI 未出现超预算。
Light/Dark、开合抽帧、长拖/短拖回弹、实际 Reduced Motion 已检查，连续真机视觉未验证。
实验源码完全恢复，脱敏原帧、离群值、设备/统计边界与 APK 验证见
`report_2026-10-01_perf_blur_01.md` 和 `evidence_2026-10-01_blur_profile.json`。

## TASK-WEEKLY-PERF-PROFILE-01（2026-09-28）

`sdk_gphone64_x86_64` / Android 16 API 36 / 60.000004 Hz，Flutter profile、Impeller OpenGLES，
通过 DevTools Performance 记录 idle、冷/热/快速切周、Preview open/close 与临时 blur A/B。
启用 blur 的 Preview-open 代表帧三次 Raster 34.9–37.2 ms；profile-only 绕过 `GlassSurface` 与
Sheet blur 后三次为 5.9–7.2 ms，UI 仍低于 1.2 ms。静止约 15 秒无新帧。切周有超预算代表帧，
但未可靠统计慢帧频率。当前 AVD 只有 10 条节次时间配置，14+ 节滚动未测。X 命中、repaint
区域、真机/iOS/release 未验证。A/B 源码已恢复；无生产逻辑变更。最终 `flutter analyze --no-pub`
无问题、全量 314/314、`git diff --check` 通过；`flutter build apk --debug --no-pub` 成功，产物
`build/app/outputs/flutter-apk/app-debug.apk`（207,132,994 字节，SHA-256
`26A9A567F23B84C12EA1F13B589406D42265BEE6887B6E2CF94A45163EBBA6EE`）。详见专项报告。

## TASK-PREVIEW-GEOMETRY-01（2026-09-28）

新增 `preview_geometry_test.dart` 10 项：两个明显不同的 viewport（640/1000dp）最终矩形等于实测
内容框；起始矩形对齐点击课程块；14 节纵向滚动后仍从当前课程块位置开始；Reduced Motion 最终
矩形正确；resize 使用安全 fallback；关闭反向返回源位置且只回调一次；source 关闭前失效时使用
fallback；live source 移位、drag 跟手及短拖回 destination。与既有
`preview_dismiss_test.dart` 合跑专项 19 项。最终 `flutter analyze --no-pub` 无问题，
`flutter test --no-pub` 314/314；`git diff --check` 通过。全量基线 304/304。未执行设备实画；
本任务 APK 按批次计划 `PENDING`。详见 `report_2026-09-28_preview_geometry_01.md`。

## 统一 APK 构建（2026-09-28 17:01 +08:00）

按用户后续要求对当前工作树统一执行一次 `flutter build apk --debug --no-pub`，成功生成
`build/app/outputs/flutter-apk/app-debug.apk`（207,125,368 字节；SHA-256
`90cda25ad60f05b6d4b97d763d0585196ee49b2e570b9a0d6a3e5bd8849f965c`）。
这是构建验证，不等于真机、iOS 或实际教务验收；构建后未改代码，前次全量 304/304 仍是最近测试记录。

## TASK-PREVIEW-BACK-01（2026-09-28）

基线 analyze 无问题、295/295。新增 `preview_dismiss_test.dart` 9 个 Widget 测试：
Weekly Preview 的系统 Back、关闭后原路由返回、双 Back、X 后 Back、编辑先关闭再导航；
GlassSheetHost 的背景与程序化双源关闭、短拖回弹和下拖关闭、Reduced Motion 重复关闭、
关闭后重开新周期。定向 9/9、全量 304/304；真机 predictive back / iOS 手势未验。
APK 遵用户安排本轮不构建，验证状态见专项报告。

## TASK-CALENDAR-DATE-01（2026-09-28）

基线 `flutter analyze --no-pub` 无问题、`flutter test --no-pub` 290/290。
`calendar_exception_date_picker_test.dart` 新增 5 个真实路由 Widget 测试：当前学期今天、历史学期
夹到末日、未来学期夹到首日、编辑合法原日期、编辑超范围原日期；每例均检查 DatePickerDialog 的
initialDate 与原 firstDate / lastDate。修复前 3 例边界失败，修复后定向 5/5 通过。
最终 analyze 无问题、全量测试 295/295、Debug APK 构建与 diff check 均通过，详见专项报告。真机/iOS 未验。

## TASK-DATA-INTEGRITY-01（2026-09-28）

基线 analyze 无问题、283/283。新增 `import_integrity_test.dart` 7 例：跨学期同课共存和稳定 ID、
同学期重导替换、跨学校隔离、旧格式 ID 重导替换、三部分成功写入、课程插入主键冲突时回滚、
学期元数据更新后注入异常时回滚。两类失败均比较数据库内作息、课程、学期原始行快照。
现有 `course_repository_test.dart` 更新 ID 调用签名，原测试继续通过。最终 analyze 无问题、290/290。
Debug APK 与 diff check 见本轮报告。真实教务、真机和 iOS 均 `UNVERIFIED`。

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
