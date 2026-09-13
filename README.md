# 汇课

多校通用本地课表 App（Flutter）。一所学校的课表从「创建学校档案」开始：
填学校名称与教务网址（选填），导入时 App 自动逐个尝试内置教务适配器，
不需要知道学校用什么教务系统；导入结果先预览、确认后才写入。

## 现状

- 多校数据模型（学校/学期/课程/作息，无任何内置默认学校）
- 教务导入（HTTPS + 白名单 WebView + 社区适配脚本契约桥 + 预览确认）
- 今日历牌 + 整周横向周历（打开整周第一列必是今天）
- 手动课程 CRUD、学期与作息设置、日/夜间主题
- Android 桌面小组件与上课提醒尚未迁移（见 knowledge/tasks.md）

## 开发

```bash
subst S: "D:\桌面\汇课"   # 中文路径会破坏 Flutter 工具链
cd /s
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze && flutter test
flutter build apk --debug
```

sqlite3 原生库的 hook 需要访问 GitHub 下载（带 sha256 校验），离线办法见
knowledge/testing.md。

## 安全与隐私

- 账号密码只在贵校教务官方页面输入；本应用不接触、不保存任何凭据。
- 教务数据只在设备本地；导入原始响应只驻留内存，不落盘。
- 不绕过验证码或任何认证机制，只处理当前登录用户自己的课表。

## 第三方

`assets/adapters/` 内置的通用教务适配脚本来自社区开源仓库（MIT），
许可与署名见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
