
import Vapor

struct PaymentIntentDTO: Content { let amount: Int; let currency: String }
struct PaymentIntentResponse: Content { let clientSecret: String }

final class PaymentController {
    static func createIntent(_ req: Request) async throws -> PaymentIntentResponse {
        let dto = try req.content.decode(PaymentIntentDTO.self)
        let key = Environment.get("STRIPE_SECRET_KEY") ?? "sk_test_xxx"
        // Placeholder: In production, call Stripe's API here.
        req.logger.info("Creating payment intent for amount=\(dto.amount) \(dto.currency)")
        // Return a fake client secret for now
        return PaymentIntentResponse(clientSecret: "pi_test_\(UUID().uuidString)")
    }
}
