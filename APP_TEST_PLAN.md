# NyxAgent CLI / ADB 全功能测试台账

更新日期：2026-07-11

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
| 主导航 | `pages/agents/agents` | 筛选、私聊/群聊入口、新建 Agent、新建群聊、头像选择、首次引导 | 测试中 | ADB 已通过私聊/群聊筛选与会话入口；创建、头像和首次引导待测 |
| 主导航 | `pages/todo/todo` | 待办新增/完成/筛选/删除、笔记搜索/新增/编辑 | 测试中 | ADB 已通过页面进入、列表与筛选布局；写操作待测 |
| 主导航 | `pages/files/files` | 根目录、面包屑、搜索、排序、导入、新建文件/目录、打开、重命名、删除 | 测试中 | ADB 已通过根目录、名称回退与主导航；导入和写操作待测 |
| 主导航 | `pages/settings/settings` | 所有设置入口、资料摘要、状态展示 | 测试中 | ADB 已通过设置列表与运行诊断入口；各设置写操作继续回归 |
| 设置 | `pages/settings/diagnostics/diagnostics` | 错误记录、诊断编号、技术详情、清空、空状态 | 测试中 | ADB 已通过入口与空状态；错误注入、详情和清空待测 |
| 私聊 | `pages/chat/chat` | 文本发送、流式状态、停止/续跑、工具栏、图片/拍照/文件、滚动、重进恢复 | 测试中 | 已完成进入、历史渲染、输入框焦点基线；键盘修复待回归 |
| 私聊 | `pages/agent-settings/agent-settings` | 名称/备注/头像/Prompt/规则/模型/语音/生成参数/Skills/工具/截断/删除 | 待测 | 键盘遮挡问题优先 |
| 群聊 | `pages/group-chat/group-chat` | 文本/媒体、调度、暂停、后台续流、成员消息、上下文/文件/记忆入口 | 测试中 | 干净编译后 ADB 已通过历史渲染与页面进入；发送、后台流和键盘待测 |
| 群聊 | `pages/group-chat-settings/group-chat-settings` | 群名、成员、调度 Prompt、共享 Prompt、未保存退出 | 测试中 | ADB 已通过页面进入和成员列表；编辑、保存与退出保护待测 |
| 群聊 | `pages/group-chat-sessions/group-chat-sessions` | 会话新增、切换、重命名、删除 | 测试中 | ADB 已通过页面进入和当前会话展示；写操作待测 |
| 历史 | `pages/history/history` | 私聊/群上下文切换、预览、恢复、批量删除、清空 | 待测 | |
| 编辑器 | `pages/note-editor/note-editor` | 新建/编辑/保存/返回保护 | 测试中 | 已统一为页面 resize，关闭固定编辑区的控件级上推；待回归 |
| 编辑器 | `pages/common/editor/editor` | 全屏编辑、保存、取消、空内容、长文本 | 测试中 | 已统一为页面 resize，关闭固定编辑区的控件级上推；待回归 |
| 媒体 | `pages/common/crop/crop` | 图片加载、缩放/移动、裁剪、取消 | 测试中 | 设置头像已成功打开系统 Picker 并显示测试 PNG；选择、裁剪、保存与取消路径继续执行 |
| 上下文 | `pages/context-preview/context-preview` | 请求快照、标签顺序、空状态、长内容滚动 | 待测 | |
| 记忆 | `pages/memory/memory` | 分类/目标切换、新增/编辑/删除、搜索、记忆整理状态 | 待测 | |
| 设置 | `pages/settings/profile/profile` | 用户名、简介、详细介绍、头像、保存与私聊注入 | 测试中 | 设置头像相册入口已在 emulator-5554 打开；裁剪保存和权限分支继续执行 |
| 设置 | `pages/settings/basic/basic` | 提供商列表、启停、默认配置入口 | 待测 | |
| 设置 | `pages/settings/basic/provider-edit` | 新增/编辑提供商、URL/API Key/模型、校验、删除 | 待测 | 键盘遮挡问题优先 |
| 设置 | `pages/settings/model/model` | 旧模型设置兼容与跳转 | 待测 | |
| 设置 | `pages/settings/default-models/default-models` | chat/TTS/STT/vision/organize 默认模型与图片描述 Prompt | 待测 | |
| 设置 | `pages/settings/generation/generation` | 温度、Token、迭代、流式配置与边界值 | 待测 | |
| 设置 | `pages/settings/plugin/plugin` | 插件配置、启停、输入校验、错误态 | 待测 | |
| 设置 | `pages/settings/skills/skills` | Skill 新增/编辑/删除、Agent 绑定、长文本编辑 | 待测 | |
| 设置 | `pages/settings/data/data` | 导出、导入、取消、无效文件、覆盖确认 | 测试中 | 已完成清单校验、SQLite 事务、工作区 staging 恢复与用户目录恢复；ADB 文件选择/真实 ZIP 回归待执行 |
| 设置 | `pages/settings/about/about` | 版本信息、外链打开 | 待测 | |
| 通用组件 | `rice-ui/action-sheet` | 展示、选择、取消、遮罩关闭 | 待测 | 通过业务入口覆盖 |
| 通用组件 | `rice-ui/dialog` | 确认、取消、输入校验、遮罩行为 | 待测 | 通过业务入口覆盖 |

