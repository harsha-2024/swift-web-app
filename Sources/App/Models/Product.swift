
import Vapor
import Fluent

final class Product: Model, Content {
    static let schema = "products"

    @ID(key: .id) var id: UUID?
    @Field(key: "title") var title: String
    @Field(key: "price") var price: Double
    @OptionalField(key: "desc") var desc: String?

    init() {}
    init(id: UUID? = nil, title: String, price: Double, desc: String? = nil) {
        self.id = id
        self.title = title
        self.price = price
        self.desc = desc
    }
}

struct CreateProduct: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema(Product.schema)
            .id()
            .field("title", .string, .required)
            .field("price", .double, .required)
            .field("desc", .string)
            .create()
    }
    func revert(on db: Database) async throws {
        try await db.schema(Product.schema).delete()
    }
}
