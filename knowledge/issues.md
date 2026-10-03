# Issues

## TASK-WEBVIEW-FRAMEWORK-01 通用登录浏览器导航与错误恢复

Status: 工程缺口已修复（2026-10-03）；截图ERR_CONNECTION_ABORTED的直接根因仍UNVERIFIED。

Confirmed: Android原插件取消全部主导航后在ALLOW时loadUrl重发；子frame Dart CANCEL不能实际阻止；没有主frame错误状态且错误页能运行适配。已修同步快照导航、错误提示/手动reload/导入门控和generation隔离。Java14/14、全量381/381与专项回归；不能将源码缺口等同截图故障已证实因果。昨日adapter更新未发现直接网络失败路径。见report_2026-10-03_webview_framework.md。

## ISSUE-020 修改教务网址保存/取消后红屏

Status: Resolved（2026-10-01，TASK-SCHOOL-URL-DIALOG-01；代码与 Widget 回归验证，用户真机复测 `UNVERIFIED`）

Observed: 用户截图显示 `framework.dart:6281 _dependents.isEmpty`。修改教务网址关闭时触发。

Root Cause: `showGlassDialog` 返回 navigator.push 的 popped future，pop 时即完成，而退出动画尚未结束；调用方立刻 dispose 外部控制器。尚存活的 TextField 在失焦重建时使用已销毁控制器，后续 `_FocusInheritedScope` 清理触发截图同款继承组件断言。

Resolution: 删除外部控制器，通过 onChanged 记录文本，让 TextField 内部 State 持有并在自身卸载时释放；保存前增加 mounted 检查。统一网址校验/仓库更新保持原语义。

Evidence: 修复前6项回归失败且捕获同款断言；修复后专项6/6、全量332/332。见 `report_2026-10-01_school_url_dialog.md`。

Prevention: pop future 完成不代表路由子树卸载；资源生命周期应归属使用该资源的 State，不以固定延迟猜测释放时机。

## ISSUE-001 导航只放行入口那一台主机，教务跳统一认证时被静默拦死

Status: Resolved（2026-09-14，TASK-009）

Observed: 导入 WebView 的白名单只收到 `allowedHosts: [widget.host]`，即入口页确认的那一台主机。
教务登录跳统一认证/CAS（另一域名）时主框架导航被 `CANCEL`，用户看到一条
「已拦截：主机不在白名单：xxx」，导入根本走不到适配器执行。

Root Cause: 契约层的 `appendConfirmedHost` 已实现「运行期追加主机」，但除学校管理改址外无人调用，
WebView 侧从未把学校档案里的已确认主机读进来；`navigation_policy.dart` 的注释却已宣称支持
「会话中确认过的主机」——文档宣称的能力没有接线。

Impact: 任何登录跨域（国内教务极常见）的学校都无法导入；由于提示只出现一瞬间，
很容易被误判为「适配器不适配」，从而去做无效的适配脚本排查。

Resolution: 放行范围改为「入口地址 + 学校档案 `acceptedHosts` + 会话中新确认主机」；
主框架跳新主机时弹窗确认一次，同意即加入白名单并经 `appendConfirmedHost` 落库（只增不减），
拒绝则本会话不再询问；子框架不参与判定；scheme 允许 http/https（见 DEC-005）。

Evidence: `CONFIRMED` 逻辑层——`test/navigation_policy_test.dart` 6 条覆盖放行、追加后即刻生效、
未确认主机拦截、子域名不自动放行、非 http(s) scheme 拦截。`UNVERIFIED`：弹窗实际观感，
需装机走一次跨域登录（见 ISSUE-005）。

Prevention: 文档与注释承诺的机制必须有调用点，否则补实现或删描述（`AGENTS.md` 工程准则）。

## ISSUE-002 明文放开漏改学校管理页改址，同一所学校两套判定

Status: Resolved（2026-09-14，TASK-009）

Observed: 引导页建校与导入入口都已接受明文 HTTP，但学校管理页「修改教务网址」仍是
`uri.scheme != 'https'` 就报「仅支持 HTTPS 教务地址」。结果是南工这类明文教务能建校、
能导入，却无法从设置里改地址，只能删校重建。

