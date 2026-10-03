# 框架报告 — 教务系统导入与适配

2026-10-03 TASK-LOGIN-RESET-01：增加LoginRecoveryPolicy+LoginSessionReset。明确可信主frame401/TOO_MANY_REDIRECTS自动恢复一次，正常连接错误/403不清；菜单主动重登作为补充。精确Domain/Path与已访问origin，销毁旧上下文后删除、前缀Cookie核验、未知/共享父域/iOS partial。旧桥/错误/手动确认绑定generation；内核可持久保留Cookie，App不另行持久保存或记录。服务真实Android synthetic1/1、专项10/10；最终完整页自动恢复/全量/APK见report_2026-10-03_login_recovery.md。

2026-10-03 TASK-IMPORT-RELIABILITY-02：新增安全布尔探针遍历同源frame，最多32窗口、深度4；跨源只记inaccessibleFramePresent，不读或绕过。主动导入时最多4秒轮询动态标记；未知特征仍兼容回退。脚本放在局部作用域，按family对应frame执行；attempt独立桥/fetch/timers，在切候选/导航/重试/离页/结束时清理，不覆盖页面fetch/timer全局，不保证撤销已送达请求或任意DOM副作用。全量385/385及真实Android WebView synthetic1/1通过，严格CSP/下载正文取消经复审修正。真实学校/完整App跨host登录仍未验；详见report_2026-10-03_import_reliability_startup.md。

2026-10-03 TASK-WEBVIEW-FRAMEWORK-01：NavigationPolicy的hosts/schemes通过ImportWebSettings.toMap快照交给vendored Android两个Client；已确认主导航返回false继续原请求，未知主机仍经Dart确认/setSettings更新。HTTP(S)子frame继续，非法scheme原生取消；POST/初始/子资源不是全请求沙箱。主frame网络/HTTP错误由Flutter安全提示层覆盖，保留内核失败URL供reload；成功加载前与失败时禁用导入，generation隔离异步桥注入和适配尝试。昨日adapter profile/attempt契约保持；真实学校/真机/iOS未验。见report_2026-10-03_webview_framework.md。下方09-28“仅Dart子frame安全/无错误接管”是历史快照。

2026-10-02 TASK-ADAPTER-GENERAL-01 当前状态（优先于下方09-28审计快照）：catalog schema 2分离Adapter family与School Profile；ImportWebPage先按profile名称/别名、已保存adapter偏好、精确URL规则和页面布尔特征排序，再让未尝试的本地脚本按兼容顺序回退。页面探针不向Dart传页面文字、输入值、query或原始响应。每次尝试带attemptId；四个内置脚本在save/completion回传该ID，session拒绝旧attempt迟到回调。成功要求当前attempt完成且至少一门课程经既有normalizer接受。失败默认给可操作提示，用户主动查看/复制时才生成固定码诊断。Profile和课程字段alias只存在bundled catalog；当前生产schoolProfiles为空。导航、预览、diff、事务、课程数据范围与schema 3不变。

### TASK-ADAPTER-GENERAL-01 当前调用链

地址及明文风险确认 → WebView受限导航 → 页面内安全特征探针 → `AdapterProbePlanner`选出去重候选 → 每项间隔800ms、创建新attempt上下文后注入脚本 → `AdapterBridge`按可选attemptId暂存三类payload → 当前attempt完成后交`AdapterBatchNormalizer`校验 → 有效课程非空方可进既有diff/preview → 用户确认后经`CourseRepository.confirmImport`单事务写入 → 离开页面清理内存session。

候选顺序：profile精确name/alias → 学校档案既存adapterId → 精确host/path profile → 页面协议/功能特征 → 剩余bundled脚本兼容回退。页面信号只是排序提示，不单独构成匹配成功。成功门槛、schema、fixture范围、风险及未验证边界见`adapters.md`与`report_2026-10-02_adapter_framework.md`。

下方§3/§4中的行号和逐步表格是2026-09-28代码审计快照；与本节当前调用链或`adapters.md`不一致处，以2026-10-02代码与本节为准。

2026-10-02 TASK-LOGIN-REPAIR-01：学校首读前自动修复已知失效默认入口，ImportEntry预填已修URL；用户确认进入登录后复用updateLoginUrl保存网址/host，取消/非法不保存。旧“候选仅追加host不保存URL”失效。checkLoginUrl/NavigationPolicy/明文确认/WebView/平台网络规则未放宽；入口参数来自修后档案，无静默全局重定向。

