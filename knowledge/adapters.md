# 教务适配器契约与导入链路

2026-10-03 TASK-LOGIN-RESET-01：可信主frame401/明确跳转循环自动受限重登一次，不自动处理403/连接错误；normalizer/preview/课表DB不变。重登旧上下文销毁、generation失效，8桥回调均拒绝旧view。scope Cookie/存储与真实验证边界见report_2026-10-03_login_recovery.md。

2026-10-03 TASK-IMPORT-RELIABILITY-02：同源frame布尔探针与framePath静态索引，不传页面内容。导入前最多4秒动态等待，按family选同源执行窗口；局部函数包装保持四个脚本的window.shiguangBridge*合同与attemptId。运行时仅管理本次脚本的桥/fetch/timers，不修改学校页面全局。跨源frame不绕过，真实学校命中仍UNVERIFIED。专项10/10、全量385/385、真实Android WebView synthetic1/1、analyze/复审通过；实跑内置URP，其余三脚本仅源码核对。详见report_2026-10-03_import_reliability_startup.md。

2026-10-03 TASK-WEBVIEW-FRAMEWORK-01：加载失败前不执行适配；主frame网络/HTTP错误禁用导入并提供安全提示/手动reload。导航generation终止旧attempt并清理内存，异步脚本读取后再次检查当前页面。既有profile候选、attemptId、normalizer与确认事务不变；同步原生导航快照和验证边界见report_2026-10-03_webview_framework.md。

Status: 通用适配框架与合同 fixture 经代码/单测验证（2026-10-02）；真实教务端到端与四类脚本的真实学校命中仍 `UNVERIFIED`。

## 1. 资源来源与许可

- `assets/adapters/` 下的 4 个 JS 脚本（正方 / 青果 / URP / 超星通用获取）来自
  社区开源适配器仓库 **xingheyuzhuan/shiguang_warehouse**（MIT）。
  完整许可声明固定在根目录 `THIRD_PARTY_NOTICES.md`，不得删除或改写。
- `assets/adapters/catalog.json` 是本项目的目录清单（schema 2），不是上游 yaml；
  adapter 字段含 id / family / kind / asset / category / description / hints / maintainer，
  并标记 bundled script 是否回传尝试 ID。`schoolProfiles` 保存可选别名、精确 URL 规则、
  adapterId、variant 和 options。当前 `schoolProfiles` 为空：没有经证据确认的真实学校映射。
- 参考实现（仅作行为对照，未复制代码）：单仓库适配器生态的宿主实现方式
  见同目录报告与本地研究笔记；本项目按 MIT 要求署名并保持契约兼容。

## 2. 桥契约（已按脚本用法全量枚举，见 grep 证据）

脚本运行在学校教务页面内，经以下全局对象与宿主通信：

| API | 形态 | 签名 / 返回 |
| --- | --- | --- |
| `shiguangBridge.showToast(msg)` | 同步 | 无返回 |
| `shiguangBridge.notifyTaskCompletion(attemptId?)` | 同步 | 无返回；结束当前导入尝试。无参数仍兼容旧 bridge 调用 |
| `shiguangBridgePromise.showAlert(title, message, buttonText)` | 异步 | `bool`（确认=true，取消=null/false） |
| `shiguangBridgePromise.showSingleSelection(title, jsonNames, defaultIndex)` | 异步 | 选中**下标** `int`，取消 `null` |
| `shiguangBridgePromise.showPrompt(title, message, defaultText, validator?)` | 异步 | 输入串 `String`，取消 `null` |
| `shiguangBridgePromise.saveImportedCourses(json, attemptId?)` | 异步 | bool |
| `shiguangBridgePromise.savePresetTimeSlots(json, attemptId?)` | 异步 | bool |
| `shiguangBridgePromise.saveCourseConfig(json, attemptId?)` | 异步 | bool |

后三个 save 与完成方法只在第二个参数增加可选尝试 ID；原 handler 名、首参数数据形状和返回值不变。当前四个本地脚本均回传该 ID，过期尝试的迟到回调被会话拒绝；旧的一参数桥调用仍可运行。

数据形状（契约）：

```jsonc
// saveImportedCourses
[{ "name": "", "teacher": "", "position": "", "day": 1,
   "startSection": 1, "endSection": 2, "weeks": [1,2] }]
// savePresetTimeSlots
[{ "number": 1, "startTime": "08:00", "endTime": "08:45" }]
// saveCourseConfig
{ "semesterStartDate": "2026-09-07", "totalWeeks": 20 }
```

本 App 的处理器名（`AdapterBridge.handlerNames`）：`huike_showToast`、
`huike_showAlert`、`huike_showSingleSelection`、`huike_showPrompt`、
`huike_saveImportedCourses`、`huike_savePresetTimeSlots`、
`huike_saveCourseConfig`、`huike_notifyTaskCompletion`。
桥 JS 侧幂等（`__huikeBridgeInstalled` 守卫），对外保持 `shiguangBridge*` 契约名。