## 跨功能检查

| 检查项 | 状态 | 证据 / 备注 |
| --- | --- | --- |
| 首次安装与冷启动 | 待测 | |
| 前后台切换与页面退出时流继续 | 待测 | |
| App 进程重启后的数据恢复 | 待测 | |
| 软键盘与输入框可见性 | 测试中 | 真机确认页面顶部不再被推出屏幕，但输入栏未抬到键盘上方；已增加 resize 差额补偿并通过 Android 编译，待二次真机回归 |
| 长消息滚动与底部定位 | 测试中 | 私聊/群聊已改为固定 80 渲染单元、每次 40 单元的双向批量滑动窗口；Android class 编译通过，滚动锚点待下次 ADB/真机回归 |
| 相册、相机、文件权限 | 待测 | |
| 断网、超时、无模型配置错误态 | 测试中 | LLM transport error 已与正常回复分离；私聊/群聊显示失败消息和 toast，运行诊断保留结构化记录；待 ADB 断网注入回归 |
| 深浅色、系统字体和高 density 布局 | 待测 | 当前设备 density 640 |
| 日志中的 crash / ANR / UTS 异常 | 测试中 | 2026-07-11 干净编译后完成主要页面冒烟，未发现 `FATAL EXCEPTION`、`NoSuchMethodError` 或未捕获 UTS 异常 |
| 未注册或不可达页面检查 | 已确认 | `pages/group-chats/group-chats.uvue` 未注册且全项目无调用方，是旧群聊列表遗留页；当前入口由 `pages/agents/agents.uvue` 承担，文件暂保留 |

## 发现的问题

