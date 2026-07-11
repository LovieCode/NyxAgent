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
| 主导航 | `pages/agents/agents` | 筛选、私聊/群聊入口、新建 Agent、新建群聊、头像选择、首次引导 | 测试中 | ADB 已通过私聊/群聊筛选与会话入口、Agent 新建/删除；首次引导待测 |
| 主导航 | `pages/todo/todo` | 待办新增/完成/筛选/删除、笔记搜索/新增/编辑 | ADB 通过 | 已实测待办新增、单击完成、筛选、删除，以及笔记新增、编辑、保存、删除；测试数据已清理 |
| 主导航 | `pages/files/files` | 根目录、面包屑、搜索、排序、导入、新建文件/目录、打开、重命名、删除 | 测试中 | ADB 已通过根目录、名称回退、新建空名称校验、弹窗返回和遮罩行为；导入和实际写操作继续覆盖 |
| 主导航 | `pages/settings/settings` | 所有设置入口、资料摘要、状态展示 | 测试中 | ADB 已通过设置列表与运行诊断入口；各设置写操作继续回归 |
| 设置 | `pages/settings/diagnostics/diagnostics` | 错误记录、诊断编号、技术详情、清空、空状态 | 测试中 | ADB 已通过入口与空状态；错误注入、详情和清空待测 |
| 私聊 | `pages/chat/chat` | 文本发送、流式状态、停止/续跑、工具栏、图片/拍照/文件、滚动、重进恢复 | 测试中 | ADB 已通过文本发送、退出页面后台续流、重进恢复和防重复；图片 runtime、删除失效、长历史滚动与键盘继续回归 |
| 私聊 | `pages/agent-settings/agent-settings` | 名称/备注/头像/Prompt/规则/模型/语音/生成参数/Skills/工具/截断/删除 | 测试中 | ADB 已通过临时改名、全屏编辑往返保留未保存状态、不保存退出、Agent 删除；其余设置继续覆盖 |
| 群聊 | `pages/group-chat/group-chat` | 文本/媒体、调度、暂停、后台续流、成员消息、上下文/文件/记忆入口 | 测试中 | ADB 已通过历史渲染、拍照入口、普通/永久权限拒绝恢复；文本发送、后台流、相册/文件和键盘继续覆盖 |
| 群聊 | `pages/group-chat-settings/group-chat-settings` | 群名、成员、调度 Prompt、共享 Prompt、未保存退出 | 测试中 | ADB 已通过页面进入和成员列表；编辑、保存与退出保护待测 |
| 群聊 | `pages/group-chat-sessions/group-chat-sessions` | 会话新增、切换、重命名、删除 | 测试中 | ADB 已通过页面进入和当前会话展示；写操作待测 |
| 历史 | `pages/history/history` | 私聊/群上下文切换、预览、恢复、批量删除、清空 | 测试中 | ADB 已通过历史预览、切换到对话和管理模式选择；未对用户数据执行批量删除 |
| 编辑器 | `pages/note-editor/note-editor` | 新建/编辑/保存/返回保护 | ADB 通过 | 新建、保存、删除及 Android 物理返回放弃确认均通过 |
| 编辑器 | `pages/common/editor/editor` | 全屏编辑、保存、取消、空内容、长文本 | 测试中 | 跨页保留未保存内容已通过；补齐 Android 物理返回确认，文件读写和长文本继续覆盖 |
| 媒体 | `pages/common/crop/crop` | 图片加载、缩放/移动、裁剪、取消 | ADB 通过 | 系统 Picker -> 裁剪页、返回取消、完成裁剪均通过；无 `CROP_SOURCE_MISSING` |
| 上下文 | `pages/context-preview/context-preview` | 请求快照、标签顺序、空状态、长内容滚动 | 测试中 | ADB 已通过原始上下文展示、长内容滚动与复制入口 |
| 记忆 | `pages/memory/memory` | 分类/目标切换、新增/编辑/删除、搜索、记忆整理状态 | 测试中 | 短期缓存保存、清空确认和重进持久化已通过；重要信息 CRUD 继续覆盖 |
| 设置 | `pages/settings/profile/profile` | 用户名、简介、详细介绍、头像、保存与私聊注入 | 测试中 | 相册选择、裁剪、内部文件落盘和“不保存”临时文件回收已通过；相机永久拒绝后的设置恢复入口 ADB 通过，资料保存继续覆盖 |
| 设置 | `pages/settings/basic/basic` | 提供商列表、启停、默认配置入口 | 测试中 | ADB 已通过提供商管理入口、列表渲染与返回；启停、删除引用清理和失败回滚待隔离数据回归 |
| 设置 | `pages/settings/basic/provider-edit` | 新增/编辑提供商、URL/API Key/模型、校验、删除 | 测试中 | Android class 编译与常规编辑页 ADB 通过；首启不再预置过时模型，多模型必须显式选择默认项；全新安装流程待隔离数据回归 |
| 设置 | `pages/settings/model/model` | 旧模型设置兼容与跳转 | 静态确认 | 页面仍注册，但项目内没有跳转方，也没有代码写入 `pending_agent_model_id`；保留/重定向/下线需要兼容策略确认 |
| 设置 | `pages/settings/default-models/default-models` | chat/TTS/STT/vision/organize 默认模型与图片描述 Prompt | 测试中 | ADB 已通过 Chat/Memory/Vision 区域、页面返回；TTS dirty 保护已编译，五类任务选择和非法参数待写操作回归 |
| 设置 | `pages/settings/generation/generation` | 温度、Token、迭代、流式配置与边界值 | 测试中 | ADB 已通过上下界裁剪、流式开关、退出重进与 force-stop 持久化；发现数值逐字符保存会污染非法输入回退值，待下一轮修复 |
| 设置 | `pages/settings/plugin/plugin` | 插件配置、启停、输入校验、错误态 | 测试中 | ADB 已通过页面入口、搜索与 AstrBot 配置渲染；401/500/超时/断网及 diagnostics 待测 |
| 设置 | `pages/settings/skills/skills` | Skill 新增/编辑/删除、Agent 绑定、长文本编辑 | 测试中 | ADB 已通过页面入口、空状态和返回；损坏 JSON 全链路写保护已编译，CRUD/长文/绑定待隔离数据回归 |
| 设置 | `pages/settings/data/data` | 导出、导入、取消、无效文件、覆盖确认 | 测试中 | ADB 安全备份生成与 Android 分享选择器通过；导入增加字段/资源完整性拒绝，真实覆盖恢复仍待隔离数据回归 |
| 设置 | `pages/settings/about/about` | 版本信息、外链打开 | ADB 通过 | 版本 `1.5.0`、构建号 `150` 正常；开发者链接打开 `https://github.com/LovieCode` |
| 通用组件 | `rice-ui/action-sheet` | 展示、选择、取消、遮罩关闭 | ADB 通过 | 头像来源与文件新建操作表展示、选择、取消和点击遮罩关闭均通过；MP API 字段类型错误已静态修复 |
| 通用组件 | `rice-ui/dialog` | 确认、取消、输入校验、遮罩行为 | ADB 通过 | Todo/文件空输入确认后保持弹窗；物理返回只关弹窗；遮罩按 `closeOnClickOverlay=false` 不误关；权限提示确认/取消通过 |

