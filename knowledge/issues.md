# Issues

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
失败只给一句可操作提示「确认已登录并停留在课表查询页面后重试」，
仅「执行中断」这类异常才附错误行（见 DEC-007）。

Evidence: `CONFIRMED` 代码与单测；`UNVERIFIED` 装机观感。

Prevention: 面向用户只呈现「你要做什么 / 结果如何」，不呈现内部机制（DEC-007）。

## ISSUE-004 真实教务导入未验收

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