## Last Updated

2026-10-03 +08:00 ｜ TASK-WEBVIEW-FRAMEWORK-01导航与加载错误；保留通用适配框架与09-28基线

## 当前结论提示（TASK-PROGRESS-REPORT-01）

`CONFIRMED`：TASK-DATA-INTEGRITY-01已将导入ID纳入semesterId，并由confirmImport单事务写入作息/课程/学期；本轮362/362包含完整性回归。下方§12的P0-O/P0-P及「无修复」是旧基线，不能当成当前未修项。依据：`course_repository.dart`、`import_integrity_test.dart`、数据完整性专项报告。

真实导入有tasks记录的09-14用户截图局部证据，完整验收仍未完成；4个内置脚本不等于各系统实测通过。联网更新未实现。全量边界见`report_2026-10-02_project_completion.md`。

证据来源：2026-09-28 只读代码调研（逐条核对链路、桥契约、策略落点与安全边界）。

> **安全敏感文件。** 本文件涉及凭据、会话、白名单与落盘边界。任何改动都要先读 `knowledge/adapters.md`（适配契约权威）与 `AGENTS.md` 安全边界，再回填本文件。

---

## 1. 边界

**负责**：用户在 WebView 里访问本校教务系统、由内置适配脚本抓取课表、经桥回传 Dart、规范化、diff、预览、确认写入 DB 的整条链路；以及这条链路上的地址校验、主机白名单、导航拦截、会话清理与落盘边界。

**不负责**：课表展示与渲染（→ `framework_motion.md` / `framework_glass.md`）、表结构与写库实现（→ `framework_data.md`）、适配脚本的上游来源与许可（→ `adapters.md`、`THIRD_PARTY_NOTICES.md`）。

---

## 2. 关键文件与入口

| 角色 | 文件 | 说明 |
| --- | --- | --- |
| 地址填写与启动 | `lib/features/import/pages/import_entry_page.dart` | 地址校验、确认弹窗、白名单落库、push 到 WebView |
| WebView 壳（唯一） | `lib/features/import/pages/import_web_page.dart` | 唯一 `InAppWebView` 宿主；桥注册、导航拦截、脚本注入、重试循环 |
| JS 桥契约 | `lib/features/import/services/adapter_bridge.dart` | 通道名、方法名清单、bootstrap JS（纯 Dart 常量，不 import 插件） |
| 内存会话 | `lib/features/import/services/import_session.dart` | `AdapterImportSession` + `ImportSessionNotifier` |
| 会话与缓存清理 | `lib/features/import/services/import_session_cleaner.dart` | 离开页面时清内存会话 + 清 HTTP 缓存 |
| 批次契约与规范化 | `lib/features/import/models/adapter_batch.dart` | `AdapterCourseDraft` / `AdapterTimeSlot` / `AdapterCourseConfig` / `AdapterBatchNormalizer` |
| 写入 | `lib/features/import/services/course_repository.dart` | `replaceImportedCourses` / `replaceSectionTimes` / 导入 id 指纹 |
| 差异比对 | `lib/features/import/services/import_diff.dart` | 按 `Course.id` 比对，统计新增/移除/修改 |
| 导航策略（唯一） | `lib/features/import/services/navigation_policy.dart` | `NavigationDecision.decide` |
| 地址校验（唯一） | `lib/features/schools/services/login_url_policy.dart` | `checkLoginUrl` |
| 预览与确认 | `lib/features/import/pages/import_preview_page.dart` | 四类计数、无效原因、两个可选写入、确认按钮 |
| 脚本目录与加载 | `lib/features/schools/services/adapter_catalog.dart` + `assets/adapters/` | `catalog.json` + 4 个脚本 |
| 内置学校档案 | `lib/features/schools/services/school_presets.dart` | 见 `framework_school_calendar.md` |

---

## 3. 完整链路