Root Cause: 地址校验在三个入口各写了一份，放宽时只改了两处。
（同类问题在用户否掉「按南工白名单」时也出现过一次：多校工具不能按校个案放行。）

Impact: 明文学校的改址路径不可用，且错误提示与其它入口自相矛盾，用户会以为是自己填错。

Resolution: 抽出 `checkLoginUrl`（`features/schools/services/login_url_policy.dart`），
三处入口共用；页面 hint 与 `updateLoginUrl` 注释同步（见 DEC-006）。

Evidence: `CONFIRMED` `test/login_url_policy_test.dart` 8 条覆盖空输入必填/非必填、
http 标记明文、https、裁剪空白、缺 scheme、非 http(s) scheme、无主机。

Prevention: 跨页策略只允许一个函数（DEC-006）；放宽类改动先做入口盘点。

## ISSUE-003 探测过程暴露给用户，且失败后罗列内部明细

Status: Resolved（2026-09-14，TASK-009）

Observed: 每次尝试适配器都弹一条「正在尝试 xxx…」；全部失败后弹窗逐条列出四个适配器的
内部结果文案。用户明确指出：用户只需要负责使用，过程不该显示。

Root Cause: 把「实现可观察」当成了用户价值——这些信息对用户没有可操作价值，
只反映 App 的内部机制（哪个脚本、失败在哪个环节）。

Impact: 用户要读四条与自己无关的失败原因；更糟的是容易被引导去怀疑适配器，
而真正的失败点（如 ISSUE-001 的跨域拦截）被淹没。

Resolution: 去掉逐个尝试提示；脚本之间固定间隔 800ms（请求节奏由代码承担）；
默认失败只给可操作提示，不显示候选清单或逐项结果。TASK-ADAPTER-GENERAL-01补充用户主动打开的安全诊断：只含固定阶段、状态、错误码及静态说明；不含动态异常、原始网址/页面数据/账号或会话值（见 DEC-007/011）。

Evidence: `CONFIRMED` 代码与单测；2026-10-02通用框架全量377/377及诊断回归通过；`UNVERIFIED` 装机观感。见`report_2026-10-02_adapter_framework.md`。

Prevention: 面向用户只呈现「你要做什么 / 结果如何」，不呈现内部机制（DEC-007）。

## ISSUE-004 真实教务导入未验收

Update（2026-10-02，TASK-PROGRESS-REPORT-01）：tasks已有09-14用户截图确认课程/教室/教师落库的局部真实证据；下方「没有任何记录」是更早观察。适配器命中、四类预览、最新版本及真机变体完整验收仍待完成，保持Open/BLOCKED，不扩大为所有学校可用。

Status: Open（`BLOCKED`，TASK-006）

Observed: 导入链路目前只有代码、单测与 example.com 探测循环的证据，
没有任何一所真实教务系统的端到端记录（真实教务形状为 `UNVERIFIED`）。

Impact: 适配脚本能否命中真实页面、登录能否走通，都还是推断；
ISSUE-001 正是这类「只有代码证据」掩盖住的问题。

Next Action: 用户装机后走「登录 → 打开课表页 → 执行导入 → 预览 → 确认写入」，
确认跨域确认弹窗是否正常出现、是否命中适配器。南工已预填地址；
若四个通用脚本都不命中，再按已确认的接口形状写专用脚本。

## ISSUE-005 新增的跨域确认弹窗、探测节奏与调休界面未装机验证

Status: Open

Observed: TASK-009 与 TASK-004 的改动只做了 `flutter analyze` 与单测（109/109）。
未装机验证的部分：跨域确认弹窗的实际观感、弹窗与脚本桥弹窗是否互相干扰、
800ms 间隔下探测是否可接受、调休/停课页的日期选择与单选/星期选择的可用性、
整周列头「停课 / 调休 · 按周X」小签是否挤压列头空间。

Impact: 可能出现「弹窗时机不对」「同一域名反复询问」「小签把列头挤成两行」这类
只有真机才暴露的问题。

Next Action: 与 ISSUE-004 一并验收；先把 release 包重装到设备再走导入，
顺路进「设置 → 调休 / 停课」加一条停课与一条调休，回今日与整周核对显示。

