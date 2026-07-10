# NyxAgent CLI / ADB 全功能测试台账

更新日期：2026-07-10

## 目标与环境

- 目标：使用 HBuilderX CLI 和 ADB 覆盖 App 的页面、主流程、权限、持久化、异常恢复与关键跨页交互；发现缺陷后修复并回归。
- HBuilderX：`5.15.2026070915`
- 编译目标：uni-app x Android class
- 设备：`emulator-5554`，Redmi 22127RK46C，Android 9
- 分辨率：`1440x2560`，density `640`
- 调试基座：`io.dcloud.uniappx`

状态：`待测` / `测试中` / `通过` / `失败` / `受阻` / `不适用`

## 执行规则

1. 每个页面至少验证进入、返回、主要按钮、空状态、输入状态和一次重启后的持久化。
2. 输入类页面必须验证软键盘弹出后输入框可见、可输入、可收起，页面布局不重叠。
3. 媒体与文件功能必须分别验证授权允许、授权拒绝、取消选择和成功选择。
4. 网络或模型功能必须记录请求前置条件；未配置凭据时至少验证错误态和恢复路径。
5. 每个修复记录修改文件、复现证据、回归证据和 commit。

## 页面与功能矩阵

| 区域 | 页面 / 功能 | 核心检查 | 状态 | 证据 / 备注 |
| --- | --- | --- | --- | --- |
| 主导航 | `pages/agents/agents` | 筛选、私聊/群聊入口、新建 Agent、新建群聊、头像选择、首次引导 | 待测 | |
| 主导航 | `pages/todo/todo` | 待办新增/完成/筛选/删除、笔记搜索/新增/编辑 | 待测 | |
| 主导航 | `pages/files/files` | 根目录、面包屑、新建文件/目录、打开、重命名、删除 | 待测 | |
| 主导航 | `pages/settings/settings` | 所有设置入口、资料摘要、状态展示 | 待测 | |
| 私聊 | `pages/chat/chat` | 文本发送、流式状态、停止/续跑、工具栏、图片/拍照/文件、滚动、重进恢复 | 测试中 | 已完成进入、历史渲染、输入框焦点基线；键盘修复待回归 |
| 私聊 | `pages/agent-settings/agent-settings` | 名称/备注/头像/Prompt/规则/模型/语音/生成参数/Skills/工具/截断/删除 | 待测 | 键盘遮挡问题优先 |
| 群聊 | `pages/group-chat/group-chat` | 文本/媒体、调度、暂停、后台续流、成员消息、上下文/文件/记忆入口 | 测试中 | 键盘布局同步修复，待进入群聊回归 |
| 群聊 | `pages/group-chat-settings/group-chat-settings` | 群名、成员、调度 Prompt、共享 Prompt、未保存退出 | 待测 | 键盘遮挡问题优先 |
| 群聊 | `pages/group-chat-sessions/group-chat-sessions` | 会话新增、切换、重命名、删除 | 待测 | |
| 历史 | `pages/history/history` | 私聊/群上下文切换、预览、恢复、批量删除、清空 | 待测 | |
| 编辑器 | `pages/note-editor/note-editor` | 新建/编辑/保存/返回保护 | 测试中 | 已统一为页面 resize，关闭固定编辑区的控件级上推；待回归 |
| 编辑器 | `pages/common/editor/editor` | 全屏编辑、保存、取消、空内容、长文本 | 测试中 | 已统一为页面 resize，关闭固定编辑区的控件级上推；待回归 |
| 媒体 | `pages/common/crop/crop` | 图片加载、缩放/移动、裁剪、取消 | 待测 | |
| 上下文 | `pages/context-preview/context-preview` | 请求快照、标签顺序、空状态、长内容滚动 | 待测 | |
| 记忆 | `pages/memory/memory` | 分类/目标切换、新增/编辑/删除、搜索、记忆整理状态 | 待测 | |
| 设置 | `pages/settings/profile/profile` | 用户名、简介、详细介绍、头像、保存与私聊注入 | 待测 | 键盘遮挡问题优先 |
| 设置 | `pages/settings/basic/basic` | 提供商列表、启停、默认配置入口 | 待测 | |
| 设置 | `pages/settings/basic/provider-edit` | 新增/编辑提供商、URL/API Key/模型、校验、删除 | 待测 | 键盘遮挡问题优先 |
| 设置 | `pages/settings/model/model` | 旧模型设置兼容与跳转 | 待测 | |
| 设置 | `pages/settings/default-models/default-models` | chat/TTS/STT/vision/organize 默认模型与图片描述 Prompt | 待测 | |
| 设置 | `pages/settings/generation/generation` | 温度、Token、迭代、流式配置与边界值 | 待测 | |
| 设置 | `pages/settings/plugin/plugin` | 插件配置、启停、输入校验、错误态 | 待测 | |
| 设置 | `pages/settings/skills/skills` | Skill 新增/编辑/删除、Agent 绑定、长文本编辑 | 待测 | |
| 设置 | `pages/settings/data/data` | 导出、导入、取消、无效文件、覆盖确认 | 待测 | |
| 设置 | `pages/settings/about/about` | 版本信息、外链打开 | 待测 | |
| 通用组件 | `rice-ui/action-sheet` | 展示、选择、取消、遮罩关闭 | 待测 | 通过业务入口覆盖 |
| 通用组件 | `rice-ui/dialog` | 确认、取消、输入校验、遮罩行为 | 待测 | 通过业务入口覆盖 |

## 跨功能检查

