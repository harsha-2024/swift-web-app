
import Vapor
import Fluent

final class Order: Model, Content {
    static let schema = "orders"

    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Parent(key: "product_id") var product: Product
    @Field(key: "quantity") var quantity: Int
    @Field(key: "total") var total: Double

    init() {}
    init(id: UUID? = nil, userID: UUID, productID: UUID, quantity: Int, total: Double) {
        self.id = id
        self.$user.id = userID
        self.$product.id = productID
        self.quantity = quantity
        self.total = total
    }
}

struct CreateOrder: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema(Order.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
            .field("product_id", .uuid, .required, .references(Product.schema, .id, onDelete: .restrict))
            .field("quantity", .int, .required)
            .field("total", .double, .required)
            .create()
    }
    func revert(on db: Database) async throws {
        try await db.schema(Order.schema).delete()
    }
}
