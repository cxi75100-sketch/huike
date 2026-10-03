# Current State

## Last Updated

2026-10-03 +08:00（TASK-RELEASE-100；正式版1.00收口）

## 正式版1.00收口（2026-10-03）

- 版本`1.0.0+9`，用户名称1.00。导入页可更换学校、管理页可新增；新增后返回导入确认，ID变化同步网址并重置同意，原档案/课表保留；异步导航校验当前route避免连续点击误退。专项7/7、全量395/395、analyze无问题、复审APPROVE。
- 发布/构建/签名/远端结果以`release_1.0.0.md`为准；旧章节中的“未提交/推送”是当时快照。
- `CONFIRMED`：Release/Debug均成功，元数据/签名/catalog/散列已核验；Release在API36模拟器安装/启动成功。GitHub源码历史/标签/发行版/三个附件已上传并读回，标签代码提交57a59ea；Gitee网页已登录，源码推送等待桌面Git认证，发行页已准备但未发布，不能宣称双远端完成。
- 真实学校/真机/iOS仍`UNVERIFIED`；当前huike构建沿用既有debug签名以兼容安装，生产签名未配置。

## 登录状态恢复（2026-10-03）

- 可信主frame401/明确重定向循环自动恢复一次，默认保留Cookie，网络错误/403不清；主动重登作补充。精确Cookie属性/已访问origin，未知或共享父域/iOS返回partial。旧原生上下文撤销后才清Cookie，旧回调与旧确认绑定generation，课表DB不变。
- `CONFIRMED`：真实API36/WebView133.0.6943.137 synthetic服务清理1/1及实际ImportWebPage自动401恢复1/1（无需点击按钮，重建一次后Cookie消失/200/导入就绪）；专项10/10、全量394/394、最终analyze/diff-check无问题，代码/安全复审APPROVE；已验前缀Cookie和其他host状态保留。
- `CONFIRMED`：Debug0.1.7+8，`build/app/outputs/flutter-apk/huike-20261003-login-recovery-debug.apk`；SHA256 `9404856E29E2FC370A1B0EB0D2BAE7341FA5AD067E04C59301146605897BEE59`，签名与上一轮一致，APKcatalog schema2。详见report_2026-10-03_login_recovery.md。无提交/推送。
- `UNVERIFIED`：真实学校/真机/iOS与截图内网连接中止的根因，不能宣称实际登录恢复。

## 首次使用与框架可靠性（2026-10-03）

- `CONFIRMED`：空库启动直接显示首页，不再强制填学校或网址，也不播种虚构学校。今日/整周均有导入入口，主动导入才显示学校/网址/校历表单；完成后provider切为风险确认页，保留返回首页的栈。已有课表和schema保持。
- `CONFIRMED`：UI专项29/29；补充320×568、字体1.3与真实router.pop回归通过，UI复审APPROVE。
- `CONFIRMED`：同源frame安全布尔探针、4秒有限采样、局部脚本作用域/owner桥/fetch/timer清理；严格CSP与下载正文取消缺口经复审修复。框架专项10/10、真实Android WebView synthetic1/1（API36/WebView133.0.6943.137）通过，含POST302/307、Cookie、严格CSP动态frame、完整URP、跨源不可读、旧timer与流式body取消。最终全量385/385、analyze无问题、复审APPROVE；详见report_2026-10-03_import_reliability_startup.md。
- `CONFIRMED`：新版Debug包`build/app/outputs/flutter-apk/huike-20261003-startup-import-debug.apk`，0.1.6+7、com.huike.huike_timetable、签名与上一轮一致、APK内catalog schema2；SHA256 `11EE9B94A17A64C0B9D44B3637BFE73959FC3806F9354810D1BEDB450F1B9B99`。未新建Release、未提交/推送。
- `UNVERIFIED`：真实学校/真机/iOS、完整ImportWebPage跨host确认UI/真实CAS、新窗口；仅URP在本轮实跑合成解析，其他三个脚本为源码兼容核对。独立WebView组件测试不等于完整App端到端。

## TASK-WEBVIEW-FRAMEWORK-01（2026-10-03，通用登录浏览器框架）

- `CONFIRMED`：昨日adapter更新未修改登录URL/平台权限/导航；候选脚本只在执行导入后运行，bootstrap不联网。没有发现直接导致截图加载失败的路径；昨日未验真实WebView登录。
- `CONFIRMED`：Android两个Client接入NavigationPolicy快照，已确认导航继续原请求，新主机仍确认；子frame原生检查scheme。加载失败安全提示/手动reload、导入门控、generation隔离旧尝试。无学校网址特例、schema或依赖升级。
- `CONFIRMED`：Java14/14、入口专项34/34、全量381/381、最终状态专项4/4、analyze无问题、复审APPROVE、汇课Release/Debug构建成功；详见report_2026-10-03_webview_framework.md。
- `UNVERIFIED`：用户手机对内网地址的路由、连接中止直接原因、真实登录/SSO/POST、真机/iOS。没有设备安装、提交或推送；框架修复不等于真实登录恢复。

## TASK-ADAPTER-GENERAL-01（2026-10-02，通用教务适配框架）

- `CONFIRMED`：catalog schema 2 分离 adapter family 与 school profile；支持精确名称/别名、精确 host/path、variant/options。真实学校 profile 目录为空，没有新增猜测映射；`courseFieldAliases` 接入统一 normalizer，可用同一 family 处理不同桥字段名。
- `CONFIRMED`：WebView 按学校配置、精确 URL、安全页面特征和剩余脚本兼容回退排序；探针只返回布尔/协议标记。四个本地脚本保留既有桥名/数据首参并携带尝试 ID，迟到 save/completion 不会污染新尝试。成功仍要求当前尝试完成且至少一门课程通过既有校验；失败提供按需查看/复制的固定码安全诊断。
- `CONFIRMED`：四类 synthetic bridge/page-feature fixture、profile alias/URL、两组同协议字段 option、旧 catalog schema 兼容、stale callback 与安全诊断测试通过。全量 **377/377**（`--concurrency 2`）、`flutter analyze --no-pub` 无问题、`git diff --check` 通过。`flutter build apk --flavor huike --debug --no-pub`成功，已核对`app-huike-debug.apk`内catalog为schema 2；详情与SHA-256见 `report_2026-10-02_adapter_framework.md`。
- `CONFIRMED`：没有更改 WebView 导航判定/跨 host 确认、导入确认事务、学校/学期隔离或手动课程写入；无 Drift migration，schema 仍为 3。未增加远端加载/更新或依赖。
- `UNVERIFIED`：四类脚本在真实学校/真实登录页的命中与字段覆盖、真实跨框架/网络行为、真机/iOS。fixture 是 bridge 与安全特征快照，不等同实际教务验收。无提交/推送。

## TASK-LOGIN-REPAIR-01（2026-10-02，旧入口自动修复）

- `CONFIRMED`：历史commit4f7cef7只更新新建学校默认入口、未迁移已有loginUrl；导入确认原本只记host、不保存更改的URL。两处实现缺口会让旧入口继续使用，不是按使用时长过期。
- `CONFIRMED`：学校首读前事务修复已知学校的失效默认root入口，其他自定义网址不动；确认进入导入后网址与host同事务保存、取消/非法不保存。课程/学期/主题不改。
- `CONFIRMED`：专项18/18、全量367/367、analyze/复审通过；Release/Debug构建与包名/版本/证书/哈希核对完成，本机入口正常GET200；验证/产物见report_2026-10-02_login_repair.md。手机旧档案与登录/实际导入仍`UNVERIFIED`。不自动放行新host，不改变HTTP确认/网络边界，无提交/推送。

## 全量完成度报告（2026-10-02）

- 报告：`report_2026-10-02_project_completion.md`。18个模块中12项核心实现齐备、3项部分完成、3项未实现；66.7%/83.3%仅为等权模块覆盖率，不是正式发布完成率。
- `CONFIRMED`：本轮全量362/362、analyze无问题、diff-check通过；rapid及最新light-launch-status两组APK哈希与专项报告一致，没有重建/安装/联网核对远端。
- 写报告期间三项UI任务已收口，按下节最新交付与report_2026-10-02_today_launch_root.md判断；完整今日页方案的其余部分仍未实施。
- 真实导入有09-14用户截图局部证据，完整验收待完成；iOS/真机GPU/新版覆盖安装仍`UNVERIFIED`。小组件/提醒/联网更新未实现，普通汇课正式签名未完成。未提交/推送，保留现有业务代码与改动。

## 2026-10-02 今日状态、浅色启动与底部手势（最新）

- `CONFIRMED`：今日蓝色横线移除，进行中课程卡右上淡底标签显示结束时刻、对应轴点蓝色；课前/课间显示距下一节时间，全天结束仅灰色文字。未知时间混入不宣称全结束，卡片字段与现有点击保持。
- `CONFIRMED`：启动保留原矢量标志，浅色#F5F6F9品牌层/「汇课」在就绪后280ms退场；首页不透明、第一触摸立即完成装饰，Reduced无过渡、不重播。Android日夜启动底色与系统栏均浅色；品牌前景接管系统栏，过渡到目的主题时按背景亮度选图标。iOS原生白底保持。
- `CONFIRMED`：底部272×64控件内滑动（左今日/右周课表）与点按均可切换；控件外无根分支切换手势，取消/Reduced/分支保留验证通过。
- `CONFIRMED`：最终全量362/362（concurrency2），analyze无问题、复审APPROVE、资源校验通过；Release/Debug构建见report_2026-10-02_today_launch_root.md。设备/GPU/iOS仍`UNVERIFIED`，不改数据库/导入机制，无提交/推送。
- 导课截图加载旧jwxt域名，当前代码预设为既有IP入口；本机旧地址HTTP无响应/HTTPS握手失败，IP入口HEAD403但正常GET200。未改用户已存网址、未尝试登录，手机网络可达性未知。

