import Foundation
import SQLite3
import DCloudUTSFoundation

private let lqjSqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

struct DepotConfigSwift {
	var secretPhrase: String? = nil
	var enableCipher: Bool = false
	var homeDirectory: String? = nil
}

struct DepotOutcomeSwift {
	var grid: [[Any]]? = nil
	var fields: [String]? = nil
	var affectedRows: Int? = nil
	var lastInsertId: Int64? = nil
	var errorText: String? = nil
	var records: [[String: Any]]? = nil
}

struct DepotBatchSwift {
	var statement: String = ""
	var args: [Any]? = nil
}

class LqjSqlIosDepot {
	private var handle: OpaquePointer?
	private var isTransactionOpen: Bool = false
	private var settings: DepotConfigSwift
	private var currentAlias: String = "sqlite"
	private var currentFileURL: URL?
	private var exportedSnapshotURL: URL?

	init(config: DepotConfigSwift = DepotConfigSwift()) {
		self.settings = config
	}

	func openStore(alias: String? = nil) -> OpaquePointer? {
		let resolvedAlias = sanitizeAlias(alias)
		let databaseURL = storeURL(for: resolvedAlias)

		if let handle = handle, currentFileURL?.path == databaseURL.path {
			return handle
		}

		disconnect()

		do {
			try prepareDirectory(for: databaseURL)
		} catch {
			return nil
		}

		var pointer: OpaquePointer?
		if sqlite3_open(databaseURL.path, &pointer) != SQLITE_OK {
			if let pointer = pointer {
				sqlite3_close(pointer)
			}
			return nil
		}

		handle = pointer
		currentAlias = resolvedAlias
		currentFileURL = databaseURL
		applyCipherKeyIfNeeded()
		return pointer
	}

	func execute(_ statement: String, args: [Any] = []) -> DepotOutcomeSwift {
		guard let handle = activeHandle() else {
			return failure("数据库尚未初始化")
		}

		var prepared: OpaquePointer?
		guard sqlite3_prepare_v2(handle, statement, -1, &prepared, nil) == SQLITE_OK, let prepared else {
			return failure(lastErrorText(from: handle))
		}

		defer {
			sqlite3_finalize(prepared)
		}

		if let bindError = bind(args, to: prepared) {
			return failure(bindError)
		}

		let stepCode = sqlite3_step(prepared)
		guard stepCode == SQLITE_DONE || stepCode == SQLITE_ROW else {
			return failure(lastErrorText(from: handle))
		}

		return DepotOutcomeSwift(
			grid: nil,
			fields: nil,
			affectedRows: Int(sqlite3_changes(handle)),
			lastInsertId: sqlite3_last_insert_rowid(handle),
			errorText: nil,
			records: nil
		)
	}

	func select(_ statement: String, args: [Any] = []) -> DepotOutcomeSwift {
		guard let handle = activeHandle() else {
			return failure("数据库尚未初始化")
		}

		var prepared: OpaquePointer?
		guard sqlite3_prepare_v2(handle, statement, -1, &prepared, nil) == SQLITE_OK, let prepared else {
			return failure(lastErrorText(from: handle))
		}

		defer {
			sqlite3_finalize(prepared)
		}

		if let bindError = bind(args, to: prepared) {
			return failure(bindError)
		}

		let totalColumns = Int(sqlite3_column_count(prepared))
		var fieldNames: [String] = []
		fieldNames.reserveCapacity(totalColumns)
		for index in 0..<totalColumns {
			if let rawName = sqlite3_column_name(prepared, Int32(index)) {
				fieldNames.append(String(cString: rawName))
			} else {
				fieldNames.append("")
			}
		}

		var matrix: [[Any]] = []
		var mappedRows: [[String: Any]] = []

		while true {
			let code = sqlite3_step(prepared)
			if code == SQLITE_DONE {
				break
			}
			if code != SQLITE_ROW {
				return failure(lastErrorText(from: handle))
			}

			var row: [Any] = []
			row.reserveCapacity(totalColumns)
			var record: [String: Any] = [:]
			for index in 0..<totalColumns {
				let value = decodeColumn(prepared, column: Int32(index))
				row.append(value)
				record[fieldNames[index]] = value
			}
			matrix.append(row)
			mappedRows.append(record)
		}

		return DepotOutcomeSwift(
			grid: matrix,
			fields: fieldNames,
			affectedRows: nil,
			lastInsertId: nil,
			errorText: nil,
			records: mappedRows
		)
	}

