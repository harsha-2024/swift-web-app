
import Vapor
import Fluent

struct CreateOrderDTO: Content { let productID: UUID; let quantity: Int }

final class OrderController {
    static func create(_ req: Request) async throws -> Order {
        let user = try req.auth.require(User.self)
        let dto = try req.content.decode(CreateOrderDTO.self)
        guard let product = try await Product.find(dto.productID, on: req.db) else { throw Abort(.notFound) }
        let total = Double(dto.quantity) * product.price
        let order = Order(userID: try user.requireID(), productID: try product.requireID(), quantity: dto.quantity, total: total)
        try await order.save(on: req.db)
        return order
    }
}
