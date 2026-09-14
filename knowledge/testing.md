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
flutter test             # 当前基线：110/110（含 App 壳与界面 widget 测试）
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
- 导航白名单（`navigation_policy_test`）：白名单放行、http/https 都允许、未确认主机拦截、
  子域名不自动放行、非 http(s) scheme 一律拦截、名单追加后原策略即刻生效。
- 教务地址校验（`login_url_policy_test`）：空输入必填/非必填、http 标记明文、https、裁剪空白、
  缺 scheme、非 http(s) scheme、无主机——三处入口共用同一函数（DEC-006）。
- 校历例外解析（`calendar_exception_service_test`）：无例外按自然星期、停课当天、
  同一天任意时刻都命中、调休按目标星期、未指定目标星期退回自然星期、
  越界目标星期夹到 1-7、多条例外互不干扰、中文星期名。
- 校历例外写路径（`calendar_exception_repository_test`，内存库）：写入可读回（时刻被裁掉）、
  同一天二次写入是覆盖、带 id 编辑换日期不残留、停课忽略传入的 makeupWeekday、
  删除只删指定记录、跨校隔离、删校级联清。
- 校历例外界面（`calendar_exception_ui_test`）：今天标停课后首页显示停课空状态、
  标调休后显示「今天按周五的课表上课」提示条、从设置能进入「调休 / 停课」页并列出例外。
- App 壳 widget 流程（全新安装→引导；创建学校→首页；空课日→历书式空状态；
  `today-agenda` 与 `week-agenda` 互斥切换、整周当天行 `week-day-0-<weekday>` 存在、
  今日课程→详情页十站节次线；首页不再出现「本周线路概览」语义标签）。

## 真机/模拟器验证约定

- UI 断言用 `adb shell uiautomator dump` 读语义树；Git Bash 传 `/sdcard/...` 路径需
  `export MSYS_NO_PATHCONV=1`；Windows python 读 dump 用 Windows 路径。
- 模拟器 `ncpu_api36` 与其它项目共用；本项目包名独立，验证后删除冒烟学校，
  不触碰其它应用的数据。
- 导入探测的端到端验证可用任意 HTTPS 站点（如 example.com）：四个适配器应依次
  尝试并弹出逐项失败汇总；真实教务导入仍需用户本人登录（`UNVERIFIED`）。

## 2026-09-14 TASK-010 模拟器实画

- `CONFIRMED`：`ncpu_api36` / API 36 / x86_64 安装 release 包；日间首页、整周、设置与
  夜间整周已实画检查，两列窄屏没有溢出，空槽在夜间模式的节次/时间对比度已调高。
- `CONFIRMED`：冷启动约 0.7s；logcat 未命中 `FATAL EXCEPTION` / `E/flutter` /
  `RenderFlex overflowed` / `MissingPluginException` / ANR。
- `CONFIRMED`：release x86_64 APK 构建成功，已覆盖安装并保留测试学校。模拟器已停在
  「导入教务课表」风险确认入口，等用户本人登录。
- `UNVERIFIED`：真实教务站登录、课表解析、差异预览与确认写入。
