# laoqianjunzi-sqlite

`laoqianjunzi-sqlite` 是一个面向 `uni-app x` 的 SQLite 统一数据库插件，提供 Android、iOS、Harmony、Web 四端一致的数据库访问入口。插件直接暴露 `LqjSqlDepot` 类，适合需要手写 SQL、精确控制事务、批量执行和本地快照管理的业务场景。

## 插件定位

- 面向 `uni-app x` 项目
- 统一封装 SQLite 的打开、建表、增删改查、事务、批处理、快照备份与恢复
- 保留 SQL 直写能力，不引入 ORM 抽象
- 优先保证 API 直接、清晰、可控

## 适用场景

- 离线表单、离线采集、草稿箱
- 本地缓存、轻量配置中心、日志落盘
- 需要跨 Android、iOS、Harmony、Web 共用一套数据库调用代码的业务
- 需要对 SQL 语句、事务边界、备份恢复过程进行显式控制的项目

## 平台支持

| 平台 | 状态 | 说明 |
| --- | --- | --- |
| App Android | 支持 | 原生 SQLite，支持本地目录、快照路径导出 |
| App iOS | 支持 | 原生 SQLite，支持本地目录、快照路径导出 |
| App Harmony | 支持 | 支持核心数据库能力，快照走系统存储，不导出独立文件路径 |
| Web | 支持 | 基于 `sql.js`，依赖插件内置 `sql-wasm.js` 与 `sql-wasm.wasm` |
| 微信小程序 | 暂未启用 | 当前仅保留占位实现，`prepare()` 会返回 `false`，数据库操作会返回不支持错误 |

## 环境要求

- `HBuilderX` `>= 5.07`
- `uni-app x` `>= 4.75`

## 导入方式

插件位于 `uni_modules` 后，可直接从模块根路径导入：

```uts
import { LqjSqlDepot } from '@/uni_modules/laoqianjunzi-sqlite'
```

如果需要类型提示，也可以一起导入类型：

```uts
import {
  LqjSqlDepot,
  type LqjSqlBatchStatement,
  type LqjSqlDepotOptions,
  type LqjSqlOutcome,
  type LqjSqlSnapshot
} from '@/uni_modules/laoqianjunzi-sqlite'
```

## 快速开始

### 1. 创建实例

```uts
const depot = new LqjSqlDepot({
  homeDirectory : 'laoqianjunzi/demo'
})
```

### 2. 打开数据库

统一推荐使用异步 `prepare()`，这样可以在所有已支持平台保持一致的调用方式：

```uts
async function openDb() : Promise<void> {
  const ready = await depot.prepare('contacts')
  if (!ready) {
    console.error('数据库初始化失败')
  }
}
```

### 3. 建表

`ensureTable()` 的 `schema` 参数是一个 `UTSJSONObject`，值为原始 SQLite 字段定义：

```uts
const schema = {
  id : 'INTEGER PRIMARY KEY AUTOINCREMENT',
  name : 'TEXT NOT NULL',
  city : 'TEXT',
  created_at : 'INTEGER'
} as UTSJSONObject

const createResult = depot.ensureTable('contacts', schema)
if (createResult.errorText != null) {
  console.error(createResult.errorText)
}
```

### 4. 写入与查询

```uts
const insertResult = depot.storeRow('contacts', {
  name : '苏青',
  city : '苏州',
  created_at : Date.now()
} as UTSJSONObject)

if (insertResult.errorText != null) {
  console.error(insertResult.errorText)
}

const queryResult = depot.select(
  'SELECT id, name, city FROM contacts WHERE city = ? ORDER BY id DESC',
  ['苏州']
)

if (queryResult.errorText == null) {
  console.log(queryResult.fields)
  console.log(queryResult.grid)
  console.log(queryResult.records)
}
```

### 5. 页面销毁时关闭连接

```uts
onUnmounted(() => {
  depot.disconnect()
})
```

## 完整示例

下面这段示例覆盖初始化、建表、插入、查询和释放连接，适合作为接入起点：

