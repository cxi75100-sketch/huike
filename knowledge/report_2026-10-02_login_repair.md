# TASK-LOGIN-REPAIR-01：旧教务入口自动修复与复发原因

2026-10-02 +08:00。用户明确要求由应用解决，不要求用户手动换网址。

## 历史核对与根因

`CONFIRMED`：commit4f7cef7（2026-09-14）修正school_presets.defaultLoginUrl和新建档案测试，但没有修复已有school.loginUrl。createSchool只在建校时把当时的默认网址写入，后续更新预设不会改已存记录。原ISSUE-013报告“不是代码缺陷”只说明最初域名失效的外部因素，没有覆盖此升级缺口。

`CONFIRMED`：ImportEntry._start原来只appendConfirmedHost，并以临时输入URL打开WebView，未保存候选loginUrl。因此在导入页临时修正一次地址后，下次打开仍可读回旧地址。

用户截图确实仍访问jwxt旧域名，但没有读取用户真机数据库，不能确定其旧值具体由哪一次建校/输入写入。两处实现缺口均会保留或复用旧值；不是代码中存在“使用时间到期”的机制，不应把ERR_CONNECTION_REFUSED当作账号过期或解析脚本出错。后续UI回合没有修改ImportWebPage网络/导航代码，git diff核对无相应变更。

## 修复

- SchoolPreset.replacementForRetiredLoginUrl唯一定义：仅已知retired host、HTTP/HTTPS默认端口、空或/根路径，无userinfo/query/fragment时返回当前预设入口。自定义host/path/port及未知学校不匹配。
- SchoolRepository.repairRetiredLoginUrls事务读取/定向更新，按presetId（非空优先）或精确校名识别学校，WHERE同时核对原loginUrl。只改loginUrl，不改课程/学期/作息/主题/确认hosts。
- schoolsProvider在query.watch前await修复；启动ready等待该provider，因此导入页首次预填不会先看到旧网址。兼容导入在beforeOpen完成，层级保持，不将feature预设引入数据库层。
- ImportEntry确认后复用updateLoginUrl持久化网址和host；updateLoginUrl合并成事务，相同网址不重复更新。取消/非法不保存，避免再次出现“临时能打开，下次又旧网址”。

## 入口与边界盘点

建校onboarding使用当前preset默认和checkLoginUrl；设置school_manage使用updateLoginUrl；导入确认ImportEntry现同样使用updateLoginUrl并保留明文确认；WebView/NavigationPolicy不变、参数来自修后入口且仍限定协议/host；AndroidManifest/network_security_config和iOS ATS不变。此次不扩大协议/域名/平台权限规则，修复不会预授权新host；用户正常进入导入时的已有安全确认保持。

## 验证

- `CONFIRMED`：专项18/18（retired_login_url_repair+import_flow_regression），最终全量367/367（concurrency2）、analyze无问题、独立代码复审APPROVE、diff-check通过。
- 新回归：provider首个列表即修正、重复修复幂等、其他列/课程/学期/hosts保持、改名但preset已知仍修、无关学校/自定义地址不动；真实入口widget预填与传给WebView参数、确认候选URL持久化、取消保持旧值。
- provider单测需listen保持实际强订阅；Riverpod3只read.future时可能暂停异步流而等待，测试补监听与异步清理。不得将测试生命周期问题当作app故障。导入Widget缺少原生平台实现的已知异常仅用于参数验证，不作为WebView成功加载证据。
- `UNVERIFIED`：用户真机旧档案升级/真实登录/课程导入与iOS；fixture和路由测试不能替代它们。

## APK

- `CONFIRMED`：汇课Release/Debug均构建成功，包名com.huike.huike_timetable，版本0.1.5+6；Release无debuggable标记，Debug有。两包沿用现有Android Debug签名，证书SHA256为9f3fff6ec93838bd7c1d4e2a66fc43ccd0d5a19c5856c6c45019571c20dc57b3；不等于正式商店签名。
- Release：build/app/outputs/flutter-apk/huike-20261002-login-repair-release.apk；SHA256：519A084951E56B3F98FF6387FD819E188651D39DC1C9B4CA1008F5E1348F5840。
- Debug：build/app/outputs/flutter-apk/huike-20261002-login-repair-debug.apk；SHA256：E7B612A54A6CF380B6C9CB9072BB5E4ECBCBFB4C1E511BAFD3784479C07E48F0。普通app-debug.apk同步为本轮Debug。
- `CONFIRMED`：本轮正常GET当前预设登录入口返回HTTP200，响应丢弃、不保存原始内容、不涉及凭据；HEAD403不能等同GET加载失败。仅本机网络证据，真机登录/导入仍UNVERIFIED。

本轮保留已有工作树与其他报告，无提交/推送/设备安装。
