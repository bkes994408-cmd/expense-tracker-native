import Foundation
import GRDB

final class GRDBCategoryStore: CategoryStore {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try migrator.migrate(dbQueue)
    }

    func fetchActive() throws -> [Category] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT id, name, isArchived, sortOrder
                FROM categories
                WHERE isArchived = 0
                ORDER BY sortOrder ASC
            """)
            return rows.map {
                Category(
                    id: $0["id"],
                    name: $0["name"],
                    isArchived: ($0["isArchived"] as Int64) == 1,
                    sortOrder: $0["sortOrder"]
                )
            }
        }
    }

    func add(name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        try dbQueue.write { db in
            let maxOrder: Int = try Int.fetchOne(db, sql: "SELECT COALESCE(MAX(sortOrder), -1) FROM categories") ?? -1
            try db.execute(
                sql: "INSERT INTO categories (name, isArchived, sortOrder) VALUES (?, 0, ?)",
                arguments: [trimmed, maxOrder + 1]
            )
        }
    }

    func archive(id: Int64) throws {
        try dbQueue.write { db in
            try db.execute(sql: "UPDATE categories SET isArchived = 1 WHERE id = ?", arguments: [id])
        }
    }

    func move(from: Int, to: Int) throws {
        guard from != to else { return }
        try dbQueue.write { db in
            var activeRows = try Row.fetchAll(db, sql: """
                SELECT id, sortOrder
                FROM categories
                WHERE isArchived = 0
                ORDER BY sortOrder ASC
            """)
            guard from >= 0, from < activeRows.count, to >= 0, to < activeRows.count else { return }

            let moved = activeRows.remove(at: from)
            activeRows.insert(moved, at: to)

            for (index, row) in activeRows.enumerated() {
                let id: Int64 = row["id"]
                try db.execute(sql: "UPDATE categories SET sortOrder = ? WHERE id = ?", arguments: [index, id])
            }
        }
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createCategories") { db in
            try db.create(table: "categories") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("name", .text).notNull()
                table.column("isArchived", .integer).notNull().defaults(to: 0)
                table.column("sortOrder", .integer).notNull()
            }
        }
        return migrator
    }
}