```uts
<script setup lang="uts">
import { LqjSqlDepot } from '@/uni_modules/laoqianjunzi-sqlite'

const depot = new LqjSqlDepot({
  homeDirectory : 'laoqianjunzi/demo'
})

async function bootstrap() : Promise<void> {
  const ready = await depot.prepare('contacts')
  if (!ready) {
    console.error('数据库初始化失败')
    return
  }

  const schema = {
    id : 'INTEGER PRIMARY KEY AUTOINCREMENT',
    name : 'TEXT NOT NULL',
    city : 'TEXT',
    created_at : 'INTEGER'
  } as UTSJSONObject

  let outcome = depot.ensureTable('contacts', schema)
  if (outcome.errorText != null) {
    console.error(outcome.errorText)
    return
  }

  outcome = depot.storeRow('contacts', {
    name : '访客-1',
    city : '杭州',
    created_at : Date.now()
  } as UTSJSONObject)
  if (outcome.errorText != null) {
    console.error(outcome.errorText)
    return
  }

  const rows = depot.select(
    'SELECT id, name, city, created_at FROM contacts ORDER BY id DESC'
  )
  if (rows.errorText != null) {
    console.error(rows.errorText)
    return
  }

  console.log(rows.grid)
  console.log(rows.records)
}

onMounted(() => {
  bootstrap()
})

onUnmounted(() => {
  depot.disconnect()
})
</script>
```

## 核心对象

### `LqjSqlDepotOptions`

| 字段 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `secretPhrase` | `string \| null` | `null` | 数据库密钥 |
| `enableCipher` | `boolean \| null` | `null` | 是否启用密钥逻辑，传入密钥后通常可省略此项 |
| `wasmResolver` | `(filename : string) => string` | `null` | 仅 Web 有意义，用于自定义 `sql-wasm.wasm` 地址 |
| `homeDirectory` | `string \| null` | `null` | 数据库存储目录，主要用于 Android 与 iOS |

### `LqjSqlOutcome`

所有数据库操作都返回 `LqjSqlOutcome` 或其数组，可按以下字段读取结果：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `grid` | `any[][] \| null` | 二维数组形式的查询结果 |
| `fields` | `string[] \| null` | 查询列名 |
| `affectedRows` | `number \| null` | 受影响行数 |
| `lastInsertId` | `number \| null` | 最近一次插入的自增主键 |
| `errorText` | `string \| null` | 错误描述，`null` 表示成功 |
| `records` | `Map<string, any>[] \| null` | 按列名映射后的结果集 |

推荐统一按下面的方式判断成功与失败：

```uts
const outcome = depot.execute('DELETE FROM contacts WHERE id = ?', [12])
if (outcome.errorText != null) {
  console.error(outcome.errorText)
  return
}
console.log(outcome.affectedRows)
```

### `LqjSqlSnapshot`

`peekSnapshot()` 用于查看当前快照信息：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `kind` | `'path' \| 'bytes' \| 'none'` | 快照载体类型 |
| `filePath` | `string \| null` | 路径型快照的文件路径，或 Web 中的别名标识 |
| `bytes` | `Uint8Array \| null` | 二进制快照内容，主要出现在 Web |

## API 说明

### 初始化与连接

| 方法 | 返回值 | 说明 |
| --- | --- | --- |
| `new LqjSqlDepot(options?)` | `LqjSqlDepot` | 创建数据库实例 |
| `prepare(alias?)` | `Promise<boolean>` | 打开或创建数据库，所有平台可用 |
| `disconnect()` | `void` | 关闭当前连接 |
| `switchHome(directory)` | `void` | 切换存储目录 |
| `changeSecret(secretPhrase?)` | `void` | 切换密钥配置 |

说明：

- `alias` 是数据库别名，建议保持简洁稳定，例如 `contacts`、`offline-cache`
- 在调用 `execute()`、`select()` 之前，必须先执行 `prepare()`
- 若业务会重复进入页面，建议在 `onUnmounted()` 中显式调用 `disconnect()`

### SQL 执行与数据读写

| 方法 | 返回值 | 说明 |
| --- | --- | --- |
| `execute(statement, args?)` | `LqjSqlOutcome` | 执行非查询 SQL |
| `select(statement, args?)` | `LqjSqlOutcome` | 执行查询 SQL |
| `storeRow(tableName, payload)` | `LqjSqlOutcome` | 按对象插入一行 |
| `reviseRow(tableName, payload, filterClause, args?)` | `LqjSqlOutcome` | 按条件更新记录 |
| `discardRow(tableName, filterClause, args?)` | `LqjSqlOutcome` | 按条件删除记录 |

