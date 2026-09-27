# TASK-022B — App Launch → Home Motion

2026-09-27；仅本轮启动改动，保留全部原工作区；未commit/push/reset/clean。

## 根因与颜色

- CONFIRMED（代码）：Router把activeSchoolId加载中的null当作没有学校；Home把未解析学期当作无学期，把未解析课程/作息/校历当作空值或fallback。主题先取system再读保存值。这些初始默认值可产生引导→Home、无学期→网格、主题切换与网格重排；不是已有启动动画太慢。
- CONFIRMED（资源/模拟器画面）：Android原始drawable为白色/系统默认背景，NormalTheme也是系统默认色；Android12+未显式指定windowSplashScreenBackground，与Flutter灰白/石墨底色不同。
- 仅对齐背景资源：light #F5F6F9、dark #111319；Android12+显式启动背景、旧版drawable与NormalTheme共用颜色。保留图标/品牌，不改signing。
- Flutter首帧有完整AmbientBackdrop，不用空Scaffold/黑白遮罩。环境光渐变与单色Splash并非逐像素相同；固定App主题与系统主题相反时仍会有一次预期明暗切换，native不读取数据库主题。

## 接线与motion

- main在runApp前启动保存主题读取，deferFirstFrame仅到真实主题读取结束（失败也allow）；其余数据库读取同时进行，没有sleep/Future.delayed。
- launchReadiness订阅既有provider，区分初始loading与真实空值；初始学校、保存学期、作息、课程、校历读完后挂载root。错误也结束等待，保留原页面错误合同。不修改DB/schema/repository与router。
- 初始等待画稳定环境背景；不先挂载错误引导/无学期内容。一次性latch保证后续刷新、普通导航与前台恢复不会重新挡住页面。
- LaunchReveal为整个初始root一次180ms easeOutCubic、4dp→0绘制平移与opacity 0.92→1。复用GlassMotion.standard/enter，非新增节奏；无logo动画/逐卡飞入/stagger/spring/scale。
- 内容挂载的首帧已有92%可见度且可点；动画不参与数据读取与ready判断，不等动画结束再显示课表。Reduced直接opacity1、offset0，无启动动画。
- 首次主题落地禁用默认200ms主题tween，下一帧恢复正常用户主题切换；系统栏透明、图标按实际主题，关闭额外contrast scrim，edge-to-edge保留。

## 性能界限

没有人为等待，没有动画完成门槛。为消除错误初始布局，首次root可交互时间取决于真实初始数据就绪，不能称作初始化零耗时；未做同条件改前/改后性能benchmark，不能声称首屏耗时无回归或GPU稳定60fps。模拟器Debug的am start TotalTime只是Activity首帧，不是首门课程出现时间。

## 修改文件

- lib/main.dart、lib/app.dart
- lib/core/widgets/launch_readiness.dart、launch_reveal.dart
- android/app/src/main/res/drawable/launch_background.xml、drawable-v21/launch_background.xml
- android/app/src/main/res/values/styles.xml、values-night/styles.xml
- android/app/src/main/res/values/launch_colors.xml、values-night/launch_colors.xml
- android/app/src/main/res/values-v31/styles.xml、values-night-v31/styles.xml
- test/launch_motion_test.dart
- knowledge/current_state.md、tasks.md、README.md、architecture.md、design.md、testing.md、changelog.md、本报告

禁止范围源码未修改；无新package。

## 验证

- 基线git status/diff stat已检查：大量既有未提交内容；analyze无问题、262/262。
- 新增6例：保存暗色/系统浅色首次主题无tween；Light/Dark×Reduced开关首帧点击、180ms完成、ready刷新不重播；未解析学校不会画引导。
- 最终flutter analyze --no-pub无问题；flutter test --no-pub 268/268；flutter build apk --debug --no-pub成功；git diff --check通过。
- Android API36 ncpu_api36模拟器：最终APK安装成功；四模式cold start（force-stop）与warm start（Back后重建Activity，am start明确WARM）均执行；额外Home返回前台不重播。Light/Dark首页与系统栏静态画面检查正常，测试数据为既有QA空周，无真实课表/凭据。
- 录像抽样确认Splash→正确明暗Ambient背景，无白黑中间遮罩；录制片段未充分覆盖全部root动效末帧，不把抽样当作完整逐帧/GPU流畅性验收。完整root最终画面与动效数值由截图/widget测试分别覆盖。
- Code-reviewer复核通过，首次主题同帧边界已修复。
- UNVERIFIED：iOS、Android真机、非空课程设备启动、Release性能与完整GPU流畅性；widget与模拟器不替代这些验收。

完成后停止，不开始其它任务。
