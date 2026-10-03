# 兼容覆盖升级、旧图标与 Debug APK

2026-10-01 +08:00；TASK-LEGACY-UPGRADE-01；用户明确选择「直接覆盖旧应用，保留原数据」。本轮包含已修复的修改网址关闭红屏（ISSUE-020）。

## 安装契约

Android覆盖安装需要应用ID一致、签名证书一致和更高版本号。只修改图标或显示名称不能实现覆盖。已读取旧APK实际清单与公开证书，而非仅凭源码猜测。

| 产物类型 | 应用ID | 版本 | 签名 |
| --- | --- | --- | --- |
| 普通汇课 huike | com.huike.huike_timetable | 0.1.5 / 6 | 既有本机debug |
| 旧正式安装兼容 legacyUpgrade | cn.edu.ncpu.timetable.ncpu_timetable | 1.1.0 / 10006 | 原正式证书 |
| 旧Debug安装兼容 legacyUpgrade | 同上 | 同上 | 既有本机debug |

已核对旧正式universal版本1.0.3/versionCode4；旧1.0.1/1.0.2/1.0.3正式证书实测一致。10006同时高于旧ABI拆分版本范围。两个兼容包都是Flutter Debug构建；「正式签名」只指签名证书，不指release构建。它们代码与数据迁移相同，只签名不同。不同旧证书不能用同一APK覆盖，因此提供对应包，不能通过卸载来规避签名不匹配。

公开证书SHA-256：正式 `2e8ac142d9c68df3ebc45a77269b8c9d98ad313c4763ab704ba68087a8b58799`；本机debug `9f3fff6ec93838bd7c1d4e2a66fc43ccd0d5a19c5856c6c45019571c20dc57b3`。私钥、密码未输出或写入本仓库。Gradle仅通过HUIKE_UPGRADE_SIGNING_PROPERTIES环境变量指向外部本地properties；签名由flavor决定，buildType不覆盖它。

## 数据保留

旧文件ncpu_timetable.sqlite的schema1与当前huike_timetable.sqlite的schema3结构不同，不能简单改文件名或按当前v1→v3迁移原地打开。新增单向兼容导入，源SQLite OpenMode.readOnly +读事务，所有目标写入在一个Drift事务内。

- 所有学期和课程：保留ID、星期、节次、周次、显式起止时间、名称、教师、地点、备注、colorKey；旧manual/ncpu映射为manual/imported。日期按原Drift Unix秒解码。
- 自定义节次时间保留；分组沿既有1–4上午、5–8下午、9+晚间规则；使用内置学校档案恢复教室作息变体与教务入口，adapterId=auto。
- 旧当前学期规则是开学日期倒序第一条，迁移显式写当前学期key。旧自定义学期name归档在legacy_semester_name:<id>设置元数据；当前UI仍按已有日期/周次显示，未新增学期名称字段。
- 仅迁移合法theme_mode偏好；未知settings、账号、Cookie、Session、Token不复制。
- databaseProvider接入AppDatabase.beforeOpen，任何首读等待导入完成。成功marker最后写入；重复启动不重导，用户后来删除数据也不复活。已有目标学校时不覆盖；无旧文件的新安装保持原空引导。
- 错误整体回滚且不写marker，源库保留，下次开库可重试。HuikeApp通过既有主题首读hasError显示读取失败与重试，避免把失败误当作未建校；点重试invalidate数据库。未新增根组件学校订阅，避免重建无关WebView。

## 图标

按用户指定恢复蓝色Flutter标志。Android五密度launcher及foreground/monochrome共15 PNG原样复制；adaptive白底保留16% inset。iOS15 PNG与Contents.json使用同版资产；旧未引用槽位已移除。原图模板入库于assets/icon/native，tools/make_icon.py只复制，不重绘；tools/verify_icon.py逐字节、尺寸、slot及adaptive引用核对。原三白块报告与icon_qa.png是历史证据，不用于当前验收。

## 验证与限制

- `CONFIRMED`：迁移专项8/8；源文件成功/失败后逐字节不变，覆盖所有字段、多学期、自定义时间/主题、幂等、已有目标、事务失败重试、无源、未知schema、孤儿课程。
- `CONFIRMED`：应用级失败阻断与用户重试1项通过；导入WebView定向回归通过。一次全量查出的根组件额外学校订阅已收窄并复审。
- Widget测试清理曾因fake zone中预启动db.close使Drift暂停stream/Timer.run无法结束而挂起；修复测试资源所有权，全部容器与实例在runAsync中依次关闭，不吞超时或失败。生产迁移未因此改动。
- `CONFIRMED`：独立代码复审已解决签名覆盖和迁移失败空引导问题；图标15 Android/15 iOS检查通过。
- 最终全量、analyze、diff、APK文件/哈希在下方收口记录。
- `UNVERIFIED`：用户真机实际覆盖安装与原数据迁移、模拟器端到端覆盖、iOS构建/安装、真实教务登录/导入。没有读取真实用户旧数据库，仅使用合成fixture。签名/包名一致和测试不能替代设备验收。

## 构建入口

普通：`flutter build apk --debug --no-pub --flavor huike`。

兼容：`flutter build apk --debug --no-pub --flavor legacyUpgrade`。覆盖旧正式签名时设置HUIKE_UPGRADE_SIGNING_PROPERTIES指向原签名properties；旧debug安装构建时不设置它。不要把properties或keystore复制进仓库。

所有开工前未提交修改保留；无提交、推送或卸载操作。

## 最终验证收口

`CONFIRMED`：全量341/341；analyze无问题；导入+启动重试定向14/14；图标校验通过；git diff --check通过。两个兼容Debug包的apksigner证书分别匹配对应旧包；aapt实测应用ID/版本/debuggable=true与完整MainActivity正确。APK字节/哈希记录如下。

| 文件（build/app/outputs/flutter-apk/） | 字节 | SHA-256 |
| --- | --- | --- |
| ncpu-upgrade-1.1.0-debug-release-sign.apk | 207132705 | E2C997D09BE05C79D2F062634C5EFC1BFB48C7ED26104F68F4663B02D5C8897D |
| ncpu-upgrade-1.1.0-debug-debug-sign.apk | 174739901 | CB80E9F867376DB7C67ECDD8D943555B6918FCFDBF64838B3A71F7A97E0A7FF1 |
| app-huike-debug.apk（app-debug.apk副本相同） | 174740209 | 01F22DD4B74AFA6838B4725E2BEA4BC899C9425F94B3451F97B463DE48F79689 |

两兼容包的kernel_blob.bin与三种架构的Flutter/SQLite native库解压后SHA-256一致，证实同代码；体积差异不表示功能不同。三包包含arm64-v8a、armeabi-v7a、x86_64。普通汇课产物为app-huike-debug.apk，app-debug.apk同时更新为其副本。