| # | 步骤 | 位置 | 异步/超时 |
| --- | --- | --- | --- |
| 1 | 用户勾选风险确认 | `import_widgets.dart:41` → `import_entry_page.dart:106,124` | — |
| 2 | 点「开始导入」→ `_start(schoolId)` | `import_entry_page.dart:207` | async |
| 3 | `checkLoginUrl(..., required: true)`（纯字符串/Uri 解析，**无网络**） | `:210` → `login_url_policy.dart:26` | 否 |
| 4 | 确认弹窗（明文 HTTP 额外警示） | `:217`、`:224-226` | 弹窗，无超时 |
| 5 | `appendConfirmedHost(schoolId, uri.host)` 落库白名单 | `:242-243` → `school_repository.dart:64-79` | async DB，无超时 |
| 6 | `context.push('/import/web?host=…&url=…')` | `:245-248` → `app_router.dart:141-147` | — |
| 7 | WebView `initState`：取会话、建 cleaner、组装 `_allowedHosts`、建 `NavigationPolicy` | `import_web_page.dart:73-89` | — |
| 8 | 首个请求 = 用户填的地址；settings 仅开 JS / 透明底 / 禁右键菜单 | `:136-141` | — |
| 9 | `onLoadStop` → 注入桥 bootstrap | `:146-150` | async，无超时 |
| 10 | 点「执行导入」→ `_runAutoImport()` | `:115` → `:452` | async |
| 11 | 取目录 → 注入 bootstrap → 循环每脚本：`reset()` → `_probeGap` → `scriptFor()` → `evaluateJavascript` → `_waitAttempt()` | `:453-487` | 见下 |
| 12 | `_waitAttempt`：尝试超时 **25s**、探测间隔 **800ms**、300ms 轮询、桥弹窗打开时重置 deadline | `:525-537`（常量 `:67,:70`） | 是 |
| 13 | 脚本经桥 save → 会话 `_rebuild` → `AdapterBatchNormalizer.normalize` | `:384-403` → `import_session.dart:34-53,69-89` → `adapter_batch.dart:79` | — |
| 14 | `notifyTaskCompletion` → 以 `normalized.courses.isNotEmpty` 判定本次尝试成败 | `:406-414` | — |
| 15 | 成功 → `completed` → `ref.listen` 见状态 → push 预览页 | `:483`、`:101-106` | — |
| 16 | 预览确认 → 可选替换作息 → 替换导入课程 → 可选写学期 → `reset()` → `go('/')` | `import_preview_page.dart:400,417,422,430,436,440` | async DB |

**只有 3 个显式超时/节流常量**（25s / 800ms / 300ms）。其余 async（`rootBundle.loadString`、`evaluateJavascript`、Dialog、DB 写）**均无超时**。

---

## 4. 适配脚本

`CONFIRMED`：

- 来源：内置资产 `assets/adapters/`（`pubspec.yaml:40-41` 声明目录），目录清单 `assets/adapters/catalog.json`。**无远程下载、无运行期更新**（只用 `rootBundle`，`adapter_catalog.dart:56-67`）。
- 共 **4 个脚本**（`test/adapter_catalog_test.dart:6-18` 断言 `hasLength(4)`）：

| 脚本 | 行数 | 键 |
| --- | --- | --- |
| `zhengfang_01.js` | 260 | 正方 |
| `qingguo_01.js` | 144 | 青果 |
| `urp_01.js` | 199 | URP |
| `chaoxing.js` | 727 | 超星 |

- 上游与许可：`THIRD_PARTY_NOTICES.md:3-32`（MIT）。**不得删除或改写该署名**。
- 每个脚本都是顶层 `async function runImportFlow()` 并在文件末尾直接调用，**无 IIFE 包装 → 注入即触发**。
- 注入时机：① 每次 `onLoadStop` 注入桥；② 点「执行导入」再注入一次桥；③ 适配脚本只在按钮按下后逐个注入。**不存在自动开跑**。

### `catalog.json` 条目模型

`adapter_catalog.dart:11-42`，字段（`:25` 注释「目前只有 `jsScript`；保留字段为将来扩展 JSON 直连接口」）：`id` / 名称 / `jsScript` / 匹配条件等。

---

## 5. JS 桥契约（`adapter_bridge.dart`）

- JS 侧调用：`window.flutter_inappwebview.callHandler(name, ...args)`（`:20-21,48-58`）
- 对外全局：`window.shiguangBridge`（同步）与 `window.shiguangBridgePromise`（异步）（`:59-75`）
- 幂等守卫：`__huikeBridgeInstalled`（`:46-47`）
- 注册点：`import_web_page.dart:142-145` → `_registerHandlers`（`:416-447`），**8 个 handler**