Update（2026-09-23，TASK-017）：调休编辑器的单选、星期选项和备注输入改用共享玻璃控件；
危险确认框也改为共享玻璃对话框。表单/对话框由 widget test 覆盖，但本轮没有连接设备，
日期选择、页面布局和真实 WebView 弹窗交互仍为 `UNVERIFIED`，本 issue 保持 Open。

## ISSUE-006 签名仍为 Flutter 默认 debug 证书

Status: Open

Observed: release 包使用 Flutter 默认 debug 证书签名，仅供自用试用。

Impact: 换正式 keystore 必须卸载重装，本机数据会丢；仓库已公开，
若把包分发给别人，debug 签名的包会被部分设备/商店拒绝。

Next Action: 正式分发前完成签名决策（换签的时机越早代价越小）。

## ISSUE-007 iOS 未构建验证

Status: Open

Observed: ATS 已按「仅 WebView 放开」配置，但从未在 macOS 上构建过 iOS 包。

Impact: iOS 侧全部为 `UNVERIFIED`；ATS 放开在审核中还需要给出理由。

Next Action: 需要 mac 环境；优先级低于 ISSUE-004/005。

## ISSUE-008 仓库内历史遗留物未清理

Status: Open

Observed: `tools/patch_*.py`（交接报告自己标注「可删」的一次性结构调整脚本）与
`assets/icon/candidates/`（历史候选图标）仍在已公开的仓库里。

Impact: 公开仓库里存在与当前功能无关的脚本与图片，增加误读成本。

Next Action: 按 DEC 保留到发版前统一清理；删除前确认无脚本仍在被引用。

## ISSUE-010 设置页的单选组嵌在带背景的 Container 里（背景与涟漪不可见）

Status: Resolved（2026-09-14，TASK-004 写界面测试时发现）

Observed: 新增 `calendar_exception_ui_test` 首次让测试走进「设置」页后，Flutter 对
主题单选组里的三个 `RadioListTile` 各抛一次断言：
「ListTile background color or ink splashes may be invisible」。

Root Cause: `ListTile`/`RadioListTile` 的背景与涟漪画在**最近的 Material** 上；
设置页把单选组放在 `Container(decoration: 带 surface 背景)` 里，中间没有 Material，
背景色把 Material 的效果盖住。此前模拟器冒烟走过设置页却没报，是因为这条断言随
Flutter 版本新加，且当时的验收只看有没有崩溃。

Impact: debug 构建下打开设置页会抛断言（release 被裁掉，用户侧只是涟漪不可见）；
更麻烦的是它会让任何「进设置页」的 widget 测试直接失败。

Resolution: 在 `Container` 外层补 `Material(color: palette.surface, borderRadius: 12)`，
边框仍由内层 Container 画；同时删掉因此不再使用的 `_groupDecoration` 辅助方法。

Evidence: `CONFIRMED` `flutter test` **109/109**——新增的 3 条界面测试会真的进入
设置页与「调休 / 停课」页；`flutter analyze` 无问题。

Prevention: 需要「有色块 + ListTile 系列」时先放 Material 再放 Container；
新增页面尽量补一条会真的走进去的 widget 测试——纯逻辑测试发现不了这类问题。

## ISSUE-011 子框架导航绕过非 HTTP(S) scheme 限制

Status: Resolved（2026-09-14，TASK-010 接手审查）

Observed: `ImportWebPage._handleNavigation` 在策略拒绝后，先判断 `isForMainFrame == false`
并直接放行，导致 iframe 内的 `file:`、`intent:`、`tel:` 等 scheme 绕过
`NavigationPolicy`；这与「非 http/https 一律拦截」的文档和逻辑测试声明不一致。

Root Cause: 「子框架不参与主机白名单确认」被实现成「子框架不参与任何导航判定」，
混淆了主机确认边界与 scheme 安全边界。

Impact: 恶意或异常页面可从子框架触发非 HTTP(S) 导航；即使 WebView/系统最终拒绝，
应用自身的安全口径也已失效。

Resolution: `NavigationPolicy` 新增 `allowsScheme`；页面对所有框架先执行 scheme 判定，
只有通过 http/https 后，子框架才免去新主机确认。既有非 http(s) 用例同时锁定该接口。

Evidence: `flutter analyze` 无问题；`flutter test test/navigation_policy_test.dart` 6/6 通过。

