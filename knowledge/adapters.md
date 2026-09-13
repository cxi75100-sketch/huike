# 教务适配器契约与导入链路

Status: 代码与单测已验证（2026-09-13）；真实教务端到端 `UNVERIFIED`。

## 1. 资源来源与许可

- `assets/adapters/` 下的 4 个 JS 脚本（正方 / 青果 / URP / 超星通用获取）来自
  社区开源适配器仓库 **xingheyuzhuan/shiguang_warehouse**（MIT）。
  完整许可声明固定在根目录 `THIRD_PARTY_NOTICES.md`，不得删除或改写。
- `assets/adapters/catalog.json` 是本项目的目录清单（自定 schema），不是上游 yaml；
  字段：id / name / kind / asset / category / description / hints / maintainer。
- 参考实现（仅作行为对照，未复制代码）：单仓库适配器生态的宿主实现方式
  见同目录报告与本地研究笔记；本项目按 MIT 要求署名并保持契约兼容。

## 2. 桥契约（已按脚本用法全量枚举，见 grep 证据）

脚本运行在学校教务页面内，经以下全局对象与宿主通信：

| API | 形态 | 签名 / 返回 |
| --- | --- | --- |
| `shiguangBridge.showToast(msg)` | 同步 | 无返回 |
| `shiguangBridge.notifyTaskCompletion()` | 同步 | 无返回；脚本执行完毕 |
| `shiguangBridgePromise.showAlert(title, message, buttonText)` | 异步 | `bool`（确认=true，取消=null/false） |
| `shiguangBridgePromise.showSingleSelection(title, jsonNames, defaultIndex)` | 异步 | 选中**下标** `int`，取消 `null` |
| `shiguangBridgePromise.showPrompt(title, message, defaultText, validator?)` | 异步 | 输入串 `String`，取消 `null` |
| `shiguangBridgePromise.saveImportedCourses(json)` | 异步 | bool |
| `shiguangBridgePromise.savePresetTimeSlots(json)` | 异步 | bool |
| `shiguangBridgePromise.saveCourseConfig(json)` | 异步 | bool |

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
- WebView 导航白名单：scheme 仅 https（V1 不支持明文 HTTP 教务，入口页显式拦截并说明），
  host 仅用户确认过的主机（创建学校时的登录地址 + 运行期显式确认追加，只增不减）。
- 账号密码只在用户学校官方页面输入；App 不接触凭据，不绕过验证码/认证。

## 4. 导入写路径

- 课程 id：`CourseRepository.importedCourseId(schoolId, draft)`——
  内容指纹（校名+课程名+星期+节次+周次段）双散列；同内容同 id，内容变化即新 id，
  因此 `diffImportedCourses` 能识别「修改」。
- 作息：预览页勾选「同时更新默认作息」才整体替换 `section_time_entries`
  （默认勾选仅当现值仍等于通用兜底）；分组按 节次<=4 上午 / <=8 下午 / 其余晚上 推导。
- 学期配置：勾选「更新学期设置」才覆盖开学周一/总周数；未勾选不动用户值。

## 5. 新增内置适配器的流程

1. 取得脚本（需 MIT 或同等许可），放入 `assets/adapters/`。
2. `catalog.json` 登记条目（id 与 asset 对应）。
3. `test/adapter_catalog_test.dart` 会自动验证资产存在且使用桥契约。
4. 如脚本用了契约之外的新桥函数，先在 `AdapterBridge` 补处理器与单测，不盲猜语义。
