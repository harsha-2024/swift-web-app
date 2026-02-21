
import Vapor
import Redis

/// Simple token-bucket-like limiter using Redis (fallback: in-memory).
public final class RateLimitMiddleware: Middleware {
    private let window: TimeAmount = .seconds(60)
    private let max: Int = 120
    private let prefix = "rl:"
    private var local: [String: (count: Int, reset: Date)] = [:]

    public init() {}

    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        let key = prefix + (request.headers.first(name: .xForwardedFor) ?? request.remoteAddress?.description ?? "unknown")
        if let redis = request.application.redis {
            let expire: Int = 60
            let value = request.eventLoop.makePromise(of: Response.self)
            redis.connectionPool.withConnection(logger: request.logger) { conn in
                conn.increment(key)
                    .flatMap { newVal in
                        if newVal == 1 { return conn.expire(key, after: .seconds(expire)).transform(to: ()) }
                        return request.eventLoop.makeSucceededVoidFuture()
                    }
                    .flatMap { _ in
                        redis.get(key, as: Int.self)
                    }
                    .whenComplete { result in
                        switch result {
                        case .success(let count):
                            if (count ?? 0) > self.max {
                                let res = Response(status: .tooManyRequests)
                                res.body = .init(string: "Rate limit exceeded")
                                value.succeed(res)
                            } else {
                                next.respond(to: request).cascade(to: value)
                            }
                        case .failure:
                            next.respond(to: request).cascade(to: value)
                        }
                    }
            }
            return value.futureResult
        } else {
            // In-memory fallback (best-effort)
            let now = Date()
            let entry = local[key]
            if entry == nil || entry!.reset < now {
                local[key] = (1, now.addingTimeInterval(60))
                return next.respond(to: request)
            } else if entry!.count >= max {
                return request.eventLoop.makeSucceededFuture(Response(status: .tooManyRequests))
            } else {
                local[key]!.count += 1
                return next.respond(to: request)
            }
        }
    }
}