## TASK-PREVIEW-RAPID-01（2026-10-02，最新连续操作规则）

- `CONFIRMED`：Weekly预览开始关闭后遮罩/面板立即放行点击；新课程或同课程点击通过generation key取消旧关闭ticker、从当前进度重开；旧完成回调不清新预览。编辑待执行导航保持所有权。
- `CONFIRMED`：箭头立即换周/换网格，标签轻量动画不阻塞；新的横向拖动可结束上一段落位并接受本次手势，普通点击/纵滚不提前提交。保留每次手势单周、取消回弹、边界与多指规则。替代旧“落位期间整次忽略”合同。
- `CONFIRMED`：全量355/355、analyze无问题、代码复审APPROVE；预览先复现关闭40ms后点击无响应，再回归通过。APK见report_2026-10-02_rapid_interaction.md。
- 今日页改版仅整理proposal_2026-10-02_today.md，未实施；用户设备/iOS/GPU帧率仍`UNVERIFIED`。保留既有改动，无提交/推送。

## TASK-COURSE-HUES-01（2026-10-02，最新课程色规则）

- `CONFIRMED`：16色覆盖红橙黄绿青蓝紫粉，明暗分别统一明度/饱和度；替代上一轮冷色色板。Today/Weekly共用，hash/16色取模/数据库字段不变，既有动画与节次提示保留。
- `CONFIRMED`：专项8/8，明暗8个色相区间覆盖、16色唯一/不透明、正文对比度≥4.5；明暗360/430dp合成静态渲染检查通过，代码复审APPROVE。构建结果见report_2026-10-02_course_hues.md。
- `UNVERIFIED`：真机视觉与GPU流畅度、iOS；本轮只改色板，上一轮全量349/349为历史验证。本轮不承诺不同课程绝不重复颜色（名称hash仍可能同余）。

## TASK-TODAY-MOTION-COLOR-01（2026-10-02，当前课程色与今日过渡）

- `CONFIRMED`：课程16色改为蓝/青/绿为主的冷色配对，保留原hash、colorKey、纯色底与明暗文字对比度≥4.5；替代前轮混合粉橙紫色板。用户未回复可选配色询问，按已说明推荐方向落地。
- `CONFIRMED`：今日预览透明PageRoute不再整层Fade/Slide；只对终态尺寸面板平移、遮罩颜色独立变化，同一曲线映射保证入场中Back不跳变，Reduced无位移。Today source不挂Hero，详情复用glassPage且不重复渐显正文；Today预览/详情父面板和按钮不采样BackdropFilter。Weekly路径保持前轮规则。
- `CONFIRMED`：Weekly横穿课程的蓝杠撤除，当前节次改左轴「当前/4节」式文字提示，IgnorePointer、不遮课程；仍按学校作息节次显示，不声称精确分钟线。
- `CONFIRMED`：全量349/349、实画/交互专项47/47、analyze无问题、独立复审APPROVE；合成数据明暗360/430dp静态检查完成。安装包与证据见report_2026-10-02_today_motion_color.md。
- `UNVERIFIED`：无连接设备，真机GPU/60Hz/高刷流畅度与安装、iOS、真实教务未验；结构减负不等于真机卡顿已消除。保留未提交改动，无提交/推送。

## TASK-VISUAL-RETURN-01（2026-10-02，当前视觉规则）

- `CONFIRMED`：Android adaptive/monochrome及Android 12+启动标志改为独立矢量资源；保留旧Flutter标志与PNG/iOS fallback。所有adaptive路径顶点在66dp安全圆内，不再复用低分辨率launcher前景放大。
- `CONFIRMED`：课程16色改为直接定义的明亮纯色/夜间深色，不再由灰暗基色混白；原hash、colorKey、数据库均不变，文字对比度≥4.5。
- `CONFIRMED`：Weekly预览使用终态尺寸底部平移，不接source几何；正文全程保留，背景不缩放、遮罩不模糊，仅压暗。父面板blur22和单次关闭状态机保持。启动取消全屏Opacity，保留一次性4dp平移与Reduced Motion。
- `CONFIRMED`：专项36/36、全量342/342、analyze无问题、独立复审通过。产物、资源验证与边界见report_2026-10-02_visual_return.md；保留前轮未提交改动，无提交/推送。
- `UNVERIFIED`：未连接设备，用户真机启动/桌面清晰度、60Hz/高刷返回流畅度与iOS未验；不把减小代码渲染工作等同于卡顿已消失。下方早期任务为历史快照，本节替代其视觉规则。

## TASK-LEGACY-UPGRADE-01（2026-10-01）

- 用户明确要求旧图标、Debug APK直接覆盖旧应用并保留原数据；Android新增huike/legacyUpgrade发行类型，普通应用身份保持，兼容包使用既有应用ID与更高versionCode。
- `CONFIRMED`：图标恢复蓝色Flutter标志；15张Android PNG、15张iOS PNG与槽位/原图字节/引用校验通过。唯一生成入口tools/make_icon.py从入库模板原样复制。
- `CONFIRMED`：旧schema1文件只读导入目标schema3；beforeOpen阻塞首读，整体事务/成功marker，已有学校不覆盖。学期、课程、自定义节次与主题保留，学期名归档为显式元数据，未知设置不复制。迁移专项8/8。
- `CONFIRMED`：正式签名兼容Debug包证书与旧正式APK一致，包名一致，versionCode10006高于已核对旧universal版4；最终产物与验证见report_2026-10-01_legacy_upgrade.md。用户真机/iOS `UNVERIFIED`。
- `CONFIRMED`：最终全量341/341、analyze无问题、图标检查与diff-check通过；正式/Debug证书分别匹配对应旧安装，旧1.0.1/1.0.2/1.0.3正式证书一致。迁移失败提示/重试和导入回归14/14；独立复审通过。未提交/推送。

## TASK-SCHOOL-URL-DIALOG-01（2026-10-01）

- `CONFIRMED`：修改教务网址关闭时提前释放 TextEditingController，先触发 disposed 异常，再触发与用户截图一致的 `framework.dart:6281 _dependents.isEmpty` 焦点组件断言。修复为输入框自主管理控制器，通过 onChanged 读取文本，保存前检查页面 mounted。
- `CONFIRMED`：专项 6/6、全量 332/332；保存 HTTP/HTTPS、取消、空值/非法网址、遮罩与系统返回、重复打开均覆盖退出动画帧和数据库结果。详见 `report_2026-10-01_school_url_dialog.md`。
- `UNVERIFIED`：用户真机/iOS复测；保留原未提交改动，无提交或推送。

## TASK-UI-COMPACT-COLOR-01（2026-10-01）

- `CONFIRMED`：学校管理移除添加学校按钮；学校切换、编辑地址、删除仍沿用原实现。初始化建校路由保留；ISSUE-019 的该 UI 触发入口已撤除，未修改 redirect。
- `CONFIRMED`：Today 常规卡片最小高度 134 × 0.75 = 100.5dp；宽度和字号保持可读，短信息同行，名称、地点、教师、周次、备注不限行，长内容自然撑高。
- `CONFIRMED`：共享课程色板扩为16色；Today/Weekly 每卡使用不透明纯色底，无渐变。hash/数据库不变，取色模数从8变16，部分既有课程显示色会变化。
- 验证与边界见 `report_2026-10-01_compact_color.md`；原未提交改动保留，无提交/推送。

## TASK-PERF-BLUR-01（2026-10-01）

- `CONFIRMED` / **EMULATOR PROFILE EVIDENCE**：API 36、60 Hz、Impeller OpenGLES profile，
  A–H 每组预热后 3 次。单关 Sheet/Preview 面板无稳定明显收益；下层 Weekly glass 与
  Preview 嵌套按钮各为组级 `CONTRIBUTOR`；同时关闭 Weekly/Preview glass、保留 Sheet
  为 6.162–7.947 ms。不能按层数外推性能，也未排序每个下层控件。
- 仅 Weekly Preview 的 X/详情/编辑按钮复用父面板 sigma 22 的模糊；GlassButton 可选
  blurSigma 默认 null。Today、全屏 Sheet blur、几何/关闭状态机、RepaintBoundary 均保持。
  最终三次 open Raster 21.026/22.202/24.841 → 18.205/17.553/18.441 ms，
  峰值中位数约下降 18%；UI 无超预算。**仍有 Raster 超预算，不宣称达到帧预算**。
- `CONFIRMED`：模拟器 Light/Dark、open/close 抽帧、长拖/短拖回弹、实际 Reduced Motion
  检查；连续 60 Hz 视觉、真机/iOS/release/14+ 节仍 `UNVERIFIED`。
- `CONFIRMED`：analyze 无问题，全量 **322/322**，Preview 专项 **27/27**；临时接线完全
  移除，main/GlassSurface/GlassSheetHost 开工哈希恢复。APK 与最终 diff 结果见报告。
  未清理旧批次、提交或推送。逐帧证据与离群关闭帧保留在
  `evidence_2026-10-01_blur_profile.json`；完整结论见 `report_2026-10-01_perf_blur_01.md`。

## TASK-WS-AUDIT-01 工作区盘点（2026-09-30，只读）

