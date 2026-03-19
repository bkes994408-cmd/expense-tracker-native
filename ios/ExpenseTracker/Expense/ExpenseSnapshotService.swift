import Foundation

struct ExpenseSnapshot: Codable, Equatable {
    struct Record: Codable, Equatable {
        let title: String
        let amount: Decimal
        let createdAt: Date
        let categoryId: Int64?
    }

    let version: Int
    let createdAt: Date
    let records: [Record]
}

enum ExpenseSnapshotError: LocalizedError {
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .decodingFailed:
            return "無法解析 Snapshot，請確認備份內容格式是否正確。"
        }
    }
}

final class ExpenseSnapshotService {
    private let store: ExpenseStore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(store: ExpenseStore) {
        self.store = store

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func exportSnapshot() throws -> String {
        let expenses = try store.fetchAll(searchText: nil)
        let snapshot = ExpenseSnapshot(
            version: 1,
            createdAt: Date(),
            records: expenses.map {
                .init(title: $0.title, amount: $0.amount, createdAt: $0.createdAt, categoryId: $0.categoryId)
            }
        )
        return String(decoding: try encoder.encode(snapshot), as: UTF8.self)
    }

    func restoreSnapshot(from rawJSON: String) throws {
        guard let data = rawJSON.data(using: .utf8),
              let snapshot = try? decoder.decode(ExpenseSnapshot.self, from: data)
        else {
            throw ExpenseSnapshotError.decodingFailed
        }

        let existing = try store.fetchAll(searchText: nil)
        try existing.forEach { try store.delete(id: $0.id) }
        try snapshot.records.forEach {
            try store.add(title: $0.title, amount: $0.amount, categoryId: $0.categoryId, createdAt: $0.createdAt)
        }
    }
}