| ID | 严重度 | 问题 | 状态 | 证据 | 修改文件 / commit |
| --- | --- | --- | --- | --- | --- |
| ENV-001 | P1 | HBuilderX CLI 检测到雷电 ADB server，最新包编译成功但调试基座连接超时 | 已解决 | 改由 HBuilderX 内置 ADB 独占 server，最新包同步与启动成功 | 无项目改动 |
| UI-001 | P1 | 手机弹出软键盘后页面顶端被推出屏幕；关闭控件上推后输入栏又停在键盘下方 | 差额补偿完成，真机待复验 | 真机确认顶部位移已消失；现按 `keyboardHeight - window resize` 只抬升系统未处理的高度，避免页面上推和双重补偿 | `pages/chat/chat.uvue`、`pages/group-chat/group-chat.uvue`、`components/FullscreenTextEditor/FullscreenTextEditor.uvue`、`utils/keyboard-inset.uts` |
| UI-002 | P2 | 聊天输入框文字底部留白不足，视觉上顶头 | ADB 通过 | 私聊实机渲染截图确认单行文字上下居中；群聊复用相同参数，待群聊流程回归 | `pages/chat/chat.uvue`、`pages/group-chat/group-chat.uvue` / `fix: stabilize keyboard layouts` |
| STRUCT-001 | P3 | `pages/group-chats/group-chats.uvue` 存在但未注册到 `pages.json` | 已确认遗留 | 全项目仅文件自身引用其 TabBar current，当前群聊列表由 Agent 页承载 | 暂不删除，后续清理需单独确认 |
| DATA-001 | P1 | 私聊离页后后台流最终回复可能不持久化 | 已修复，ADB 待回归 | 离页后继续 reduce，终态强制保存；后台跳过页面 UI 副作用 | `pages/chat/chat.uvue` / `a6b0447` |
| DATA-002 | P1 | 运行中群会话可被删除，runtime 后续写回孤儿消息 | 已修复 | 删除前失效、移除并 abort runtime，旧回调由 runId 拦截 | `utils/group-chat-turn-runtime.uts` 等 / `3ba2355` |
| DATA-003 | P1 | 全量备份缺少用户文件恢复，旧包可能误清工作区 | 已修复，ADB 待回归 | 用户目录进入恢复范围；ZIP 前缀验证；工作区 staging 后替换 | `utils/data-import.uts` 等 / `9b49cc7`、`0183777` |
| DATA-004 | P1 | 导入前清库且无事务，损坏备份可造成部分提交 | 已修复，ADB 待回归 | 校验 app/schema/data，核心表 transaction + rollback | `utils/data-import.uts`、`utils/database.uts` / `ea56926` |
| DATA-005 | P2 | 待办/笔记写入失败仍提示成功，并可能先删旧文件 | 已修复，ADB 待回归 | 检查 FileOpResult，失败重载；全部新文件写成功后才清理旧文件 | `pages/todo/todo.uvue` / `8e8bed1` |
| DATA-006 | P1 | 私聊、群聊多表删除与集合保存可能留下部分状态 | 已修复 | 私聊历史删除、群会话 7 表删除及集合重写均事务化 | `utils/database.uts`、`utils/group-chat-service.uts` 等 / `4368d55`、`ede3edc` |
| DATA-007 | P2 | Agent/群聊实体删除但工作区保留时，文件页把内部 ID 当名称显示 | 已修复，ADB 待回归 | 当前名称、中央元数据、SQLite 快照、内置名称依次回退；无历史名称时显示删除占位 | `utils/workspace-name-snapshot.uts`、`utils/file-manager.uts` 等 |
| PERF-001 | P1 | 对话消息过多时渲染节点持续增长，流式更新导致列表性能快速下降 | 已修复，ADB 待回归 | 私聊/群聊上下边缘按 40 单元批量换窗，窗口固定 80 单元；消息 key 稳定，群聊 runtime UI 同步合并为 40ms | `utils/chat-message-window.uts`、`pages/chat/chat.uvue`、`pages/group-chat/group-chat.uvue` |
| RUNTIME-001 | P0 | Android 消息 key 读取时间戳时触发 `Long cannot be cast to String`，历史私聊白屏 | 已修复，ADB 通过 | 私聊和群聊列表 key 改为窗口 source index；历史页可正常渲染 | `pages/chat/chat.uvue`、`pages/group-chat/group-chat.uvue` |
| GROUP-001 | P1 | 群聊缺少只对用户可见的成员私发；其他成员/调度/复盘可能读取私密正文 | 已修复，ADB 待回归 | 私发由用户原文显式触发；只对用户和原 Agent 可见，原 Agent 后续公开发言保留连续性但不得主动泄露；不进入公开计数和复盘 | `utils/group-chat-*`、`components/ChatBubble/ChatBubble.uvue` |
| ERROR-001 | P1 | LLM 网络/API/SSE 失败被当作正常 assistant 正文，或流结束后无提示 | 已修复，ADB 待回归 | transport error 独立传递；失败气泡、toast、诊断记录；失败不写成功快照、不触发 TTS | `llm-api-client.uts`、`llm-client.uts`、`utils/event.uts`、聊天页面 |
| ERROR-002 | P1 | Provider、模型、资料、生成参数、插件、Skill 等保存失败仍更新 UI 或提示成功 | 已修复，ADB 待回归 | DAO 返回真实 boolean；相关多字段保存改为事务；失败回滚即时选择或保留 dirty 状态 | 设置页面、`database-settings.uts`、`provider.uts` 等 |
| ERROR-003 | P2 | App 每次启动尝试重复 `ALTER TABLE`，logcat 持续输出 `duplicate column` | 已修复，ADB 通过 | 迁移前使用 `PRAGMA table_info` 检查字段；冷启动清空 logcat 后无重复字段错误 | `utils/database-core.uts`、`utils/database.uts` |
| RUNTIME-002 | P0 | 修改导出 UTS 函数返回值后，Android 增量缓存混用旧调用方与新实现，进入群聊触发 `NoSuchMethodError` | 已修复，ADB 通过 | 恢复既有公共函数 JVM 签名；需要结果的页面改用已有底层状态写入；`--cleanCache true` 重编 28 页面后群聊入口正常 | Agent/历史/文件/群聊页面与 runtime state helpers |
| DATA-008 | P1 | 默认群聊创建或调度持久化中途失败时可能残留数据库行、目录，部分失败只写日志 | 已修复，ADB 入口通过 | 创建失败事务清理 9 张关联表并回收工作区；复盘、任务、记忆、指标、上下文和快照写入失败进入统一诊断 | `utils/database-group-chat.uts`、`utils/group-chat-service.uts`、`utils/group-chat-scheduler.uts` 等 |