- `CONFIRMED`：工作区即 2026-09-28 批次的未提交改动——15 个修改文件（lib 7、knowledge 7、
  test 1，+776/−236）+ 22 个未跟踪文件（knowledge 18、test 4），逐项映射到
  TASK-DATA-INTEGRITY-01、TASK-CALENDAR-DATE-01、TASK-PREVIEW-BACK-01、
  TASK-PREVIEW-GEOMETRY-01、TASK-WEEKLY-PERF-PROFILE-01 与两轮审计/ISSUE-019 诊断，
  无孤儿改动、无文档与代码冲突。本地 master = origin/master = `7bc4f10`，已提交内容全部推送。
- `CONFIRMED`（当日复验，`S:\`）：analyze 无问题、全量 **314/314**、`git diff --check` 通过；
  `app-debug.apk`（207,132,994 字节）与 `huike-0.1.4-release.apk`（63,982,250 字节）
  SHA-256 复算与既有记录逐字一致。
- 待处置：① 删除 `.playwright-mcp/` 遗留截图并把该目录加入 `.gitignore`；
  ② 本批改动已滞留 2 天未归档，建议按 2026-09-27 模式提交并推送（推送需用户令牌）。
  详见 `report_2026-09-30_workspace_audit.md`。

## TASK-WEEKLY-PERF-PROFILE-01（2026-09-28）

- `CONFIRMED`：Android 16/API 36、60 Hz 模拟器 profile 中，Weekly 切周多次采到超过 16.7 ms 的代表帧；但慢帧总数/频率未可靠统计，warm revisit 的 UI 40.8 ms 为单次峰值，未证明持续掉帧或 cold mount 更慢。
- `CONFIRMED`（范围仅限当前模拟器 Preview-open）：启用 blur 的三次代表 Raster 帧为 34.9–37.2 ms；临时 profile-only 绕过 `GlassSurface` 与 Sheet blur 后为 5.9–7.2 ms，几何与动画保留。表明 blur/filter 工作与该路径 Raster 峰值强相关，但没有隔离各个滤镜层，也不外推到真机。
- `NOT OBSERVED`：静止约 15 秒未产生新帧；无 blur A/B 的 Preview-open 代表帧未超预算；没有可重复 cold > warm 差异。
- `UNVERIFIED`：14+ 节滚动、真机/iOS、release、具体 repaint 区域与慢帧频率。AVD 仅有 10 条节次时间配置，未添加合成数据。
- 最终 `flutter analyze --no-pub` 无问题、`flutter test --no-pub` 314/314、Debug APK 构建成功（207,132,994 字节）、`git diff --check` 通过；无生产行为更改，A/B 开关已恢复。详见 `report_2026-09-28_weekly_perf_profile_01.md`。

## TASK-PREVIEW-GEOMETRY-01（2026-09-28）

- `CONFIRMED`：Weekly Preview source 使用点击 Course Block 的 `RenderBox.localToGlobal`；纵向滚动偏移包含在采样位置。destination 在 Preview 正常底部约束下经透明首帧实际布局测量；两者转换至 `GlassSheetHost` Stack-local 后 `Rect.lerp`。移除原 `size.height * 0.5` 与整张 Preview 的非等比 scale。
- `CONFIRMED`：10 个几何 Widget 用例覆盖 640/1000dp viewport、点击起点、14 节滚动起点、终点与实际测量内容重合、Reduced Motion、resize fallback、反向回源/单回调、关闭时 source 已失效 fallback、source 移位与拖动跟手/回弹。定向几何 10/10；最终全量 314/314；基线 304/304。
- `CONFIRMED`：关闭仍服从 TASK-PREVIEW-BACK-01 状态机；destination/source 不可测或运行时 Host 几何环境变化时回退至底部位移。未保存 RenderObject，关闭时通过 GlobalKey 查询存活 source。
- `UNVERIFIED`：模拟器实画、Android 真机、iOS、旋转/resize 动画、predictive back 几何联动、极端快速触摸与性能 profile。`flutter build apk --debug --no-pub` 按本批计划 `PENDING`。

## 统一 Debug APK（2026-09-28 17:01 +08:00；早于 TASK-PREVIEW-GEOMETRY-01）

- `CONFIRMED`：在 `S:\` 执行 `flutter build apk --debug --no-pub` 成功；产物 `build/app/outputs/flutter-apk/app-debug.apk`，207,125,368 字节，SHA-256 `90cda25ad60f05b6d4b97d763d0585196ee49b2e570b9a0d6a3e5bd8849f965c`。基于当前未提交工作树，未提交或推送；此前全量 304/304 测试和 analyze 无问题。未安装到设备，真机/iOS 行为仍 `UNVERIFIED`。

## TASK-PREVIEW-BACK-01（2026-09-28）

- `CONFIRMED`：Weekly Preview 仍为页内 `GlassSheetHost`；Android Back 由 `TimetablePage` 的 `PopScope` 在 Sheet 存在期间消费并请求关闭。X、背景、下拖及编辑入口共用关闭状态机；仅动画正常完成后一次回调清理。完整详情仍只 push，不关闭 Preview。
- `CONFIRMED`：9 个 Widget 测试覆盖 Back、双 Back、关闭中 Back、两入口交叉、下拖/回弹、Reduced Motion、重新打开和编辑路由；基线 295/295，最终全量 304/304。静态分析与 diff check 结果见专项报告。
- `UNVERIFIED`：Android 真机 predictive back、iOS 手势、极端高速触摸。APK 依用户要求待本批任务结束统一构建。

## TASK-CALENDAR-DATE-01（2026-09-28）

- `CONFIRMED`：校历例外新增优先今天、编辑优先已有日期；两者均按既有学期日期范围夹取，历史和未来学期可打开 DatePicker。`firstDate` / `lastDate` 计算未变。
- `CONFIRMED`：新增 5 个 Widget 行为测试覆盖当前、历史、未来、合法旧日期和越界旧日期；修复前 3 个边界场景失败，修复后均通过。基线 analyze 无问题、290/290；最终 analyze 无问题、295/295、Debug APK 与 diff check 通过，见专项报告。
- `INFERRED`：学期设置页若读到 2020–2040 之外的已保存开学日期，其固定范围 DatePicker 可能有同类断言；本轮只审查，未改此页。
- `UNVERIFIED`：真实设备日期选择器与 iOS。

## TASK-DATA-INTEGRITY-01（2026-09-28）

- `CONFIRMED`：导入课程 ID 现在按 `schoolId + semesterId + 课程内容` 稳定计算；同校不同学期同课程可共存，同学期重导仍按 `(schoolId, semesterId, source=imported)` 删除后重建。旧格式 ID 在下一次同学期重导时随旧行删除，自然换为新 ID。
- `CONFIRMED`：`CourseRepository.confirmImport` 用一个 Drift 事务顺序写入选中的作息、课程和选中的学期配置；内部原始写入步骤不再各自开事务。定向故障注入验证课程写入失败与学期更新后失败均回滚全部旧数据。
- `CONFIRMED`：基线 283/283；当前全量 290/290、`flutter analyze --no-pub` 无问题。Debug APK 构建及最终 `git diff --check` 结果见本轮报告。
- `UNVERIFIED`：真实教务端到端、真机和 iOS。本轮不处理 Preview/Motion 其他问题。

## 归档与推送（2026-09-27 17:11–17:15 +08:00）

- 自 2026-09-15 起一直留在未提交工作区的 TASK-013～TASK-026 改动已整体归档为三笔提交：
  `e804223`（17:11:01）图标与启动底色（TASK-026 与 TASK-022B 的 Android 资源部分）、
  `f9eccc9`（17:11:28）Weekly/Today、Liquid Glass、动效、测试与知识库（0.1.4+5）、
  `5e5972a`（17:12:02）归档与推送记录。工作区已干净。
- 归档前验证（2026-09-27 17:09 跑完）：`S:\` 下 `flutter analyze --no-pub` 无问题、
  `flutter test --no-pub` **283/283**；推送前敏感扫描无凭据命中（命中的都是 third_party 源码与
  策略文档表述），构建产物未入库。
- `CONFIRMED`（2026-09-27 17:12）：**已推送 Gitee**——用户提供令牌后以
  `git -c credential.helper= -c http.extraHeader="Authorization: Basic …"` 推送成功，
  远端 master 由 `79c9267` 前进到 `5e5972a`；**无令牌** `git ls-remote origin master` 读回同一
  提交 `5e5972a83b5dea234adb0cca3de6a1aa3770bba6`，本地与 origin/master 已一致（0/0）。
  推送前本地 `origin/master` 引用是陈旧的（停在 `5a6bbf0`），实际远端早已含 0.1.1～0.1.3 的
  5 笔提交（`bd0ecc8`…`79c9267`），即本轮真正新传的是 3 笔归档提交。
- `14c1b52`（17:14:48）记录推送结果、`e907d52`（17:23:01）记录发布结果，两笔随时推送。
- 发布：见下方「发布 v0.1.4（2026-09-27 17:20–17:22 +08:00）」一节。核对 Gitee API 时发现
  `v0.1.2`(1143378) 与 `v0.1.3`(1143514) 也早有 release 与 APK 附件（都创建于 2026-09-14），
  知识库此前只记到 `v0.1.1`，本次一并补记。
- 下方各任务段落结尾的「未commit/push」是当时轮次的状态记录；归档与推送结果以本节为准。

## 发布 v0.1.4（2026-09-27 17:20–17:22 +08:00）

- `CONFIRMED`（2026-09-27 17:20:01）：release APK 由 `S:\` 下
  `flutter build apk --release --no-pub` 产出（`build/app/outputs/flutter-apk/app-release.apk`），
  17:20:30 复制为发布名 `build/huike-0.1.4-release.apk`：通用包 arm64-v8a / armeabi-v7a / x86_64，
  **63,982,250 字节**，SHA-256 `720f0eb1d342b1c6936e5b13ec7dd4c99f1029f408a9df8ac60fb2f4bc5cb545`。
  `aapt2 dump badging` 读回 versionCode 5 / versionName 0.1.4 / minSdk 24 / targetSdk 36 /
  label「汇课」，manifest 含 `networkSecurityConfig`（明文 HTTP 策略沿用 2026-09-13 的口径）。
- `CONFIRMED`（2026-09-27 17:20:53）：annotated tag `v0.1.4` → `14c1b52`（发布时的 master HEAD，
  含本日三笔归档提交），随即推送。
- `CONFIRMED`（2026-09-27 17:21:36）：Gitee release id `1170081` 创建完成，随后上传附件
  <https://gitee.com/chenxihh/huike/releases/download/v0.1.4/huike-0.1.4-release.apk>（17:22 完成）。
  中文名与正文经 UTF-8 文件传参写入，读回无替换字符；**无令牌** HEAD 该附件返回 `200`、
  `Content-Length` 与本地一致（17:23 复核）。
- 历史上已有的 release：`v0.1.1`(1143273)、`v0.1.2`(1143378)、`v0.1.3`(1143514)，均挂 APK。
- 签名仍是 Flutter 默认 debug 证书（ISSUE-006 未决），release 正文已标注「仅内测分发」。

## TASK-020B Floating Liquid Glass Switcher

- Today / Weekly复用既有路径成为StatefulShellRoute两个保留分支，默认Weekly；普通子路由不变。
- 底部中性Glass岛仅root可见；单capsule与内容共享280ms easeOutCubic，内容12dp+fade。Reduced直接到位。
- Weekly非当前周、Today滚动保持；无root横滑；FAB只上移80dp避让，不改变grid viewport。
- 基线268/268；新增15例，最终283/283、analyze无问题、Debug APK与diff check通过。
- API36约390dp明暗双向录屏/抽帧已查，返回第2周保持；69个保护文件哈希未变。真机/iOS/GPU帧耗时UNVERIFIED。
- 详细文件与验证见report_2026-09-27_root_switcher.md；未commit/push。旧TASK-020B移除summary记录属于前一次范围。

## TASK-026 App Icon

- 附件指定单方案：三厚圆角白课程块向中心汇聚，纯冷蓝#3057D5；中间长20%，上下内倾9°，无字/日历细节/Glass层。
- 复用既有Python与flutter_launcher_icons；Android 5legacy+5foreground+5monochrome、iOS全部21PNG/25slot更新；16% adaptive inset保留，66-unit安全圆及三mask×48/64px通过。
- analyze无问题、268/268、Debug APK与diff check通过；API36 Launcher/Recent Apps/Settings应用列表已查。Android真机/其它launcher与iOS设备UNVERIFIED。
- 全部79个Flutter源码哈希未变，未改签名/依赖/锁文件；历史候选保留但无活动引用。未commit/push，见report_2026-09-27_app_icon.md。

## TASK-022B 启动连续性

- 保存主题首帧解析、初始数据ready与一次性180ms/4dp/92%→100% reveal；Reduced直接显示，初始环境背景持续可见。
- Android旧版/12+启动和窗口背景对齐App基础明暗色，保留品牌；系统与App固定主题相反时仍有预期颜色切换。
- 基线262；新增6例，268/268、analyze/build/diff check通过。API36四模式cold/warm及前台恢复已执行，静态画面已查；完整GPU动效、非空课程真机/iOS与耗时无回归仍UNVERIFIED。
- 不改普通transition/Weekly/Today/Preview/Import/DB/导航架构，不新增package；无commit/push，详见report_2026-09-27_launch_motion.md。

## TASK-022A 普通Motion审计

- 普通页面短距离12dp+opacity，Dialog8dp+opacity；集中280/180/90ms语义token。iOS保留原生边缘返回，Reduced无translation/scale。
- 学期Sheet补统一曲线；菜单统一尺寸/opacity且关闭完成再隐藏，删除旋转；普通Detail删除重复分批淡入；按压/焦点/Snackbar局部统一。
- 基线252/252；新增10例，最终262/262、analyze无问题、Debug APK成功、diff check通过。四种明暗/Reduced widget画面人工检查；无设备，真机/GPU/iOS设备仍UNVERIFIED。
- 未修改Weekly分页、Today布局、Preview专用transition/dismiss、Import内部或启动；详见report_2026-09-27_motion_audit.md。未commit/push，完成后停止。

## TASK-021 Today Compact Semantic Timeline

- Today由固定164dp节次轨道改为内容高度课程节点、连续左侧时间轴、分级16/24/40dp空档。普通卡最小134dp，内容增多自然长高；duration与卡片高度无关。大标题30sp缩至22sp。
- 当前时间采用单个语义标记：进行中关联课程节点、课间放在两课之间、首课前与末课后有状态带；无有效时间不伪造节点。30秒检查设备时间，分钟变化更新状态，dispose取消timer。
- 复用CourseTimeService、Glass/tint、Today CourseHero及既有/today/course/:id预览路径；预览类原文保留，不改router或全局Motion。
- 基线analyze无问题、232/232；新增20例涵盖时长独立高度/内容增高、空档、排序、全部时间位置、未知/空/单课/四课/重叠及360/390/430×1.0/1.3×Light/Dark。390dp中文字体widget渲染已检查，不等同于设备验收。
- 最终analyze无问题、252/252通过、生产Debug APK成功、diff check退出0；详见 `report_2026-09-27_today_semantic_timeline.md`。全部Weekly源码哈希保持开工时内容。未commit/push/reset/clean，不开始其它任务。

## TASK-020B Separate Today From Weekly

- Weekly删除Today摘要整条（课程数量、下一节、课名及相关summary计算），学校行增加明确的「今日」按钮复用既有`/today`。周导航之后直接接星期栏/网格，无横条占位。
- 删除不再被使用的`today_glass_shortcut.dart`；不改TodayPage、Timeline、router、Weekly paging、Course Block或其它禁止范围。
- 基线analyze无问题、229/229；新增360/390/430dp ×1.3字体三例：Weekly无summary、七列/顶部衔接、今日按钮44dp目标、选择其它周后Today仍显示今天课程、返回保留所选周；原Today预览/详情测试保留。
- 最终analyze无问题、232/232通过、生产Debug APK成功、diff check退出0；详见 `report_2026-09-27_separate_today_from_weekly.md`。本轮无设备验收，不开始Timeline重构，未commit/push。

## TASK-020A Weekly Swipe Paging

- 单次手势的资格在 down 时锁定；落位/回弹期间开始的整次手势忽略。drag end 在启动弹簧前消费会话，取消手势只回弹；成功提交仍只由 pager 完成回调修改一次周次。
- 保留三页1:1跟手、15%页宽距离阈值、380px/s速度阈值、原有箭头切周路径。共享offset现在也跟随弹簧更新。
- 基线 analyze 无问题、217/217。新增12个widget行为测试验证双向普通/高速/超长拖动、阈值回弹、连续独立手势、动画中触摸、cancel、箭头、Reduced Motion、第二指取消及标题/网格日期一致性。
- 单次高速/超长连跳在原实现widget测试中未复现；已复现cancel错误提交，确认原实现允许动画接管且缺少明确会话消费。最终验证见 `report_2026-09-27_weekly_swipe_paging.md`。本轮设备/真机/iOS交互为 `UNVERIFIED`。
- 仅修Weekly pager，不启动Today或全局Motion；保留既有未提交改动，无commit/push。

## TASK-019 最后视觉收尾（当前策略）

- 本轮用户要求玻璃优先、课程色次之，覆盖下方 TASK-019D 的明显色差要求。
- 仅调整 `timetable_course_block.dart` 的 fill/border/glow：浅色 tint 8–10%，深色12–16%，中性边框仅混入6%课程色；更透明的基底与左上微亮反射。不新增模糊、装饰条或依赖。
- 三字段、字号、compact地点、测量/空间分配、10/12/14节、冲突与切周均未修改；所有禁止范围保持本轮开始时内容。右下角加号遮挡仅记录，不修复。不开始TASK-020。
- 本轮验证详见 `report_2026-09-26_weekly_glass_surface.md` 顶部最终收尾记录；旧段落为历史快照。

## TASK-019D 历史增量（已由最后视觉收尾覆盖）

- 用户明确要求明显课程色差，覆盖前版过于克制的染色要求：保留课程色相，提高Weekly材质饱和度至0.70，整面渐变各处都有染色；light混色alpha为0.23–0.32，dark为0.20–0.28，按压略增强。
- 小号地点/教师文字由palette secondary向ink混合50%，配合彩色背景维持可读性；八色、明暗、静止/按压状态及两种基底的对比度测试均≥4.5:1。
- 仍无独立竖条、保持3dp卡间距和固定网格；下方019B/C是历史增量，当前色彩以本段为准。
- `CONFIRMED`：API36约390dp七色Light/Dark实画已检查；analyze无问题、217/217、生产Debug APK与diff check通过。真机/iOS未验。

## TASK-019C 当前增量

- 用户反馈前版课程边界难区分；恢复卡片间3dp间隔，以完整0.9dp中性色混tint边框、微弱投影及较清楚的玻璃基底分离课程。
- 不恢复独立竖条，三字段、字号和固定10/12节一屏策略保持；以下TASK-019B材质数值为历史增量。
- `CONFIRMED`：API36约390dp七门相邻课程Light/Dark截图已检查；analyze无问题、215/215、生产Debug APK及diff check通过。真机/iOS未验。完整说明见TASK-019B报告追加的TASK-019C记录。

## TASK-019B 当前增量

- `CONFIRMED`：Weekly 彻底删除独立课程色竖条、横向占位及 marker 常量；文字仅留左右各1dp，释放4dp宽度。
- `CONFIRMED`：课程颜色融入三段低透明度整卡渐变、均匀0.7dp半透明边框与极轻 tinted shadow；按压时 tint/边缘略增强。没有独立彩色装饰区、连续实心边条或逐卡 BackdropFilter。
- `CONFIRMED`：API 36 约390dp 匿名七色课程 Light/Dark 实画，颜色克制且可区分，三字段可读；仍12节一屏。
- TASK-019B 验证收口见 `report_2026-09-26_weekly_glass_surface.md`。TASK-019 下方描述为前一增量，当前视觉以本段为准。

## TASK-019 当前增量

- `CONFIRMED`：Weekly 普通两节课块依次显示名称、compact 地点、教师；不绘制起止时间。
  使用主题合并后的样式测量真实行数，先为每项预留一行，再补足地点/教师换行，最后扩展名称。
  极短空间依次保留名称、地点、教师；长名称在固定高度内最多四行并可淡出，不反向扩大网格。
- `CONFIRMED`：compact 地点仅展示时移除开头校区；实训中心前的东西南北区可移除。
  原始地点、导入与数据库保持不变；无已知校区结构的地址不猜测缩写。
- `CONFIRMED`：360/390/430dp、文字 1.0/1.3 下 10/12 节一屏，14 节保留网格纵向滚动。
  本轮 API 36 模拟器约 390dp 的匿名有课周已检查 Light/Dark；真机/iOS 未验。
- 详细测试结果与边界见 `report_2026-09-26_weekly_information_density.md`。

## Project Boundary

- `CONFIRMED`：本目录是独立 Git 仓库（`D:\桌面\汇课`），是「汇课」多校通用课表 App 的唯一代码与知识库。
- 本项目与任何单校课表项目相互独立：不共享代码、数据库、签名或知识库；公开文档中不出现彼此的名称与归属关系。
- 参考与引用边界：教务适配脚本来自社区开源仓库（MIT），署名固定在 `THIRD_PARTY_NOTICES.md`，不得删除。

## Handoff

- 完整交接报告：`knowledge/report_2026-09-14_handoff.md`（文件地图、适配契约、错误报告、
  恢复命令）。新会话接手请先读它。**注意**：该报告写于 2026-09-14（`0.1.1+2`），版本号、tag、
  测试数字与文件地图已过时（顶部有 2026-09-27 提示），仍有效的是适配契约、安全边界与
  Gitee 推送/发版的坑；当前状态以本文件顶部两节为准。
- 前一份：`knowledge/report_2026-09-13_handoff.md`（正文为 09-13 状态，含上传模板；
  其中「今日时间轴 / 整周槽位网格」的描述已被 TASK-011 取代）。

## Current Milestone

`TASK-019` 已完成，其上至 `TASK-026` 的全部改动已于 2026-09-27 归档提交（`e804223` + `f9eccc9`）、
推送 Gitee 并随 v0.1.4 发布，工作区干净（见「归档与推送」「发布 v0.1.4」两节）。下方 TASK-011～018 段落是版本历史快照；当前 Weekly 行为以 TASK-019 增量、Working Features 与实际代码/测试为准。历史模拟器与测试数字不代表本轮验证。

TASK-001（基座）+ 用户第一轮反馈迭代（自动适配探测、印章行楷图标、
横向周历今天优先、南工内置档案与变体作息、卡片信息完整、晚上两节）
全部完成并经模拟器实测。当前版本 `0.1.4+5`（含 TASK-011 首页信息架构重做、
南工教务地址修正与老学校变体补齐、TASK-014 Weekly Timetable、TASK-015
动态玻璃 + 课程内容完整显示）。
应用图标为「朱砂印章 + 华文行楷汇 + 内框」（用户两轮否定日历卡片方案后定稿；
候选与生成脚本在 assets/icon/candidates/ 与 tools/make_icon*.py）。
2026-09-14 完成 TASK-004/009/010/011：校历例外、导入链路收口、「新历书 × 校园线路」
UI 融合，以及首页信息架构重做（今日改为当日议程、整周改为七日议程，撤销节次轨道与
站点概览装饰）。2026-09-15 完成 TASK-013：整周日期改回周一 → 周日自然顺序、当前周
以今天为初始视口锚点（周日后不再循环接回本周一），整周课程改为复用
`CourseListingRow` 的排印列表，并加上长按周次的学期翻页彩蛋。
2026-09-22 完成 TASK-014：旧「今日 / 整周」双入口被 Weekly Timetable 取代，首页直接
显示周一至周日二维网格；手机把两节组成一个紧凑视觉时段（仍以单节为精确定位单位），
课程预览、冲突布局、周滑动、明暗模式、Reduced Motion 与可访问语义均已接线。
2026-09-23 完成 TASK-015：建立 `lib/core/glass/` 统一动态玻璃系统（触摸跟随高光、
按压弹簧、Sheet 进度同时驱动背景缩放/模糊/压暗、跟手切周），并把课程块改成
「内容测量驱动行高」——课程名称、地点、教师、起止时间一律完整折行显示，
禁止省略号，空间不足时课表变高并纵向滚动。
2026-09-24 完成 TASK-018A：修掉 Liquid Glass 引入的布局回归——`GlassButton` 在
`Scaffold.bottomNavigationBar` 的松约束下纵向撑满整屏，把「导入教务课表」「创建学校」
「导入预览」三页 body 挤成 0 高、CTA 恒不可用（ISSUE-017）；导入入口补齐加载/失败/空态，
底部 CTA 补键盘高度；离开导入 WebView 时不再抛 dispose 期异常，内存导入会话确实被清空
（ISSUE-018）。下一步是用户本人执行 TASK-006 真实教务导入验收。

## Working Features

- Flutter Android/iOS 工程；Riverpod 3 + GoRouter + Drift/SQLite 单机架构，与设计文档一致。
- 多校数据模型（schema **v3**：v2 的 `schools.presetId`/`scheduleVariantsJson` 基础上，
  v3 新增 `calendar_exceptions`（校历例外），见 `app_database.dart` 的 `schemaVersion => 3`）：
  `schools`（用户显式创建，含导航白名单）、
  `semesters`（属于学校，开学周一 + 总周数）、`course_entries`（`schoolId` + `source=manual|imported`）、
  `section_time_entries`（每校一套默认作息，含时段分组）、`calendar_exceptions`（调休/停课）、`settings`。
- 没有任何内置默认学校/学期/作息覆盖路径：`ensureDefaults()` 为空壳，播种只发生在创建学校时一次。
- 通用兜底作息（8:00 起上午四节、14:00 起下午四节、19:00 起晚间 9/10 两节，**共 10 节**），
  仅作播种，`BellSchedule.equalsFallback()` 用于判断「未被修改」。
- 导入链路（TASK-001 核心，TASK-009 修复）：风险确认门（明文 HTTP 额外警示）→ 受限 WebView
  （导航放行范围 = 入口地址 + 学校档案已确认主机 + 会话中新确认主机；主框架跳新主机时
  弹窗确认一次并记住，只增不减）→ 注入社区契约桥 → 点「执行导入」后由catalog schema 2
  的 School Profile / adapter family、已保存adapter偏好、精确URL规则与页面布尔特征排序候选，
  最后兼容回退剩余内置适配器。用户看不到逐个尝试过程；每次尝试用attemptId隔离迟到桥回调，
  脚本之间间隔800ms，桥弹窗打开时暂停该次超时→
  脚本回传数据全部暂存内存 → 预览页（新增/移除/修改/无效四类明细 + 附加选项）→
  确认后事务替换 (schoolId, semesterId, imported)。当前attempt完成且至少一门课程通过规范化才算匹配成功；
  全部失败默认只给可操作提示，用户主动请求时可查看固定码安全诊断。
  手动课程永不触碰。
- 教务地址校验统一在 `features/schools/services/login_url_policy.dart`（`checkLoginUrl`），
  引导页建校、学校管理改址、导入入口三处共用；http/https 都收，明文由入口额外警示
  （DEC-006，杜绝同一策略多处各写一份）。
- 校历例外「调休 / 停课」：设置里按日期维护，只表达两种语义——**这天停课**，或
  **这天按某个星期的课表上课**（如周六补周四的课）；同一天只保留一条，再填即覆盖。
  折算逻辑是纯函数 `CalendarExceptionService.resolve(date)`，今日页与整周页共用
  （今日：停课显示空状态牌、调休显示「今天按周X的课表上课」；整周：列头给
  「停课 / 调休 · 按周X」小签，课程按折算后的星期取）。换学校/换学期天然隔离，删校级联清除。
- 引导页不要求选教务系统类型：只填学校名称（必填）、教务网址（选填，http/https 均可）、
  开学周一（必填）与总周数；填了网址的学校 adapterId='auto'。
- 社区适配脚本契约完整实现：`shiguangBridge.showToast/notifyTaskCompletion` +
  `shiguangBridgePromise.showAlert/showSingleSelection/showPrompt/saveImportedCourses/
  savePresetTimeSlots/saveCourseConfig`，契约名不变，社区脚本零修改可跑。
  三类 save 只进内存会话；落库必须经预览确认（与「预览确认」准则一致）。
- 导入规范化器 `AdapterBatchNormalizer`：课程（name/day/startSection/endSection/weeks 必需，
  weeks 接受数组或周次文本）、节次时间、学期配置；不满足契约的条目丢弃并计数，
  预览页明示「N 条无效」与原因，不猜语义。
- TASK-019 更新周卡：固定七列，10/12 节依视口均分一屏；超过 12 节只滚动网格，星期栏固定。普通两节块显示名称、compact 地点、教师；极短块按物理空间降级。原始完整信息在预览、Today 和详情。课程块无逐卡 BackdropFilter。
- 课程冲突保持一门全宽 + `+N`，按当前课程直接重叠的 peers 计数；切周判据使用画面偏移和松手速度，`stepRequest` 在销毁时解除引用。冲突布局每次 build 为七天各算一次，测量与绘制共享。
- `/today` 是独立时间轴页面，学校行「今日」按钮点击跳转；Weekly不展示今日摘要。课程点击打开预览。加号展开添加课程、导入课表、添加事件菜单，事件复用 Course 模型/编辑页。
- `SectionCountResolver` 是网格、编辑、详情的节次上限共享来源；详情区分 Loading/Data/Error/Not Found，空周次有安全兜底。
- `lib/core/glass/` 管理玻璃材质、动效、尺寸、指针物理、Sheet、用户可见表单与对话框；`AmbientBackdrop` 提供环境背景。浅/深色采用独立语义色。系统日期/时间选择器保留平台控件。Reduced Motion 降级动画过程，终态材质保持正确。
- TASK-017：Weekly 预览 → 详情、Today 课程卡 → 预览 → 详情均接入真实 PageRoute Hero，身份包含课程、学校、学期、来源与目标；Today 预览是透明 PageRoute 承载的玻璃底部面板。Reduced Motion 跳过 Hero 并短淡入。用户可见输入、选项、选择器与确认框统一为共享玻璃控件；日期/时间选择器继续使用平台控件。
- TASK-016 设备验收记录（历史）：当时 API 36 隔离 QA 用户实画检查匿名空周首页；模拟器 QA 用户已删除，主用户应用数据未清理。该实画不覆盖 TASK-017 的 Hero/表单。
- 最终验证（2026-09-23，TASK-017）：`flutter analyze --no-pub` 通过，`flutter test --no-pub` 194/194，Android debug APK 构建成功（`build/app/outputs/flutter-apk/app-debug.apk`，207,085,563 字节，SHA-256 `B41FED2C23A339F7332B72BE2C6533F98A60DE1C3A9B7BD25C4D7B1B02E010ED`）。本轮 `adb devices -l` 无连接设备，未做模拟器/真机实画；iOS、真机 GPU、TalkBack/VoiceOver 仍为 `UNVERIFIED`。教务脚本、桥、NavigationPolicy、Drift schema 均未变。未创建 commit。
- 课程 CRUD：手动新增/编辑/删除（表单含星期签、节次下拉、周次文本解析、备注），
  详情页完整元数据。导入课程 id 由内容指纹生成，同内容同 id，供差异比对。
- 学期设置（开学周一选择后自动对齐所在周周一、总周数 1-30）、默认作息编辑（时间选择器，
  手动格式化 HH:mm 避免本地化格式破坏契约）、恢复通用默认（显式操作）。
- 外观三档（跟随系统/日间/夜间）持久化到 settings 表，系统栏图标随明暗切换。
- 学校管理：列表、点按切换激活、修改教务网址（http/https 均可，与建校/导入入口同一判定；
  白名单只增不减）、
  删除学校（级联清数据 + 清激活键，确认弹窗）。切换后另一校数据保留但不显示。
- Android 主清单已声明 `INTERNET`（吸取单校版 release 缺权限的教训）。
- **明文 HTTP 策略（2026-09-13 变更，取代此前的「仅南工白名单」）**：多校现实是大量教务为
  明文且无法运行期新增放行域名，故放开明文——Android `network_security_config`
  base-config 允许明文、iOS `NSAllowsArbitraryLoadsInWebContent`（仅 WebView）；
  应用层两道门保留：导入入口地址确认（明文额外警示）+ 导航仅限确认过的主机。
  本应用唯一网络消费是导入 WebView。

## In Progress

- TASK-006：等用户本人在设备上执行真实教务导入；本轮没有连接 Android 设备，也没有留下模拟器现场。

## Not Started

- TASK-002 Android 桌面小组件（迁移 + 载荷由 Dart 预计算整学期每日课程，消除双实现）。
- TASK-003 上课提醒（按学校档案与学期排程，时区语义「课程所在地墙上时间」）。
- TASK-005 适配器目录联网更新（需先定配置源与校验策略）。
- iOS 构建验证（`UNVERIFIED`，不阻塞）。

## Current Blockers

- `BLOCKED`：TASK-006 真实教务导入验收，等用户本人装机完成登录与导入（见 `tasks.md` Now）。
  模拟器上没有留待办现场：TASK-011 核验后已删除冒烟学校并 `pm clear`，应用回到全新安装的引导页。
  该任务需要用户本人登录真实教务；本轮无连接设备。TASK-017 的 Android debug 构建使用本机
  已缓存的 sqlite3 hook 成功完成；若未来缓存缺失，hook 可能需要网络下载。

## Important Context

- 「汇课」为用户 2026-09-13 确认定稿的名称；改名是纯文案工作。
- 应用包名 `com.huike.huike_timetable`（`flutter create --org com.huike`）。
- 中文路径下 Flutter 工具链需 `subst S: "D:\桌面\汇课"` 后在 `S:\` 执行（同单校项目经验）。
- Gitee 推送：`origin` 是无令牌的公开地址；令牌只经环境变量传入、不落盘。
  **不能用 `https://用户名:令牌@gitee.com/...` 的 URL 形式**（会被拒为
  `Incorrect username or password (access token)`），要用
  `git -c credential.helper= -c http.extraHeader="Authorization: Basic <base64(用户名:令牌)>"`。
  给 Gitee API 传中文参数也要走 UTF-8 文件（`--data-urlencode "body@文件"`），否则变成乱码。
  细节见 `report_2026-09-14_handoff.md` §12 坑 14~16 与 §14。
