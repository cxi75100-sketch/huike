# 今日状态、浅色品牌启动与底部局部手势

2026-10-02 +08:00。TASK-TODAY-STATUS-01 / TASK-LAUNCH-BRAND-01 / TASK-ROOT-SWIPE-01。

## 交付范围

- 今日撤除_NowBand蓝横线与当前时间。进行中卡片右上淡底标签含结束时间、对应轴点蓝色；课前/课间显示距下一节时间，全天结束灰色文字。未知时间混入不宣称全天结束；showCurrentTime=false不画当前状态。卡片完整字段/纯色/点击保持。不实施proposal中的更多信息架构调整。
- LaunchReveal矢量FlutterLogo+汇课品牌，日夜统一浅底#F5F6F9，就绪后280ms缩小8%/上移12dp/淡出；首页不透明4dp平移。首pointer立即完成装饰并透传，Reduced直接完成、重建不重播，无额外ready延迟。Android四套LaunchTheme及日夜底色浅色；iOS原生白底保持。
- 品牌前景独立AnnotatedRegion接管系统栏，下层AppBar不能覆盖；状态栏依据浅底与目的主题底的混合亮度选黑/白图标。导航栏启动期浅底深图标，退场后目的主题接续。
- 底部272×64区域内横向拖动选择对应位置（右划周课表、左划今日）；复用weekSwipeTarget阈值，首指cancel不提交、每手势单次选择。点按、Reduced、分支状态保留，区域外没有根切换手势。

## 验证

- `CONFIRMED`：Today25/25、launch8/8，Root与既有周/今日路由定向回归通过。
- `CONFIRMED`：最终全量362/362（concurrency2），analyze无问题，独立复审APPROVE，verify_icon.py/diff-check通过。
- 初次默认并发全量的import_flow worker未完成；单文件13/13及低并发全量重跑通过。首次worker退出原因未确认，不宣称业务错误。
- 明暗三状态静态合成实画：build/today-status-qa/status-{active,between,after}-{light,dark}.png。捕获模式用环境HUIKE_TODAY_QA_DIR载入本地中文字体，普通测试不保存截图。静态图不是真机GPU证据。
- `UNVERIFIED`：adb无设备，真机启动/手势/流畅度与iOS、覆盖安装未验。

## 导课截图诊断（只读）

截图加载http://jwxt.ncpu.edu.cn/并报ERR_CONNECTION_REFUSED，说明未进入登录网页。当前school_presets.dart已有预设入口http://218.204.129.252:8088/jwglxt/xtgl/login_slogin.html，学校档案loginUrl持久化，不自动覆盖用户旧网址。

本机只读探测：旧域名HTTP Empty reply/HTTPS握手失败；预设IP入口HEAD403、正常GET200。HEAD403不能推断登录不可用。本轮没有输入凭据、保存教务响应或改用户网址；手机网络与真实登录未验。用户可在设置→学校管理→修改教务网址使用已有预设入口。

## APK

huike普通发行类型，com.huike.huike_timetable、0.1.5/versionCode6；Release/Debug构建成功，Release无debuggable、Debug有。apksigner verify通过，既有本地证书SHA256：9f3fff6ec93838bd7c1d4e2a66fc43ccd0d5a19c5856c6c45019571c20dc57b3。Release构建模式不代表商店正式签名。

- build/app/outputs/flutter-apk/huike-20261002-light-launch-status-release.apk：SHA256 240DE462BF9CDE358C01894EB5702F4D2F475FBCE46C5ABA46F6671756CAD5EE。
- build/app/outputs/flutter-apk/huike-20261002-light-launch-status-debug.apk：SHA256 565BE5286B77A0D74F733933AD4D231FB5C1D78CF37EF4D097FF4EDEA7A589E6。

保留旧日期专属APK与其他未提交工作；无commit/push/设备安装。