说明：

- 所有带参数 SQL 都建议使用 `?` 占位符，不要直接拼接用户输入
- `payload` 必须是 `UTSJSONObject`
- `reviseRow()` 的 `filterClause` 不需要写 `WHERE` 关键字前缀以外的内容，例如可传 `id = ?`

### 表结构管理

| 方法 | 返回值 | 说明 |
| --- | --- | --- |
| `hasTable(tableName)` | `boolean` | 判断表是否存在 |
| `ensureTable(tableName, schema)` | `LqjSqlOutcome` | 不存在时创建表 |
| `removeTable(tableName)` | `LqjSqlOutcome` | 删除表 |

建表字段定义示例：

```uts
const schema = {
  id : 'INTEGER PRIMARY KEY AUTOINCREMENT',
  title : 'TEXT NOT NULL',
  status : 'INTEGER DEFAULT 0',
  updated_at : 'INTEGER'
} as UTSJSONObject
```

### 事务控制

| 方法 | 返回值 | 说明 |
| --- | --- | --- |
| `openTransaction()` | `LqjSqlOutcome` | 开启事务 |
| `finishTransaction()` | `LqjSqlOutcome` | 提交事务 |
| `cancelTransaction()` | `LqjSqlOutcome` | 回滚事务 |

事务示例：

```uts
const beginResult = depot.openTransaction()
if (beginResult.errorText != null) {
  console.error(beginResult.errorText)
  return
}

const first = depot.storeRow('contacts', {
  name : '事务记录',
  city : '成都',
  created_at : Date.now()
} as UTSJSONObject)

if (first.errorText != null) {
  depot.cancelTransaction()
  console.error(first.errorText)
  return
}

const commitResult = depot.finishTransaction()
if (commitResult.errorText != null) {
  console.error(commitResult.errorText)
}
```

### 批量执行

| 方法 | 返回值 | 说明 |
| --- | --- | --- |
| `executeSeries(entries)` | `LqjSqlOutcome[]` | 顺序执行多条 SQL |

批量执行示例：

```uts
const tasks = [
  {
    statement : 'INSERT INTO contacts (name, city, created_at) VALUES (?, ?, ?)',
    args : ['批量甲', '北京', Date.now()]
  },
  {
    statement : 'INSERT INTO contacts (name, city, created_at) VALUES (?, ?, ?)',
    args : ['批量乙', '上海', Date.now()]
  }
] as LqjSqlBatchStatement[]

const outcomes = depot.executeSeries(tasks)
const failure = outcomes.find((item : LqjSqlOutcome) : boolean => {
  return item.errorText != null
})

if (failure != null) {
  console.error(failure.errorText)
}
```

如果业务需要严格控制提交与回滚时机，建议显式调用事务 API，不要只依赖批处理本身。

### 快照备份与恢复

| 方法 | 返回值 | 说明 |
| --- | --- | --- |
| `saveSnapshot(alias?)` | `Promise<LqjSqlOutcome>` | 将当前数据库内容保存为快照 |
| `restoreSnapshot(alias)` | `Promise<LqjSqlOutcome>` | 从指定快照恢复当前数据库 |
| `peekSnapshot()` | `LqjSqlSnapshot \| null` | 查看当前可读取的快照信息 |
| `restoreFromBytes(binaryData)` | `Promise<LqjSqlOutcome>` | 从二进制恢复数据库 |
| `restoreFromFileObject(fileObject)` | `Promise<LqjSqlOutcome>` | 从浏览器文件对象恢复数据库 |
| `restoreFromRemote(remoteUrl)` | `Promise<LqjSqlOutcome>` | 从远程地址恢复数据库 |

快照示例：

```uts
async function restoreDemo() : Promise<void> {
  const saveResult = await depot.saveSnapshot('contacts-backup')
  if (saveResult.errorText != null) {
    console.error(saveResult.errorText)
    return
  }

  const restoreResult = await depot.restoreSnapshot('contacts-backup')
  if (restoreResult.errorText != null) {
    console.error(restoreResult.errorText)
  }
}
```

查看快照示例：