| handler | JS 侧 | 返回值 | Dart 行为 |
| --- | --- | --- | --- |
| `huike_showToast` | `showToast(msg)` | 无 | SnackBar（`:244-250`） |
| `huike_notifyTaskCompletion` | `notifyTaskCompletion()` | 无 | 完成信号（`:406-414`） |
| `huike_showAlert` | `await showAlert(title,message,buttonText)` | `bool` | 取消/未挂载 → false（`:252-282`） |
| `huike_showSingleSelection` | `await showSingleSelection(title,jsonNames,defaultIndex)` | `int?` 选中下标 | 取消/解析失败 → null（`:284-337`） |
| `huike_showPrompt` | `await showPrompt(title,message,defaultText,validator?)` | `String?` | **第 4 个参数 validator 未实现**，多余 JS 参数被忽略（`:339-382`） |
| `huike_saveImportedCourses` | `saveImportedCourses(json)` | `bool` | → `import_session.dart:34` |
| `huike_savePresetTimeSlots` | `savePresetTimeSlots(json)` | `bool` | → `import_session.dart:41` |
| `huike_saveCourseConfig` | `saveCourseConfig(json)` | `bool` | → `import_session.dart:48` |

- **注销：全仓无 `removeJavaScriptHandler` 调用** → handler 随 controller/页面生命周期存在，未显式注销。
- `AdapterBridge.handlerNames` 在 `lib/` 内无调用点，仅被 `test/adapter_bridge_test.dart` 使用。

---

## 6. 批次数据契约（`adapter_batch.dart`）

### 课程 `AdapterCourseDraft`（`:10-37`）

| 字段 | 必填 | 规则 |
| --- | --- | --- |
| `name` | ✅ | 非空（`:113-114`） |
| `day` / `weekday` | ✅ | int 1..7（`:116-117`） |
| `startSection` / `start` | ✅ | int 1..30（`:119-122`） |
| `endSection` / `end` | 缺省 = `startSection` | 须 ≥ start 且 ≤ 30（`:123-125`） |
| `weeks` | ✅ | `List<int>` 每项 1..40（去重排序）或字符串走 `parseWeeks`（`:142-150`） |
| `teacher` | 缺省 `''` | `:18,132` |
| 教室 | 缺省 `''` | 依次取 `position` → `classroom` → `room`（`:133`） |

### 作息 `AdapterTimeSlot`（`:39-49`）

`number`/`section`、`startTime`/`start`、`endTime`/`end` 三者必填；时间须匹配 `^\d{1,2}:\d{2}$`（`:161-168,186-189`）。

### 配置 `AdapterCourseConfig`（`:51-56`）

`semesterStartDate` 须匹配 `^\d{4}-\d{2}-\d{2}$`（`:172-176`）；`totalWeeks` int 1..30，越界置 null（`:177-183`）。两者默认 null。

### 结果 `AdapterImportBatch`（`:58-74`）

`courses` / `timeSlots` / `courseConfig` / `invalidCount` / `invalidReasons`。

### 校验与错误表达

- 全部校验在 `AdapterBatchNormalizer`（`:76-213`），**不抛异常**。
- 非法课程条目**直接丢弃并计数**（`:86-93`）；`invalidCount` 只统计课程（`:106`）；`invalidReasons` 只保留前 5 条人类可读原因（`:107,203-212`）。
- **时间槽非法条目静默丢弃、不计入 invalid**（`:95-99`）。
- JSON 解析失败由 `stage*` 返回 `false`（`import_session.dart:34-53,91-107`），该 bool 直接作为桥调用返回值。

---

## 7. 安全边界（**逐条给证据**）

### 7.1 明文 HTTP 与主机白名单

| 策略 | 唯一定义点 | 调用点 |
| --- | --- | --- |
| 地址校验（含明文判定 `isCleartext`） | `login_url_policy.dart:26-43`（`http`/`https` 均接受，`:39-41`；`:22`） | 仅 3 处：`onboarding_page.dart:275`、`school_manage_page.dart:204`、`import_entry_page.dart:210` |
| 主机白名单判定 | `navigation_policy.dart:36-44` → `NavigationDecision.decide` | `import_web_page.dart:173` |
| 白名单组装 | `import_web_page.dart:84-87`（`widget.host` + `school.acceptedHosts`） | — |
| 白名单持久化 | `school_repository.dart:64-79`（**只增不减**）；另 `:111`（改址）、`onboarding_page.dart:282`（建校） | — |