Prevention: 导航策略应把 scheme 与 host 分层判断；任何免检规则必须明确只免哪一层。

## ISSUE-009 知识库曾长时间与代码不一致

Status: Resolved（2026-09-14）

Observed: `current_state.md` 写 schema v1（实为 v2）、兜底作息 12 节（实为 10 节）、
「HTTPS 强制」与同文件的「放开明文」并存、「汇课」为暂定名（早已定稿）、
Blockers 写「无外部阻塞」（实际 TASK-006 为 `BLOCKED`）；
`architecture.md`/`adapters.md` 停留在明文放开之前；
`testing.md` 与 `changelog.md` 的测试基线、发布状态、仓库可见性也全部过期。
`tasks.md` 里还有两个 `## Now` 段。

Root Cause: 工作流程第 5 步（更新知识库）在多轮用户反馈迭代里被跳过，
只更新了代码与提交信息。

Impact: 接手者按文档理解项目会得到错误结论（例如以为导航支持「会话中确认主机」，
或以为学校管理页已支持明文），把时间花在错误的方向上。

Resolution: 按代码逐项校正 `current_state.md` / `architecture.md` / `adapters.md` /
`testing.md` / `changelog.md` / `tasks.md` / 交接报告；知识库改为
`README.md`（索引）+ `decisions.md`（DEC-xxx）+ `issues.md`（ISSUE-xxx）的固定结构。

Prevention: 知识库同步属于同一笔提交（`AGENTS.md` 工程准则第一条）；
文档与代码冲突时以代码与测试为准，先修文档再干活。

## ISSUE-012 引导页把教务网址写死为「HTTPS」，与明文放开策略冲突

Status: Resolved（2026-09-14，TASK-011 装机核验时发现）

Observed: 引导页建校表单的网址字段标签是「教务网址（选填，HTTPS）」，输入框本身
接受 `http://`，只有文案在劝退明文学校。而 DEC-004 之后策略已放开明文 HTTP
（`network_security_config` base-config 允许明文、`checkLoginUrl` 三处入口都收 http/https）。

Root Cause: 明文放开的入口盘点（ISSUE-002）只核对了校验逻辑与学校管理页的硬拦，
没有把「用户可见文案」纳入盘点。

Impact: 大量只有明文 HTTP 教务的学校会以为本 App 不支持自己的学校——与 DEC-004
的结论相反；属「文档说 A、代码说 B」在界面文案上的同类问题。

Resolution: 标签改为「教务网址（选填，http/https）」；复查 `import_entry_page.dart`、
`school_manage_page.dart` 的同类文案，未见其它把协议写死的位置。

Evidence: 装机实画（`ncpu_api36`，`0.1.1+2`）；`flutter analyze` 无问题、
`flutter test` **110/110**。

Prevention: 放宽类改动做入口盘点时，除了列出文件，还要覆盖「用户可见文案」——
文案与策略不一致时用户看不到代码里的宽容度。

## ISSUE-013 南工内置档案的教务地址已失效，导入入口打不开登录页

Status: Resolved（2026-09-14，用户报障）

2026-10-02复查（TASK-LOGIN-REPAIR-01）：旧结论“不是代码缺陷”只适用于最初域名不可达的外部因素。commit4f7cef7只改新建档案默认入口，未迁移已有school.loginUrl；ImportEntry确认地址后原本只追加host、不保存网址，临时改新地址会在下次恢复旧值。两者是实现缺口，已补首读前定向修复和确认后事务保存；不按使用时长触发，也不是账号过期。真实设备旧档案和登录未验，自动修复用合成旧记录与入口接线回归。

Observed: 用户点「南昌工学院」建校后进导入页，WebView 一直白屏、登录页打不开，
「根本登不进去」。档案里预填的是 `http://jwxt.ncpu.edu.cn`。

Root Cause: 该域名当前只剩 IPv6 解析（`240e:980:4210:100::16:64` 等），
本机请求 20 秒超时（curl 返回 `000`）；学校实际入口是明文 HTTP 的正方教务
`http://218.204.129.252:8088/jwglxt/xtgl/login_slogin.html`。预设地址自建档起
未复核过，属于「写进档案就再没验证」的数据陈旧，不是代码缺陷。

