# 汇课 1.00 发布记录

日期：2026-10-03 +08:00。用户指定正式版1.00，工程版本`1.0.0+9`，标签`v1.0.0`。

## 本版行为

- 首次打开直接浏览首页；导入时再填写学校、教务网址与校历。
- 导入页可更换学校，管理页可添加；新增返回导入确认。切换同步网址、重新确认，已有学校/课表分别保留。异步导航核对当前route，避免旧route退出动画误退下层。
- 通用导航保留POST/重定向；同源iframe/动态页面识别，有限采样与尝试隔离、取消清理；可信主frame登录明确失效自动恢复一次，网络错误不自动删Cookie。
- 收录既有今日/整周、课程详情、配色、玻璃与动效、数据完整性修复；完整历史见changelog。

## 验证

- `CONFIRMED`：全量395/395；学校切换/新增路由专项7/7，最终analyze与diff-check通过，学校切换代码复审APPROVE。
- 本轮前序真实Android WebView合成环境：导入框架、登录清理服务、实际导入页自动恢复各1/1，见三个2026-10-03报告。合成环境不等于真实学校验收。
- `UNVERIFIED`：真实学校、截图内网连接中止根因、真机、iOS、本版真机覆盖升级；小组件/通知/在线脚本更新仍待做。

## APK

构建使用显式`--flavor huike --target lib/main.dart`，正式包`--release`，辅助包`--debug`。
Release最初`--no-pub`失败：上次调试工具生成的registrant包含integration_test，而Release Gradle过滤开发插件。重新允许Flutter生成Release插件清单后成功；未编辑生成Java或升级依赖。

| 产物 | 字节 | SHA256 |
| --- | ---: | --- |
| `build/app/outputs/flutter-apk/huike-1.0.0-release.apk` | 64661937 | `9473D45E0830DAE5D7893B2338618222418D54D623D72B703EA3227D41080D89` |
| `build/app/outputs/flutter-apk/huike-1.0.0-debug.apk` | 176247147 | `E073DFB9A1FFA0B5F2A1F5D57A4AE5560B1B00B78358456BDAE7E41DFB94AE91` |

包名`com.huike.huike_timetable`，versionCode9/versionName1.0.0，minSdk24/targetSdk36。Release无application-debuggable，Debug有该标记。APK内catalog schema2。签名SHA256`9f3fff6ec93838bd7c1d4e2a66fc43ccd0d5a19c5856c6c45019571c20dc57b3`，沿用既有调试证书以兼容安装；**生产签名尚未配置，Release模式不代表已具备商店发布签名**。秘钥不入库。

`CONFIRMED`：API36 Android模拟器`emulator-5554`安装本版Release成功，启动后进程存在，dumpsys核验versionCode9/versionName1.0.0；未等同真机/真实教务验收。

## 发布目标与状态

- `CONFIRMED` GitHub：`https://github.com/cxi75100-sketch/huike`，本轮新建；完整Git历史与v0.1.0至v0.1.4、v1.0.0已推送。源码发布提交`57a59ea49192d630fa5c144682b14408a6dec340`。ls-remote读回master与v1.0.0^{}均为该提交，annotated tag对象`e8b29cb8364a91294150b2a0836849187f54ee84`。
- `CONFIRMED` GitHub发行版：`https://github.com/cxi75100-sketch/huike/releases/tag/v1.0.0`，已公开发布、非draft/非prerelease；Release、Debug、SHA256SUMS三个附件成功，网页服务端APK SHA256与本地一致。
- `BLOCKED` Gitee：`https://gitee.com/chenxihh/huike`，已有公开仓库，原master为`7bc4f10cef9a60ea0dec320c75778d1da76dad6f`。网页登录已确认，但Git客户端需用户在Windows安全中心完成认证；推送正等待。发行说明、Release与校验附件已准备，未创建指向旧代码的v1.0.0发行版。Gitee单附件100MB，Debug超过限额，提供GitHub同版链接。
- 只发布源码、脱敏知识库、合成测试和正式产物；本地附件、页面截图、生成报告、构建缓存和秘钥排除。
- Gitee认证完成后继续推送master/v1.0.0、读回并发布发行版；不force、不删除目标独有refs。GitHub后续文档收口提交允许领先代码标签，APK对应标签代码不变。