```uts
const snapshot = depot.peekSnapshot()
if (snapshot != null) {
  console.log(snapshot.kind)
  console.log(snapshot.filePath)
  console.log(snapshot.bytes)
}
```

### Android / iOS 额外同步方法

以下方法仅在 App Android 与 App iOS 编译目标中存在：

| 方法 | 返回值 | 说明 |
| --- | --- | --- |
| `prepareSync(alias?)` | `boolean` | 同步打开数据库 |
| `saveSnapshotSync(alias?)` | `LqjSqlOutcome` | 同步保存快照 |
| `restoreSnapshotSync(alias)` | `LqjSqlOutcome` | 同步恢复快照 |

如果你的页面逻辑需要跨 Web、Harmony、Android、iOS 共用，仍建议优先使用统一的异步方法。

## 平台差异说明

### Android

- 支持 `homeDirectory`
- 支持快照路径导出，`peekSnapshot()` 通常返回 `kind: 'path'`
- 不支持 `restoreFromBytes()`、`restoreFromFileObject()`、`restoreFromRemote()`

### iOS

- 支持 `homeDirectory`
- 支持快照路径导出，`peekSnapshot()` 通常返回 `kind: 'path'`
- 不支持 `restoreFromBytes()`、`restoreFromFileObject()`、`restoreFromRemote()`

### Harmony

- 支持核心增删改查、事务、批处理、按别名恢复快照
- `saveSnapshot()` 走系统存储，不导出独立文件路径
- `peekSnapshot()` 固定返回 `kind: 'none'`
- 不支持自定义 `homeDirectory`
- 不支持运行时切换密钥
- 不支持 `restoreFromBytes()`、`restoreFromFileObject()`、`restoreFromRemote()`

### Web

- 依赖 `uni_modules/laoqianjunzi-sqlite/static/sql-wasm.js` 与 `uni_modules/laoqianjunzi-sqlite/static/sql-wasm.wasm`
- 默认会从 `/uni_modules/laoqianjunzi-sqlite/static/sql-wasm.wasm` 加载 wasm 文件
- 可以通过 `wasmResolver` 自定义 wasm 地址
- `saveSnapshot()` 使用本地存储保存快照内容
- `peekSnapshot()` 返回 `kind: 'bytes'`
- 支持 `restoreFromBytes()`、`restoreFromFileObject()`、`restoreFromRemote()`
- `homeDirectory` 在 Web 没有真实物理目录语义

### 微信小程序

- 当前不提供实际 SQLite 能力
- `prepare()` 返回 `false`
- 绝大多数数据库调用会返回错误码 `9802`

## 错误码

| 错误码 | 含义 |
| --- | --- |
| `9801` | 数据库尚未初始化 |
| `9802` | 当前平台暂不支持该恢复方式 |
| `9803` | 找不到本地备份文件 |
| `9804` | 数据库快照导出失败 |
| `9805` | 事务状态不正确 |
| `9806` | SQL 参数或表结构不合法 |

## 使用建议

- 所有数据库操作前先调用 `prepare()`
- 所有返回结果统一检查 `errorText`
- 所有动态 SQL 参数统一使用 `?` 占位符
- 建表 `schema` 直接传 SQLite 字段定义字符串，不要传前端字段注释对象
- 页面或组件销毁时及时调用 `disconnect()`，避免连接长时间悬挂
- 多条写入建议显式包裹事务，避免中途失败后状态不明确
- Web 侧若自定义静态资源路径，请同时确认 `sql-wasm.js` 与 `sql-wasm.wasm` 可访问
- 若使用 `secretPhrase` 或 `enableCipher`，请务必按目标平台单独验证加密链路后再投入正式环境

## 示例页面

插件内已附带演示页面，可直接参考：

- `uni_modules/laoqianjunzi-sqlite/pages/index.uvue`

该页面演示了以下能力：

- 打开数据库
- 创建数据表
- 插入、查询、更新、删除
- 批量执行
- 事务控制
- 快照保存与恢复
- 快照信息查看

## 说明

本插件聚焦于当前 `uni-app x` 项目的统一 SQLite 能力封装。若业务需要更复杂的数据同步、远程分发或数据库加密策略，请在现有 API 基础上自行扩展上层服务逻辑。