- host **精确匹配**：子域不放行、端口不参与判定（`test/navigation_policy_test.dart:36,59-75`）。
- 平台层放行：`android/.../network_security_config.xml:11` 是 `<base-config cleartextTrafficPermitted="true"/>`（**全局放行**）；iOS `Info.plist:5-9` 只有 `NSAllowsArbitraryLoadsInWebContent`（仅 WebView）。
- **已知来源注释与代码冲突（索引表 G）**：`AndroidManifest.xml:3-5` 注释写「不声明 `usesCleartextTraffic`：明文 HTTP 站点被系统默认拒绝，导入页只允许 HTTPS」，与同文件引用的 network security config 相反。按 `AGENTS.md`「冲突时以代码与测试为准」，**以 config 的全局放行为准**，注释待修。

### 7.2 导航拦截判定顺序（`import_web_page.dart:167-203`）

```
uri == null                                  → ALLOW
decide().allowed                             → ALLOW
scheme 非 http/https                          → CANCEL + 提示（对所有框架生效）
action.isForMainFrame == false                → ALLOW（子框架免主机确认；null 不走近路）
host 为空 或 已拒绝                            → CANCEL
已有主机确认弹窗在开                            → CANCEL
用户允许                                       → 追加白名单 + appendConfirmedHost 落库 + ALLOW
否则                                          → 记 _deniedHosts（仅会话内，不落盘）+ CANCEL
```

### 7.3 凭据与会话

- **不保存或上传教务密码**：`lib/` 内无密码/凭据输入或存储代码；无 `package:http`/`dio`/`HttpClient` 调用 → **无上传通道**。
- **Cookie 与 WebStorage 被明确保留**（`import_session_cleaner.dart:5-6`，DEC-010 延续），清理器**只清 HTTP 缓存**（`:25`）。因此「会话数据不落盘」严格指**内存导入会话**；WebView 内核管理的 Cookie 会留在应用数据目录，代码层**没有 Cookie 清理入口**（其内核过期策略**不确定**）。
- 无 Token 处理代码。
- `_deniedHosts` 只在会话内（`:53`），不落盘。

### 7.4 原始响应与中间结果的生命周期

| 数据 | 生命 | 证据 |
| --- | --- | --- |
| 适配脚本返回的原始 JSON、解析结果 | **只驻内存**（`AdapterImportSession`） | `import_session.dart:9-11,12-26` |
| 离开导入页 | `ImportSessionCleaner.dispose` → 清内存会话 + `clearAllCache()` | `import_web_page.dart:92-95` → `import_session_cleaner.dart:15-29` |
| 写入成功后 | 同样 `reset()` | `import_preview_page.dart:436` |
| **落盘的** | 规范化后的课程行、作息行、学期字段 | `course_repository.dart:36-57,70-82`、`school_repository.dart:151-168` |
| 文件/日志 | 代码中**无写文件、无写日志路径**；`lib/` 内无 `print`/`debugPrint`/`developer.log` | grep 0 命中 |

### 7.5 日志风险（事实，不下结论）

- 适配脚本自身含 `console.*`：`chaoxing.js` 45 处、`zhengfang_01.js` 12 处、`urp_01.js:160` 1 处。
- 其中 `chaoxing.js:437` 打印 `xhid`（该脚本注释称 `xhid` 为「学号ID」，`:509`）以及开学日期与课程数。
- 这些 console 是否进入 Release logcat 取决于 WebView 的 WebChromeClient 默认行为；**代码未设 `onConsoleMessage`** → **不确定**。
- 失败 SnackBar 直接拼接 DB error 文本（`import_preview_page.dart:442`）→ 具体内容是否含路径/SQL **不确定**。

---

## 8. diff 与写入语义

