# Homework 0.3.0 (6) — 原生交互改版

在现有 [PR #1](https://github.com/kuangkeming2006-max/HomeworkApp/pull/1) 和 feature/iphone-interactions-theme 分支继续开发，PR 保持草稿且未合并。最低版本为 iOS/iPadOS 26；使用 Xcode 27 和实际 iPhone 15 Pro / iOS 27.0 模拟器构建、运行及截图。

## 本次实现

- 分类位于 Assignments 标题右侧，没有灰色背景。All、Upcoming、Completed、Abandoned、Deleted 使用原生 Menu / Picker；All 保留三个固定颜色分段，其他分类真正筛选。Sort 恢复原生菜单和系统勾选标记。分类选择不会被滚动回调改回。
- 大标题随列表滚走后，导航栏显示普通小字和分类菜单。搜索默认隐藏，下拉后显示标准搜索栏；支持输入、取消和辅助功能 Search 操作。使用系统 TabView、Liquid Glass 工具栏和原生安全区，页面立即切换，工具栏反应不阻塞页面。
- 点击圆圈立即完成或恢复，带有限的图标/粒子动画和系统成功触感。Upcoming 最多保留完成行五秒，离开标签或撤销即清除待移除状态；All 立即移动同一 UUID 的行。原生侧滑动作及五秒撤销保留。
- Deleted 与任务状态分开记录；恢复保留原状态、内容和附件，并增加修订号。软删除记录引用的附件不会被清理。
- 新建和已有项目统一使用本地草稿和原生推入页面，只有 Save 才提交。Back 和交互返回显示居中的 Save / Discard Changes / Keep Editing 提示。验证失败保留草稿，重复保存受保护。
- 附件添加和删除先暂存；Discard 保留旧文件并清理本次导入副本。保存采用三方合并，保留独立外部修改，冲突时保留草稿并提示。Photos / Files 在同一行左右排列，各有 44 点触控范围；删除为红色侧滑按钮并要求确认。
- 列表缩略图直接打开图片；详情显示大图且不显示图片文件名。图片支持分享、捏合和双击缩放、受边界约束的平移，以及 1x 时下拉关闭。缩略图有缓存和解码尺寸上限，文档使用 Quick Look。
- 日历横滑跟随手指移动，浏览月份保留已选日期；日期点击和横滑分开识别，纵向拖动可以滚动页面。选中底色只属于当前页的正确日期。详情的模糊过渡可取消，过期回调不能覆盖新操作。
- 保留深浅色、跟随系统和七种不同的主题色。默认紫色及主题色影响范围参考 0.2.0；状态和删除等语义颜色固定。二级设置和编辑页面按原生导航隐藏底栏。
- 保留冻结的 V1 模型、迁移、旧备份、提醒、AI 显式确认及现有 iPad 兼容路径，没有引入第三方 UI 库。

## 主要文件

| 范围 | 主要文件 |
| --- | --- |
| 查询、回收站与并发草稿合并 | AssignmentQuery.swift、AssignmentDraftMerge.swift、AssignmentStore.swift、AppContainer.swift |
| 显式保存和返回保护 | AssignmentEditor.swift、AssignmentDetailView.swift、EditorDismissalGuard.swift |
| 标题、搜索和完成反馈 | AssignmentListView.swift、AssignmentListProjection.swift、AssignmentHeadingLayout.swift、AssignmentSearchField.swift、AssignmentCompletionButton.swift |
| 附件暂存和图片手势 | AttachmentViewModel.swift、AttachmentList.swift、AttachmentPreview.swift |
| 导航、工具栏和主题 | AppNavigation.swift、AssignmentWorkspace.swift、WorkspaceToolbar.swift、AppMotion.swift、SettingsView.swift |
| 日历 | CalendarView.swift、CalendarMonthPager.swift、HorizontalCalendarPan.swift、CalendarViewModel.swift |
| 聚焦验证与构建 | NativeRedesignTests.swift、IPhoneLayoutPreviewTests.swift、原有编辑/附件/任务流程测试、run_apple.py、iphone-preview.yml |

标题采用真实 List 内容和系统内联栏的小字。具体布局和 Apple 参考见 [NATIVE_IPHONE_LAYOUT.md](NATIVE_IPHONE_LAYOUT.md)。

主要逻辑提交：dec2f36（显式保存和回收站）、2556ae9（五分类、完成反馈、图片和日历）、1d3ec6d（并发草稿合并和触控范围）、41b17df / 064741a（原生返回和交互返回保护）、bb0cf07（日历方向识别）、6353a01 / b688bb4（真实列表标题和下拉搜索）、a074476（标题行边距）、ce5900a（对齐系统搜索 Close 的验证）。[完整代码范围](https://github.com/kuangkeming2006-max/HomeworkApp/compare/56f61c7...ce5900a)。最终验证源码和交付文档提交分别记录，文档提交不改变安装包源码。

## 实际验证

最终安装包和验证源码为 ce5900ab76e42ae78f6a3a51ebfa0ed6e0f5e43c，应用布局与 a074476 相同。[最终运行](https://github.com/kuangkeming2006-max/HomeworkApp/actions/runs/39908595081)通过无警告的未签名 arm64 iPhoneOS 构建、22 项领域测试，以及全部 4 项聚焦模拟器检查（3 项 UI、1 项布局状态）。实际环境为 iPhone 15 Pro / iOS 27.0（24A434），Xcode 27.1。没有报告运行时警告；模拟器构建的 AppIntents 元数据跳过提示保存在交付记录中。

| 最终 UI 检查 | 结果 |
| --- | --- |
| 原生菜单点击/长按拖选、标题收起及末行可达 | 通过，68.638 秒 |
| 五分类筛选、颜色分段和初始隐藏搜索 | 通过，82.664 秒 |
| 16 次切页、两页标题等高、下拉/输入/关闭搜索与列表恢复 | 通过，103.146 秒 |

滚动布局状态检查通过（0.004 秒），单用例 180 秒时限保持不变。实际测得 Assignments 与 Calendar 的大标题起始高度均为 116.667 点；小标题位于左侧原生工具栏内。最终 11 张原始 PNG 已逐一检查。

此前相关 [整组运行](https://github.com/kuangkeming2006-max/HomeworkApp/actions/runs/39808705659)（4fedcc6）通过 22 项领域测试及 36/37 项模拟器检查：27 项宿主回归和 9 项 UI 用例通过，组合标题用例失败。其 31 张非失败截图已逐一检查。后续保留断言和原有 180 秒时限，将组合用例拆分为菜单/收起、五分类、重复切页/搜索三项，增加实际小标题位置、标题等高和搜索输入/取消检查。最终改动后没有重跑整组用例，不能将此前整组结果记为当前版本全绿。

中间失败、实际截图暴露的问题及修复保留在 [STATUS.md](STATUS.md)，不计为通过证据。

## 交付和限制

交付目录为 outputs/Builds/v0.3.0，包含完整和无 Widget 的未签名 arm64 IPA、安装说明、SHA-256、验证摘要和 38 张未修改的原图（最终 11 张、此前相关流程 27 张）。每张截图的确切源码和运行写入 Previews/manifest.json；当前标题、菜单、收起、五分类和搜索截图优先展示。两个 IPA 的身份、版本 0.3.0 / build 6、扩展变体、设备 arm64 架构及无预置签名已核对。完整包约 1.59 MB，无扩展包约 1.54 MB。

模拟器不能证明实际签名安装、震动感受、通知送达或真机帧率。深色和 accessibility3 截图来自此前相关运行；减少动态效果的合成检查使用应用自己的测试开关，系统全局 Reduce Motion 和 VoiceOver 仍需真机核验。已覆盖系统 Photos / Files 的打开和取消及 PDF 的 Quick Look；未自动完成系统选择器内的选片/文件导入，导入服务和草稿文件处理另有测试。未运行全部无关 UI 用例或 iPad 外观矩阵。

