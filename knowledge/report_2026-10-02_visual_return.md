# 2026-10-02 启动图标、课程配色与预览返回修正（TASK-VISUAL-RETURN-01）

## 问题与原因

用户提供启动、桌面、Weekly及关闭过渡截图，反馈启动/图标模糊、课程配色灰闷、返回明显顿挫。截图只用于观察，不落盘进知识库，不复制真实课程/教师信息。

- `CONFIRMED`：10-01图标恢复把小尺寸launcher PNG同时复制到adaptive foreground/monochrome。Android12+未指定独立启动图，默认会复用应用图标；资源放大存在清晰度和裁切风险，不能由截图量化设备采样。
- `CONFIRMED`：旧课程色从灰暗饱和色混白0.28得到；关闭几何使正文在progress<0.65时透明，玻璃容器仍回缩成课程宽度，形成空白胶囊。背景缩放/遮罩sigma变化还随每帧发生。
- `UNVERIFIED`：用户真机的慢帧原因与新路径帧耗时。前轮API36模拟器profile仅为既有路径证据，本轮没有连接设备。

## 最终实现

- `tools/make_icon.py`保留原蓝色Flutter标志与旧PNG/iOS fallback，Android生成108dp矢量adaptive和独立纯黑monochrome；所有path顶点在66dp安全圆内。启动图为独立288dp矢量，路径在192dp可视圆内，values-v31/night-v31明确接线。几何源自Flutter SDK，BSD-3-Clause声明增补到THIRD_PARTY_NOTICES，原MIT署名保持。
- `CourseTint.card`直接使用16组明亮Light/深色Dark，原hash/colorKey/数据不变；不再混白或混灰，纯色底与字号/网格保持。Light onChip使用深色配对；正文对比度≥4.5。
- `TimetablePage`不再传sourceRect/provider，Weekly使用终态尺寸FractionalTranslation，正文全程保留；背景scale0、maxBlur0，Host零blur分支只画压暗ColoredBox。父面板blur22和三个按钮blur0保持。通用Host几何功能及harness保留；Today默认参数不变。
- 启动LaunchReveal移除Opacity，保留既有一次性180ms/4dp平移、就绪链、Reduced Motion；不新增启动依赖。
- 背景/X/下拖/Android Back/编辑继续共用原单次关闭状态机；完整详情保留预览，返回后再关闭为固定大小下滑。没有卸载、数据库重置或提交/推送。

## 验证

- `CONFIRMED`：专项36/36、全量342/342，flutter analyze无问题；新增完整详情返回后的中途关闭尺寸/方向回归。Weekly打开动画中整宽/课程原位、14节滚动、Reduced、viewport变化、Host通用几何、重复关闭/编辑/拖动均覆盖。初次两项旧几何起帧测试因平移路径在进度0尚未挂载失败，改为首个动画帧检查新产品合同后通过。
- `CONFIRMED`：verify_icon核对旧PNG/iOS字节与槽位、adaptive/启动接线、monochrome纯黑及两种可视安全圆；aapt列包包含三张矢量资源。独立复审发现最初adaptive角点超安全圆，缩至56/202并逐顶点验证后APPROVE。
- `CONFIRMED`：三包构建成功，兼容正式签名证书与前轮正式签名包实时读回一致，debug证书匹配既有debug。签名私钥/密码未输出或复制进仓库。正式签名包仍是Debug构建；不据此宣称release流畅度。
- `UNVERIFIED`：用户真机安装与清晰度、桌面mask实际效果、冷启动/60Hz/高刷返回帧耗时、iOS构建/显示。去掉宽高重排/滤镜只是代码层减负，尚不宣称卡顿消除。

## 当前安装包

路径均在`build/app/outputs/flutter-apk/`；前轮有明确日期/名称的包保留。本轮兼容包应用ID/版本维持原兼容合同（1.1.0 / 10006）；可用匹配证书进行同版本覆盖，未实际安装。普通包仍为0.1.5 / 6。`app-debug.apk`已更新为本轮普通包副本。

| 文件 | 字节 | SHA-256 |
| --- | --- | --- |
| app-huike-debug.apk | 207132488 | 3137A460CCE528BB1486B7AC43EC4730F5E65ACFE3F09776D6A231EB7F3D9D22 |
| huike-visual-fix-legacy-release-sign.apk | 174741156 | 9E9A3166071A0C02F36281C3EB69F78568FA3A0D2FE805C91315440AEE08F785 |
| huike-visual-fix-legacy-debug-sign.apk | 174741156 | 64F4CD7E8DB0664C97401E4BC788D3AFC05E4FF266ECFB6E7D471367BF9000B3 |

证书SHA-256：兼容正式`2e8ac142d9c68df3ebc45a77269b8c9d98ad313c4763ab704ba68087a8b58799`；本机debug`9f3fff6ec93838bd7c1d4e2a66fc43ccd0d5a19c5856c6c45019571c20dc57b3`。aapt确认兼容应用ID、debuggable及完整MainActivity正确。所有安装包仅构建/核对，没有执行设备安装。