- sqlite3（3.5.2）的 Dart hook 构建期从 GitHub 下载预编译库并缓存在项目内
  `.dart_tool/hooks_runner/shared/sqlite3/build/download-<hash>/`，带 sha256 校验；
  同版本工程的缓存可直接复用（2026-09-13 已这样完成离线构建）。
- 调试 UI 用 `adb shell uiautomator dump` 读语义树（Flutter 文本在 content-desc/text 里）；
  Git Bash 调 adb 传 `/sdcard/...` 路径要设 `MSYS_NO_PATHCONV=1`，native python 读文件用 Windows 路径。
- 模拟器 `ncpu_api36` 是与单校项目共用的验证环境；本项目 App 包名独立（`com.huike.*`），
  冒烟时全程未触及其它应用的数据库。
- Riverpod 3 注意：`AsyncValue.valueOrNull` 已删除，用 `.value`；`RadioListTile` 的
  groupValue/onChanged 已弃用，改用 `RadioGroup` 祖先。
- GoRouter 必须单实例 + `refreshListenable` 做响应式 redirect；重建 Router 会让进行中
  导航悬挂（曾导致 widget 测试 pumpAndSettle 超时）。navigator key 也不能是全局变量，
  用 `rootNavigatorKeyProvider` 每容器一份。

