import { common } from '@kit.AbilityKit'
import { ValueType, ValuesBucket, relationalStore } from '@kit.ArkData'
import { BusinessError } from '@ohos.base'

export type LqjSqlHarmonyScalar = string | number | boolean | Uint8Array | null

export interface LqjSqlHarmonyOutcome {
  grid: LqjSqlHarmonyScalar[][] | null
  fields: string[] | null
  affectedRows: number | null
  lastInsertId: number | null
  errorText: string | null
  records: Map<string, LqjSqlHarmonyScalar>[] | null
}

export interface LqjSqlHarmonyBatchStatement {
  statement: string
  args: LqjSqlHarmonyScalar[] | null
}

function emptyOutcome(): LqjSqlHarmonyOutcome {
  return {
    grid: null,
    fields: null,
    affectedRows: null,
    lastInsertId: null,
    errorText: null,
    records: null
  }
}

function failureOutcome(message: string): LqjSqlHarmonyOutcome {
  return {
    grid: null,
    fields: null,
    affectedRows: null,
    lastInsertId: null,
    errorText: message,
    records: null
  }
}

function normalizeAlias(alias: string | null): string {
  if (alias == null) {
    return 'sqlite'
  }
  const trimmed = alias.trim()
  if (trimmed.length == 0) {
    return 'sqlite'
  }
  return trimmed
}

function toValueTypeArray(args: LqjSqlHarmonyScalar[] | null): ValueType[] {
  if (args == null) {
    return []
  }
  const result: ValueType[] = []
  for (let index = 0; index < args.length; index++) {
    result.push(args[index] as ValueType)
  }
  return result
}

function readNumericCell(outcome: LqjSqlHarmonyOutcome, fallback: number = 0): number {
  if (outcome.grid == null || outcome.grid.length == 0) {
    return fallback
  }
  const firstRow = outcome.grid[0]
  if (firstRow.length == 0) {
    return fallback
  }
  const rawValue = firstRow[0]
  if (typeof rawValue == 'number') {
    return rawValue
  }
  return fallback
}

export class LqjSqlHarmonyDepot {
  private storeConfig: relationalStore.StoreConfig = {
    name: 'sqlite.db',
    securityLevel: relationalStore.SecurityLevel.S3,
    customDir: 'laoqianjunzi-sqlite'
  }
  private activeStore: relationalStore.RdbStore | null = null
  private activeAlias: string = 'sqlite'
  private transactionOpened: boolean = false

  prepare(alias: string | null = null): Promise<boolean> {
    const nextAlias = normalizeAlias(alias)
    if (this.activeStore != null && this.activeAlias == nextAlias) {
      return Promise.resolve(true)
    }
    if (this.activeStore != null) {
      this.disconnect()
    }
    this.activeAlias = nextAlias
    this.storeConfig.name = this.activeAlias + '.db'
    const context = getContext() as common.UIAbilityContext
    return new Promise<boolean>((resolve) => {
      relationalStore.getRdbStore(context, this.storeConfig).then((store: relationalStore.RdbStore) => {
        this.activeStore = store
        resolve(true)
      }).catch((error: BusinessError) => {
        console.error('laoqianjunzi-sqlite harmony prepare failed: ' + error.message)
        resolve(false)
      })
    })
  }

  execute(statement: string, args: LqjSqlHarmonyScalar[] | null = []): LqjSqlHarmonyOutcome {
    if (this.activeStore == null) {
      return failureOutcome('数据库尚未初始化')
    }
    const store = this.activeStore
    try {
      store.executeSync(statement, toValueTypeArray(args))
      const upperSql = statement.trim().toUpperCase()
      const affectedRows = readNumericCell(this.select('SELECT changes()'), 0)
      const lastInsertId = upperSql.startsWith('INSERT') ? readNumericCell(this.select('SELECT last_insert_rowid()'), 0) : null
      return {
        grid: null,
        fields: null,
        affectedRows,
        lastInsertId,
        errorText: null,
        records: null
      }
    } catch (error) {
      const err = error as BusinessError
      return failureOutcome(err.message)
    }
  }

  select(statement: string, args: LqjSqlHarmonyScalar[] | null = []): LqjSqlHarmonyOutcome {
    if (this.activeStore == null) {
      return failureOutcome('数据库尚未初始化')
    }
    const store = this.activeStore
    try {
      const resultSet = store.querySqlSync(statement, toValueTypeArray(args))
      const fields = resultSet.columnNames
      const grid: LqjSqlHarmonyScalar[][] = []
      const records: Map<string, LqjSqlHarmonyScalar>[] = []
      while (resultSet.goToNextRow()) {
        const row: LqjSqlHarmonyScalar[] = []
        const rowMap = new Map<string, LqjSqlHarmonyScalar>()
        for (let index = 0; index < fields.length; index++) {
          const fieldName = fields[index]
          const value = resultSet.getValue(index) as LqjSqlHarmonyScalar
          row.push(value)
          rowMap.set(fieldName, value)
        }
        grid.push(row)
        records.push(rowMap)
      }
      return {
        grid,
        fields,
        affectedRows: null,
        lastInsertId: null,
        errorText: null,
        records
      }
    } catch (error) {
      const err = error as BusinessError
      return failureOutcome(err.message)
    }
  }

