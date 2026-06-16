package uts.sdk.modules.laoqianjunziSqlite

import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import org.json.JSONObject
import java.io.File

data class DepotConfigNative(
    var secretPhrase: String? = null,
    var enableCipher: Boolean = false,
    var homeDirectory: String? = null
)

data class DepotOutcomeNative(
    val grid: List<List<Any>>? = null,
    val fields: List<String>? = null,
    val affectedRows: Int? = null,
    val lastInsertId: Long? = null,
    val errorText: String? = null,
    val records: List<Map<String, Any>>? = null
)

data class DepotBatchNative(
    val statement: String,
    val args: List<Any>? = null
)

class LqjSqlAndroidDepot(
    private val context: Context,
    private val config: DepotConfigNative = DepotConfigNative()
) {
    private var database: SQLiteDatabase? = null
    private var activeAlias: String = DEFAULT_ALIAS
    private var activePath: String? = null
    private var snapshotPath: String? = null
    private var transactionOpen: Boolean = false

    fun openStore(alias: String? = null): SQLiteDatabase? {
        val normalizedAlias = normalizeAlias(alias)
        val targetFile = resolveDatabaseFile(normalizedAlias)

        if (database?.isOpen == true && activePath == targetFile.absolutePath) {
            return database
        }

        disconnect()

        return try {
            targetFile.parentFile?.mkdirs()
            val opened = SQLiteDatabase.openOrCreateDatabase(targetFile, null)
            database = opened
            activeAlias = normalizedAlias
            activePath = targetFile.absolutePath
            applyCipherPragma(opened, "key")
            opened
        } catch (_: Exception) {
            database = null
            activePath = null
            null
        }
    }

    fun execute(statement: String, args: List<Any?> = emptyList()): DepotOutcomeNative {
        val db = requireDatabase() ?: return failure("Database not initialized")
        return try {
            val compiled = db.compileStatement(statement)
            try {
                bindArguments(compiled, args)
                val verb = statement.trimStart().uppercase()
                when {
                    verb.startsWith("INSERT") -> {
                        val insertedId = compiled.executeInsert()
                        DepotOutcomeNative(affectedRows = if (insertedId >= 0) 1 else 0, lastInsertId = insertedId)
                    }

                    verb.startsWith("UPDATE") || verb.startsWith("DELETE") || verb.startsWith("REPLACE") -> {
                        DepotOutcomeNative(affectedRows = compiled.executeUpdateDelete())
                    }

                    else -> {
                        compiled.execute()
                        DepotOutcomeNative(affectedRows = 0)
                    }
                }
            } finally {
                compiled.close()
            }
        } catch (e: Exception) {
            failure(e.message)
        }
    }

    fun select(statement: String, args: List<Any> = emptyList()): DepotOutcomeNative {
        val db = requireDatabase() ?: return failure("Database not initialized")
        return try {
            val cursor = db.rawQuery(statement, args.map { stringifyArgument(it) }.toTypedArray())
            try {
                val columns = cursor.columnNames.toList()
                val rows = mutableListOf<List<Any>>()
                val recordList = mutableListOf<Map<String, Any>>()

                while (cursor.moveToNext()) {
                    val row = mutableListOf<Any>()
                    val record = linkedMapOf<String, Any>()
                    for (index in 0 until cursor.columnCount) {
                        val field = cursor.getColumnName(index)
                        val value = readCursorValue(cursor, index)
                        row.add(value)
                        record[field] = value
                    }
                    rows.add(row)
                    recordList.add(record)
                }

                DepotOutcomeNative(grid = rows, fields = columns, records = recordList)
            } finally {
                cursor.close()
            }
        } catch (e: Exception) {
            failure(e.message)
        }
    }

    fun storeRow(tableName: String, payload: JSONObject): DepotOutcomeNative {
        val columns = extractPayload(payload)
        if (columns.isEmpty()) {
            return failure("Payload is empty")
        }

        val table = safeIdentifier(tableName)
            ?: return failure("Invalid table name")
        val names = columns.map { it.first }
        val values = columns.map { it.second }
        val placeholders = List(names.size) { "?" }.joinToString(",")
        val sql = "INSERT INTO $table (${names.joinToString(",")}) VALUES ($placeholders)"
        return execute(sql, values)
    }

    fun reviseRow(
        tableName: String,
        payload: JSONObject,
        filterClause: String,
        args: List<Any> = emptyList()
    ): DepotOutcomeNative {
        val columns = extractPayload(payload)
        if (columns.isEmpty()) {
            return failure("Payload is empty")
        }

        val table = safeIdentifier(tableName)
            ?: return failure("Invalid table name")
        val assignments = columns.map { "${it.first} = ?" }
        val mergedArgs = mutableListOf<Any?>()
        mergedArgs.addAll(columns.map { it.second })
        mergedArgs.addAll(args)
        val sql = "UPDATE $table SET ${assignments.joinToString(",")} WHERE $filterClause"
        return execute(sql, mergedArgs)
    }

    fun discardRow(tableName: String, filterClause: String, args: List<Any> = emptyList()): DepotOutcomeNative {
        val table = safeIdentifier(tableName)
            ?: return failure("Invalid table name")
        val sql = "DELETE FROM $table WHERE $filterClause"
        return execute(sql, args)
    }

    fun saveSnapshot(alias: String? = null): DepotOutcomeNative {
        val db = requireDatabase() ?: return failure("Database not initialized")
        return try {
            val sourceFile = File(db.path)
            if (!sourceFile.exists()) {
                return failure("Database file not found")
            }
            val snapshotFile = resolveSnapshotFile(normalizeAlias(alias ?: activeAlias))
            snapshotFile.parentFile?.mkdirs()
            if (snapshotFile.exists()) {
                snapshotFile.delete()
            }
            sourceFile.copyTo(snapshotFile, overwrite = true)
            snapshotPath = snapshotFile.absolutePath
            DepotOutcomeNative()
        } catch (e: Exception) {
            failure(e.message)
        }
    }

    fun restoreSnapshot(alias: String): DepotOutcomeNative {
        return try {
            val snapshotFile = resolveSnapshotFile(normalizeAlias(alias))
            if (!snapshotFile.exists()) {
                return failure("Snapshot not found")
            }

            val targetAlias = activeAlias
            val targetFile = resolveDatabaseFile(targetAlias)
            disconnect()
            targetFile.parentFile?.mkdirs()
            snapshotFile.copyTo(targetFile, overwrite = true)
            snapshotPath = snapshotFile.absolutePath

            if (openStore(targetAlias) == null) {
                return failure("Database reopen failed")
            }
            DepotOutcomeNative()
        } catch (e: Exception) {
            failure(e.message)
        }
    }

    fun saveLocalCompat(alias: String? = null): DepotOutcomeNative {
        val db = requireDatabase() ?: return failure("Database not initialized")
        return try {
            val sourceFile = File(db.path)
            if (!sourceFile.exists()) {
                return failure("Database file not found")
            }
            val localFile = resolveLocalCompatFile(normalizeAlias(alias ?: activeAlias))
            localFile.parentFile?.mkdirs()
            if (localFile.exists()) {
                localFile.delete()
            }
            sourceFile.copyTo(localFile, overwrite = true)
            DepotOutcomeNative()
        } catch (e: Exception) {
            failure(e.message)
        }
    }

    fun loadLocalCompat(alias: String): DepotOutcomeNative {
        return try {
            val normalizedAlias = normalizeAlias(alias)
            val localFile = resolveLocalCompatFile(normalizedAlias)
            val restoreSource = if (localFile.exists()) localFile else resolveSnapshotFile(normalizedAlias)
            if (!restoreSource.exists()) {
                return failure("Local database not found")
            }

            val targetAlias = activeAlias
            val targetFile = resolveDatabaseFile(targetAlias)
            disconnect()
            targetFile.parentFile?.mkdirs()
            restoreSource.copyTo(targetFile, overwrite = true)
            if (restoreSource.absolutePath == resolveSnapshotFile(normalizedAlias).absolutePath) {
                snapshotPath = restoreSource.absolutePath
            }

            if (openStore(targetAlias) == null) {
                return failure("Database reopen failed")
            }
            DepotOutcomeNative()
        } catch (e: Exception) {
            failure(e.message)
        }
    }

    fun exportDatabasePathCompat(): String? {
        val db = requireDatabase() ?: return null
        return try {
            val sourceFile = File(db.path)
            if (!sourceFile.exists()) {
                return null
            }
            val exportFile = File.createTempFile(normalizeAlias(activeAlias) + "-", ".db", context.cacheDir)
            sourceFile.copyTo(exportFile, overwrite = true)
            exportFile.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    fun applyHomeDirectory(directory: String) {
        config.homeDirectory = directory
    }

    fun applySecret(secretPhrase: String?) {
        config.secretPhrase = secretPhrase
        config.enableCipher = !secretPhrase.isNullOrEmpty()
        database?.let { opened ->
            try {
                applyCipherPragma(opened, "rekey")
            } catch (_: Exception) {
            }
        }
    }

    fun hasTable(tableName: String): Boolean {
        val table = safeIdentifier(tableName) ?: return false
        val result = select(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
            listOf(table)
        )
        return result.errorText == null && !result.records.isNullOrEmpty()
    }

    fun ensureTable(tableName: String, schema: Map<String, String>): DepotOutcomeNative {
        val table = safeIdentifier(tableName)
            ?: return failure("Invalid table name")
        if (schema.isEmpty()) {
            return failure("Schema is empty")
        }

        val segments = mutableListOf<String>()
        for (entry in schema.entries) {
            val column = safeIdentifier(entry.key) ?: return failure("Invalid column name")
            segments.add("$column ${entry.value}")
        }
        val definition = segments.joinToString(",")
        return execute("CREATE TABLE IF NOT EXISTS $table ($definition)")
    }

    fun removeTable(tableName: String): DepotOutcomeNative {
        val table = safeIdentifier(tableName)
            ?: return failure("Invalid table name")
        return execute("DROP TABLE IF EXISTS $table")
    }

    fun disconnect() {
        try {
            if (transactionOpen) {
                database?.endTransaction()
            }
        } catch (_: Exception) {
        }
        transactionOpen = false
        database?.close()
        database = null
        activePath = null
    }

    fun openTransaction(): DepotOutcomeNative {
        val db = requireDatabase() ?: return failure("Database not initialized")
        return try {
            if (transactionOpen) {
                return failure("Transaction already open")
            }
            db.beginTransaction()
            transactionOpen = true
            DepotOutcomeNative()
        } catch (e: Exception) {
            failure(e.message)
        }
    }

    fun finishTransaction(): DepotOutcomeNative {
        val db = requireDatabase() ?: return failure("Database not initialized")
        return try {
            if (!transactionOpen) {
                return failure("Transaction not open")
            }
            db.setTransactionSuccessful()
            db.endTransaction()
            transactionOpen = false
            DepotOutcomeNative()
        } catch (e: Exception) {
            failure(e.message)
        }
    }

    fun cancelTransaction(): DepotOutcomeNative {
        val db = requireDatabase() ?: return failure("Database not initialized")
        return try {
            if (!transactionOpen) {
                return failure("Transaction not open")
            }
            db.endTransaction()
            transactionOpen = false
            DepotOutcomeNative()
        } catch (e: Exception) {
            failure(e.message)
        }
    }

    fun executeSeries(entries: List<DepotBatchNative>): List<DepotOutcomeNative> {
        if (entries.isEmpty()) {
            return emptyList()
        }

        val outcomes = mutableListOf<DepotOutcomeNative>()
        val inheritedTransaction = transactionOpen

        if (!inheritedTransaction) {
            val beginOutcome = openTransaction()
            if (beginOutcome.errorText != null) {
                return listOf(beginOutcome)
            }
        }

        var failed = false
        for (entry in entries) {
            val outcome = execute(entry.statement, entry.args?.map { it } ?: emptyList())
            outcomes.add(outcome)
            if (outcome.errorText != null) {
                failed = true
                break
            }
        }

        if (!inheritedTransaction) {
            val closingOutcome = if (failed) cancelTransaction() else finishTransaction()
            if (closingOutcome.errorText != null) {
                outcomes.add(closingOutcome)
            }
        }

        return outcomes
    }

    fun peekSnapshotPath(): String? {
        return snapshotPath
    }

    private fun requireDatabase(): SQLiteDatabase? {
        return if (database?.isOpen == true) database else openStore(activeAlias)
    }

    private fun normalizeAlias(alias: String?): String {
        val trimmed = alias?.trim().orEmpty()
        return if (trimmed.isEmpty()) DEFAULT_ALIAS else trimmed
    }

    private fun resolveDatabaseFile(alias: String): File {
        val fileName = "$alias.db"
        val baseDir = config.homeDirectory?.takeIf { it.isNotBlank() }?.let { File(it) }
        return if (baseDir != null) File(baseDir, fileName) else context.getDatabasePath(fileName)
    }

    private fun resolveSnapshotFile(alias: String): File {
        val homeDir = config.homeDirectory?.takeIf { it.isNotBlank() }?.let { File(it) }
        val snapshotDir = if (homeDir != null) {
            File(homeDir, "snapshots")
        } else {
            File(context.filesDir, "laoqianjunzi-sqlite-snapshots")
        }
        return File(snapshotDir, "$alias.db")
    }

    private fun resolveLocalCompatFile(alias: String): File {
        val homeDir = config.homeDirectory?.takeIf { it.isNotBlank() }?.let { File(it) }
        val localDir = homeDir ?: context.filesDir
        return File(localDir, "$alias.db")
    }

    private fun bindArguments(statement: android.database.sqlite.SQLiteStatement, args: List<Any?>) {
        args.forEachIndexed { index, rawValue ->
            val position = index + 1
            when (val value = normalizeValue(rawValue)) {
                null -> statement.bindNull(position)
                is ByteArray -> statement.bindBlob(position, value)
                is String -> statement.bindString(position, value)
                is Float -> statement.bindDouble(position, value.toDouble())
                is Double -> statement.bindDouble(position, value)
                is Int -> statement.bindLong(position, value.toLong())
                is Long -> statement.bindLong(position, value)
                is Short -> statement.bindLong(position, value.toLong())
                is Byte -> statement.bindLong(position, value.toLong())
                is Boolean -> statement.bindLong(position, if (value) 1L else 0L)
                is Number -> statement.bindDouble(position, value.toDouble())
                else -> statement.bindString(position, value.toString())
            }
        }
    }

    private fun extractPayload(payload: JSONObject): List<Pair<String, Any?>> {
        val items = mutableListOf<Pair<String, Any?>>()
        val iterator = payload.keys()
        while (iterator.hasNext()) {
            val rawName = iterator.next()
            val column = safeIdentifier(rawName) ?: continue
            items.add(column to normalizeValue(payload.opt(rawName)))
        }
        return items
    }

    private fun readCursorValue(cursor: Cursor, index: Int): Any {
        return when (cursor.getType(index)) {
            Cursor.FIELD_TYPE_INTEGER -> cursor.getLong(index)
            Cursor.FIELD_TYPE_FLOAT -> cursor.getDouble(index)
            Cursor.FIELD_TYPE_BLOB -> cursor.getBlob(index)
            Cursor.FIELD_TYPE_STRING -> cursor.getString(index)
            Cursor.FIELD_TYPE_NULL -> ""
            else -> cursor.getString(index) ?: ""
        }
    }

    private fun normalizeValue(value: Any?): Any? {
        return if (value == JSONObject.NULL) null else value
    }

    private fun stringifyArgument(value: Any): String {
        val normalized = normalizeValue(value)
        return normalized?.toString() ?: ""
    }

    private fun safeIdentifier(value: String): String? {
        val trimmed = value.trim()
        return if (IDENTIFIER_PATTERN.matches(trimmed)) trimmed else null
    }

    private fun applyCipherPragma(db: SQLiteDatabase, command: String) {
        if (!config.enableCipher || config.secretPhrase.isNullOrEmpty()) {
            return
        }
        val statement = db.compileStatement("PRAGMA $command = ?")
        try {
            statement.bindString(1, config.secretPhrase!!)
            statement.execute()
        } finally {
            statement.close()
        }
    }

    private fun failure(message: String?): DepotOutcomeNative {
        return DepotOutcomeNative(errorText = message ?: "Unknown error")
    }

    companion object {
        private const val DEFAULT_ALIAS = "sqlite"
        private val IDENTIFIER_PATTERN = Regex("^[A-Za-z_][A-Za-z0-9_]*$")
    }
}
