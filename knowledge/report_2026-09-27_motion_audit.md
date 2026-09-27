# TASK-022A — App Motion / Transition Audit

日期：2026-09-27；工作区未提交。仅普通页面、普通反馈与弹层。

## 审计摘要

搜索 AnimationController / Animated* / Tween* / CurvedAnimation / transitionBuilder /
CustomTransitionPage / showModalBottomSheet / Duration / Curves，核查 GlassMotion、GlassMetrics
与 disableAnimations。非动画的时间计算、时钟timer、debounce未当作动效修改。

| 分类 | 原实现证据 | 本轮处理 |
| --- | --- | --- |
| A 已用token | PressPhysics时长/弹簧、GlassTextField时长、menu时长、学期Sheet时长、GlassSheetHost、Weekly | 保留既有定义，仅补普通入口曲线 |
| B 绕过token | touchFollow用easeOut；表单焦点/菜单opacity默认曲线 | 使用GlassMotion.enter；菜单进退共用enter/exit |
| C Flutter默认 | 普通MaterialPage、showDialog、学期Sheet默认曲线、Snackbar默认时长 | 普通route短距离淡入；Dialog保留DialogRoute合同换绘制transition；Sheet补曲线；非Import Snackbar显式token |
| D 无需动画 | 菜单加号旋转；普通Detail路由与内容分批淡入重复 | 删除旋转，图标直接切状态；普通Detail只走route动画 |
| E 不一致 | 菜单关闭立即移除子树；表单线性变化；Dialog与普通页面默认节奏 | 菜单SizeTransition完成后Offstage；统一普通进退节奏 |

主动保留的例外：iOS普通页面使用原生Cupertino transition保留交互式边缘返回；
仍使用集中时长，Reduced Motion只有淡入淡出但保留原生手势检测。Settings日期/时间选择器
仍使用Flutter专用picker合同及其默认内部动画，本轮没有复制picker实现。Snackbar内部曲线
由Flutter控制（公开AnimationStyle提供时长），不新增自制Snackbar系统。
Onboarding/冷启动、Course Preview/Detail的Hero来源路径、Weekly分页/周标签动画、Import内部反馈
属于排除范围；审计记录而不调整。原有按压弹簧参数不重新调节。

## Motion合同

- GlassMotion新增语义别名：pageEnter280ms、pageExit180ms、dialog180ms、reduced90ms、
  snackEnter180ms、snackExit110ms；原有token与弹簧不变，没有第二套系统。
- 普通非iOS页面最多12dp纵向绘制平移+opacity；Dialog最多8dp+opacity；不做scale或远距离飞入。
  GlassTransition持有并释放CurvedAnimation，中途反向锁定当前曲线方向，避免跳变。
- 普通Detail不再另做metadata stagger；Hero来源Detail继续使用原有reveal，Preview专用代码不变。
- 学期Sheet只补enter/exit曲线，维持280/180ms；GlassSheetHost原文不变。
- Liquid Menu使用单一220/180ms进度做尺寸与opacity；关闭期间IgnorePointer，结束Offstage，
  不再突然删除内容。移除AnimatedRotation；滚动时opacity110ms使用统一曲线。
- PressPhysics触摸跟随用enter；GlassTextField焦点动画用enter；GlassSurface按压外层也遵守Reduced。
- Reduced：普通route/Dialog90ms纯opacity，无scale/translation；menu/学期Sheet/Snackbar立即状态变化；
  按压没有scale但点击正常。没有动画等待业务提交。

## 修改文件

生产代码共14个：core/glass下glass_motion、glass_metrics、glass_transition（新增）、glass_dialog、
glass_surface、glass_form、press_physics；core/router下glass_page（新增）、app_router；
school_manage_page、course_edit_page（仅Snackbar）；course_detail_page（非Hero reveal开关）；
liquid_add_button；week_navigation（仅学期Sheet曲线）。新增test/motion_audit_test.dart，同步知识库。

## 验证与边界

- 开始git status/diff stat已检查；保存已有lib源码哈希。基线analyze无问题、252/252。
- 新增10例：普通过渡内容不逐帧重建/绘制位移；中途反向连续；Reduced按压仍可点击且不缩放；
  菜单关闭保留内容且禁点击；Light/Dark×normal/reduced四条真实router功能旅程；
  iOS normal/reduced边缘返回最终router状态两例。
- 旅程覆盖Weekly、Today、Settings、普通Detail、Edit、Import入口外壳、Dialog确认、
  学期Sheet关闭、Liquid Menu进入事件编辑、Snackbar。68张widget帧（中间帧/完成帧）
  已人工查看四组联系图。QA输出目录位于本地visualizations的task022目录；
  可选HUIKE_MOTION_QA_DIR加载本机中文/图标字体。部分无显式fontFamily标题在测试引擎仍用占位字形，
  本轮画面核查用于动效geometry/opacity/材质而非中文字体验收。
- 最终flutter analyze --no-pub无问题；flutter test --no-pub 262/262；
  flutter build apk --debug --no-pub成功；git diff --check通过；新增未追踪文件补做空白检查。
- 代码复审APPROVE：iOS兼容问题已修复并通过两种模式手势测试，无剩余阻断。
- CONFIRMED：普通transition hoist child，没有逐帧重建内容；菜单内容缓存，仅小型SizeTransition
  进行尺寸变化；不新增BackdropFilter，不新增冲突计算，不延长时长掩盖jank。
- UNVERIFIED：adb没有设备；未做真机/模拟器连续手动操作、iOS设备或GPU帧时间测量。
  widget截图与自动化不等同于真实设备性能验收，没有宣称已解决设备jank。
- 开工源码哈希确认Today布局、Weekly swipe/grid/Course Block、Preview sheet/Hero/GlassSheetHost、
  Import全部源码、数据库、main/app保持原文。week_navigation仅学期Sheet曲线变化；
  app_router仅普通路由与普通Detail分支变化。没有启动/Preview专用动画、Android root exit、
  icon或全局页面之外的业务重构。保留全部既有未提交工作；无commit/push/reset/clean。

APK：build/app/outputs/flutter-apk/app-debug.apk。本轮完成后停止。
