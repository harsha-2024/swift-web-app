
import Vapor
import Fluent

struct ProductDTO: Content { let title: String; let price: Double; let desc: String? }

final class ProductController {
    static func index(_ req: Request) async throws -> [Product] {
        try await Product.query(on: req.db).all()
    }

    static func create(_ req: Request) async throws -> Product {
        let dto = try req.content.decode(ProductDTO.self)
        let p = Product(title: dto.title, price: dto.price, desc: dto.desc)
        try await p.save(on: req.db)
        return p
    }
}
