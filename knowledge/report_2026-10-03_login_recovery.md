# 登录状态恢复

2026-10-03 +08:00。用户先同意重新登录机制，后明确要求框架解决失效登录，而非只交付清理按钮。

## 行为与范围

- 默认保留内核Cookie/WebStorage，正常离开、普通连接错误/403/普通重试不清理。内核可能持久保存登录状态，App不另行持久保存、不写日志或上传；修正原ImportSessionCleaner“任何会话数据都不落盘”的不准确注释。
- NavigationPolicy允许的主frameHTTP401或内核TOO_MANY_REDIRECTS触发一次有限恢复：清理访问范围的登录状态，销毁旧WebView，重新打开原入口。policy在重建时保持，持续异常不会反复清理。401/重定向只是恢复触发信号，不证明Cookie是根因；不能代用户输入凭据。
- 登录选项菜单提供主动重新登录，先固定文案确认（说明共享登录站点可能需重登），期间禁用导入。手动确认返回时核对view generation/controller，过期弹窗不得影响自动恢复后的新页面。旧WebView桥与错误回调均绑定generation。
- 仅本次访问且已确认的HTTP(S)URL（去query/fragment，内存驻留）；当前页面/同源frames存储清理先核对真实origin授权。stopLoading/清当前存储/撤销旧上下文之后才删除Cookie，避免旧页面继续写入。
- Cookie按实际Domain/Path删除，HTTPS查询Secure状态；__Secure-/__Host-按前缀约束过期并核验未残留，固定'expired'值非凭据。未知属性/范围外共享父域跳过且partial。Cookie不按port隔离；同一登录域共享状态可能受影响。
- 已访问origin通过无外链空白Headless页面精确清localStorage，当前页清sessionStorage；Android另调用deleteOrigin（不把它当作全IndexedDB/cache清理）。没有deleteAllCookies/deleteAllData。iOS固定partial，未宣称完整。
- complete仅表示已知访问URL/root/HTTPS查询范围及已访问origin操作完成，不保证未知路径Cookie、所有IndexedDB或全站注销。部分失败显示固定提示，不显示异常/URL/凭据。

## 验证

服务/policy/UI专项10/10（服务3、policy2、UI5），覆盖自动/手动、取消、普通错误不删、旧回调与确认交错。真实API36/WebView133.0.6943.137 synthetic服务集成1/1通过：HttpOnly/Secure/Path/Domain及__Secure-/__Host- Cookie删除核验，local/sessionStorage清理、另一host Cookie/localStorage保留，scope外current controller存储保留且partial。命令：`flutter test integration_test/login_session_reset_test.dart --flavor huike -d emulator-5554 --no-pub`（S盘）。

实际ImportWebPage自动恢复集成1/1通过（5秒）：内存provider不访问真实学校DB，本地HttpServer用固定合成Cookie返回401；没有点击按钮，真实清理服务删除Cookie并重建login-webview-1，原入口重新请求200且导入按钮恢复就绪。命令：`flutter test integration_test/login_recovery_flow_test.dart --flavor huike -d emulator-5554 --no-pub`。内核可能在取消前重试HTTP认证挑战，rejected次数>=1；恢复次数由新view key==1约束，Cookie消失及页面就绪独立断言。

安全复审APPROVE/LOW，最终代码/新增集成复审APPROVE。发现当前origin越界、前缀Cookie属性、旧手动弹窗controller竞态均已修复并补回归；最终全量394/394通过。Dart fix仅修正13处if花括号，最终analyze无问题，git diff --check通过。

## Debug包

`flutter build apk --flavor huike --debug --target lib/main.dart --no-pub`成功（25.1秒），明确正常App入口，不将integration测试APK作为交付。文件：`build/app/outputs/flutter-apk/huike-20261003-login-recovery-debug.apk`。com.huike.huike_timetable，versionName0.1.7/versionCode8，debuggable/INTERNET正确，APK内catalog schema2。

SHA256：`9404856E29E2FC370A1B0EB0D2BAE7341FA5AD067E04C59301146605897BEE59`；签名SHA256：`9f3fff6ec93838bd7c1d4e2a66fc43ccd0d5a19c5856c6c45019571c20dc57b3`，与上一轮一致。未新建Release，最终正常入口APK未做真机安装。

`UNVERIFIED`：真实学校登录恢复、实体设备/iOS、用户截图内网ERR_CONNECTION_ABORTED的实际网络原因。synthetic WebView服务测试不等于完整真实学校App登录验收。保留既有未提交改动，无提交/推送。