## 修改记录

| 日期 | 文件 | 修改 | 验证 | commit |
| --- | --- | --- | --- | --- |
| 2026-07-10 | `APP_TEST_PLAN.md` | 建立全功能测试矩阵和缺陷台账 | `git diff --check` 通过 | `fix: stabilize keyboard layouts` |
| 2026-07-10 | `pages/chat/chat.uvue`、`pages/group-chat/group-chat.uvue` | 关闭输入组件重复顶起；键盘变化后重测滚动区；统一输入文字上下留白 | HBuilderX CLI 编译、ADB 输入与截图检查通过；真软键盘待真机 | `fix: stabilize keyboard layouts` |
| 2026-07-10 | `components/FullscreenTextEditor/FullscreenTextEditor.uvue`、`pages/note-editor/note-editor.uvue`、`pages.json` | 全屏编辑改为页面 resize，关闭控件 transform 上推 | HBuilderX CLI 编译与 ADB 静态布局通过；真软键盘待真机 | `fix: stabilize keyboard layouts` |
| 2026-07-10 | `pages/files/files.uvue`、`pages/settings/settings.uvue` | 按 V5 设计对齐一级页层级；文件页新增搜索、排序与更多菜单 | HBuilderX 5.15 对 27 页面执行 Android 差量编译成功 | `30a59e6` |

## 自动审计修复轮次

