# 2026-10-02 通用教务适配框架实施报告（TASK-ADAPTER-GENERAL-01）

## 结论

本轮把导入从“固定顺序逐个试脚本”扩展为“学校轻量配置 → 少量协议族 → 页面安全特征排序 → 内置兼容回退”的框架。协议实现和学校配置已经分开；一个protocol family可被多个School Profile复用。没有添加未经真实系统确认的学校映射，也没有声称四个既有脚本覆盖所有高校。现有桥、课程校验、预览/diff/确认事务、学校学期隔离、手动课程和导航策略保持。

## A. 改造前的导入架构审计

- `ImportEntryPage` 校验并确认登录网址与风险提示后进入唯一 `ImportWebPage` WebView；导航由现有 `NavigationPolicy` 限定，主框架新host仍逐次确认，iframe规则保持。
- WebView 安装既有 `AdapterBridge`，将脚本的课程、作息、学期配置暂存在 `ImportSessionNotifier` 内存；原 JS handler 名称和三类数据首参数与既有契约一致。
- 导入尝试原本主要依据现有本地 catalog/固定兼容循环。会话数据经 `AdapterBatchNormalizer` 进入既有课程模型，再由预览展示新增/移除/修改及无效项。只有用户确认才经 `CourseRepository.confirmImport` 在一个事务中写课程与所选作息、学期设置；离开导入流程清理会话。
- 审计确认需补强的是学校和脚本解耦、候选优先级及跨尝试迟到回调隔离、profile字段差异配置、失败诊断安全模型与可扩展fixture。未将“用户重导时如何保留用户改动”这一独立产品行为纳入本轮。

## B. 新导入架构与调用链

入口确认 → 受限 WebView → 页面内只读特征探针 → `AdapterProbePlanner`结合 profile、已存偏好、精确URL和页面特征排序并去重 → 每个候选使用独立 attempt 上下文（候选间隔800ms）→ bridge 暂存带 attemptId 的结果 → 当前 attempt 完成后规范化 → 至少一门有效课程才进入既有预览 → 用户确认后单事务写入 → 离开页面清理内存会话。

探针只把布尔值与协议族标记交给Dart，不传页面文字、输入值、query、Cookie、Token或响应正文。profile/fingerprint仅用于候选排序；信号本身不算成功。未知页面仍可走未尝试的内置脚本兼容回退。

## C. 新增与修改的核心文件

- 新增：`lib/features/import/services/adapter_probe.dart`（安全特征、profile候选计划与兼容回退）；`lib/features/import/models/adapter_diagnostic.dart`（受控阶段/状态/错误码）；四类synthetic fixtures、`test/adapter_probe_test.dart`、`test/adapter_diagnostic_test.dart`。
- 修改：`lib/features/schools/services/adapter_catalog.dart`、`assets/adapters/catalog.json`；`adapter_batch.dart`、`adapter_bridge.dart`、`import_session.dart`、`import_web_page.dart`、`import_preview_page.dart`；四个既有 JS adapter 增加attempt上下文回传并收敛异常输出；已有catalog/batch测试扩展。
- 同步：`current_state.md`、`tasks.md`、`adapters.md`、`framework_import.md`、`framework_index.md`、`architecture.md`、`decisions.md`、`issues.md`、`testing.md`、`changelog.md`及本报告。
- 未新增运行时依赖；既有社区脚本许可及署名保留。

## D. Catalog / Adapter Profile最终结构

`catalog.json` 使用 `schemaVersion: 2`。每个Adapter条目保留 `id/name/kind/asset/category/description/hints/maintainer` 等既有字段，新增/明确 `family` 与 `supportsAttemptToken`。Family表示可共享的解析协议族；Adapter仍是实际可执行脚本。

`schoolProfiles[]` 是可选学校轻配置：`id`、`name`、`aliases[]`、`adapterId`、可选 `variant`、`urlRules[]`、`options`。URL规则仅精确host和可选path前缀（按路径边界匹配），不接受通配域名。`options.courseFieldAliases`接入标准课程规范化，允许已知的桥字段名称映射到统一课程字段。当前生产 `schoolProfiles` 为空，避免猜测真实学校和地址；schema 1 catalog仍可读取。

## E. Adapter选择与fallback算法

候选顺序为：精确profile校名/别名 → 学校档案已保存的adapterId偏好 → 精确host/path profile → 页面内布尔/协议族特征 → 其余本地bundled脚本兼容回退。候选ID去重；脚本失败后继续下一项。页面探针不使用泛域名、学校名称相似度或页面任意文本猜测。

匹配成功条件为：收到属于当前 attempt 的完成通知，且本次标准化结果至少含一门有效课程。单纯脚本无异常、发现表格/hidden input、空列表或配置出现都不会判成功。存在有效与无效课程时进入部分成功状态，并由现有预览显示计数；全部无效不进入预览。学校、学期及手动课程写入范围仍由现有确认事务控制。

## F. 错误与诊断模型

`AdapterDiagnostic`只由枚举阶段、状态、固定错误码和静态描述组成，覆盖登录/页面识别/脚本执行/桥payload/课程规范化/无有效课程/部分成功/写入等阶段。默认失败页面仅提供可操作提示；用户主动选择“查看安全诊断”后才显示或复制诊断JSON。未把动态异常、完整URL、query、页面内容、课程内容、账号/密码、Cookie、Session或Token放入诊断；诊断只在当前内存流程使用，不落盘、不上传。写事务失败由既有事务回滚，并显示固定安全错误。

