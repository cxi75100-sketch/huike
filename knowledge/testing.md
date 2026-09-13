# Testing

## 环境

- 中文路径会破坏 Flutter 工具链：先 `subst S: "D:\桌面\汇课"`，在 `S:\` 下执行一切命令。
- sqlite3（3.5.2）hook 构建期要从 GitHub 下载预编译库（Clash 未开时必失败）。
  缓存位置：项目内 `.dart_tool/hooks_runner/shared/sqlite3/build/download-<hash>/`，
  带 sha256 校验；同版本工程之间可直接整目录拷贝复用（2026-09-13 已验证）。

## 命令

```bash
cd /s/
flutter analyze          # 当前基线：No issues found
flutter test             # 当前基线：65/65（含 3 个 App 壳 widget 测试）
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## 覆盖清单

- 周次解析（范围/离散/单双周/中英文括号/格式化）。
- 学期服务（currentWeek 边界、termStatus、dateFor 不夹取、weekMonday 夹取、weekdayOf）。
- 作息表（兜底生成、跨节次解析、缺节次返回 null、时段分组、equalsFallback）。
- 适配器规范化（契约形状、weeks 数组与文本、day=0 丢弃并计数、非法时间忽略、配置字段边界）。
- 导入差异（added/removed/changed、周次乱序不算修改）。
- 桥契约（8 处理器齐、社区契约名保持、幂等注入、不落盘）。
- 数据库/仓库语义（内存库）：作息只播种一次、导入替换保手动课、跨校隔离、
  内容指纹 id、级联删除、设置读写。
- 适配器目录（4 条目、资产存在、脚本用桥契约）。
- App 壳 widget 流程（全新安装→引导；创建学校→首页；空课日→历书式空状态）。

## 真机/模拟器验证约定

- UI 断言用 `adb shell uiautomator dump` 读语义树；Git Bash 传 `/sdcard/...` 路径需
  `export MSYS_NO_PATHCONV=1`；Windows python 读 dump 用 Windows 路径。
- 模拟器 `ncpu_api36` 与其它项目共用；本项目包名独立，验证后删除冒烟学校，
  不触碰其它应用的数据。
- 导入探测的端到端验证可用任意 HTTPS 站点（如 example.com）：四个适配器应依次
  尝试并弹出逐项失败汇总；真实教务导入仍需用户本人登录（`UNVERIFIED`）。