## 跨功能检查

| 检查项 | 状态 | 证据 / 备注 |
| --- | --- | --- |
| 首次安装与冷启动 | 测试中 | 冷启动已通过；首次安装需要隔离用户数据的测试用户/模拟器快照，尚未执行 |
| 前后台切换与页面退出时流继续 | 测试中 | 私聊已实测发送后 50ms 退出、回复在退出后约 1 秒完成，重进后仅 `1 user + 1 assistant`；群聊真实流继续回归 |
| App 进程重启后的数据恢复 | ADB 通过 | force-stop 后 PID `14222 -> 15042`，重新触发 `App Launch/Show`；首页联系人和群聊可见项计数前后一致 |
| 软键盘与输入框可见性 | 测试中 | 真机确认页面顶部不再被推出屏幕，但输入栏未抬到键盘上方；已增加 resize 差额补偿并通过 Android 编译，待二次真机回归 |
| 长消息滚动与底部定位 | 测试中 | 私聊/群聊已改为固定 80 渲染单元、每次 40 单元的双向批量滑动窗口；Android class 编译通过，滚动锚点待下次 ADB/真机回归 |
| 相册、相机、文件权限 | 测试中 | 相册选择、文件选择和头像裁剪已通过；头像、私聊、群聊相机普通/永久拒绝均显示恢复弹窗并可打开设置；实体相机成像成功链路待真机 |
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
| DATA-001 | P1 | 私聊离页后后台流最终回复可能不持久化 | 已修复，ADB 通过 | 测试消息退出后才生成助手回复，SQLite 最终完整保存，重进可见且无重复 | `utils/chat-turn-runtime.uts`、`pages/chat/chat.uvue` |
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
| ERROR-002 | P1 | Provider、模型、资料、生成参数、插件、Skill 等保存失败仍更新 UI 或提示成功 | 部分修复，ADB 待回归 | DAO 与主要页面已补回滚/dirty 状态；Provider 拉取、AstrBot diagnostics 和跨引用事务仍有缺口 | 设置页面、`database-settings.uts`、`provider.uts` 等 |
| ERROR-003 | P2 | App 每次启动尝试重复 `ALTER TABLE`，logcat 持续输出 `duplicate column` | 已修复，ADB 通过 | 迁移前使用 `PRAGMA table_info` 检查字段；冷启动清空 logcat 后无重复字段错误 | `utils/database-core.uts`、`utils/database.uts` |
| RUNTIME-002 | P0 | 修改导出 UTS 函数返回值后，Android 增量缓存混用旧调用方与新实现，进入群聊触发 `NoSuchMethodError` | 已修复，ADB 通过 | 恢复既有公共函数 JVM 签名；需要结果的页面改用已有底层状态写入；`--cleanCache true` 重编 28 页面后群聊入口正常 | Agent/历史/文件/群聊页面与 runtime state helpers |
| DATA-008 | P1 | 默认群聊创建或调度持久化中途失败时可能残留数据库行、目录，部分失败只写日志 | 已修复，ADB 入口通过 | 创建失败事务清理 9 张关联表并回收工作区；复盘、任务、记忆、指标、上下文和快照写入失败进入统一诊断 | `utils/database-group-chat.uts`、`utils/group-chat-service.uts`、`utils/group-chat-scheduler.uts` 等 |
| DATA-009 | P0 | 同 Schema 的不完整备份缺少数组/资源条目时仍可预览并把现有数据覆盖为空，ZIP 漏文件也会假成功 | 已修复，编译通过 | 导入前强制校验全部消费字段和资源映射；ZIP 任一清单条目写失败即删除失败包；0 Agent 备份也包含空工作区根目录 | `utils/data-import.uts`、`utils/data-export.uts`、`utssdk/app-data-export/index.uts` |
| DATA-010 | P1 | 全量/设置导入跨 SQLite、storage、Agent/Skill 文件和工作区，后半段失败无法统一回滚 | 待重构 | 当前已阻止不完整包和资源缺失进入写阶段，但跨介质提交仍不是单一原子事务 | 后续需要 staged import + 快照回滚协议 |
| DATA-011 | P1 | Todo/Note/文件编辑使用覆盖写，进程中断或磁盘异常可能留下空文件或半文件 | 待重构 | 页面已检查写入结果并显示失败，但底层 `File.writeText` 不具备崩溃原子性 | 后续需要同目录临时文件、落盘同步和原子替换 |
| DATA-012 | P1 | 安全备份仅恢复设置时会把现有 AstrBot API Key 用空值覆盖 | 已修复，编译通过 | 空的 `settings_api_key` 与 `settings_astrbot_api_key` 均保留本机旧值 | `utils/database-settings.uts` |
| MEDIA-001 | P1 | 系统相册返回会先触发来源页 `onShow`，空裁剪结果被误消费，裁剪页随后报 `CROP_SOURCE_MISSING` | 已修复，ADB 通过 | 空结果保留请求；裁剪取消显式清理；完成结果持久化到内部 avatars，放弃保存会回收临时文件 | `utils/avatar-image-picker.uts`、裁剪/资料/Agent 页面 |
| UI-003 | P1 | 笔记和通用全屏编辑器的 Android 物理返回绕过放弃确认 | 已修复，ADB 通过 | `onBackPress` 统一进入确认逻辑，放弃前清 dirty 防止重复确认循环 | `pages/note-editor/note-editor.uvue`、`pages/common/editor/editor.uvue` |
| PERF-002 | P1 | 长消息滚到底部先写 `scrollTop=0`，误触双向滑窗向旧消息换窗，造成底部位置错误 | 已修复，长历史待回归 | 程序化滚底期间锁定窗口换页，避免 0 脉冲参与边缘检测 | 私聊/群聊页面 |
| RUNTIME-003 | P1 | 兼容旧页面保留的 void 包装器因无可达调用被 DCE 删除，热更新仍可能 `NoSuchMethodError` | 已修复，字节码验证通过 | 新 boolean 入口真实调用旧 void ABI；`javap` 确认两个 JVM 签名同时存在 | `utils/agent-settings-page-helpers.uts` |
| SECURITY-001 | P0 | 导入备份可携带伪造的群会话 `workspace_path`，后续复制/删除可能越出群聊工作区；系统文件选择器返回的文件名也可包含路径片段 | 已修复，ADB 入口通过 | 导入时只按受限 group/session ID 重建应用私有路径；Android 使用 canonical path 校验目录包含关系；递归复制拒绝 symlink，递归删除只移除链接本身；文件导入只接受 basename | `utils/data-import.uts`、`utils/file-manager-io.uts`、`utils/group-chat-service.uts`、`pages/files/files.uvue` |
| MEDIA-002 | P1 | 私聊生成过程中仍可追加图片/文件/位置，新增消息不会进入当前请求；群聊图片转述异步完成后可能写入已切换的会话，停止讨论也未失效 caption | 已修复，ADB 入口通过 | 媒体入口统一阻止并发追加；位置失败进入诊断；群聊 caption 绑定 group/session/message ID，切换与停止时失效；文件保存失败回滚消息 | `pages/chat/chat.uvue`、`pages/group-chat/group-chat.uvue` |
| RUNTIME-004 | P0 | 私聊流由页面实例持有，退出重进可启动第二条流并互相覆盖 | 已修复，ADB 通过 | 按 Agent + conversation 唯一注册 `ChatTurnRuntime`；页面只订阅；图片 caption、批量 reducer、停止、保存和错误均由 runtime 持有；删除/导入会失效旧 runtime；退出重进后 SQLite 为 `1 user + 1 assistant` | `utils/chat-turn-runtime.uts`、`pages/chat/chat.uvue`、历史/Agent 删除与数据导入链路 |
| SECURITY-002 | P2 | 非 Android 平台的目录包含检查仍是词法前缀判断，无法识别工作区内部 symlink | 待跨端验证 | Android 已封堵 canonical path 和递归 symlink；iOS/WEB 缺少当前可验证的 lstat/realpath 实现，涉及复制/删除前仍需平台实现后再开放同等级保证 | `utils/file-manager-io.uts` |
| SET-001 | P1 | 编辑已停用 Provider 后自动保存会固定写成启用 | 已修复，写操作待回归 | 编辑时保留原 `enabled == 1` 状态，新建项才默认启用；异常非 1 值不会被提升为启用 | `pages/settings/basic/provider-edit.uvue` |
| SET-002 | P1 | 模型级 `maxTokens`、`params`、`supportsToolCall` 可保存但聊天运行请求不读取 | 待重构 | 需要统一解析模型运行配置并定义旧数据兼容语义，不能只在页面层补字段 | 待用户确认运行时配置重构 |
| SET-003 | P1 | `skills_list` JSON 损坏后被当成空列表，后续保存 Agent 或导出备份会覆盖/固化为空 | 已修复，故障注入待回归 | 解析失败进入 diagnostics；Skill 公共保存、Agent 设置和数据导出统一停止；绑定 ID 保留，页面显示保护状态 | `utils/skills.uts`、`utils/agent-settings-save-service.uts`、`utils/data-export.uts`、Skill/Agent 设置页 |
| SET-004 | P1 | 停用/删除 Provider 或模型时，默认任务、联网搜索及 Agent 引用可能悬空 | 待重构 | 需要统一引用统计、阻止或事务清理策略，并纳入 Agent 引用 | 待用户确认 Provider 引用重构 |
| SET-005 | P1 | 获取模型列表无明确超时和结构化错误，HTTP/解析/空列表/断网统一折叠为失败 | 已修复，异常注入待回归 | 15 秒超时；区分鉴权、404、服务端、网络、非法响应和合法空列表；错误写入 diagnostics | `provider.uts`、`provider-edit.uvue` |
| SET-006 | P1 | 首次引导分步保存 Provider、active、默认模型和完成标记，失败会留下半配置 | 待重构 | 需要 DAO 事务或完整补偿回滚协议 | 待用户确认首次引导事务重构 |
| SET-007 | P1 | vision/reasoning 能力只按 model ID 全局匹配，同名模型可能串 Provider | 待重构 | 能力查询和调用链需要同时携带 `providerId + modelId` | 待用户确认模型能力解析重构 |
| SET-008 | P2 | AstrBot 测试失败只显示 toast，不进入统一 diagnostics | 已修复，异常注入待回归 | 连接失败统一记录 `ASTRBOT_CONNECTION_TEST_FAILED` 并显示诊断编号 | `pages/settings/plugin/plugin.uvue` |
| SET-009 | P2 | 相机权限永久拒绝后没有跳转系统授权设置的恢复入口 | 已修复，ADB 通过 | 头像和私聊在 `cameraAuthorized == denied` 时显示恢复弹窗；确认进入应用授权设置，取消留在原页面；群聊复用同一处理器 | `utils/media-permission.uts`、头像/私聊/群聊媒体入口，`81976fa` |
| SET-010 | P2 | 默认模型页 TTS 参数修改后直接返回会静默丢失 | 已修复，交互待回归 | TTS 全字段加入快照、统一未保存确认、保存成功刷新快照、不保存恢复快照 | `pages/settings/default-models/default-models.uvue` |
| SET-011 | P2 | Provider 模型已拉取成功后仍同步等待 models.dev 元数据刷新，异常网络可额外阻塞约 30 秒 | 已修复 | 能力元数据改为单例后台刷新，模型列表成功后立即可用 | `provider-edit.uvue`、`llm-metadata.uts` |
| UI-004 | P1 | Rice 输入组件把 `30rpx` 截成 `30r` 交给 Android 原生字号解析，新建文件对话框触发 `NumberFormatException` | 已修复，ADB 通过 | placeholder 字号统一经 `getPxNum` 转为真实 px；新建文件对话框打开、取消且日志无同类异常 | `rice-input.uvue`、`rice-textarea.uvue`、`rice-search.uvue` |
| SECURITY-003 | P1 | Provider 编辑页默认以明文输入展示 API Key，Android UI hierarchy 可读取完整内容 | 已修复，交互待回归 | API Key 默认使用密码态，提供显式可见性切换 | `pages/settings/basic/provider-edit.uvue` |
| SET-012 | P0 | 首次启动和内置 Agent 硬编码 `deepseek-v4-flash`，选择其他 Provider 时仍可能调用 DeepSeek 模型；首启多模型又静默保存列表第一项 | 已修复，首装待回归 | Provider 初始模型列表为空；内置 Agent 默认跟随任务模型；只迁移仍使用旧裸 ID 的内置 Agent；首启从真实拉取结果中显式选择默认模型 | Provider/Agent/首启相关页面与 helpers |
| SET-013 | P1 | 通用 `/models` 拉取只适合 OpenAI-compatible Provider，Anthropic 等协议无法通过同一端点可靠发现模型 | 待重构 | 对照 AstrBot 后确认模型可用性应由 Provider adapter 获取；models.dev 只用于能力元数据，不能替代账号实际模型列表 | 后续需要 Provider Source / Model adapter 层，属于架构调整 |
| UI-005 | P2 | Agent 设置页把 CSS 变量交给 Android 原生 placeholder 颜色解析器，持续输出 `Color_Parser` 越界异常 | 已修复，ADB 通过 | placeholder 改用等价静态色；最新包进入聊天设置并渲染输入框后日志无 `Color_Parser` | `pages/agent-settings/agent-settings.uvue` |
| UI-006 | P1 | Rice Dialog 点击确认后无条件关闭，业务空值校验或写入失败无法保留输入重试 | 已修复，ADB 通过 | 新增兼容默认开启的 `closeOnClickConfirm`；Todo/文件弹窗由成功分支关窗；空标题/名称确认、物理返回和遮罩行为均通过 | Rice Dialog、Todo、Files，`815ecf6` |
| SET-014 | P1 | Agent 旧裸 `modelId` 在标签、选择面板和运行时分别猜测不同 Provider | 已修复，Android 编译通过 | 标签和面板统一按运行时默认 Chat Provider 解释；不迁移用户数据，未配置模型明确标注 | `utils/agent-settings-models.uts`，`815ecf6` |
| UI-007 | P1 | Rice Dialog/ActionSheet 小程序 API 分支引用错误字段、未声明变量及错误的 fail 参数类型 | 已修复，待 MP 编译 | `cancelText` 改为 `cancelButtonText`，失败信息统一传字符串 `err.errMsg` | Rice Dialog/ActionSheet API，`815ecf6` |
| SET-015 | P2 | 生成参数保存失败后页面继续展示未持久化值，重进时才突然回退 | 已修复，故障注入待回归 | 两条保存路径失败时立即重新读取最后成功配置 | `pages/settings/generation/generation.uvue`，`815ecf6` |
| SET-016 | P2 | 旧模型设置页仍注册并参与备份白名单，但已无入口和运行态写入方 | 待兼容决策 | 直接删除可能影响外部深链或旧备份语义；可选重定向到默认模型页或正式下线 | 待用户确认兼容清理策略 |
| SET-017 | P2 | 生成参数数值框在 `@input` 每字符保存，清空旧值时会把中间态裁剪后写库并污染非法输入回退 | 待修复 | ADB 复现 `65536 -> 清空 -> abc` 回退为 `256`、`100 -> abc` 回退为 `1`；应改为 blur/confirm 提交 | `pages/settings/generation/generation.uvue` |

