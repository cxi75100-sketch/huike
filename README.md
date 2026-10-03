# 汇课

多校通用本地课表 App（Flutter），正式版 **1.00（1.0.0+9）**。
首次打开直接浏览首页；需要导入时再填写学校与教务网址。
导入页可以更换或添加学校，各学校课表分别保留。
App 自动识别并尝试内置教务适配器，导入结果先预览、确认后才写入。

## 现状

- 多校数据模型（学校/学期/课程/作息，无任何内置默认学校）
- 教务导入（统一地址/导航策略、WebView、社区适配脚本、预览确认）
- 今日课程 + 整周课表、课程详情、主题与玻璃外观设置
- 同源 iframe / 动态页面识别、导入尝试清理、可信登录失效自动恢复一次
- 手动课程 CRUD、学期与作息设置、日/夜间主题
- Android 桌面小组件与上课提醒尚未迁移（见 knowledge/tasks.md）

## 开发

```bash
subst S: "D:\桌面\汇课"   # 中文路径会破坏 Flutter 工具链
cd /s
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze && flutter test
flutter build apk --flavor huike --release --target lib/main.dart
```

sqlite3 原生库的 hook 需要访问 GitHub 下载（带 sha256 校验），离线办法见
knowledge/testing.md。

## 安全与隐私

- 账号密码只在贵校教务官方页面输入；本应用不单独保存或上传凭据。
- WebView 可保留登录 Cookie；明确失效时限定范围恢复，另提供主动重新登录。
- 教务数据只在设备本地；导入原始响应只驻留内存，不落盘。
- 不绕过验证码或任何认证机制，只处理当前登录用户自己的课表。

## 第三方

`assets/adapters/` 内置的通用教务适配脚本来自社区开源仓库（MIT），
许可与署名见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 版本验证范围

工程验证与发布记录见 [knowledge/release_1.0.0.md](knowledge/release_1.0.0.md)。
真实学校、真机、iOS 尚未完成本轮验收；不承诺所有教务站点均可连接或解析。
当前 Android 构建沿用已有调试签名以兼容既有安装；Release 模式不等于生产签名已配置。