| 事实 | 位置 |
| --- | --- |
| 比对键 = `Course.id` = 内容指纹（`schoolId|name|weekday|startSection|endSection|weeks`，双散列 `imp-<schoolId>-<hex><hex>`） | `course_repository.dart:143-159` |
| **teacher/classroom/startTime/endTime/note 不进指纹** | 同上 |
| 只比 `source=imported` 的课程；手动课程不参与 | `import_preview_page.dart:472-486`、`import_diff.dart:55-57,61-78` |
| changed 字段口径：名称、教师、教室、星期、节次、周次（排序后比较）、起止时间、备注 | `import_diff.dart:11-28,30-38` |
| 写入**不是 upsert**：事务内先删 `(schoolId, semesterId, source=imported)` 再逐条 insert | `course_repository.dart:21-59` |
| **手工改过的导入课程会被覆盖**（编辑走 `updateCourse` + `copyWith`，保留 id 与 `source=imported`）→ 下次导入丢字段（含备注） | `course_edit_page.dart:304-317` |
| 删掉的导入课程下次导入会重新出现 | 同上 |
| 备注本来就不来自导入（预览构造的 `Course` 不带 note） | `import_preview_page.dart:381-396`、`course_repository.dart:138` |
| 作息：仅在预览页勾选时**整体替换该校全部节次**，分组 1-4 上午 / 5-8 下午 / 其余晚上 | `course_repository.dart:62-84,86-90` |
| 学期：`updateSemester` 对 null 用 `Value.absent()`，不覆盖 | `school_repository.dart:156-167` |
| **无显式去重**：指纹相同的两条会以同一 id 连续 insert → 主键冲突会中止整个事务 | 未找到去重代码 |
| **P0-O `CONFIRMED`：跨学期同课冲突。** `importedCourseId` 的指纹载荷**不含 `semesterId`**，而 `replaceImportedCourses` 只删**当前学期**的 imported 行 → 同一学校第二学期出现同样课程时，旧学期行仍在，插入同一主键会失败，**导入无法完成** | `course_repository.dart:143-158` + `:27-56` |
| **P0-P `CONFIRMED`：导入确认不是单一事务。** `_apply` 依次调用 `replaceSectionTimes` → `replaceImportedCourses` → `updateSemester`，前两者各自独立 `transaction`，学期更新又是独立写入；后段失败时前段已提交，界面只报一次「写入失败」 | `import_preview_page.dart:415-440` |

---

## 9. 预览页

- 展示：新增/移除/修改/无效 四类计数（`:136-163`）、无效条目与原因（`:196-226`）、作息勾选（`:228-235`）、学期勾选（`:237-254`）、差异明细（`:256-304`）；无差异与无数据各有文案（`:110-116`、`:48-53`）。
- 用户选择：`_replaceSchedule`（**仅在当前作息等于通用兜底时自动勾选**，且只初始化一次，`:68-73`）、`_applyConfig`（默认 false，`:35`）、「确认写入 N 门课程」（`:122-130`）。
- 确认链：`_apply` → 可选 `replaceSectionTimes` → `replaceImportedCourses` → 可选 `updateSemester` → `reset()` → SnackBar + `go('/')`；失败显示错误并恢复按钮（`:400-444`）。

---

## 10. 唯一定义点

| 策略 | 唯一位置 |
| --- | --- |
| 地址校验与明文判定 | `login_url_policy.dart` → `checkLoginUrl()` |
| 主机白名单判定 | `navigation_policy.dart` → `NavigationDecision.decide()` |
| 白名单组装 | `import_web_page.dart:84-87` |
| WebView 宿主与 settings | `import_web_page.dart:135-153` |
| 桥的通道名与方法名清单 | `adapter_bridge.dart` → `handlerNames` + 各调用辅助 |
| 批次字段与校验 | `adapter_batch.dart` → `AdapterBatchNormalizer` |
| 导入课程 id 指纹 | `course_repository.dart` → `importedCourseId()` |
| 会话与缓存清理 | `import_session_cleaner.dart` |
| 脚本加载 | `adapter_catalog.dart`（只用 `rootBundle`） |
| 超时常量 | `import_web_page.dart:67,70`（25s / 800ms） |

## 11. 改动时必须同步的位置

- 改白名单/地址/明文策略 → **先做入口盘点**（`AGENTS.md` 硬性要求：`onboarding_page` 建校、`school_manage_page` 改址、`import_entry_page` 导入确认、`import_web_page` + `navigation_policy` 导航、Android config + Manifest、iOS ATS）+ 本文件 §7.1
- 改桥方法名/参数 → `adapter_bridge.dart` + `import_web_page.dart` 的 8 个 handler + **4 个脚本内的调用点** + `test/adapter_bridge_test.dart`
- 改批次字段 → `adapter_batch.dart` + 4 个脚本的字段名 + `import_diff.dart` + 预览页展示
- 加/改适配脚本 → `assets/adapters/` + `catalog.json` + `framework_dependencies.md` + `THIRD_PARTY_NOTICES.md`（署名不得删改）+ `adapters.md`
- 改超时/重试 → `import_web_page.dart:67,70` + 本文件 §3
- 改清理语义（尤其 Cookie）→ `import_session_cleaner.dart` + 本文件 §7.3（**属安全边界变更，需用户确认**）