## G. 测试及结果

- 新增四类页面特征和最小bridge payload synthetic fixtures，无真实高校网页、账号或课表数据。
- 覆盖schema 1兼容/schema 2解析、profile精确别名与URL规则、同family不同profile/字段alias、候选排序与未知页回退、当前attempt成功门槛、迟到attempt回调拒绝、诊断脱敏。
- `flutter test --no-pub --reporter expanded --concurrency 2`：**377/377 passed**。首轮全量曾有calendar exception日期测试一次未复现失败，该测试单跑5/5通过，随后concurrency 2全量377/377通过；不据此声称修复或制造与适配改动有关的回归。

## H. Analyze / diff-check / build

- `flutter analyze --no-pub`：无问题。
- `git diff --check`：最终通过；先前发现的一个adapter脚本行尾空格已修正。Git提示部分既有Windows工作区文件存在LF/CRLF转换警告，不是空白错误。
- 普通无flavor构建命令曾报告成功，但对应的旧 `app-debug.apk` 内仍是catalog schema 1，因此没有把它计作本任务产物；旧包已备份保留。
- `flutter build apk --flavor huike --debug --no-pub`：成功输出 `build/app/outputs/flutter-apk/app-huike-debug.apk`；从APK内解包检查确认 `assets/flutter_assets/assets/adapters/catalog.json` 为schema 2。SHA-256：`B1B100D8B44B700A3A0B12FFEFFBD3D7F9DA44095C58C88286E64F67F41489D8`。本次没有安装该包；debug构建不能代表Release、设备WebView或真实登录验收。

## I. 旧数据与旧 Adapter 兼容性

- catalog schema 1仍可加载；学校表既有 `adapterId` 继续作为选择偏好，不需要数据迁移。
- bridge handler名称、旧调用第一数据参数形状与回值不变。attemptId是新增可选参数；没有token的旧桥脚本按catalog能力继续兼容。旧脚本不提供跨尝试隔离保证，内置四个脚本已接入token。
- batch normalizer仍产出既有课程模型；字段alias只在显式profile option存在时生效，不改变缺省映射。
- 预览、确认事务、导入范围、导航安全策略与本地缓存/session清理契约保持。

## J. 当前能够声明支持的协议范围

仓库内当前包含四个既有适配脚本：正方、青果、URP与超星；实现中保留各自已有页面结构识别逻辑，并为候选排序添加对应安全特征。当前可以声明“本地存在这四类通用解析实现及可扩展选择框架”；不能声明任一具体高校已由本轮真实登录验证，也不能声明四类实现覆盖所有版本、二次开发或所有高校。

## K. 仍需真实学校验证

需要用户在本人设备和学校账号环境完成“登录 → 课表页 → 导入 → 预览 → 确认写入”，核对真实适配器命中、字段覆盖、跨域登录、作息/学期选项和最终课程。当前既无真实页面fixture，也未连接真机/iOS；真实教务成功、真实网页selector稳定性、WebView行为均为 `UNVERIFIED`。不得将synthetic fixture、widget测试、analyze或APK构建当作替代证据。

## L. 下一所学校接入步骤

1. 先取得用户授权范围内、已脱敏的真实页面/字段证据；不保存密码、Cookie、Session、Token或原始响应。
2. 可复用family时，在catalog增加该校精确Profile、经证据确认的别名/host/path及必要options；为安全页面特征和bridge payload加入synthetic `.test` fixture，补候选与normalizer测试。仅字段名差异优先使用 `courseFieldAliases`。
3. 若需新协议实现，增加一个可复用的family adapter脚本并在catalog登记，不先复制成每校一份；同步补该类安全探针与fixture。仅确属独特或高度魔改协议才采用专用Adapter。
4. 若桥契约确实缺少必要能力，先定义并测试兼容桥接口，再接入脚本；若引入第三方脚本，核对许可并更新 `THIRD_PARTY_NOTICES.md`。
5. 完成单测/analyze后，在真实学校环境做独立端到端验收并明确记录 `CONFIRMED` 范围和未覆盖版本。

## M. 数据库迁移

**没有数据库 migration；Drift schema仍为3。** School Profile和family属于bundled catalog配置；不改数据库表或版本。

## N. 未解决事项与回归风险

- TASK-006仍待真实教务导入验收；当前任务不关闭该验收项。
- 四类脚本遇到学校自研/升级页面结构时仍可能全部失败；fallback提供扩展机会，不保证命中。特征探针如无足够页面标记可能排错候选顺序，但候选最终仍逐项回退。
- 本轮未改变导入覆盖用户改动课程的产品策略；未实现TASK-005远端adapter更新；无真实profile、无新教务协议族、无平台权限或host白名单放宽。
- 已回归确认profile不污染其它学校/学期；现有事务及手动课程隔离路径未改，完整写入回归在377项全量中通过。adapter之间存在共享JS页面环境的历史行为，attempt token隔离了迟到bridge回调；真实页面副作用仍需WebView验收。
- 无提交、推送或设备安装；保留工作区内并行/既有未提交改动。