## Validation Snapshot

以下按时间顺序记录，**最新基线在末尾**；早期条目里的测试数（65/65、75/75）是当时基线，
不是当前状态（当前 207 个用例 / 205 通过，2 个既有 430dp 失败见 `knowledge/testing.md`）。

- `CONFIRMED`（2026-09-13 19:10 +08:00）：`flutter analyze`（`S:\`）No issues found。
- `CONFIRMED`（2026-09-13 19:12 +08:00）：`flutter test` **65/65 通过**。覆盖：周次解析、
  学期服务、作息表、适配器规范化、导入差异、桥契约、数据库/仓库语义（内存库：
  播种一次、导入替换保手动、跨校隔离、级联删除、设置读写）、目录资产、App 壳 widget 流程。
- `CONFIRMED`（2026-09-13 20:10 +08:00）：自动适配探测端到端验证——创建
  adapterId='auto' 的学校（网址 example.com）→ 风险确认 → WebView → 执行导入 →
  四个适配器依次尝试（正方脚本弹出其自带确认框，超时正确暂停；取消后继续）→
  全部失败后弹出逐项汇总弹窗，四条结果文案正确。删除冒烟学校后回到引导页。
  全程 logcat 无 `FATAL EXCEPTION` / `E/flutter`。
- `CONFIRMED`（2026-09-13 20:20 +08:00）：新图标（印章行楷）装机确认，
  应用抽屉中圆形遮罩下内框与字形完整清晰。
- `CONFIRMED`（2026-09-13 19:20 +08:00）：Debug APK 构建成功
  （`build/app/outputs/flutter-apk/app-debug.apk`，含 INTERNET 权限）。
- `CONFIRMED`（2026-09-13 19:00-19:30 +08:00，`ncpu_api36` 模拟器 / API 36 / x86_64）：
  装机冒烟全程通过——冷启动 `Status: ok`；引导页渲染完整 → 创建学校（SmokeUniversity，
  手动类型，开学周一 2026-09-07，20 周）→ 首页 hero「9月13日 星期日 第 1 周」计算正确 →
  整周七天纵列与周切换器正常 → 手动加课（SmokeCourse101，周一第 1 节）落格显示 08:00 →
  课程详情元数据完整 → 设置四组入口正常 → 默认作息 12 节含上下午晚分组（**该时间点的版本；
  同日迭代 `4db55f2` 后兜底作息改为 10 节**）→
  学校管理「使用中」标签与溢出菜单正常 → 导入入口对手动学校显示降级说明 →
  删除学校（确认弹窗）后回到引导页，激活键清除。期间发现并修复「使用中的学校无菜单
  无法删除」缺陷（trailing 改为始终提供 PopupMenuButton）。logcat 全程无
  `FATAL EXCEPTION` / `E/flutter`。共用模拟器上的其它应用数据未被触碰。
- `CONFIRMED`（2026-09-13 23:00 +08:00）：今日时间轴按用户「与整周雷同/卡片
  空隙」反馈重做并在模拟器实测——课程卡贴内容高度（跨节次不再拉成大空块）、
  左侧色条 + 完整信息；整周网格卡同样改为信息紧跟课程名；轴线与进行中强调
  正常。`flutter analyze` 无问题、`flutter test` 75/75、logcat 0 致命异常。
  遗留：模拟器上留有一门冒烟课「TimelineClass」（周日 1-4 节），进详情点
  删除即可，不影响任何功能。
- `CONFIRMED`（2026-09-13 22:10 +08:00）：南工预设端到端实测——引导页点
  「南昌工学院」→ 名称/开学周一(2026-08-31)/周数预填 → 建校后今日页显示
  官方三段范围（08:20-11:55 / 14:00-17:25 / 19:00-20:30 只两槽）→ 加
  明智楼外的教室 3-4 节课显示基础时间 10:25-11:55 与完整卡片信息（名称 +
  完整起止时间 + 教室·教师），第 2 周周次正确；变体路径（明志楼→10:15）由
  `school_presets_test` 锁定（adb 无法输中文故 UI 只验了基础时间分支）。
  `flutter analyze` 无问题、`flutter test` 75/75、冒烟课已删、logcat 0 致命。
- `CONFIRMED`（2026-09-13 23:40 +08:00）：明文 HTTP 策略变更完成后重建 release 包并复核：
  `aapt2 dump xmltree` 确认 manifest 带 `networkSecurityConfig=@0x7f110001`、
  `dump resources` 确认该资源在包内、`dump permissions` 确认 `INTERNET`；
  `flutter analyze` 无问题、`flutter test` 76/76。
- `UNVERIFIED`：真实教务系统导入（用户已取 release 包在真机试用，结果待反馈）；
  arm64 真机安装；iOS 构建；应用名「汇课」为用户 2026-09-13 确认定稿。
- `CONFIRMED`（2026-09-14 00:05 +08:00）：仓库已上传 Gitee `chenxihh/huike`（**私有**）——
  master 读回 `8cdccda`（= 本地 HEAD）、annotated tag `v0.1.0`（`5bd42fb` → `8cdccda`）；
  推送前敏感扫描无命中、构建产物未入库；`origin` 已配为无令牌地址。
- `CONFIRMED`（2026-09-14 00:20 +08:00）：**仓库已转公开**——用户绑定第三方账号后
  `PATCH private=false` 成功；无令牌 `ls-remote` 读回 master `ceb3686`、tag `v0.1.0`，
  网页可匿名访问。
- `CONFIRMED`（2026-09-14）：TASK-009 导入链路修复后复核——`flutter analyze`（`S:\`）
  No issues found、`flutter test` **90/90**（新增 `test/navigation_policy_test.dart`
  6 条、`test/login_url_policy_test.dart` 8 条）。改动：导航跨域确认（`import_web_page.dart`
  `_handleNavigation`/`_confirmNewHost`）、地址校验统一（`login_url_policy.dart` 三处共用）、
  探测过程收敛（去掉逐个尝试提示、失败不逐项罗列、脚本间隔 800ms）。
  **模拟器/真机未跑**：本次仅静态与单测验证，跨域确认弹窗与探测节奏待装机复测（TASK-009 的
  UI 行为为 `UNVERIFIED`）。
- `CONFIRMED`（2026-09-14）：TASK-004 调休/停课例外表完成后复核——`flutter analyze` 无问题、
  `flutter test` **109/109**（新增 `test/calendar_exception_service_test.dart` 9 条、
  `test/calendar_exception_repository_test.dart` 7 条覆盖停课/调休折算、同日覆盖、
  编辑换日期、跨校隔离、删校级联清；`test/calendar_exception_ui_test.dart` 3 条覆盖
  今日页停课牌/调休提示条与「设置 → 调休 / 停课」路由）。schema 升 v3，
  v2→v3 为 `createTable`，老数据语义不变（空表 = 没有例外）。
  新界面测试顺带查出一个既有缺陷并修复：设置页的 `RadioListTile` 组嵌在带背景的
  `Container` 里，触发 Flutter「背景与涟漪不可见」断言（见 ISSUE-010）。
  **模拟器/真机未跑**：调休/停课页日期选择与整周列头小签的实际观感为 `UNVERIFIED`。
- `CONFIRMED`（2026-09-14）：TASK-011 首页信息架构重做后 `flutter analyze` 无问题，
  `flutter test` **110/110**；release APK `0.1.1+2`（通用包，arm64-v8a / armeabi-v7a /
  x86_64）构建成功并安装到 `ncpu_api36`（API 36 / x86_64）。装机实画核验：
  ① 空课日——历牌「9月14日 星期一 第 1 周」+「今日无课」字牌 + 看整周/加课程/教务导入三入口；
  ② 单课与多课——「下一节 08:00 ××× 第 1 节」提示条 + 当日议程行（不同课程签色、
  发丝线分隔、跨节次显示「第 3-4 节」）；
  ③ 整周——「第 1 周 9.14 - 9.20」七天分组，今天行在首位且朱砂浅底、空日各占一行右侧「无课」、
  有课日右侧「2 门」并在表头下列出课程；④ 夜间——今日与整周对比度正常；
  ⑤ 窄屏 360dp（`wm size 720x1600` + `wm density 320`）——历牌行、议程行与 FAB 均无溢出。
  首页确已无路线水印与七日站点概览。logcat 全程无 `FATAL EXCEPTION` / `E/flutter`。
  核验后删除冒烟学校、`wm size/density reset`、`pm clear` 恢复全新安装态（共用模拟器未被污染）。
- `CONFIRMED`（2026-09-14）：TASK-010 完成后 `flutter analyze` 无问题，`flutter test`
  **110/110**；release x86_64 APK 构建成功并安装到 `ncpu_api36`。日间首页/整周/设置、
  夜间整周、窄屏两列与空课快捷入口已实画检查；logcat 未见致命异常。
  课程详情「十站节次线」和调休/停课回归行为由 widget 测试锁定。
  （该版首页的竖向时间轴与节次槽位网格已被 TASK-011 取代。）
- `CONFIRMED`（2026-09-14）：南工教务地址失效已修复并装机复核——旧档案地址
  `http://jwxt.ncpu.edu.cn` 当前只剩 IPv6 解析、curl 请求 20s 超时（`000`）；
  改为学校实际入口 `http://218.204.129.252:8088/jwglxt/xtgl/login_slogin.html`
  （明文 HTTP、正方 jwglxt V9.0、UTF-8）。`ncpu_api36` 实测：引导页点「南昌工学院」
  预填新地址 → 建校 → 导入页显示新地址与明文警示 → 确认后 WebView 成功加载
  「南昌工学院教学综合信息服务平台」登录页，**全程未输入任何凭据**。
  `flutter analyze` 无问题、`flutter test` **112/112**（新增 IP+端口地址用例
  与白名单主机粒度用例）。见 ISSUE-013。
