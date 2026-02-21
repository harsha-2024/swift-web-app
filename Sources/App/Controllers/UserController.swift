
import Vapor

final class UserController {
    static func me(_ req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        return .init(id: user.id, name: user.name, email: user.email)
    }
}

extension User {
    struct Public: Content { let id: UUID?; let name: String; let email: String }
}