## 3. 安全语义

- 三类 `save*` **只写入内存会话**（`ImportSessionNotifier`），不写库、不落盘、不写日志；
  原始 JSON 离开导入页即丢弃（`ImportSessionCleaner`）。
- 落库必须经预览页确认；差异按 (schoolId, semesterId, source=imported) 范围替换，
  手动课程永不触碰。
- WebView 导航白名单：scheme 允许 http/https（明文教务已放开）。host 放行范围 =
  入口地址主机 + 学校档案 `acceptedHosts` + **会话中用户新确认的主机**——主框架跳到新主机时
  弹窗问一次「允许访问 xxx」，同意即加入白名单并通过 `appendConfirmedHost` 落库（只增不减），
  拒绝过的主机本次会话不再询问。因此教务登录跳统一认证/CAS 可正常继续。
  子框架（iframe）不参与判定：正方等教务常用 iframe 承载课表，拦掉会弄坏页面
  （`import_web_page.dart` 的 `_handleNavigation`）。
- 自动探测优先级：catalog school profile 精确名称/别名 → 已保存的学校 adapterId → 精确 host/path profile →
  页面安全特征 → 其余内置通用脚本兼容回退。候选去重；失败继续下一项，脚本间仍间隔 800ms。
  未知学校和探测失败不会被阻断。页面探针只返回协议族布尔标记、是否存在密码输入框和课表标记；
  不把页面文字、输入值、URL query 或原始响应传入 Dart。青果探针只在页面内把表格文本用于布尔判断。
- **默认不显示探测顺序。** 全部失败时显示可操作提示；用户主动点「查看安全诊断」后才可查看/复制
  adapter/family、阶段、固定错误码与脱敏开发说明。诊断不含完整 URL、页面数据、账号、Cookie、token 或动态异常；
  只留在当前内存会话，不写文件、不上传。
- 成功条件不是「脚本没抛异常」或空数组：完成信号须来自当前尝试，且现有 batch normalizer 至少接受一门课程。
  有效课程与无效项并存时标为 partial success；全部无效不会进入预览。预览显示目标学校、学期锚点、adapter 类型和有效/无效数量。
- `options.courseFieldAliases` 是目前接线的 school profile option：它把有限字段名别名映射回既有统一课程模型。
  未添加未经证据支持的 URL、selector、endpoint 或教学楼规则；其它静态 options 可传给脚本上下文供已实现变体使用。
- 账号密码只在用户学校官方页面输入；App 不接触凭据，不绕过验证码/认证。

## 4. 导入写路径

- 课程 id：`CourseRepository.importedCourseId(schoolId, semesterId, draft)`——
  学校、学期、课程名、星期、节次、周次段构成稳定双散列，并在 ID 中保留学校和学期前缀；
  同学期同内容同 id，跨学期同内容不冲突。预览差异和落库共用此函数。
  旧格式 ID 在同学期重导时随范围删除被新 ID 替换；首次重导的预览差异可能显示移除和新增。
- 作息：预览页勾选「同时更新默认作息」才整体替换 `section_time_entries`
  （默认勾选仅当现值仍等于通用兜底）；分组按 节次<=4 上午 / <=8 下午 / 其余晚上 推导。
- 学期配置：勾选「更新学期设置」才覆盖开学周一/总周数；未勾选不动用户值。
- 确认导入：`CourseRepository.confirmImport` 将所选作息替换、导入课程替换、所选学期配置更新
  放在同一个 Drift 事务中。任一步失败时全部回滚；单独调用两个 `replace*` 方法仍各自保证原子性。

## 5. 新增内置适配器的流程

1. 取得脚本（需 MIT 或同等许可），放入 `assets/adapters/`。
2. `catalog.json` 登记条目（id 与 asset 对应）。
3. `test/adapter_catalog_test.dart` 会自动验证资产存在且使用桥契约。
4. 如脚本用了契约之外的新桥函数，先在 `AdapterBridge` 补处理器与单测，不盲猜语义。

## 6. School/Adapter Profile 与 fixture

- schema 2 仅扩展 bundled catalog，不扩展 Drift；数据库仍为 schema 3。
- `schoolProfiles[]` 字段为 `id`、`name`、`aliases[]`、`adapterId`、可选 `variant`、`urlRules[]` 与 `options`。
  `urlRules` 只接受精确 host 和可选 path prefix，不支持通配域名；adapter 条目的 `family` 将学校映射到共享协议族。
- 新学校先查能否复用已有 family/script。只有真实证据支持的别名/host/path 和解析差异才进 catalog；
  测试 profile 使用 `.test` 域名与 synthetic aliases，不代表真实高校。
- 四类 fixture 位于 `test/fixtures/adapters/`，只含安全页面特征快照和最小 bridge course JSON；
  验证候选排序、统一规范化和配置字段别名，不替代真实 WebView/教务端验收。