---

## 12. 已知问题与技术债

### P0（第二阶段复核新增，`CONFIRMED`）

> **基线说明**：以下两项描述的是**已提交基线 `7bc4f10`** 的状态。本文件建立时，工作区已出现另一会话的**未提交**改动（`course_repository.dart` 的 id 注释改为「学校 + 学期 + 内容指纹」、`import_preview_page.dart` 写入路径、新增 `test/import_integrity_test.dart`），指向的正是这两条。**本文件不覆盖未提交代码，也不判断其完成度**；该工作落地后须重新同步本文件与 `framework_data.md`（详见 `framework_index.md` 顶部「文档基线与并行改动」）。

- **O 跨学期导入主键冲突**：`importedCourseId` 不含 `semesterId`，`replaceImportedCourses` 只删当前学期的 imported 行 → **第二学期相同课程的导入无法完成**。现有 `course_repository_test.dart` 只测同学期重导与跨学校隔离，**未覆盖此场景**。
- **P 导入多段写入缺整体事务**：`replaceSectionTimes` / `replaceImportedCourses` / `updateSemester` 三段独立提交，后段失败时前段已落库而界面只报一次失败 → **部分写入**。需明确「要么全成、要么全不成」的合同。

> 第二阶段复核给出的下一步建议任务：**TASK-DATA-INTEGRITY-01**（处理跨学期导入课程 ID 与导入确认的整体事务边界，并验证失败回滚）。本报告只登记，不实施。

### 其余

- **索引表 G**：`AndroidManifest.xml:3-5` 注释与 `network_security_config.xml:11` 全局放行明文相矛盾。
- **索引表 K**：导入写入「删后重建」→ 手工改过的导入课程在下次导入后丢失。
- `chaoxing.js` 内含 45 处 `console.*`，其一打印 `xhid`（学号 ID）与开学日期 → 日志面风险**不确定**。
- `showPrompt` 的 `validator` 参数未实现（多余 JS 参数被忽略）。
- 时间槽非法条目**静默丢弃且不计入 `invalidCount`** → 用户看不到作息丢失。
- 内置脚本只发 `semesterStartDate`，**无脚本发 `totalWeeks`** → 预览页「共 N 周」分支在内置脚本下走不到。
- **无脚本哈希/签名校验**（DEC-008 记录联网更新（TASK-005）尚未开始，哈希校验留到那时设计）。
- 启动期与导入期的 async 调用（`rootBundle`、`evaluateJavascript`、DB 写）**均无超时**。
- `AdapterCourseDraft.toFieldMap` 无调用点。
- 无子框架注入保证：`onLoadStop`/`evaluateJavascript` 作用于主框架，代码未见按 frame 注入 → **不确定**。
- 未使用（本轮确认非必需，但属事实）：`CookieManager`、`onReceivedHttpError`、`onConsoleMessage`、`creationParams`。

---

## 13. 未验证边界

- **真实教务端到端：`UNVERIFIED`**（`adapters.md:3`；`tasks.md` TASK-006 仍在 Now，待用户验收适配器命中与预览明细）。
- 4 个脚本对真实站点的命中率、字段覆盖率：`UNVERIFIED`。
- 子框架（iframe）内课表页的抓取：**不确定**。
- Cookie 在 WebView 内核中的实际保留时长与清理时机：**不确定**。
- 适配脚本 `console.*` 是否进入 Release 日志：**不确定**。
- iOS WebView 的 ATS 表现与 `clearAllCache` 行为：`UNVERIFIED`。

---

## 14. 更新记录

| 日期 | 变更 | 依据 |
| --- | --- | --- |
| 2026-09-28 | 首次建立：完整链路、4 脚本、8 个桥方法、批次契约、安全边界逐条落点、diff/写入语义 | 2026-09-28 只读调研 |
| 2026-10-02 | catalog schema 2、School Profile、候选计划、attempt隔离与按需安全诊断；标明旧行号为历史快照 | TASK-ADAPTER-GENERAL-01 |
