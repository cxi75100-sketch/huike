# TASK-PREVIEW-RAPID-01：快速换课与翻周

日期：2026-10-02 +08:00。

## 根因与修复

Weekly预览的关闭动画期间，全屏GestureDetector仍拦截点击，父页面_openSheet又因_sheetClosing拒绝打开课程。新增普通模式回归在旧实现失败：关闭40ms后点击下一课程被遮罩截获。

关闭时遮罩和面板IgnorePointer立即放行；每次_openSheet赋新generation key，GlassSheetHost.didUpdateWidget识别关闭期间新周期、重置状态并_open。原TickerFuture被stop取消，其then不调用旧_finishDismiss，因此新面板不会被旧清理误关。普通模式从当前进度重开，同课程也可重开。自然关闭保留单次完成/PopScope Back保护，编辑_afterSheetDismiss已请求时不取消导航。

翻周原策略在旧落位期间拒绝整次新手势；箭头也等弹簧完成才更新周次。现箭头停止旧动画/清_target/立即_finish，网格和周次同帧更新，标签独立轻量动画保留。新horizontalDragStart结束旧pending目标并接受新手势；仅tap/纵滚不会提前消费pending。每次手势最多提交单周，cancel回弹/边界/多指规则保持。箭头中断时以当前已提交周为基准切换，取消未完成的旧目标。

## 验证与范围

- `CONFIRMED`：新预览回归先失败后通过；dismiss/geometry/blur专项31/31。
- `CONFIRMED`：preview_dismiss与week_agenda_ui专项56/56；新增首/末周连续操作边界单项通过；最终flutter test --no-pub全量355/355。
- `CONFIRMED`：flutter analyze --no-pub无问题，独立代码复审APPROVE，git diff --check通过。
- 新测试覆盖普通/Reduced关闭40ms点下一课程、同课程重开、等待旧回调无误清、连续箭头、落位接管、第一/末周不越界；既有Back/编辑/长拖/取消/多指保持通过。
- 今日页面新改版仅整理proposal_2026-10-02_today.md，未实施。
- `UNVERIFIED`：adb无连接设备；真机/iOS视觉/GPU帧率与安装未验。Widget点击响应成功不等于硬件卡顿测量。

## APK

普通汇课huike flavor，Release/Debug构建成功。两包aapt确认com.huike.huike_timetable、0.1.5/versionCode6；Release无debuggable，Debug有。apksigner均verify通过、证书SHA256：9f3fff6ec93838bd7c1d4e2a66fc43ccd0d5a19c5856c6c45019571c20dc57b3（本地既有debug证书，Release构建不代表商店正式签名）。

- build/app/outputs/flutter-apk/huike-20261002-rapid-release.apk：SHA256 B100EE70682563AE504EDC9ACFB1A21B0F84DC8A7B548E28B1341708EC377A32。
- build/app/outputs/flutter-apk/huike-20261002-rapid-debug.apk：SHA256 CCB8CA08F02FAB5F947F24AA36A7C69674A8AFE160E3D46C6D22D9AA7D10189C。

保留旧日期专属APK与既有工作树改动，无提交/推送/设备安装。
