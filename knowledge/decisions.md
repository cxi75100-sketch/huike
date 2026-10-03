# Decisions

## 2026-10-03 登录失效恢复（TASK-LOGIN-RESET-01）

用户要求框架处理失效登录。正常保留内核Cookie/WebStorage，可信主frame401/内核重定向循环尝试一次受限恢复；网络中断/403/子资源/未知域不删。手动重新登录先确认，旧确认/generation失效即拒绝。只清已访问且确认范围，未知Cookie属性/共享父域/iOS返回partial；不全局删，不代输入凭据，不以触发信号断言Cookie根因。课表DB保持。

## 2026-10-03 通用浏览器导航（TASK-WEBVIEW-FRAMEWORK-01，DEC-006延续）

NavigationPolicy唯一提供host/scheme规则；既有settings接口将快照交给vendored Android同步解释器。已确认导航继续原请求，新主机保持Dart确认和动态更新；不维护学校特例、不放宽混合内容/证书。保留内核失败页供reload，由Flutter安全提示层覆盖；只手动重试。导航回调不覆盖POST/初始/全部子资源，不能宣称全请求沙箱；真实登录独立验收。

## DEC-001 使用 Flutter 做单机应用

Status: Accepted

Context: 目标是一套代码覆盖 Android/iOS 的多校课表工具，数据全部产生于本机（用户自己的课表）。

Decision: Flutter / Dart；Riverpod 3 状态管理、GoRouter 路由、Drift + SQLite 持久化；
不做后端、账号与云同步。

Reason: 课表是个人本机数据，没有同步需求；缩小安全面与交付范围，除教务登录外不接触任何用户数据。

Consequences: 数据只在本设备，跨设备迁移需另做导出（未做）；依赖 Flutter 工具链，
构建期需 sqlite3 hook（离线缓存办法见 `testing.md`）。

## DEC-002 多校是一等维度，且不内置任何默认学校

Status: Accepted

Context: 同一款 App 要服务不同学校，作息与校历差异很大；单校硬编码会迫使每个人改代码。

Decision: 学校 / 学期 / 课程 / 作息全部以学校为维度；2026-10-03用户明确调整首次使用：空库直接进入首页，主动导入时才填写学校/网址；
没有任何内置默认学校、默认学期或默认作息覆盖路径。

Reason: 任何「默认值」都会把某校的事实伪装成通用事实。

Consequences: 不生成虚构学校，空首页提供导入CTA；建校成功后回到导入确认。内置学校档案（`presetId` + 作息变体）只负责少填几次，
不作为兜底数据；通用兜底作息仅用于播种，并可用 `equalsFallback()` 判为「未被修改」。

## DEC-003 密码只在学校官方页面输入，导入原始数据只驻内存

Status: Accepted

Context: 教务凭据与课表原始响应都属于敏感数据。

Decision: App 不提供自建登录表单，不保存、不上传密码；脚本回传的三类 JSON 只进内存会话，
用户确认写入前不落库；离开导入页清理 HTTP 缓存与内存暂存（保留 Cookie）。

Reason: 不接触凭据、不绕过验证码与认证；内存优先把「误落盘」的可能性降到零。

Consequences: 导入依赖校方页面可用性与本机会话；调试不得用真实响应做样本，
只能使用脱敏后的解析结构。

## DEC-004 明文 HTTP 放开，取代按校白名单

Status: Accepted

Context: 大量教务是明文 HTTP，而 Android/iOS 无法在运行期新增放行域名；
先前实现的「按校白名单」把其它学校直接挡死（用户当即指出）。

Decision: Android `network_security_config` 的 base-config 允许明文、
iOS `NSAllowsArbitraryLoadsInWebContent`（仅 WebView）；应用层保留两道门——
入口地址确认（明文额外警示）与导航仅限确认过的主机。

Reason: 多校工具不能按校个案放行；协议由学校决定，App 的职责是让用户清楚自己正在明文站点上做什么。

Consequences: 明文风险由入口警示与主机确认承担；不得再回到按校名单拦截。
地址判定只有一个函数（见 DEC-006）。

## DEC-005 WebView 导航放开跨域跳转，逐主机确认一次

Status: Accepted

Context: 教务登录常跳统一认证/CAS 到另一域名。此前导航只放行入口那一台主机，
主框架跳转被 CANCEL，导入卡在登录页且用户只看到一条「已拦截」（见 ISSUE-001）。

Decision: 放行范围 = 入口地址 + 学校档案已确认主机 + 会话中新确认主机；
主框架跳到新主机时弹窗确认一次，同意即记住（内存 + `appendConfirmedHost` 落库，只增不减），
拒绝则本会话不再询问。子框架（iframe）不参与白名单判定。scheme 允许 http 与 https。

Reason: 域名无法预先穷举；白名单必须来自用户显式确认，但不能因此把正常登录流程拦死。

Consequences: 首次遇到统一认证域名会多一次确认；用户点过的域名被永久记住；
子框架放行是有意为之（教务常用 iframe 承载课表），意味着白名单只约束用户可见的主框架导航。

## DEC-006 教务地址校验只有一个函数

Status: Accepted

