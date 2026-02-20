import XCTest
@testable import ExpenseTracker

private final class FakeRepo: TransactionRepository {
    var lastAdd: (Int64, String, Date)?

    func list() throws -> [Transaction] { [] }

    func add(amountCents: Int64, note: String, occurredAt: Date) throws -> Int64 {
        lastAdd = (amountCents, note, occurredAt)
        return 123
    }

    func delete(id: Int64) throws {}
}

final class AddTransactionUseCaseTests: XCTestCase {
    func testTrimsNote_andReturnsId() throws {
        let repo = FakeRepo()
        let useCase = AddTransactionUseCase(repository: repo)

        let now = Date(timeIntervalSince1970: 1)
        let id = try useCase(amountCents: 1000, note: "  lunch ", occurredAt: now)

        XCTAssertEqual(id, 123)
        XCTAssertEqual(repo.lastAdd?.0, 1000)
        XCTAssertEqual(repo.lastAdd?.1, "lunch")
        XCTAssertEqual(repo.lastAdd?.2, now)
    }

    func testThrowsWhenAmountIsZero() throws {
        let repo = FakeRepo()
        let useCase = AddTransactionUseCase(repository: repo)

        XCTAssertThrowsError(try useCase(amountCents: 0, note: "bad", occurredAt: .now)) { error in
            XCTAssertEqual(error as? AddTransactionValidationError, .zeroAmount)
        }
    }
}