Impact: 南工用户按预设建校后无法登录导入，等于导入功能对该校不可用
（TASK-006 无法开始）。

Resolution: 预设 `defaultLoginUrl` 改为学校实际入口；`school_presets_test`
锁定新地址（scheme/host/port/path 逐项断言，并断言不再含旧域名）；
`login_url_policy_test` 增加「IP + 端口 + 路径」用例，`navigation_policy_test`
增加「白名单按主机粒度、端口不参与判定」用例，把这种地址形态固定下来。
档案里留注释说明不要改回旧域名。

Evidence: `flutter analyze` 无问题、`flutter test` **112/112**；装机 `ncpu_api36`
实测——引导页点「南昌工学院」预填新地址 → 建校 → 导入页显示新地址 + 明文警示 →
确认后 WebView 成功加载「南昌工学院教学综合信息服务平台」登录页（正方 V9.0），
全程未输入任何凭据。

Prevention: 预设里的学校数据（地址、作息、变体）要能随外部现实变化被复核；
用户报「登不进去」时先做 DNS 与连通性验证，再怀疑代码。

## ISSUE-014 老学校的「按教学楼作息变体」从未补齐，明志楼没提前 10 分钟

Status: Resolved（2026-09-14，用户报障并提供课表截图）

Observed: 用户导入后截图显示「九龙湖校区明志楼223」的工程力学，第 3-4 节是
10:25-11:55（基础时间），而档案规定明志楼应为 10:15-11:45。

Root Cause: 变体只在 `createSchool` 那一次播种。schema v2 之前建的学校，
`scheduleVariantsJson` 是迁移新增列时的默认值 `'[]'`，**没有任何路径把它补回来**，
于是这些学校永远按基础作息显示——即使档案、匹配逻辑、运行时组装全都正确。
新建学校的路径经测试确认是好的，所以这是纯粹的历史数据缺口，不是逻辑缺陷。

Impact: 凡是「先建校、后升级」的用户（先装 09-13 版本再升级的都算），
明志/明德/至善的教学楼时间全部显示偏晚 10 分钟；用户会以为 App 不区分教学楼。

Resolution: `SchoolRepository.repairPresetVariants()` —— 只对「变体列为空」的学校补写
档案变体（`presetId` 缺失时按校名精确匹配档案），已有变体的学校一律不动，幂等。
由 `presetVariantRepairProvider` 在 App 外壳启动时触发一次（不放进 Drift 迁移，
因为 `core/database` 不应反向依赖 `features/schools` 的档案数据）。

Evidence: `flutter analyze` 无问题、`flutter test` **119/119**；新增
`test/school_variant_seeding_test.dart` 7 条，覆盖建校播种、校区前缀教室文本匹配、
老数据补齐（按 presetId / 按校名）、不误伤无档案或已有变体的学校、
以及「修复 → provider 组装 → 解析出 10:15」的接线级断言。
装机验证受限：模拟器无法输入中文教室名，真机效果待用户反馈。

Prevention: 新增「只在创建时播种」的数据时，要一并回答「老数据怎么办」；
纯空值补写是安全的修复方式，覆盖式写入不是。

## ISSUE-015 「开学第一周周一」一行在窄屏 + 大字体下挤爆（引导页 / 学期设置）

Status: Resolved（2026-09-15，TASK-013 的新测试查出并顺手修掉）

Observed: 新增「360dp + 1.3 倍字体不溢出」用例后，首次运行即在
「A RenderFlex overflowed by 67 pixels on the right」上失败，约束宽 290dp、
父节点内边距 15dp（14dp 容器内边距 + 1dp 描边）。

Root Cause: 引导页 `_dateTile` 与学期设置页的同名行都是
`Text('开学第一周周一') + Spacer + Text('yyyy-MM-dd') + 图标`，两个 Text 都是**非弹性**子节点。
窄屏放大字体后「标签 + 日期」的自然宽度超过容器宽度，Row 无处收缩只能溢出；
`Spacer` 在只剩 0 空间时不解决问题。测试字体每位等宽，症状比真机更早暴露。

Impact: 360dp 上下 + 系统大字体（无障碍设置里很常见）时，引导页与学期设置页的
开学周一行会被右侧裁掉或压出黄黑条纹；引导页是必经之路，用户第一屏就可能看到。

