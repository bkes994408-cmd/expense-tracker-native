import Foundation

protocol CategoryStore {
    func fetchActive() throws -> [Category]
    func add(name: String) throws
    func archive(id: Int64) throws
    func move(from: Int, to: Int) throws
}