  storeRow(tableName: string, payload: Map<string, LqjSqlHarmonyScalar>): LqjSqlHarmonyOutcome {
    if (this.activeStore == null) {
      return failureOutcome('数据库尚未初始化')
    }
    const store = this.activeStore
    const bucket: ValuesBucket = {}
    payload.forEach((value: LqjSqlHarmonyScalar, key: string) => {
      bucket[key] = value as ValueType
    })
    try {
      const insertedId = store.insertSync(tableName, bucket)
      if (insertedId < 0) {
        return failureOutcome('插入失败')
      }
      return {
        grid: null,
        fields: null,
        affectedRows: 1,
        lastInsertId: insertedId,
        errorText: null,
        records: null
      }
    } catch (error) {
      const err = error as BusinessError
      return failureOutcome(err.message)
    }
  }

  reviseRow(tableName: string, payload: Map<string, LqjSqlHarmonyScalar>, filterClause: string, args: LqjSqlHarmonyScalar[] | null = []): LqjSqlHarmonyOutcome {
    const fieldNames: string[] = []
    const updateValues: LqjSqlHarmonyScalar[] = []
    payload.forEach((value: LqjSqlHarmonyScalar, key: string) => {
      fieldNames.push(key)
      updateValues.push(value)
    })
    const setters = fieldNames.map((fieldName: string): string => {
      return fieldName + ' = ?'
    }).join(',')
    const mergedArgs: LqjSqlHarmonyScalar[] = []
    for (let index = 0; index < updateValues.length; index++) {
      mergedArgs.push(updateValues[index])
    }
    if (args != null) {
      for (let index = 0; index < args.length; index++) {
        mergedArgs.push(args[index])
      }
    }
    return this.execute('UPDATE ' + tableName + ' SET ' + setters + ' WHERE ' + filterClause, mergedArgs)
  }

  discardRow(tableName: string, filterClause: string, args: LqjSqlHarmonyScalar[] | null = []): LqjSqlHarmonyOutcome {
    return this.execute('DELETE FROM ' + tableName + ' WHERE ' + filterClause, args)
  }

  hasTable(tableName: string): boolean {
    const outcome = this.select("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [tableName])
    if (outcome.grid == null) {
      return false
    }
    return outcome.grid.length > 0
  }

  ensureTable(tableName: string, schema: Map<string, string>): LqjSqlHarmonyOutcome {
    const segments: string[] = []
    schema.forEach((value: string, key: string) => {
      segments.push(key + ' ' + value)
    })
    return this.execute('CREATE TABLE IF NOT EXISTS ' + tableName + ' (' + segments.join(',') + ')')
  }

  removeTable(tableName: string): LqjSqlHarmonyOutcome {
    return this.execute('DROP TABLE IF EXISTS ' + tableName)
  }

  disconnect(): void {
    if (this.activeStore != null) {
      const store = this.activeStore
      try {
        store.close()
      } catch (error) {
        console.warn('laoqianjunzi-sqlite harmony close warning')
      }
      this.activeStore = null
    }
    this.transactionOpened = false
  }

  openTransaction(): LqjSqlHarmonyOutcome {
    if (this.activeStore == null) {
      return failureOutcome('数据库尚未初始化')
    }
    const store = this.activeStore
    if (this.transactionOpened) {
      return failureOutcome('事务已经开启')
    }
    try {
      store.beginTransaction()
      this.transactionOpened = true
      return emptyOutcome()
    } catch (error) {
      const err = error as BusinessError
      return failureOutcome(err.message)
    }
  }

  finishTransaction(): LqjSqlHarmonyOutcome {
    if (this.activeStore == null) {
      return failureOutcome('数据库尚未初始化')
    }
    const store = this.activeStore
    if (this.transactionOpened == false) {
      return failureOutcome('当前没有事务可提交')
    }
    try {
      store.commit()
      this.transactionOpened = false
      return emptyOutcome()
    } catch (error) {
      const err = error as BusinessError
      return failureOutcome(err.message)
    }
  }

  cancelTransaction(): LqjSqlHarmonyOutcome {
    if (this.activeStore == null) {
      return failureOutcome('数据库尚未初始化')
    }
    const store = this.activeStore
    if (this.transactionOpened == false) {
      return failureOutcome('当前没有事务可回滚')
    }
    try {
      store.rollBack()
      this.transactionOpened = false
      return emptyOutcome()
    } catch (error) {
      const err = error as BusinessError
      return failureOutcome(err.message)
    }
  }

  executeSeries(entries: LqjSqlHarmonyBatchStatement[]): LqjSqlHarmonyOutcome[] {
    if (this.activeStore == null) {
      return [failureOutcome('数据库尚未初始化')]
    }
    const outcomes: LqjSqlHarmonyOutcome[] = []
    const inherited = this.transactionOpened
    if (inherited == false) {
      const beginResult = this.openTransaction()
      if (beginResult.errorText != null) {
        return [beginResult]
      }
    }
    let failed = false
    for (let index = 0; index < entries.length; index++) {
      const entry = entries[index]
      const result = this.execute(entry.statement, entry.args)
      outcomes.push(result)
      if (result.errorText != null) {
        failed = true
        break
      }
    }
    if (inherited == false) {
      if (failed) {
        this.cancelTransaction()
      } else {
        this.finishTransaction()
      }
    }
    return outcomes
  }

  restoreSnapshot(alias: string): Promise<boolean> {
    return this.prepare(alias)
  }
}