Resolution: 两处都把标签包进 `Expanded` + `maxLines: 1` + `ellipsis`，日期保持自然宽度。
信息优先级不变（日期是这项设置的值，标签可以省），布局不再依赖 `Spacer` 硬撑。

Evidence: 当时在 360dp / 1.3 倍字体下复现并修复；历史套件运行记录为
`flutter analyze` 无问题、`flutter test` 149/149。原测试名称已在后续 UI 重构中移除，
当前窄屏覆盖见 `course_block_content_test.dart`，不可用旧测试名作为现时证据。

Prevention: 同行放「中文标签 + 值」时，至少让一个子节点可弹性收缩并允许省略；
只用 `Spacer` 撑开在两个文本都不可压缩时会溢出。新增窄屏 / 大字体用例后应尽快跑。

## ISSUE-016 七列手机上并排冲突课程会把行高推到不可用（TASK-015 实画查出）

Status: Resolved（2026-09-23，TASK-015）

Observed: TASK-015 把行高改成「由内容测量决定」后，装机实画立刻暴露：
周五第 1-2 节有两门课时，`course_collision_layout` 把这一列劈成两条 24dp 的 lane，
文字列只剩约 5dp 宽——`线性代数与解析几何` 竖排成 9 行、时间 `15:55/17:25` 被折成
10 行，单块需求高度约 320dp，被 `max(sectionHeight)` 放大成**每节 160dp**，
整周网格变成 1600dp 高，一屏只剩一行半。

Root Cause: 行高取自「本周所有课程需求的最大值」，而并排 lane 会让需求高度无界增长；
51dp 的日列宽本身就排不下两个中文窄条，再叠加冲突徽标的宽度让出后更极端。
这是模型问题，不是排版参数问题。

Impact: 只要一周里出现过一次两门课同时段，整周课表都会变得极高、极难用；
而且被劈开的块必然出现「一行一个字」的不可读排印。

Resolution: UI 层不再并排——同一时段多门课时显示**一门课的完整全宽信息**，
顶部一条 `+N` 小签（`TimetableConflictIndicator`）进入全部课程列表；
`course_collision_layout.dart` 仍照旧计算分簇与 lane（纯函数、有单测），只是不再
用来分列宽。徽标改为占顶部一条 15dp 而不是右上角一块，避免再一次挤压文字宽度；
带冲突的块在测量与绘制时都用 `withConflictBadge()` 同一份排印，两者不会脱节。

TASK-016 更新：周块现为视口几何驱动的自适应概览；`+N` 只统计与可见课程直接重叠的 peers，
不再使用整簇成员数。上段是 TASK-015 当时的实现记录。

Evidence: `flutter test` 177/177（`week_agenda_ui_test` 的
「两门冲突课程折叠为一门完整课 + 可访问的 +1 入口」锁定新行为）；
`ncpu_api36` 实画：周五 1-2 冲突显示为一门完整课 + `+1`，行高回到 250dp / 两节，
文字无竖排、无省略。

Prevention: 任何「把可用宽度再切一刀」的布局都要先问它在最窄列（51dp）下还剩多少
文字宽度；行高由内容测量驱动时，必须先检查测量宽度是否可能退化成不可读值。

## ISSUE-017 Liquid Glass 的 GlassButton 在松约束下纵向撑满整屏，页面正文整块消失

Status: Resolved（2026-09-24，TASK-018A）

Observed: 实机打开「导入教务课表」只剩顶部标题与底部一颗 disable 的
「确认并进入教务登录」；中间没有任何可操作控件，风险确认项不在页面上，
用户永远无法把 CTA 变成可用，教务导入整条链路走不下去。
`find.text('学校')` / `导入步骤` / `登录安全提示` 在 widget test 里都找不到，
但 `tester.takeException()` 为 null（不是崩溃，是布局被挤没了）。