	func storeRow(tableName: String, payload: [String: Any]) -> DepotOutcomeSwift {
		let keys = payload.keys.sorted()
		guard !keys.isEmpty else {
			return failure("插入数据不能为空")
		}

		let columns = keys.map { quotedIdentifier($0) }.joined(separator: ", ")
		let marks = Array(repeating: "?", count: keys.count).joined(separator: ", ")
		let values = keys.compactMap { payload[$0] }
		let sql = "INSERT INTO \(quotedIdentifier(tableName)) (\(columns)) VALUES (\(marks))"
		return execute(sql, args: values)
	}

	func reviseRow(tableName: String, payload: [String: Any], filterClause: String, args: [Any] = []) -> DepotOutcomeSwift {
		let keys = payload.keys.sorted()
		guard !keys.isEmpty else {
			return failure("更新数据不能为空")
		}
		guard !filterClause.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			return failure("更新条件不能为空")
		}

		let setters = keys.map { "\(quotedIdentifier($0)) = ?" }.joined(separator: ", ")
		var values = keys.compactMap { payload[$0] }
		values.append(contentsOf: args)
		let sql = "UPDATE \(quotedIdentifier(tableName)) SET \(setters) WHERE \(filterClause)"
		return execute(sql, args: values)
	}

	func discardRow(tableName: String, filterClause: String, args: [Any] = []) -> DepotOutcomeSwift {
		guard !filterClause.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			return failure("删除条件不能为空")
		}
		let sql = "DELETE FROM \(quotedIdentifier(tableName)) WHERE \(filterClause)"
		return execute(sql, args: args)
	}

	func saveSnapshot(alias: String? = nil) -> DepotOutcomeSwift {
		guard let handle = activeHandle(), let sourceURL = liveStoreURL() else {
			return failure("数据库尚未初始化")
		}

		let snapshotAlias = sanitizeSnapshotAlias(alias)
		let targetURL = storeURL(for: snapshotAlias)
		do {
			try prepareDirectory(for: targetURL)
			try flushStore(handle)
			try copyStore(from: sourceURL, to: targetURL, allowSamePath: false)
			return DepotOutcomeSwift()
		} catch {
			return failure(error.localizedDescription)
		}
	}

	func restoreSnapshot(alias: String) -> DepotOutcomeSwift {
		let sourceURL = storeURL(for: sanitizeAlias(alias))
		guard FileManager.default.fileExists(atPath: sourceURL.path) else {
			return failure("找不到备份文件")
		}

		let targetAlias = currentAlias
		let targetURL = currentFileURL ?? storeURL(for: targetAlias)
		disconnect()

		do {
			try prepareDirectory(for: targetURL)
			try removeRelatedStoreFiles(for: targetURL)
			try copyStore(from: sourceURL, to: targetURL, allowSamePath: true)
			guard openStore(alias: targetAlias) != nil else {
				return failure("数据库恢复后无法重新打开")
			}
			return DepotOutcomeSwift()
		} catch {
			return failure(error.localizedDescription)
		}
	}

	func applyHomeDirectory(directory: String) {
		settings.homeDirectory = directory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : directory
	}

	func applySecret(_ secretPhrase: String?) {
		let trimmed = secretPhrase?.trimmingCharacters(in: .whitespacesAndNewlines)
		if let trimmed, !trimmed.isEmpty {
			settings.secretPhrase = trimmed
			settings.enableCipher = true
		} else {
			settings.secretPhrase = nil
			settings.enableCipher = false
		}

		guard handle != nil else {
			return
		}

		let escaped = escapeSQLiteLiteral(settings.secretPhrase ?? "")
		_ = executeRaw("PRAGMA rekey = '\(escaped)'")
	}

	func hasTable(tableName: String) -> Bool {
		let result = select("SELECT name FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1", args: [tableName])
		return result.errorText == nil && (result.grid?.isEmpty == false)
	}

	func ensureTable(tableName: String, schema: [String: String]) -> DepotOutcomeSwift {
		let keys = schema.keys.sorted()
		guard !keys.isEmpty else {
			return failure("表结构不能为空")
		}

		let definitions = keys.map { "\(quotedIdentifier($0)) \(schema[$0] ?? "")" }
		let sql = "CREATE TABLE IF NOT EXISTS \(quotedIdentifier(tableName)) (\(definitions.joined(separator: ", ")))"
		return execute(sql)
	}

	func removeTable(tableName: String) -> DepotOutcomeSwift {
		return execute("DROP TABLE IF EXISTS \(quotedIdentifier(tableName))")
	}

	func disconnect() {
		if let handle {
			sqlite3_close(handle)
		}
		handle = nil
		isTransactionOpen = false
	}

	func openTransaction() -> DepotOutcomeSwift {
		guard !isTransactionOpen else {
			return failure("事务已开启")
		}
		let result = execute("BEGIN IMMEDIATE TRANSACTION")
		if result.errorText == nil {
			isTransactionOpen = true
		}
		return result
	}

	func finishTransaction() -> DepotOutcomeSwift {
		guard isTransactionOpen else {
			return failure("当前没有可提交的事务")
		}
		let result = execute("COMMIT")
		if result.errorText == nil {
			isTransactionOpen = false
		}
		return result
	}

	func cancelTransaction() -> DepotOutcomeSwift {
		guard isTransactionOpen else {
			return failure("当前没有可回滚的事务")
		}
		let result = execute("ROLLBACK")
		if result.errorText == nil {
			isTransactionOpen = false
		}
		return result
	}

	func executeSeries(entries: [DepotBatchSwift]) -> [DepotOutcomeSwift] {
		guard !entries.isEmpty else {
			return []
		}

		var outcomes: [DepotOutcomeSwift] = []
		let alreadyWrapped = isTransactionOpen
		if !alreadyWrapped {
			let beginResult = openTransaction()
			if beginResult.errorText != nil {
				return [beginResult]
			}
		}

		for entry in entries {
			let result = execute(entry.statement, args: entry.args ?? [])
			outcomes.append(result)
			if result.errorText != nil {
				if !alreadyWrapped {
					_ = cancelTransaction()
				}
				return outcomes
			}
		}

		if !alreadyWrapped {
			let commitResult = finishTransaction()
			if commitResult.errorText != nil {
				outcomes.append(commitResult)
			}
		}

		return outcomes
	}

	func peekSnapshotPath() -> String? {
		guard let handle = activeHandle(), let sourceURL = liveStoreURL() else {
			return nil
		}

		do {
			try flushStore(handle)
			let cacheRoot = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
			let exportURL = cacheRoot.appendingPathComponent("laoqianjunzi_sqlite_snapshot_\(UUID().uuidString).db")
			if let exportedSnapshotURL, FileManager.default.fileExists(atPath: exportedSnapshotURL.path) {
				try? FileManager.default.removeItem(at: exportedSnapshotURL)
			}
			try copyStore(from: sourceURL, to: exportURL, allowSamePath: false)
			exportedSnapshotURL = exportURL
			return exportURL.path
		} catch {
			return nil
		}
	}

	private func activeHandle() -> OpaquePointer? {
		handle
	}

	private func sanitizeAlias(_ alias: String?) -> String {
		let trimmed = alias?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		return trimmed.isEmpty ? "sqlite" : trimmed
	}

	private func sanitizeSnapshotAlias(_ alias: String?) -> String {
		let trimmed = alias?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		if trimmed.isEmpty {
			return "\(currentAlias)-snapshot"
		}
		return trimmed
	}

	private func baseDirectoryURL() -> URL {
		if let homeDirectory = settings.homeDirectory?.trimmingCharacters(in: .whitespacesAndNewlines), !homeDirectory.isEmpty {
			return URL(fileURLWithPath: homeDirectory, isDirectory: true)
		}
		return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
	}

	private func storeURL(for alias: String) -> URL {
		baseDirectoryURL().appendingPathComponent("\(alias).db")
	}

	private func prepareDirectory(for url: URL) throws {
		try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
	}

	private func quotedIdentifier(_ value: String) -> String {
		"\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
	}

	private func failure(_ message: String) -> DepotOutcomeSwift {
		DepotOutcomeSwift(grid: nil, fields: nil, affectedRows: nil, lastInsertId: nil, errorText: message, records: nil)
	}

	private func bind(_ args: [Any], to statement: OpaquePointer) -> String? {
		for (offset, item) in args.enumerated() {
			let index = Int32(offset + 1)
			let code: Int32
			switch item {
			case let value as String:
				code = (value as NSString).utf8String.map {
					sqlite3_bind_text(statement, index, $0, -1, lqjSqliteTransient)
				} ?? sqlite3_bind_null(statement, index)
			case let value as NSString:
				code = sqlite3_bind_text(statement, index, value.utf8String, -1, lqjSqliteTransient)
			case let value as Int:
				code = sqlite3_bind_int64(statement, index, sqlite3_int64(value))
			case let value as Int32:
				code = sqlite3_bind_int(statement, index, value)
			case let value as Int64:
				code = sqlite3_bind_int64(statement, index, value)
			case let value as UInt:
				code = sqlite3_bind_int64(statement, index, sqlite3_int64(value))
			case let value as UInt32:
				code = sqlite3_bind_int64(statement, index, sqlite3_int64(value))
			case let value as UInt64:
				code = sqlite3_bind_int64(statement, index, sqlite3_int64(bitPattern: value))
			case let value as Double:
				code = sqlite3_bind_double(statement, index, value)
			case let value as Float:
				code = sqlite3_bind_double(statement, index, Double(value))
			case let value as Bool:
				code = sqlite3_bind_int(statement, index, value ? 1 : 0)
			case let value as NSNumber:
				if CFGetTypeID(value) == CFBooleanGetTypeID() {
					code = sqlite3_bind_int(statement, index, value.boolValue ? 1 : 0)
				} else if String(cString: value.objCType) == "d" || String(cString: value.objCType) == "f" {
					code = sqlite3_bind_double(statement, index, value.doubleValue)
				} else {
					code = sqlite3_bind_int64(statement, index, value.int64Value)
				}
			case let value as Data:
				code = value.withUnsafeBytes { buffer in
					sqlite3_bind_blob(statement, index, buffer.baseAddress, Int32(value.count), lqjSqliteTransient)
				}
			case is NSNull:
				code = sqlite3_bind_null(statement, index)
			default:
				let fallback = String(describing: item)
				code = (fallback as NSString).utf8String.map {
					sqlite3_bind_text(statement, index, $0, -1, lqjSqliteTransient)
				} ?? sqlite3_bind_null(statement, index)
			}

			if code != SQLITE_OK {
				return "SQL 参数绑定失败"
			}
		}
		return nil
	}

	private func decodeColumn(_ statement: OpaquePointer, column: Int32) -> Any {
		switch sqlite3_column_type(statement, column) {
		case SQLITE_INTEGER:
			return Int64(sqlite3_column_int64(statement, column))
		case SQLITE_FLOAT:
			return sqlite3_column_double(statement, column)
		case SQLITE_TEXT:
			if let raw = sqlite3_column_text(statement, column) {
				return String(cString: raw)
			}
			return ""
		case SQLITE_BLOB:
			let size = Int(sqlite3_column_bytes(statement, column))
			guard let bytes = sqlite3_column_blob(statement, column), size > 0 else {
				return Data()
			}
			return Data(bytes: bytes, count: size)
		default:
			return NSNull()
		}
	}

	private func lastErrorText(from handle: OpaquePointer?) -> String {
		guard let handle, let message = sqlite3_errmsg(handle) else {
			return "SQLite 操作失败"
		}
		return String(cString: message)
	}

	private func executeRaw(_ statement: String) -> String? {
		guard let handle = handle else {
			return "数据库尚未初始化"
		}
		var errorPointer: UnsafeMutablePointer<Int8>?
		let code = sqlite3_exec(handle, statement, nil, nil, &errorPointer)
		if code == SQLITE_OK {
			return nil
		}
		if let errorPointer {
			let text = String(cString: errorPointer)
			sqlite3_free(errorPointer)
			return text
		}
		return lastErrorText(from: handle)
	}

	private func applyCipherKeyIfNeeded() {
		guard settings.enableCipher, let secret = settings.secretPhrase, !secret.isEmpty else {
			return
		}
		let escaped = escapeSQLiteLiteral(secret)
		_ = executeRaw("PRAGMA key = '\(escaped)'")
	}

	private func escapeSQLiteLiteral(_ text: String) -> String {
		text.replacingOccurrences(of: "'", with: "''")
	}

	private func liveStoreURL() -> URL? {
		if let currentFileURL {
			return currentFileURL
		}
		guard let handle else {
			return nil
		}
		if let rawPath = sqlite3_db_filename(handle, nil) {
			let path = String(cString: rawPath)
			if !path.isEmpty {
				return URL(fileURLWithPath: path)
			}
		}
		return nil
	}

	private func flushStore(_ handle: OpaquePointer) throws {
		var errorPointer: UnsafeMutablePointer<Int8>?
		let code = sqlite3_exec(handle, "PRAGMA wal_checkpoint(FULL)", nil, nil, &errorPointer)
		if code == SQLITE_OK {
			return
		}
		if let errorPointer {
			let text = String(cString: errorPointer)
			sqlite3_free(errorPointer)
			throw NSError(domain: "laoqianjunzi-sqlite", code: Int(code), userInfo: [NSLocalizedDescriptionKey: text])
		}
		throw NSError(domain: "laoqianjunzi-sqlite", code: Int(code), userInfo: [NSLocalizedDescriptionKey: lastErrorText(from: handle)])
	}

	private func copyStore(from sourceURL: URL, to targetURL: URL, allowSamePath: Bool) throws {
		let manager = FileManager.default
		guard manager.fileExists(atPath: sourceURL.path) else {
			throw NSError(domain: "laoqianjunzi-sqlite", code: 1, userInfo: [NSLocalizedDescriptionKey: "数据库文件不存在"])
		}

		if sourceURL.path == targetURL.path {
			if allowSamePath {
				return
			}
			throw NSError(domain: "laoqianjunzi-sqlite", code: 2, userInfo: [NSLocalizedDescriptionKey: "备份目标不能与当前数据库相同"])
		}

		try prepareDirectory(for: targetURL)
		let tempURL = targetURL.deletingLastPathComponent().appendingPathComponent("\(targetURL.deletingPathExtension().lastPathComponent)-\(UUID().uuidString).tmp")
		if manager.fileExists(atPath: tempURL.path) {
			try? manager.removeItem(at: tempURL)
		}
		try manager.copyItem(at: sourceURL, to: tempURL)
		if manager.fileExists(atPath: targetURL.path) {
			try manager.removeItem(at: targetURL)
		}
		try manager.moveItem(at: tempURL, to: targetURL)
	}

	private func removeRelatedStoreFiles(for targetURL: URL) throws {
		let manager = FileManager.default
		let sidecars = [
			targetURL,
			URL(fileURLWithPath: targetURL.path + "-wal"),
			URL(fileURLWithPath: targetURL.path + "-shm"),
			URL(fileURLWithPath: targetURL.path + "-journal")
		]
		for item in sidecars where manager.fileExists(atPath: item.path) {
			try manager.removeItem(at: item)
		}
	}
}
