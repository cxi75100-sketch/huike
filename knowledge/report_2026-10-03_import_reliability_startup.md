# 首次打开与导入可靠性

2026-10-03 +08:00。用户明确授权本轮只做框架可靠性和首次打开流程，文件导入/在线更新留后续。

## 首次打开

原因：app_router全局redirect将没有学校的所有路线强制改写为/onboarding，用户无法先浏览首页。

修复：取消全局建校redirect及refresh订阅，保留单个router与两个一级分支。空库进入整周首页，今日/整周均提供导入CTA；不播种学校或学期。主动进入/import、学校读取完成且确为空库后，才显示现有OnboardingPage(forImport:true)。建校后由provider切换为既有风险确认页，保留首页返回栈；普通显式建校仍回首页。

异步学校到达或切换学校ID时更新网址控制器、取消风险勾选；同一学校输入不被watch重建覆盖。已有档案无迁移、schema不变。沿用AppTheme/GlassButton/列表表单。

## 验证

`CONFIRMED`：UI专项29/29；空库无TextField/无学校写入，今日CTA可进入表单，建校后继续导入，canPop与真实router.pop回首页；320×568字体1.3无异常，原已有课表/导入/启动回归通过。代码复审发现go('/import')替换栈问题并已修正，UI复审APPROVE。

## 导入框架

- 探针最多检查32个窗口、同源frame深度4，仅返回family布尔标记/数字frame路径与跨源不可读标记；不返回页面正文或表单值。
- AdapterPageReader最多9次采样、500ms间隔（总4秒），导航generation失效即终止。未知标记保持兼容回退，不臆造学校profile。
- 在family对应同源frame内直接执行局部函数，绑定document/location/DOMParser/jQuery和私有桥；不使用Function/eval。复审发现的严格CSP回归已修复。
- attempt拥有独立桥、fetch AbortController和timer；切候选、结束、导航/重试/离页清理，owner token防止清错。保留fetch取消句柄直至attempt结束，覆盖headers后response.text仍下载的正文；复审发现此缺口后已修复。不覆盖页面fetch/timer全局，不保证撤销已送达请求或任意DOM副作用。
- 只新增integration_test SDK开发依赖，不增加运行时依赖。catalog schema2/Drift schema3/normalizer/preview/确认事务保持。

`CONFIRMED`：框架专项10/10；最终真实Android WebView组件synthetic集成1/1通过。命令：`flutter test integration_test/import_webview_test.dart --flavor huike -d emulator-5554 --no-pub`（S盘）。环境API36、WebView133.0.6943.137。覆盖POST302转GET、307保留POST、Cookie持续、严格CSP(script-src self)下动态同源iframe、完整内置URP解析与attempt完成、跨源不可读标记、旧timer/bridge阻断、headers后流式body abort。框架和UI复审均APPROVE。

全量首次执行12个独立TodayPage密度fixture失败：fixture只提供courses/day/bell，未提供学校；新空校UI因此触发生产数据库与空态。补充与课程schoolId一致的合成qa学校override，原布局断言保留，25/25专项通过且复审APPROVE。真实空库逻辑继续由独立memory DB首启交互测试验证。

最终全量`flutter test --no-pub --concurrency 2 --reporter expanded` 385/385；最终analyze无问题，按仓库既有CRLF配置执行`git diff --check`通过。

## Debug交付

`flutter build apk --flavor huike --debug --no-pub`成功（25.3秒）。APK：`build/app/outputs/flutter-apk/huike-20261003-startup-import-debug.apk`，versionName0.1.6/versionCode7，package com.huike.huike_timetable，debuggable与INTERNET权限正确，解包catalog schema2。版本高于上一轮0.1.5+6，签名SHA256相同：`9f3fff6ec93838bd7c1d4e2a66fc43ccd0d5a19c5856c6c45019571c20dc57b3`。

APK SHA256：`11EE9B94A17A64C0B9D44B3637BFE73959FC3806F9354810D1BEDB450F1B9B99`。此轮未新建Release，不能将上一轮Release当作包含新UI/框架的包。最终APK未做真机覆盖安装或完整App设备验收。

`UNVERIFIED`：实际学校网络、账号登录及课表导入、实体设备、iOS、完整ImportWebPage跨host确认UI/真实CAS、新窗口。集成是独立真实WebView组件，不能扩大为完整App端到端。四脚本中仅URP本轮实跑合成解析，其他三个仅源码兼容性核对。模拟器synthetic站点不代表实际学校可用。无提交/推送，保留并行与既有未提交改动。
