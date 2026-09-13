# Design：「新历书」设计语言

Status: 2026-09-13 定稿并已实画验证（引导页 / 首页今日与整周 / 详情 / 设置 / 作息 / 学校管理）。

## 1. 设计判断（Design Read）

多校大学生的日常工具，方向定为「新历书」：**撕历/日历牌 × 编辑排印（editorial）**。
每一天是一页历牌；课程是排印条目，不是卡片堆。

## 2. 硬规则

1. **单强调色**：朱砂（日间 `#C3402B`，夜间提亮为 `#E0604A`）。全 App 不出现第二种饱和色。
2. **墨与纸**：日间冷纸白背景 `#FAFAF8`（不用暖奶油色），墨色正文 `#1D1C19`；
   夜间深墨 `#151418`，不用纯黑/纯白。
3. **结构靠发丝线**：条目分隔用 1px hairline（`#DEDCD5` / 夜间 `#37363C`），
   不用卡片阴影堆叠；需要抬升的表面（设置分组、弹窗）才有 12px 圆角容器。
4. **圆角系统锁**（全 App 唯一）：区块/弹层 12、按钮与输入 10、小签 4。
   不得混入其它圆角值。
5. **课程签色**：8 个低饱和编辑色（赤/青/黛/赭/藤/苔/石/绛），只出现在小块面
   （条目左侧色条、签底），不做整卡铺色；课程名散列定色（`colorKeyForName`），
   同课永远同色；夜间签底用深调、文字用提亮同色相。
6. **数字排版**：时间、周次、日期一律 `FontFeature.tabularFigures()` 对齐。
7. **动效克制**：只在有动机处使用（页面切换、确认反馈）；无循环装饰动画。
8. **空状态排印化**：如「今日无课」用细边框字牌 + 一句说明，不画插画。
9. 禁止：装饰性状态圆点、小节眉标滥用、破折号装饰、多中间点分隔
   （一行最多 1 个）、斜体标题。

## 3. 组件词汇

- `SectionHeaderLabel`：朱砂竖线 + 字距小标题（分组用）。
- `CourseListingRow`：左侧 6px 色条 + 76px 时间栏（起时 + 节次）+ 课程名/教室教师；
  发丝线分隔，onTap 进详情。
- 今日 hero：`M月D日` 34px 粗字 + 星期 + 右侧朱砂周次；学期外显示可点提示条。
- 整周：`‹ 第 N 周 (M.d-M.d) ›` 切换器 + 七个纵列日区（当天朱砂强调），
  每列复用 CourseListingRow。
- `EmptyDayPlate`：字牌式空状态。

## 4. 主题实现

- `AppPalette`（light/dark 两个 const 实例）+ `AppTheme.light()/dark()` 构建
  ThemeData；`AppTheme.paletteOf(context)` 按明暗取调色板（不做 ThemeExtension）。
- 圆角/组件样式集中在 `app_theme.dart`；课程色集中在 `course_colors.dart`。
- 外观偏好存 settings 表 `theme_mode`（system/light/dark），`ThemeController`
  (AsyncNotifier) 读写；MaterialApp 同时挂 light/dark 两套。

## 5. 参考来源

设计准则研读自 GitHub 高星设计技能库（taste-skill / hallmark / ui-ux-pro-max，
本地留档于研究阶段），采纳其：单强调色锁、反模板默认值、圆角系统锁、
动效须有动机、明暗双主题锁、内容密度纪律；并结合中文历书/排印语境落地。
