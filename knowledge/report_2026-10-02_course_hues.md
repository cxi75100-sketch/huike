# TASK-COURSE-HUES-01：课程颜色覆盖修正

日期：2026-10-02 +08:00。

## 问题与修正

上一轮虽有16个不同RGB值，但集中蓝/青/绿，用户反馈视觉颜色太少。最新色板覆盖完整暖冷色相，包含红橙黄绿青蓝紫粉。Light统一约HSL明度0.82/饱和度0.55，Dark约0.28/0.35；整数RGB有量化误差。

仅修改course_colors.dart的16个配对和颜色回归测试。Today/Weekly共用；hash、16色取模、数据库字段不变，可能仍有不同课程同色。既有今日动画、Weekly返回、图标及轴内当前节次提示保留。

## 验证

- `CONFIRMED`：`S:\`定向course_colors_test与weekly_now_indicator_test共8/8通过；明暗八个色相区间覆盖、16色唯一/不透明、正文对比度≥4.5、稳定映射与轴内提示。
- `CONFIRMED`：flutter analyze --no-pub无问题；代码复审APPROVE；git diff --check通过。
- `CONFIRMED`：重新生成明暗360/430dp合成静态渲染，检查Light/Dark配色与中文可读；build/today-color-{light,dark}-{360,430}.png。截图不是设备运行或帧率证据。
- 本轮全量未重跑；上一轮349/349为历史基线。仅低影响色值变更，定向验证覆盖本轮范围。
- `UNVERIFIED`：adb无连接设备；用户真机视觉、GPU流畅度及iOS未验证。

## APK

普通汇课flavor huike，Release与Debug均构建成功。包名com.huike.huike_timetable，versionName0.1.5/versionCode6。Release无debuggable，Debug有debuggable。均使用既有本地证书SHA256：9f3fff6ec93838bd7c1d4e2a66fc43ccd0d5a19c5856c6c45019571c20dc57b3；Release构建模式不等于商店正式签名。

- `build/app/outputs/flutter-apk/huike-20261002-16-hues-release.apk` SHA256：55BD56925107D0FA548E40E62E0E9DD28ACCAC398E971DE9F7098256525F1E73。
- `build/app/outputs/flutter-apk/huike-20261002-16-hues-debug.apk` SHA256：27A39CDAAF55782F8848424EC2BAEBC3E24FA02F15A9C6C2E65432681BFE30A4。

保留旧日期专属产物及其他未提交改动；无提交/推送，未做设备覆盖安装。