Root Cause: `GlassButton` 用
`ConstrainedBox(minWidth/minHeight: tapTarget) → Center → GlassSurface` 包视觉。
`Center`（`RenderPositionedBox` 无 width/heightFactor）在**有界松约束**下会
把自身撑到 `maxHeight`。`Scaffold.bottomNavigationBar` 正是用
`fullWidthConstraints`（宽紧、高松，上限=整屏）布局的，于是底部栏变成
整屏高（390×844 屏上量到 350×820），`contentBottom` 被顶到顶部，
body 高度被挤成 **0**：`ListView` 视口 0 高 → 一个子项都不构建 →
学校卡、步骤、网址输入、`RiskConfirmTile` 全部不在树里 → `_confirmed` 永远为 false。
TASK-016 之前这些页面用的是 `FilledButton`（按内容定高），所以是 Liquid Glass
重构引入的回归。同一 bug 还命中引导页（`创建学校` 页正文同样 0 高）与导入预览页
——三个用 `bottomNavigationBar` 放 CTA 的页面同时失效。

Impact: 全新安装的建校页、导入入口、导入预览三页正文全部不可用，等于
「建校 + 导入」主链路断掉；而 app_shell 测试当时通过，是因为它用
`widget<TextField>(...).controller!.text = ...` 与
`widget<GlassButton>(...).onPressed!()` 绕过真实点击——被压到 0 高的控件
既拿不到 tap 也不会被正常 layout，测试于是被改成直调回调，掩盖了回归。

Resolution: `GlassButton` 的 `Center` 固定 `heightFactor: 1`，只收缩纵向、
保留原有的横向占满行为；`tapTarget` 最小尺寸约束不变。修三个页面而不是三处
重复打补丁（一处策略一处定义）。同时给导入入口的底部 CTA 补上键盘高度
（`MediaQuery.viewInsetsOf(context).bottom`），因为 `Scaffold` 只让 body 避开键盘、
底部栏本身不移动。

Evidence: `test/import_flow_regression_test.dart`（13 例）锁定正文可见、
CTA disabled→enabled→进入 `/import/web`、加载/错误/空态、390dp、1.3 倍字号、
键盘与返回；`app_shell_test` 的建校用例改回真实 `enterText` + `tap`。
API 36 `ncpu_api36` 实机：导入页正文完整、勾选后 CTA 变可用、可进入 WebView。

Prevention: 共享封装里用 `Center`/`Align` 包内容时，必须写清两个轴的
`widthFactor`/`heightFactor`；放进 `bottomNavigationBar`、`floatingActionButton`
这类松约束槽位的控件要有「内容定高」的测试断言（不是只断言 widget 存在）。
测试里禁止用 `find.byType(X, skipOffstage: false).first` + 直调 `onPressed`
来绕过真实交互；出现这种写法说明控件当时多半点不到，应当先查布局。

## ISSUE-018 离开导入 WebView 的两条 dispose 期异常让内存导入会话没被清掉

Status: Resolved（2026-09-24，TASK-018A）

Observed: 真机 logcat 在退出导入 WebView 时抛
`Bad state: Using "ref" when a widget is about to or has been unmounted is unsafe`；
把这条 catch 掉之后紧接着又是
`Tried to modify a provider while the widget tree was building`。

Root Cause: `_ImportWebPageState.dispose` → `ImportSessionCleaner.dispose` →
`ref.read(importSessionProvider.notifier).reset()`。两层原因叠加：
① `ref` 在已卸载的 widget 上不可用；
② `dispose` 发生在 widget 树 finalize 阶段，即使手里有 Notifier，
在这一帧同步改 provider 也会被 Riverpod 拒绝。
结论是这两条异常都发生在 `reset()` 真正执行之前/之时，内存里的原始响应与
解析结果从未被丢弃——与 `import_session.dart` 注释宣称的「离开导入页时 reset」
不一致（属 `AGENTS.md` 的「宣称的能力必须在代码里有接线」类问题）。

Impact: 安全相关的清理没生效：离开导入页后，脚本写入的原始课表 JSON 仍留在
内存会话里，直到下一次进入导入页才被覆盖。

Resolution: `initState` 里取一次 `ImportSessionNotifier` 实例交给 cleaner
（避免用 `ref`），并把清会话推迟到 `Future.microtask`（避开 finalize 阶段）。

Evidence: `test/import_flow_regression_test.dart` 的
「离开导入 WebView 会清空内存导入会话」——把两处修复分别回退都会让该用例失败
（回退 `ref` 修复：`Bad state` + `rawCourses` 仍非空；回退 microtask：
`Tried to modify a provider…`）。API 36 实机往返进出导入页后 logcat 无 Flutter 异常。

