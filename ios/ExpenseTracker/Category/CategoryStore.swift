import Foundation

protocol CategoryStore {
    func fetchActive() throws -> [Category]
    func add(name: String) throws
    // TODO(MVP-1.2): archive flow currently only in Settings screen; refine UX later.
    func archive(id: Int64) throws
    // TODO(MVP-1.2): add explicit sort mode in UI.
    func move(from: Int, to: Int) throws
}
