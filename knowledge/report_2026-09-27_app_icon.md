# TASK-026 — App Icon Redesign

2026-09-27；仅App Icon及交付知识库。保留既有未提交工作；无commit/push/reset/clean。

## 最终概念

严格落实用户附件指定的一个方案：三个厚圆角白色课程块向中心轴汇聚。中间最长，
上下块微倾且略向左错开，右侧轮廓收拢；三块始终分离，没有字母、文字、箭头尖、
时钟或日历细节。不探索其它概念，不复制App内Glass卡片。

- 2048px超采样，输出1024px源图；中间长度58%，上下长度48.33%，长度比1.20。
- 等厚9%，端部半径为厚度50%；上下中心(47%,33%)/(47%,67%)，中间(50%,50%)。
- 上下分别向内倾9°；最窄间隙约4.3%，约为块厚48%。在48px下依然约4px厚、2px间隙。
- 不透明白色glyph；不透明冷蓝#3057D5，无渐变/阴影/透明玻璃层。
- 厚轮廓、三个独立负空间间隔、长短与倾角共同防止退化成等长菜单线；语义识别仍属
  设计判断，不宣称已经做用户识别率研究。参见assets/icon/icon_qa.png实际48/64px样本。

## Android

复用已有flutter_launcher_icons 0.14.4，仅修改pubspec的adaptive背景值，不改依赖/锁文件。
前景与monochrome复用纯白透明底foreground.png，背景由native颜色资源提供。
既有mipmap-anydpi-v26/ic_launcher.xml的16% inset保留、引用保持不变，无须修改XML。
图形按现有inset进入108-unit adaptive层后，在中心66-unit安全圆以内；圆形、圆角方形、
squircle模拟mask下都未裁主体。旧版launcher使用有圆角透明边的legacy PNG。

修改：

- assets/icon/app_icon_android.png、app_icon_ios.png、foreground.png
- android/app/src/main/res/values/colors.xml
- mipmap-mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi/ic_launcher.png（5张）
- drawable-mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi/ic_launcher_foreground.png与ic_launcher_monochrome.png（10张）
- pubspec.yaml仅icon背景配置；tools/make_icon.py、tools/verify_icon.py；assets/icon/icon_qa.png

Android signing、manifest、Splash样式、Flutter UI/Motion/Navigation/业务均未修改。

## iOS

同一核心符号，整幅不透明蓝底、不预裁圆角，由iOS自行mask。
ios/Runner/Assets.xcassets/AppIcon.appiconset/下全部21张Icon-App-*.png均已覆盖。
Contents.json现有25个slot引用与所有实际文件严格匹配，逐一验证尺寸和无透明像素；
包括1024营销、iPhone/iPad及原有旧兼容尺寸。Contents.json内容不需要更改。
没有活动asset遗留旧朱砂「汇」图形。历史assets/icon/candidates与make_icon_candidates.py
保留作历史设计资料，没有pubspec/icon引用，亦不进入Flutter assets，不会混进launcher。

## 复现与验收

正常生成：python tools/make_icon.py后执行既有flutter_launcher_icons。
本机dart run触发既有path dependency解析异常(S:\S:\third_party...)；未改依赖处理，
改为通过当前.dart_tool/package_config.json直接执行已安装包bin/flutter_launcher_icons.dart：

```powershell
dart --packages=.dart_tool/package_config.json C:\Users\ninan\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_launcher_icons-0.14.4\bin\flutter_launcher_icons.dart
python tools/verify_icon.py
```

verify_icon从native前景资源与真实XML inset构建mask，而非仅看1024源图。
验证15张Android PNG、21张iOS PNG/25slot、monochrome一致、无旧红色画面、66-unit安全圆、
三mask×48/64px白色三连通块；生成浅/深模拟壁纸样本人工检查。

- CONFIRMED：开工git status/diff stat检查；全部既有改动保留。
- CONFIRMED：flutter analyze --no-pub无问题；flutter test --no-pub 268/268；
  flutter build apk --debug --no-pub成功；git diff --check通过。
- CONFIRMED：79个lib下Flutter文件SHA256与开工一致；pubspec.lock未变。
- CONFIRMED：API36 ncpu_api36最终APK安装成功；Launcher复杂壁纸、Recent Apps顶部图标、
  Settings All apps列表中汇课图标均人工截图检查，新白符号可分辨，不显示旧图。
- Code-reviewer通过；QA标签行间距问题已修复。PNG/geometry QA为可重复验证，不是识别率测试。
- UNVERIFIED：Android真机及其它厂商launcher、iOS构建/模拟器/真机。必要assets完整不等于iOS设备验收。

知识库同步：current_state/tasks/README/design/testing/changelog及本报告。完成后停止。