| 轮次 | 范围 | 结果 | 验证 | commit |
| --- | --- | --- | --- | --- |
| 1 | 私聊后台流、键盘监听 | 最终消息可在离页后继续归并并持久化；监听按 ID 注销 | UTS 扫描、Android compile-only | `a6b0447` |
| 2 | 群聊删除与 runtime | 删除运行中会话会先终止并淘汰 runtime | UTS 扫描、Android compile-only | `3ba2355` |
| 3 | 备份用户目录 | 恢复 `user-files/`，旧包缺项不清本地 | UTS 扫描、Android compile-only | `9b49cc7` |
| 4 | 导入校验与事务 | 严格校验清单，数据库失败 rollback | UTS 扫描、Android compile-only | `ea56926` |
| 5 | 待办/笔记文件写入 | 写入失败回滚 UI，成功后才清理旧文件 | UTS 扫描、Android compile-only | `8e8bed1` |
| 6 | 工作区恢复 | staging 解压完整后再替换正式目录 | UTS 扫描、Android compile-only | `0183777` |
| 7 | 历史删除 | 私聊与群会话多表删除事务化 | UTS 扫描、Android compile-only | `4368d55` |
| 8 | Agent 删除 | 区分列表删除失败与目录清理失败 | UTS 扫描、Android compile-only | `f855051` |
| 9 | 私聊保存 | 会话与消息同事务，失败保留旧历史并可重试 | UTS 扫描、Android compile-only | `e8a7244` |
| 10 | 群聊集合保存 | 成员、会话、消息集合重写事务化 | UTS 扫描、Android compile-only | `ede3edc` |
| 11 | 群聊分支与新会话 | 工作区/数据库失败时回滚新分支和目录 | UTS 扫描、Android compile-only | `9df9fba`、`b134c0d` |
| 12 | 旧用户目录迁移 | 复制失败清理半成品且保留重试机会 | UTS 扫描、Android compile-only | `8a44236` |
| 13 | 残留工作区显示名 | 名称快照与中央元数据保留最后名称；旧内置目录恢复默认名称 | UTS 静态扫描、HBuilderX 5.15 Android class 编译通过 | `1603d00` |
| 14 | 长对话渲染性能 | 私聊/群聊固定大小双向滑动窗口；上下均批量加载和卸载；群流式事件合并刷新 | UTS 静态扫描、HBuilderX 5.15 Android class 编译通过；模拟器已关闭，滚动手感待回归 | `1603d00` |
| 15 | 群聊成员私发 | 用户显式请求时锁定 `user_private`；其他成员、调度与复盘只读公开投影；原成员保留自己的私发历史 | HBuilderX 5.15 Android class 全量编译通过；ADB 消息投递待回归 | `1603d00` |
| 16 | 统一错误链 | 结构化诊断、LLM transport error、失败气泡、设置事务与文件操作错误提示 | HBuilderX 5.15 Android class 全量及多轮热编译通过；ADB 冷启动日志通过 | `1603d00` |
| 17 | 页面错误与生命周期复审 | Agent、历史、文件、头像裁剪、资料、诊断、Provider、Skill 和导入流程补齐状态写入检查、统一提示与离页保护 | UTS 静态扫描、HBuilderX 5.15 `--cleanCache` 全量编译通过；ADB 主页面与诊断入口通过 | 待提交 |
| 18 | 群聊回滚、持久化与 ABI 复审 | 群聊创建失败回滚数据库和工作区；调度副作用写入失败可见；恢复既有导出函数 JVM 签名 | SQLite 注入回滚验证、28 页面 Android class 干净编译、ADB 群聊/会话/设置入口通过 | 待提交 |

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
| 2026-07-11 真机 | 软键盘第一次回归 | 页面顶部不再被推出屏幕；输入栏没有移动到键盘上方。随后加入 resize 差额补偿，HBuilderX Android 热编译成功，等待真机复验 |
| 2026-07-10 20:52 | 残留工作区名称与双向消息窗口编译 | HBuilderX 5.15 对 27 页面执行 Android class 差量编译成功 |
| 2026-07-10 20:53 | ADB 回归暂停 | 用户关闭模拟器；后续只执行离线静态检查与 compile-only，设备回归保留到下次 |
| 2026-07-11 03:06 | HBuilderX CLI 全量部署 | 当前工程 28 页面编译为 Android class 成功，同步并启动 `emulator-5554` |
| 2026-07-11 03:10 | 清空 logcat 后冷启动 | 无 `duplicate column`、UTS exception、Java fatal；仅保留模拟器 EGL 与框架性能日志 |
| 2026-07-11 03:12 | SQLite 只读测试数据核对 | 最大私聊历史为 380 条，群消息 50 条；可直接用于双向窗口和群聊回归，无需注入用户数据 |
| 2026-07-11 03:45 | ADB 进入群聊时发现 Android ABI 错配 | `setActiveGroupChat(String): void` 调用方与增量缓存中的 boolean 实现混用，触发 `NoSuchMethodError`；恢复公共签名并改用原子 runtime state 写入 |
| 2026-07-11 04:12 | HBuilderX CLI `--cleanCache true` 全量部署 | 28 页面重新编译为 Android class 成功，同步并启动 `emulator-5554` |
| 2026-07-11 04:13 | ADB 主要页面回归 | 群聊、群会话、群设置、私聊、待办、文件、设置和运行诊断均可进入；logcat 无 Java fatal、ABI 错误或未捕获 UTS 异常 |

## 手动真机回归

以下项目受当前模拟器软键盘窗口高度恒为 0 限制，需要后续在 Android 真机测试：

1. 私聊和群聊分别弹出键盘，确认自定义导航栏始终留在屏幕内，输入栏贴在键盘上方。
2. 键盘打开和关闭各执行三次，确认消息列表仍位于原来的阅读位置；原本在底部时继续保持到底。
3. 输入单行和三行文本，确认文字上下留白一致、输入栏高度随行数增长且不跳动。
4. 从聊天设置打开描述、提示词、对话规则全屏编辑，再测试文件编辑器和笔记编辑器；确认标题栏不被顶走，点击位置与光标位置一致。
5. 在全屏编辑器长按选择、拖动光标并收起键盘，确认正文和 footer 不重叠、不发生残留位移。
