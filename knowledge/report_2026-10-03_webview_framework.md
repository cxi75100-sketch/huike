# 2026-10-03 通用教务登录浏览器框架排查与修复（TASK-WEBVIEW-FRAMEWORK-01）

用户要求审查框架后解决，不为任何学校或网址增加特例。保留已有未提交改动；不提交、不推送、不记录教务凭据或原始网页。

## 结论与昨天改动的关系

`CONFIRMED`：截图是主页面加载失败（ERR_CONNECTION_ABORTED），发生在课表提取之前。截图地址属于RFC1918私有网络范围。截图不是适配器不匹配的证据，也不能单凭该码判断实际连接在哪一层中止。

`CONFIRMED`：已逐项读取昨日 TASK-ADAPTER-GENERAL-01 的报告及当前diff：catalog schema 2、页面特征探针、候选排序、attemptId、alias和安全诊断都在用户点击执行导入后使用；onLoadStop只记录当前URL并注入桥。桥bootstrap没有网络请求、地址重写或自动运行适配脚本。昨天未更改网络权限、URL参数来源或host导航判定。没有发现该批适配改动直接导致截图加载失败的代码路径。

`INFERRED`：真实网络/代理/服务器或既有浏览器导航行为是需要区分的方向。无法确认截图是否经历重定向，故不能宣称本轮原生修复就是该手机ERR_CONNECTION_ABORTED的已证实根因。昨天377项synthetic/widget验证和APK未包含真实WebView登录；本轮保留这一证据边界。

## 入口和框架审计

| 入口/层 | 核对结果与处置 |
| --- | --- |
| onboarding建校 | 调用唯一checkLoginUrl；HTTP/HTTPS、IP、端口接受；不改学校数据 |
| school_manage改址 | 同一checkLoginUrl、updateLoginUrl；保持既有控制器生命周期修复 |
| ImportEntry确认 | 同一checkLoginUrl；明文风险确认、确认后保存URL/host；不替换学校网址 |
| ImportWebPage初始请求 | 使用传入URL，未新增代理、UA伪装、预检请求或重定向 |
| NavigationPolicy | 用户确认host与scheme规则仍为唯一定义；快照传入Android同步解释器 |
| Android主清单/config | INTERNET已存在，base-config已放行明文；修正“仅HTTPS/HTTP默认拒绝”的过时注释，不增加权限 |
| iOS ATS | 已允许WebContent明文；未改ATS或绕过证书；iOS行为未实测 |
| Cookie/DOMStorage | 原插件默认已启用；显式表达既有值，未导出Cookie或清除登录数据 |
| 混合内容/多窗口 | 保持既有默认；本轮不启用全局mixed-content、不增加弹窗窗口宿主，不声称已支持所有SSO形态 |

## 已证实的框架缺口与修复

1. **已确认导航被取消重发**：vendored 1.1.3两个Android Client的shouldOverrideUrlLoading原来对每个主页面请求返回true，再在Dart ALLOW后调用loadUrl(url, headers)。Android官方明确建议允许的导航返回false，继续内核原请求。取消重发可能损失请求上下文；真实站点影响为INFERRED。
2. **子frame拦截说明与原生不一致**：原插件对子frame一般直接返回false，Dart CANCEL无法阻止它。新增同步解释器按Dart快照处理scheme；HTTP(S)子frame继续，非允许scheme取消。未知主机的主frame仍走原有确认流程；用户确认后通过既有setSettings更新快照。已确认主机不再进入Dart异步取消重发。
3. **没有主页面加载失败状态**：之前没有onReceivedError/onReceivedHttpError；原生错误页出现后“执行导入”仍可用。现在主frame连接失败/HTTP失败显示固定安全提示，内网地址按通用范围提示校园网或学校VPN；子资源错误不盖住正常页。只在成功加载并注入桥后启用导入。
4. **失败恢复与导航隔离**：用户主动重试调用reload，不自动重复请求；失败层保留原生失败页以保留URL。页面导航generation隔离旧桥注入完成、脚本加载与尝试结果；导航/失败终止当前等待并reset内存attempt，防止旧页面结果进入预览。

原生解释器只是执行NavigationPolicy快照，不持有学校列表或新增域名规则；hosts/schemes来自同一Dart策略。两条Android Client均接线，settings parse/toMap及普通setSettings保留扩展快照。升级插件时需保留这组补丁并复验，THIRD_PARTY_NOTICES保留原许可并注明补丁范围。

## 复审修正

独立代码复审发现本轮初版disableDefaultErrorPage=true会触发插件loadUrl(about:blank)，破坏错误状态和重试；已改false并由Flutter不透明层覆盖。另补contextBootstrap/scriptFor等待后的generation检查，避免将脚本注入新页面。最终代码复审APPROVE。

## 验证与产物

- 实际共享Java解释器由JDK17编译执行：14/14；覆盖已确认host、内网、大小写、未知host/精确子域、子frame、危险scheme、缺失/非法策略、动态确认。
- 入口/导航/错误模型专项34/34；新增真实页面callback接线widget测试验证加载→失败→重试、HTTP403、子资源不遮挡、错误后onLoadStop不启用导入；控制器为fake，不是真实内核。
- 全量381/381通过；最终新增取消回调/旧bootstrap竞态回归后状态专项4/4，最终全量再次381/381（38s）；flutter analyze --no-pub无问题，git diff --check通过（仅既有LF/CRLF提示）。真实内核重定向/POST/SSO未实测。
- 当前adb devices为空：无手机安装、网络可达性测试或真实登录/导入。iOS、真实高校、iframe/POST/SSO复杂链路均UNVERIFIED。

Android的shouldOverrideUrlLoading不覆盖POST；初始请求与POST等仍由WebView原生处理。框架没有因此成为全请求网络沙箱，不扩大原有白名单为所有子资源的保证。未知主机第一次经异步确认后仍需插件恢复导航；本轮解决的是已确认主机被反复取消重发。

参考：[Android WebViewClient官方文档](https://developer.android.com/reference/android/webkit/WebViewClient)、[InAppWebView导航事件说明](https://inappwebview.dev/docs/webview/in-app-webview/)。

## 安装包核验

`flutter build apk --flavor huike --debug --no-pub`与`--release`均成功；两个Android Client已编译，无新依赖/签名配置更改。产物版本仍0.1.5+6（包名com.huike.huike_timetable）。Release的aapt未见application-debuggable，证书SHA256为9f3fff6ec93838bd7c1d4e2a66fc43ccd0d5a19c5856c6c45019571c20dc57b3，沿用既有Debug签名，不是正式商店签名。解包核对Release catalog仍为schema2，昨日adapter框架在本轮包内保留。

- Release：`build/app/outputs/flutter-apk/huike-20261003-webview-framework-release.apk`，SHA256 `D44123DE8E93FA0047A3F3B52E3121AAD729725C4232283FBFC3920A6A43BC5C`。
- Debug：`build/app/outputs/flutter-apk/huike-20261003-webview-framework-debug.apk`，SHA256 `891D974E1D3C159A507794CF4BED76A4281360920517B01FD754F246228F264D`。

没有安装到设备。源代码修复、单测、原生解释器与编译证据不能证明手机访问内网可达或真实登录已恢复。用户正常连接本校所需网络后，可在本人登录页复验；不收集账号、密码、Cookie或原始教务网页。