| 检查项 | 状态 | 证据 / 备注 |
| --- | --- | --- |
| 首次安装与冷启动 | 待测 | |
| 前后台切换与页面退出时流继续 | 待测 | |
| App 进程重启后的数据恢复 | 待测 | |
| 软键盘与输入框可见性 | 受阻 | 修复已实现；模拟器拼音 IME 高度恒为 0，动态遮挡按下方清单留待手动真机测试 |
| 长消息滚动与底部定位 | 测试中 | 私聊长消息基线已采集；已补键盘尺寸变化后的重测量和保底部逻辑 |
| 相册、相机、文件权限 | 待测 | |
| 断网、超时、无模型配置错误态 | 待测 | |
| 深浅色、系统字体和高 density 布局 | 待测 | 当前设备 density 640 |
| 日志中的 crash / ANR / UTS 异常 | 测试中 | |
| 未注册或不可达页面检查 | 测试中 | `pages/group-chats/group-chats.uvue` 未注册，待确认是否死代码 |

## 发现的问题

| ID | 严重度 | 问题 | 状态 | 证据 | 修改文件 / commit |
| --- | --- | --- | --- | --- | --- |
| ENV-001 | P1 | HBuilderX CLI 检测到雷电 ADB server，最新包编译成功但调试基座连接超时 | 已解决 | 改由 HBuilderX 内置 ADB 独占 server，最新包同步与启动成功 | 无项目改动 |
| UI-001 | P1 | 手机弹出软键盘后页面顶端被推出屏幕；聊天与全屏编辑坐标异常 | 实现完成，真机待验 | DCloud 文档确认 `adjust-position` 默认会 transform 非滚动页面，自定义导航栏可能被推出可视范围；模拟器 IME 高度为 0 | `pages/chat/chat.uvue`、`pages/group-chat/group-chat.uvue`、`components/FullscreenTextEditor/FullscreenTextEditor.uvue`、`pages/note-editor/note-editor.uvue`、`pages.json` / `fix: stabilize keyboard layouts` |
| UI-002 | P2 | 聊天输入框文字底部留白不足，视觉上顶头 | ADB 通过 | 私聊实机渲染截图确认单行文字上下居中；群聊复用相同参数，待群聊流程回归 | `pages/chat/chat.uvue`、`pages/group-chat/group-chat.uvue` / `fix: stabilize keyboard layouts` |
| STRUCT-001 | P3 | `pages/group-chats/group-chats.uvue` 存在但未注册到 `pages.json` | 待确认 | 静态页面清单 | 待定 |

## 修改记录

| 日期 | 文件 | 修改 | 验证 | commit |
| --- | --- | --- | --- | --- |
| 2026-07-10 | `APP_TEST_PLAN.md` | 建立全功能测试矩阵和缺陷台账 | `git diff --check` 通过 | `fix: stabilize keyboard layouts` |
| 2026-07-10 | `pages/chat/chat.uvue`、`pages/group-chat/group-chat.uvue` | 关闭输入组件重复顶起；键盘变化后重测滚动区；统一输入文字上下留白 | HBuilderX CLI 编译、ADB 输入与截图检查通过；真软键盘待真机 | `fix: stabilize keyboard layouts` |
| 2026-07-10 | `components/FullscreenTextEditor/FullscreenTextEditor.uvue`、`pages/note-editor/note-editor.uvue`、`pages.json` | 全屏编辑改为页面 resize，关闭控件 transform 上推 | HBuilderX CLI 编译与 ADB 静态布局通过；真软键盘待真机 | `fix: stabilize keyboard layouts` |

## 执行日志

| 时间 | 操作 | 结果 |
| --- | --- | --- |
| 2026-07-10 15:20 | HBuilderX CLI 设备枚举 | 发现 `emulator-5554` |
| 2026-07-10 15:20 | ADB 环境采集 | Android 9，1440x2560，density 640 |
| 2026-07-10 15:21 | CLI 部署当前工程 | 27 页面 Android class 编译成功；受 ADB server 冲突影响，调试基座连接超时 |
| 2026-07-10 15:28 | 切换为 HBuilderX 内置 ADB server 后重新部署 | 当前工程同步成功，调试基座启动并进入 Agent 列表 |
| 2026-07-10 15:30 | ADB 进入私聊并采集布局基线 | 输入框 bounds `[276,2356][952,2500]`，长历史消息正常渲染 |
| 2026-07-10 15:38 | 检查软键盘窗口 | 模拟器拼音 IME 报告已显示，但窗口高度为 0；无法作为真实软键盘遮挡证据，保留真机补测项 |
| 2026-07-10 15:43 | 核对 DCloud `input` 官方文档 | 确认 `adjust-position` 默认会 transform 非滚动页面，且自定义导航栏可能被推出可视范围 |
| 2026-07-10 15:50 | 私聊输入与布局回归 | 输入 `keyboard_test` 后导航栏和输入框 bounds 保持基线，输入文字上下居中；未发现 UTS / Java fatal |
| 2026-07-10 16:02 | 全屏编辑静态布局回归 | 标题栏、元信息、正文编辑区与 footer 正常；动态软键盘仍受模拟器 IME 限制 |

## 手动真机回归

以下项目受当前模拟器软键盘窗口高度恒为 0 限制，需要后续在 Android 真机测试：

1. 私聊和群聊分别弹出键盘，确认自定义导航栏始终留在屏幕内，输入栏贴在键盘上方。
2. 键盘打开和关闭各执行三次，确认消息列表仍位于原来的阅读位置；原本在底部时继续保持到底。
3. 输入单行和三行文本，确认文字上下留白一致、输入栏高度随行数增长且不跳动。
4. 从聊天设置打开描述、提示词、对话规则全屏编辑，再测试文件编辑器和笔记编辑器；确认标题栏不被顶走，点击位置与光标位置一致。
5. 在全屏编辑器长按选择、拖动光标并收起键盘，确认正文和 footer 不重叠、不发生残留位移。