## 修改记录

| 日期 | 文件 | 修改 | 验证 | commit |
| --- | --- | --- | --- | --- |
| 2026-07-11 | 私聊 runtime、聊天页、会话恢复、历史/Agent 删除与数据导入 | 私聊流脱离页面生命周期；图片 caption/停止/保存统一进入 runtime；删除或覆盖恢复后旧页面不可复活数据；进程遗留流式消息转为明确中断态 | HBuilderX 5.15 clean 与差量编译 28 页面成功；ADB 退出续流、重进防重复、SQLite 终态和日志回归通过 | 本轮提交 |
| 2026-07-11 | 私聊/群聊媒体错误、Rice Dialog/ActionSheet、Todo、Files、Agent 模型标签、生成设置 | 补文件/相册/图片失败诊断；修复 Dialog 校验保留、物理返回和外部关闭；统一旧裸模型 Provider 语义；生成保存失败立即回滚；修正 MP API 字段 | HBuilderX 5.15 对 28 页面连续编译并同步成功；ADB 群聊相机权限、Todo/文件空输入、返回/遮罩、冷启动和前后台切换通过 | `82d7223`、`815ecf6` |
| 2026-07-11 | 相机权限公共处理器、头像、私聊与群聊媒体入口 | 永久拒绝相机权限时显示恢复弹窗，支持直接进入系统授权设置；普通相机故障继续保留结构化错误与 toast | HBuilderX 5.15 对 28 页面编译成功；ADB 覆盖头像确认打开设置、头像取消、私聊“不再询问”拒绝和取消；测试后权限与系统自动旋转状态已恢复 | `81976fa` |
| 2026-07-11 | Provider、默认模型、Skill、Agent 设置与数据导出 | 保留停用 Provider 状态；补 TTS 离页保护；Skill 损坏时阻止全链路写入和空备份 | HBuilderX 5.15 对 28 页面差量编译成功；ADB Provider/默认模型/Skills 入口与返回通过；app 定向日志无 fatal/UTS 异常 | `bcfb782` |
| 2026-07-11 | Provider 拉取、插件诊断、Rice 输入组件 | 区分模型接口错误和合法空列表；models.dev 元数据后台刷新；AstrBot 失败进入诊断；修复 Android placeholder 字号崩溃；API Key 默认掩码 | HBuilderX 5.15 差量编译与同步成功；ADB 新建文件对话框回归无 `NumberFormatException`；Provider 编辑识别为 Android 密码字段 | `dc35b2d` |
| 2026-07-11 | 首启模型、Provider 初始数据、Agent 模型继承与联网搜索 | 移除易过时的具体模型默认值；首启基于 Provider 实际返回显式选择默认模型；旧内置 Agent 定向迁移为继承；阻止裸模型跨 Provider 绑定；搜索模型不再猜测硬编码 ID | HBuilderX 5.15 连续多轮 Android class 编译成功并同步模拟器；SQLite 只读检查确认用户显式配置未被覆盖；Agent 设置和日志回归通过 | `d20fc32` |
| 2026-07-11 | 聊天、群聊、文件导入、数据恢复与 Provider 日志相关源码 | 阻止媒体并发丢消息；隔离图片转述异步任务；校验导入工作区与文件名；旧备份缺少工作区目录时保留本地；阻止递归 symlink 越界；API Key 日志仅记录是否存在 | HBuilderX 5.15 Android class 两轮编译通过；ADB 冷启动、私聊、群聊、文件和设置入口通过；logcat 无 fatal/UTS 未捕获异常 | `1c3dbed`、`8cdec95` |
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
| 17 | 页面错误与生命周期复审 | Agent、历史、文件、头像裁剪、资料、诊断、Provider、Skill 和导入流程补齐状态写入检查、统一提示与离页保护 | UTS 静态扫描、HBuilderX 5.15 `--cleanCache` 全量编译通过；ADB 主页面与诊断入口通过 | `997e7b1` |
| 18 | 群聊回滚、持久化与 ABI 复审 | 群聊创建失败回滚数据库和工作区；调度副作用写入失败可见；恢复既有导出函数 JVM 签名 | SQLite 注入回滚验证、28 页面 Android class 干净编译、ADB 群聊/会话/设置入口通过 | `997e7b1` |
| 19 | 设置、Provider 与导入复审 | Provider 删除引用清理、默认模型原子保存、禁用 Provider 过滤、不完整备份和资源缺失拒绝 | HBuilderX Android 差量编译、UTS 扫描、ADB 设置页与安全导出通过 | `5923efc` |
| 20 | 历史、记忆、Todo 与编辑器复审 | 修复 Todo 双切换、定向文件更新、短期记忆清空、历史恢复、物理返回确认 | HBuilderX Android 差量编译；ADB Todo/Note CRUD、Memory 清空、历史恢复和物理返回通过 | `5923efc` |
| 21 | 头像与 Agent 生命周期复审 | 相册返回竞态、内部头像持久化、取消/不保存回收、Agent 创建删除与未保存状态保护 | 28 页面 Android class 干净编译；ADB 相册、裁剪、取消、完成和临时文件回收通过 | `5923efc` |
| 22 | 独立代码审查追加轮 | 检查 JVM ABI/DCE、跨介质数据一致性、页面生命周期、长消息滑窗和键盘延迟回调 | 三个独立审查代理 + `javap` + `git diff --check` + ADB | `5923efc` |
| 23 | 导入边界、媒体并发与聊天生命周期复审 | 修复工作区路径穿越、恶意文件名、递归 symlink、媒体并发和群聊 caption 串会话；保持旧 schema 备份的缺目录兼容；记录私聊 runtime P0 重构项 | UTS 静态扫描、28 页面 Android class 编译、ADB 冷启动及私聊/群聊/文件/设置入口 | `1c3dbed`、`8cdec95` |
| 24 | 设置状态与损坏数据复审 | 修复停用 Provider 被重新启用、TTS 未保存丢失；Skill 损坏保护扩展到 Agent 保存和数据导出；记录模型运行配置和引用事务重构项 | 三个并行审查/ADB 代理、`git diff --check`、28 页面 Android class 差量编译、设置入口 ADB 回归 | `bcfb782` |
| 25 | 首启模型与 AstrBot 对照审查 | 清理 Provider/内置 Agent/联网搜索的过时模型默认值；首启改为真实发现并显式选择；models.dev 仅保留能力元数据职责；记录非 OpenAI-compatible adapter 缺口 | 三个并行代码/ADB 审查、AstrBot Provider 架构对照、UTS 静态扫描、多轮 28 页面 Android class 编译和设置页日志回归 | `d20fc32` |
| 26 | 私聊后台回合架构 | 新建唯一 `ChatTurnRuntime`，承接文本/图片流、批量 reducer、保存、停止、错误和生命周期；删除与导入覆盖后失效旧页面；无引用终态主动清理 registry | 三个并行审查/ADB 代理、`git diff --check`、HBuilderX 28 页面 clean/差量编译、ADB 退出续流与 SQLite 防重复验证 | 本轮提交 |

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
| 2026-07-11 04:25 | ADB Todo / Note CRUD | 新增、完成、筛选、删除待办；新增、编辑、保存、删除笔记均通过，测试数据已清理 |
| 2026-07-11 04:35 | ADB 历史、记忆与上下文 | 历史预览并恢复对话通过；短期缓存清空问题复现后修复，重进仍为 0/64；原始上下文展示和复制入口通过 |
| 2026-07-11 04:55 | ADB Agent 生命周期 | 临时改名进入全屏编辑后仍保留，选择不保存恢复原名；新建并删除测试 Agent，未残留测试数据 |
| 2026-07-11 05:07 | ADB 头像相册竞态复现 | 系统 Picker 返回后来源页误清请求，裁剪页报 `CROP_SOURCE_MISSING` |
| 2026-07-11 05:08 | ADB 头像修复回归 | 系统 Picker 正常进入裁剪；取消无错误；完成生成内部 `files/avatars/profile-*.png`，资料页不保存后文件被回收 |
| 2026-07-11 05:15 | 三轮独立代码审查 | 发现旧 ABI 被 DCE、备份字段/资源假成功、物理返回绕过确认、滚底触发旧窗口、键盘延迟离页执行等问题并修复 |
| 2026-07-11 05:20 | ADB Android 物理返回 | 未保存笔记按系统返回弹出放弃确认；修复 dirty 清理后选择放弃可正常返回且不产生笔记 |
| 2026-07-11 05:26 | 最终 HBuilderX CLI `--cleanCache true` 部署 | 28 页面 Android class 全量编译成功并同步模拟器；物理返回复测无 `StackOverflowError`、Java fatal、ABI 或 UTS 未捕获异常 |
| 2026-07-11 15:38 | 重启后工具链复核 | HBuilderX CLI `5.15.2026070915` 可用；`emulator-5554` 在线；Git Bash、ADB 与项目工作树访问正常 |
| 2026-07-11 15:40 | 本轮首次 clean compile | 捕获 `charCodeAt()` nullable UTS 编译错误并补显式空值收窄；第二次 clean compile 遇到 HBuilderX GUI 占用 `uts-openSchema/index.jar` 的 `EBUSY`，未改缓存文件 |
| 2026-07-11 15:43 | 普通 Android compile-only 回归 | 当前 28 页面编译为 Android class 成功，无后续 UTS/Kotlin 错误 |
| 2026-07-11 15:45 | CLI 部署与 ADB 冷启动 | 当前包同步成功；冷启动进入 Agent 首页，截图和 UI hierarchy 均非空；logcat 无 `FATAL EXCEPTION`、`NoSuchMethodError` 或未捕获 UTS 异常 |
| 2026-07-11 15:48 | ADB 关键入口冒烟 | 私聊显示历史与输入栏；群聊显示当前会话、消息和输入栏；文件根目录与设置首页正常渲染，页面切换无 fatal |
| 2026-07-11 16:00 | 导入/路径安全追加审查 | 发现 schema 1 旧包缺少工作区目录时的兼容回归，以及递归复制/删除跟随内部 symlink；恢复跳过语义并封堵 Android 递归越界 |
| 2026-07-11 16:02 | 安全修正 compile-only | 当前 28 页面再次编译为 Android class 成功，新增 `File` canonical/symlink 检查通过 UTS/Kotlin 编译 |
| 2026-07-11 16:32 | 设置改动首次 compile-only | HBuilderX 5.15 编译成功；缓存有效，无新增 UTS/Kotlin 错误 |
| 2026-07-11 16:37 | 设置页单线程 ADB 回归 | Provider 管理、默认模型与 Skills 页面均可进入和返回；App PID 稳定，定向 logcat 无 fatal、UTS、TypeError 或空指针异常 |
| 2026-07-11 16:39 | Skill 全链路保护差量编译 | 当前 28 页面 Android class 差量编译成功，Agent 设置、导出失败保护和页面状态通过 UTS/Kotlin 编译 |
| 2026-07-11 16:42 | 最新设置包部署 | 28 页面差量编译后同步 `emulator-5554` 并启动成功 |
| 2026-07-11 16:45 | 最新包冷启动与 Agent 设置回归 | 冷启动、私聊、聊天设置页正常渲染；App PID 定向日志 323 行中无 fatal、ABI、空指针、类型或 UTS 异常 |
| 2026-07-11 16:57 | Provider/Rice 组件差量编译 | 当前 28 页面 Android class 编译成功并同步模拟器；无新增 UTS/Kotlin 错误 |
| 2026-07-11 16:59 | ADB 新建文件对话框回归 | 操作菜单、文件名输入弹窗和取消流程正常；定向日志不再出现 `NumberFormatException` |
| 2026-07-11 17:24 | ADB Provider 密钥掩码回归 | DeepSeek 编辑页 4 个输入控件中恰好 1 个为 Android password 字段；App PID 稳定，定向日志无 fatal、ABI、类型或 UTS 异常 |
| 2026-07-11 17:56 | 首启默认模型清理首次编译 | 修复一处 SFC 闭合括号后，28 页面 Android class 完整编译成功；未出现 UTS/Kotlin 错误 |
| 2026-07-11 17:58 | placeholder 修复增量编译与部署 | 最新 28 页面连续两轮编译成功，同步并启动 `emulator-5554` |
| 2026-07-11 18:02 | ADB Agent 设置日志回归 | 首页、私聊和聊天设置正常；输入框实际渲染后无 `Color_Parser`、Java fatal 或未捕获 UTS 异常；未修改用户数据 |
| 2026-07-11 18:10 | 最终单进程 CLI 部署 | watcher 退出后重新独立编译、同步并启动首页；PID `10487`，UI hierarchy 非空，App 定向日志无 fatal、ABI、类型、UTS 或产物加载错误 |
| 2026-07-11 18:27 | ADB 头像相机永久拒绝回归 | 拒绝权限后显示“需要相机权限”；确认打开 Android 应用授权设置；普通模拟器相机故障走结构化错误且不崩溃 |
| 2026-07-11 18:31 | ADB About 与操作表回归 | About 正常显示版本 `1.5.0`、构建号 `150`；开发者链接打开 GitHub；头像来源操作表展示和取消正常 |
| 2026-07-11 18:34 | ADB 私聊相机永久拒绝回归 | 选择“不再询问”并拒绝后显示统一恢复弹窗；取消后保留当前私聊；日志记录 `MEDIA_CAMERA_PERMISSION_DENIED` |
| 2026-07-11 18:41 | 相机权限修复最终 compile-only | HBuilderX 5.15 对 28 页面重新编译为 Android class 成功；未出现新增 UTS/Kotlin 错误；权限 `USER_FIXED` 测试标记已通过系统设置清除 |
| 2026-07-11 18:47 | ADB 群聊相机正常授权回归 | 群聊拍照入口响应；模拟器硬件返回 `camera error`，应用记录 `MEDIA_CAMERA_PICK_FAILED` 且不崩溃 |
| 2026-07-11 18:50 | ADB 群聊相机永久拒绝回归 | 普通拒绝和“不再询问”均显示恢复弹窗；打开设置后重新授权，最终 CAMERA granted、flags 清空、自动旋转恢复 |
| 2026-07-11 18:59 | Dialog 与设置修复 compile-only | 28 页面 Android class 编译成功；Rice 新属性、Agent 默认 Provider 解析、生成参数失败回滚通过 UTS/Kotlin 编译 |
| 2026-07-11 19:03 | ADB Todo / Files Dialog 回归 | 空标题/空文件名点击确认仍保留弹窗；物理返回关闭弹窗且页面不退出；操作表遮罩关闭、Dialog 遮罩阻止关闭符合配置 |
| 2026-07-11 19:06 | ADB 生命周期与进程重启 | Home 键触发 `App Hide`，恢复触发 `App Show`；force-stop 后新 PID 冷启动，首页联系人/群聊可见项计数一致，无 fatal/UTS 异常 |
| 2026-07-11 20:12 | 私聊 runtime clean compile | HBuilderX 5.15 对 28 页面完成 Android class 干净编译，`ready in 130716ms`；追加清理/checkpoint 后差量编译再次成功 |
| 2026-07-11 20:23 | ADB 私聊退出续流回归 | 发送 `RUNTIME_EXIT_2021` 后约 50ms 退出；助手消息时间戳晚于用户约 1.1 秒，证明离页后继续；重进后 SQLite 严格 `1 user + 1 assistant`，无重复流、fatal、ABI 或 UTS 异常；设备恢复首页 |

## 手动真机回归

以下项目受当前模拟器软键盘窗口高度恒为 0 限制，需要后续在 Android 真机测试：

1. 私聊和群聊分别弹出键盘，确认自定义导航栏始终留在屏幕内，输入栏贴在键盘上方。
2. 键盘打开和关闭各执行三次，确认消息列表仍位于原来的阅读位置；原本在底部时继续保持到底。
3. 输入单行和三行文本，确认文字上下留白一致、输入栏高度随行数增长且不跳动。
4. 从聊天设置打开描述、提示词、对话规则全屏编辑，再测试文件编辑器和笔记编辑器；确认标题栏不被顶走，点击位置与光标位置一致。
5. 在全屏编辑器长按选择、拖动光标并收起键盘，确认正文和 footer 不重叠、不发生残留位移。