- `CONFIRMED`（2026-09-14）：「按教学楼作息变体」对老学校从未生效的问题已修复
  （ISSUE-014）。用户导入后截图显示明志楼第 3-4 节为 10:25（应为 10:15），
  查明是 v2 之前建的学校变体列停留在迁移默认 `'[]'`、无人补写；档案与代码本身正确
  （新建学校实测解析出 10:15）。修法：`SchoolRepository.repairPresetVariants()`
  只补空值、幂等，由 App 外壳启动时 watch 一次。`flutter analyze` 无问题、
  `flutter test` **119/119**（新增 `test/school_variant_seeding_test.dart` 7 条，
  含「修复 → provider 组装 → 解析出 10:15」的接线级断言）。
  **装机受限**：模拟器只能用 ASCII 输入课程表单，造不出中文教室名的课程，
  真机显示效果为 `UNVERIFIED`，等用户反馈。
  见 TASK-012（变体覆盖范围仍待用户给出学校的完整规则）。
- `UNVERIFIED`：TASK-006 真实教务登录、课表解析、差异预览与确认写入；arm64 真机安装；iOS 构建。
- `CONFIRMED`（2026-09-14）：本轮改动已推送并发布——master 读回 `bd0ecc8`（= 本地 HEAD），
  annotated tag `v0.1.1`（`a5f215a` → `bd0ecc8`）；release「汇课 0.1.1+2（首页信息架构重做）」
  挂 APK 附件 `huike-0.1.1-release.apk`，64,731,306 字节、与本地构建产物 sha256 一致
  （`98510723772fb06aaaf4bffebfe11fa6e151de4fe70e0af46a531af62f396019`）；
  **无令牌** HEAD 该附件返回 `200` 且 `Content-Length` 相同，说明公开可下载。
  推送前确认构建产物未入库（`/build/` 在 `.gitignore`）、仓库内无令牌。