Context: 明文放开时只改了引导页与导入入口，学校管理页仍硬拦 HTTPS，
同一所学校的地址在三个入口有两套判定（见 ISSUE-002）。

Decision: 地址判定统一在 `features/schools/services/login_url_policy.dart` 的 `checkLoginUrl`；
引导页建校、学校管理改址、导入入口三处都调用它；http/https 都接受，明文由入口额外警示。

Reason: 同一策略多处各写一份必然漏改，且漏掉的那处会让功能对部分学校不可用。

Consequences: 新增入口必须调用该函数；任何放宽类改动先做入口盘点（见 `AGENTS.md` 工程准则）。

## DEC-007 机制归交付方：探测全自动、不展示过程

Status: Accepted

Context: 用户在 2026-09-14 明确要求——「用户只需要负责使用，我们负责交付，过程为什么要显示出来」。
当时探测会逐个弹出「正在尝试某个适配器」，全部失败还罗列四项结果。

Decision: 适配器探测顺序、重试、请求间隔、失败后是否继续全部由 App 承担；
不展示逐个尝试的过程，不向用户征求「是否继续」；脚本之间固定间隔 800ms；
全部失败默认只给可操作提示。用户主动要求排查时可查看结构化诊断，但只显示固定阶段、状态、错误码与静态脱敏说明，不显示动态异常、页面/网络数据或候选过程（TASK-ADAPTER-GENERAL-01）。

Reason: 用户无法对内部机制做出有意义的判断，暴露过程只会增加负担与误操作。

Consequences: 默认界面保持简单；安全诊断只在用户主动请求后展示，且不得形成原始页面/凭据的旁路。异常依靠代码、固定码和单测覆盖；请求节奏由代码控制，配合安全边界里的「不高频抓取」。

## DEC-008 内置社区脚本随提交固定，哈希校验推迟

Status: Accepted

Context: 仓库已公开，内置 4 个社区脚本（MIT）在用户已登录的 WebView 中执行；
联网更新（TASK-005）尚未开始。

Decision: 现阶段脚本拷贝入库、随提交固定，不做运行期下载；
哈希校验留到 TASK-005 确定配置源时一并设计。

Reason: 没有更新通道时，哈希校验没有可校验的对象。

Consequences: 升级脚本必须走提交与发版；TASK-005 开工前必须先定哈希/签名与失败回退策略。

## DEC-009 先做调休/停课例外表，再做桌面小组件

Status: Accepted

Context: 小组件载荷 v2 计划由 Dart 预计算整学期每日课程；
调休/停课例外表（TASK-004）尚未实现，一旦例外可编辑，预计算结果即失效。

Decision: TASK-004 排在 TASK-002 之前。

Reason: 避免小组件做完就返工。

Consequences: 小组件交付时间后移；TASK-004 需同时定义例外对显示与提醒的作用范围。

## DEC-010 校历例外只表达「停课」与「按某天课表上课」

Status: Accepted

Context: 调休的现实形态有两种：放假（当天不上课）与补课（例如周六补周四的课）。
另一种常见建模是「把某天的课移到另一天」的课程级调整。

Decision: 例外表只存「某天停课」或「某天按星期 N 的课表上课」；同一天只保留一条，
再填即覆盖。不表达课程级的挪课。

Reason: 课程以「周次 × 星期」表达，挪课会让同一节课同时出现在两个日期上，
用户看到重复条目、删除时还要判断删哪一条；按「这天照谁的课表过」建模与课表的
周次语义天然一致，也与学校的实际校历公告一致。

Consequences: 极少数「只挪某一门课」的需求无法表达（需要时再单独立模型，不要塞进本表）；
小组件与上课提醒必须经 `CalendarExceptionService` 折算后再取课，否则调休日会显示错的那天。

## DEC-011 学校Profile复用协议族适配器，未知页安全回退

Status: Accepted（2026-10-02，TASK-ADAPTER-GENERAL-01）

Context: 将课表导入扩展到更多学校时，不能把学校和脚本固化成一对一映射；四个既有解析脚本也不能证明覆盖所有教务系统。需要区分可验证的学校级选择提示、协议族与特化配置，同时保留未知页尝试已有通用脚本的能力。

Decision: bundled catalog以Adapter family承载共享协议族，以School Profile提供精确校名/别名、精确host/path、可选variant/options；先按profile和学校既存adapter偏好选择，再使用安全页面特征排序，最后让未尝试的bundled adapter按兼容顺序回退。只用证据确认的生产profile；当前不猜真实学校映射、不远端加载。探针返回布尔特征，不把页面文字或原始URL细节交给Dart。候选执行仍须当前attempt完成且规范化后存在有效课程方可成功；诊断遵循DEC-007。

Reason: 少量协议实现配合学校轻配置，可以让同family学校共享脚本；明确回退与成功门槛可降低漏尝试和误识别风险，同时保留扩展入口，而不制造全校覆盖的虚假承诺。

Consequences: catalog schema 2仅扩展assets契约，Drift schema仍3。新适配需先建立合成页面特征与bridge payload fixture；真实系统命中、页面版本差异、设备WebView仍需端到端验收。异常自研学校才考虑专用adapter，不以宽泛URL/域名规则冒充协议支持。
