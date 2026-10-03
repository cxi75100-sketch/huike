# 2026-10-02 今日详情过渡、课程配色与当前节次提示修正（TASK-TODAY-MOTION-COLOR-01）

## 用户问题与范围

用户继续反馈课程颜色不好看、今日课程点详情过渡特别不流畅，并询问Weekly课程上的蓝杠用途后要求一起修复。保留启动/图标上一轮结果、Weekly关闭合同、课程内容布局、数据、学校/学期/导航业务和全部前轮未提交修改。

## 已确认实现与修正

- `CONFIRMED`：此前Today透明PageRoute同时对整层Fade/Slide，课程卡/预览/详情参与Hero；预览父面板与三按钮各自BackdropFilter，详情正文有额外渐显。这些是代码中可确认的叠加工作；没有真机逐帧数据证明其单独贡献。
- `CONFIRMED`：Today预览route.transitionsBuilder直接返回child；TodayCoursePreviewPage监听原route.animation，只对固定终态大小面板FractionalTranslation，固定全屏遮罩只变alpha。AnimatedBuilder.child保留课程内容；统一GlassMotion.enter对双向进度映射，入场中Back无曲线切换跳变。Reduced直接落位；没有新增Controller或未dispose的CurvedAnimation。
- `CONFIRMED`：CourseHero只在Weekly source且非Reduced模式挂Hero；Today卡片/预览/详情不再飞行。Today详情走既有glassPage并revealMetadata=false，保留Android普通页面过渡和iOS原生返回；详情返回仍回预览，关闭后回原时间轴。
- `CONFIRMED`：GlassSheetPanel新增blurSigma可选参数、默认22。Today预览父面板0，所有课程预览的三个按钮0；Today来源详情两个主体GlassSurface与两个操作按钮0，CourseHeroSurface本来0。保持材质绘制，不创建这些BackdropFilter；Weekly父面板22与普通按钮默认值不变。
- `CONFIRMED`：课程16色改蓝/青/绿为主的统一冷色、少量灰紫，Light/Dark直接成对定义，纯色底与原hash/colorKey不变。发出可选配色问题未收到回复，按已说明的推荐方案落地；美观接受度仍需用户确认，不把它当可由测试证明的事实。
- `CONFIRMED`：Weekly原蓝线仅按学校作息选当前节次，固定画该节中间，并非精确时间或进度。本轮撤除横穿课程的线，改轴内「当前/4节」式两行badge；IgnorePointer、文字与accentSoft背景对比度≥4.5，非本周不显示。没有改用真实分钟进度或推断教学楼时间差异。

## 验证与实画

- `CONFIRMED`：最终全量349/349；analyze无问题、git diff --check通过。实画/交互专项47/47；最后badge文字对比度与课程色6/6再次通过，并在最终代码下重新全量349/349。
- `CONFIRMED`：今日普通/Reduced入场中固定面板宽度、完整正文不淡出、全屏遮罩位置、预览/详情无BackdropFilter/Hero、详情返回后预览尺寸/回原卡片位置，以及入场40ms后立即Back位移连续性，均有Widget回归。已有Weekly Hero、关闭状态机和Root Switcher测试保持通过。
- `CONFIRMED`：当前节次badge明暗360/430dp轴内、不与任一课程块矩形重叠、非本周隐藏与文字对比度覆盖。截图使用16门合成课程、示例楼/教师，未使用用户课程/身份信息；输出build/today-color-{light,dark}-{360,430}.png。初次Ahem截图不能读中文，capture模式加载本地中文字体重绘后检查。没有给生产增加字体依赖或落盘用户数据。
- 测试初次Reduced关闭后40ms查询已卸载面板失败；调整为Reduced直接退出的合同，正常模式仍检查退出中途尺寸。失败测试运行已终止后重新通过，不吞失败或把旧结果当最终结果。
- 独立代码复审APPROVE；提出的低优先级快速Back回归建议已补并通过。复审者独立测试因同时运行时sqlite3.dll文件锁未完成；上面的成功测试均由主Agent实际运行，不将复审者未执行测试计为通过。
- `UNVERIFIED`：无设备连接，真机60Hz/高刷GPU帧耗时、iOS构建/交互、实际覆盖安装、真实教务。结构减负与静态截图不能证明真机卡顿消除；本轮没有新的设备profile。Release构建可供设备复测，但构建成功仍不等于流畅度验收。

## 安装包

汇课独立版，应用ID `com.huike.huike_timetable`，版本0.1.5/versionCode6；Release与Debug实时apksigner读回同一个既有本机debug证书，SHA-256 `9f3fff6ec93838bd7c1d4e2a66fc43ccd0d5a19c5856c6c45019571c20dc57b3`。aapt确认ID/版本，Debug有debuggable、Release没有。保留同版本覆盖合同，未执行安装或卸载。

路径均在build/app/outputs/flutter-apk/：

| 文件 | 构建模式 | 字节 | SHA-256 |
| --- | --- | --- | --- |
| huike-20261002-today-fix-release.apk | Release（签名仍为本机debug证书） | 64055405 | 5D533FACB97DB1713FFAC37C3B2A8B88F93F4379681A22D1AAA7E0646EC61B43 |
| huike-20261002-today-fix-debug.apk | Debug | 207132621 | C6F7905A47F32323D77E2CE9D223E57D2CA82C91C9CF0267609642361D48DCB1 |

app-huike-{release,debug}.apk分别与上述副本相同，app-debug.apk已更新为本轮普通汇课Debug副本。此前明确命名的兼容包保留，本轮没有重建兼容flavor。不新增签名配置、密码或私钥。工作区未提交/推送，未清理并行/前轮修改。