- `CONFIRMED`（2026-09-14）：Gitee 仓库简介原为乱码（历史遗留，UTF-8 被按 GBK 读后又被二次误编码，
  原文不可还原），已重写为「汇课：多校通用课表 App。在学生自己学校的官方教务页面登录后本地导入课表，
  离线保存与展示；不保存账号与密码。」；**无令牌**请求读回一致、不含替换字符。
  同时复核 release 与附件文案均正常。改简介的命令见 `report_2026-09-14_handoff.md` §12 坑 15
  （`PATCH /repos/{owner}/{repo}` 必须带 `name`，中文参数走 UTF-8 文件）。

- `CONFIRMED`（2026-09-15）：TASK-013 完成后 `flutter analyze`（`S:\`）No issues found、
  `flutter test` **149/149**（新增 `test/week_agenda_test.dart` 21 条覆盖自然顺序、
  周一/周日/学期前后的锚点、例外折算与学期进度边界；`test/week_agenda_ui_test.dart`
  9 条覆盖整周自然顺序与「今天为首个可见日期、过去日期在上方」、其它周从周一开始、
  「回本周」重新定位到今天、停课与调休的文字表达、`CourseListingRow` 复用与节次文案唯一、
  长按周次弹层与普通点击不误触、360dp + 1.3 倍字体不溢出）。同一次运行里
  改掉了既有的窄屏大字体缺陷（见 ISSUE-015）。
- `CONFIRMED`（2026-09-15，`ncpu_api36` 模拟器 / API 36 / x86_64，debug APK）：TASK-013
  装机实画——建校（SmokeUniversity，开学周一 2026-09-14、20 周）后加两门课，
  整周首屏**以今天（9/15 周二）为首个可见日期**、周一 9/14 在上方（上滑回看后可见，
  顺序为 9/14 → 9/20，周日之后没有第二个周一、也没有下周日期）；周切换器
  `‹ 第 1 周 9.14 - 9.20 ›` 在第一周时「上一周」为真实 disabled，「下一周」进入第 2 周后
  从周一开头并出现「回本周」，点它回到第 1 周并重新锚定到今天；长按周标题弹出学期
  翻页弹层（大号 2 +「第 2 / 20 周」+ 进度条 +「阅至此处」）；把 9/15 标为停课后该行显示
  「停课」小签、课程隐藏且仍然保持今天的四重强调。夜间（`cmd uimode night yes`）、
  窄屏 360dp（`wm size 720x1600` + `wm density 320`）、1.3 倍字体（`settings put system
  font_scale 1.3`）三种条件下整周均无溢出、无裁切。logcat 全程 0 命中
  `FATAL EXCEPTION` / `E/flutter` / `RenderFlex overflowed` / `ANR` / `MissingPluginException`。
  核验后 `pm clear` 恢复全新安装态并把 `wm size/density`、`font_scale`、夜间模式复原
  （共用模拟器未被污染）。
- `UNVERIFIED`：TASK-013 的调休「按周X上课」小签、平板宽度居中与 Reduced Motion
  三种形态只由 widget 测试/代码保证，未在模拟器实画（模拟器输入限制与耗时取舍）。

- `CONFIRMED`（2026-09-23）：TASK-015 完成后 `flutter analyze`（`S:\`）No issues found、
  `flutter test` **177/177**。新增 `test/course_block_content_test.dart` 5 条
  （360/390/430dp 下七天完整可见、超长课程名 / 完整地点 / 完整教师 / 起止时间全部落在
  课程块内且互不重叠、块内不存在 `ellipsis`/`fade`/`maxLines`、1.3 倍字体同样完整、
  内容超视口时纵向滚动且星期栏仍 sticky）、`test/glass_interaction_test.dart` 6 条
  （按下压缩与弹簧回位、指针位置驱动高光并抬手归位、进度可由外部驱动、
  玻璃表面无 InkWell/InkResponse、blurSigma 为 0 时不建滤镜层、弹簧阻尼比与时长令牌），
  并在 `week_agenda_ui_test` 当时新增 8 条（跟手位移 1:1、邻周同时在场、动画可中断、
  位置阈值提交、`weekSwipeTarget` 位置+速度判定、周次标签滑入、按压后升起预览 Sheet、
  今日 Sheet 的背景缩放/模糊同步与拖动关闭、课程块无 BackdropFilter）。
  既有「两路并排」用例按 ISSUE-016 的新行为改写。
- `CONFIRMED`（2026-09-23，`ncpu_api36` / API 36 / x86_64，debug APK）：装机实画
  （用一个只存在于模拟器的 NCPU 预设学校 + 16 门中文课程，看完即 `pm clear` 清除；
  不涉及任何真实账号或课表）——
  ① 日间 390dp：七天同屏，`高等数学 / 大学英语 / 大学生心理健康教育 /
  线性代数与解析几何 / 马克思主义基本原理 / 思想道德与法治 / 计算机科学与技术导论 /
  大学物理实验 / 体育` 全部完整折行显示，`九龙湖校区教学楼 A201`、`物理实验中心 203`
  等长地点同样完整，教师与 `08:20 / 09:50` 起止时间同屏可读，无任何省略号；
  ② 星期栏滚动时固定在顶部且课程块从其下方滑过（玻璃折射可见）；
  ③ 今日快捷显示 `今天 · 3 节课 | 今天课已上完`，点按升起 Today Glass Sheet
  （三节课的名称 / 起止时间 / 地点 / 教师完整）；
  ④ 点课程块先压缩再升起课程预览 Glass Sheet，背景课表被模糊 + 缩放 + 压暗；
  ⑤ 冲突课（周五 1-2 两门）显示一门完整课 + 顶部 `+1` 小签，文字未被挤成竖排；
  ⑥ 夜间：深墨玻璃层级、课程签色可读；⑦ 360dp（`wm size 720x1600` + `density 320`）
  仍无溢出、文字完整。logcat 全程 0 命中 `FATAL EXCEPTION` / `E/flutter` /
  `RenderFlex overflowed` / ANR。核验后 `wm size/density`、夜间模式复原并 `pm clear`。
- `UNVERIFIED`：真机 GPU 上的模糊性能（多块 BackdropFilter 同时在场时的帧率）、
  iOS、TalkBack/VoiceOver 完整人工遍历；以及用户在真机输入中文长课程名后的实际观感。
- `CONFIRMED`（2026-09-23）：release 产物 `build/huike-0.1.4-release.apk`
  （通用包 arm64-v8a / armeabi-v7a / x86_64，65,338,262 字节，sha256
  `6baece6da43bbf5c3705b6fd8daf350497ddbd3e328f91143c922d948dc130e5`，
  versionCode 5 / versionName 0.1.4 / minSdk 24 / targetSdk 36 / INTERNET 权限齐全，
  标签「汇课」）。`aapt2 dump` 核验元数据；在 `ncpu_api36` 上装机冒烟（引导页 →
  NCPU 预设建校 → 新首页渲染正常），logcat 0 命中致命；核验后 `pm clear` 并复原环境。
  **未推送 Gitee、未打 tag**（等用户确认）。
  **注意**：这条是 2026-09-23 当轮的产物快照；其中「未推送 Gitee、未打 tag」已于 2026-09-27
  收口（v0.1.4 已推送并发布），同一路径 `build/huike-0.1.4-release.apk` 也已被重新构建的
  发布包覆盖，当前文件的大小与哈希以「发布 v0.1.4（2026-09-27 17:20–17:22 +08:00）」为准。

- `CONFIRMED`（2026-09-23，TASK-017）：`flutter analyze --no-pub` 无问题；
  `flutter test --no-pub` **194/194**；`flutter build apk --debug --no-pub` 成功。
  本轮 `adb devices -l` 返回无连接设备，没有执行模拟器或真机实画，也没有安装 APK。
  Debug APK 路径/哈希见 Working Features。iOS、真机 GPU 与 TalkBack/VoiceOver 为
  `UNVERIFIED`。未创建 commit。
- `CONFIRMED`（2026-09-27 17:09–17:23 +08:00）：本轮归档并发布的最终验证——`S:\` 下
  `flutter analyze --no-pub` 无问题、`flutter test --no-pub` **283/283**（17:09 跑完）；`flutter build apk --release --no-pub` 成功，
  产物元数据以 `aapt2` 读回（versionCode 5 / 0.1.4 / minSdk 24 / targetSdk 36 / 三 ABI /
  `networkSecurityConfig` 在包内），APK 大小与 SHA-256 见「发布 v0.1.4（2026-09-27）」。
  发布后以**无令牌**请求读回 release 与附件（`200`、长度一致、无乱码）。本轮 `adb devices -l`
  无连接设备，未装机实画；真机 GPU、iOS 与 TalkBack/VoiceOver 仍为 `UNVERIFIED`。

## Recommended Next Action

归档、推送与发布都已完成（见「归档与推送」「发布 v0.1.4（2026-09-27）」两节），
下一步回到工程任务。用户侧仍挂着 TASK-006 真实教务导入验收与 TASK-012 的教学楼作息规则。

TASK-002 Android 桌面小组件（载荷 schema v2：由 Dart 预计算整学期每日课程，
原生只按日期查表）。预计算必须经 `CalendarExceptionService` 折算「某天按哪天的课表」，
否则调休日会显示错的那天。TASK-003 同理。与之并行不冲突的是 TASK-006 真实教务导入验收
（需要用户装机走一次导入，见 `tasks.md` Blocked）。
另外，真机 GPU 性能与 iOS 未验证（TASK-015 的模糊层数量已受控并有测试锁定，
但真机帧率仍建议用户在常用机型上确认）。