Prevention: 离开页面要清理的全局/内存状态，一律不在 `dispose` 里同步改 provider；
先把依赖实例抓在 `initState`，并把改动推到帧之后再执行。

## ISSUE-019 有学校时「添加学校」被 redirect 吞掉：debug 红屏、入口不可达

Status: UI trigger removed（2026-10-01按用户要求撤除学校管理添加学校入口；原修复任务被替代，redirect未改。以下保留2026-09-28历史诊断，不代表当前仍有该按钮）

Observed: 用户真机（debug 构建）在学校管理页点「添加学校」后整屏红，断言
`'package:flutter/src/widgets/navigator.dart': Failed assertion: line 4096 pos 18:
'!keyReservation.contains(key)': is not true.`，随后同树再抛
`framework.dart:6281 '_dependents.isEmpty'`，应用不可操作。截图时间 2026-09-28 16:15。

Root Cause: 两层叠加。
① 入口层：`app_router.dart:56-62` 的 redirect 把 `/onboarding` 当成单纯的「首次启动门」
（`hasSchool && onOnboarding → '/'`），不看 `?add=1`；而 `school_manage_page.dart:121` 的
「添加学校」正是 `context.push('/onboarding?add=1')`，于是有学校时目标被改写成 `/`。
② 框架层：被改写的 push 携带的是 `/` 的 match 列表（其最后一项是 `StatefulShellRoute`），
go_router `RouteMatchList.push` → `_createNewMatchUntilIncompatible` 只用「当前栈顶 match」
判断兼容性（当时栈顶是 `/settings/schools` 的 imperative match，与 shell 不相等），于是走
`_cloneBranchAndInsertImperativeMatch`，返回 `copyWith` 出来的 **shell 副本**——`copyWith`
保留 `pageKey`，而栈底原有 shell 没被替换 → 根 Navigator 的 pages 里两个 Page 同 key。

Impact: debug 构建点该按钮即红屏、整树不可用；release 构建断言被剥离，不红屏，但该入口
自 0.1.0 起就一直不可达（被静默弹回首页、无任何提示），第二所学校无法通过 UI 添加。
红屏是 0.1.4（TASK-020B 引入 `StatefulShellRoute`）之后才出现的新形态。

Resolution: 待修。已临时验证（验证后已还原，工作区无遗留）的修法：redirect 放行 `add=1`——
`final addingSchool = state.uri.queryParameters['add'] == '1';`
`if (hasSchool && onOnboarding && !addingSchool) return '/';`
打上后 match 树变为 `[Shell, Imp(/settings), Imp(/settings/schools), Imp(/onboarding)]`，
`tester.takeException()` 为 null，onboarding 表单正常出现。

Evidence: `CONFIRMED`（2026-09-28，`S:\`，`flutter test --no-pub`，一次性脚本按用户真实路径
「设置 → 学校管理 → 添加学校」用真实点击复现，逐步 dump 根 Navigator 的 match 树：第三步出现
第二个 `ShellRouteMatch`，其 `pageKey.value` 与第一个完全相同；断言原文与截图一致）。
机制、坐标与回归测试建议见 `knowledge/report_2026-09-28_add_school_entry_crash.md`。
`UNVERIFIED`：修复后的真机 debug / release 走查。

Prevention: ① 门禁型 redirect 要以「目标是否为合法状态」为准，不能只按路径字面判断——
同一路径带不带 query 可以是完全不同的语义；② push / 重定向类改动要在同一轮盘点全部入口
（本条入口清单见报告 §7）；③ 有状态 shell 之后，「把 push 改写成当前 shell 地址」这种组合
必须进回归测试；当前测试套件没有任何一条覆盖「添加学校」入口，这是它能长期坏掉的原因。

# TASK-019 只记录的范围外问题（2026-09-26）

- `CONFIRMED`：原有右下角加号浮层遮挡周日11–12节的部分课程文字，API 36 约390dp 的匿名 QA 课程已复现。属于操作浮层/首页遮挡策略，本轮遵循范围约束未修改；不将该位置宣称为无遮挡验收。
