
import Vapor
import Queues

struct EmailPayload: Codable { let to: String; let subject: String; let body: String }

struct SendEmailJob: AsyncJob {
    typealias Payload = EmailPayload

    func dequeue(_ context: Queues.QueueContext, _ payload: EmailPayload) async throws {
        context.logger.info("Sending email to: \(payload.to) :: \(payload.subject)")
        // Integrate with provider (SES, SendGrid, etc.)
    }
}
