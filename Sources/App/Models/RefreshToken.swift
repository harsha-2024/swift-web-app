
import Vapor
import Fluent

final class RefreshToken: Model {
    static let schema = "refresh_tokens"

    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Field(key: "token") var token: String
    @Field(key: "expires_at") var expiresAt: Date

    init() {}
    init(id: UUID? = nil, userID: UUID, token: String, expiresAt: Date) {
        self.id = id
        self.$user.id = userID
        self.token = token
        self.expiresAt = expiresAt
    }
}

struct CreateRefreshToken: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema(RefreshToken.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
            .field("token", .string, .required)
            .field("expires_at", .datetime, .required)
            .unique(on: "token")
            .create()
    }
    func revert(on db: Database) async throws {
        try await db.schema(RefreshToken.schema).delete()
    }
}
