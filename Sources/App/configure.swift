
import Vapor
import Fluent
import FluentPostgresDriver
import Leaf
import Redis
import Queues
import QueuesRedisDriver
import JWT
import SwiftPrometheus

public func configure(_ app: Application) throws {
    // MARK: - Environment
    let env = Environment.get("APP_ENV") ?? app.environment.name

    // MARK: - Logging
    app.logger.logLevel = env == "production" ? .info : .debug

    // MARK: - DB
    app.databases.use(.postgres(
        hostname: Environment.get("POSTGRES_HOST") ?? "localhost",
        port: Environment.get("POSTGRES_PORT").flatMap(Int.init(_:)) ?? 5432,
        username: Environment.get("POSTGRES_USER") ?? "swift",
        password: Environment.get("POSTGRES_PASSWORD") ?? "swiftpass",
        database: Environment.get("POSTGRES_DB") ?? "swiftapp"
    ), as: .psql)

    // MARK: - Redis
    if let host = Environment.get("REDIS_HOST") {
        app.redis.configuration = try RedisConfiguration(hostname: host, port: Environment.get("REDIS_PORT").flatMap(Int.init(_:)) ?? 6379)
        try app.queues.use(.redis())
    }

    // MARK: - Leaf
    app.views.use(.leaf)

    // MARK: - Migrations
    app.migrations.add(CreateUser())
    app.migrations.add(CreateProduct())
    app.migrations.add(CreateOrder())
    app.migrations.add(CreateRefreshToken())

    // MARK: - Middleware
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)
    app.middleware.use(CORSMiddleware(configuration: .init(allowedOrigin: .all)))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    app.middlewares.use(RateLimitMiddleware())

    // MARK: - JWT
    let jwtKey = Environment.get("JWT_SIGNING_KEY") ?? "CHANGE_ME_SUPER_SECRET_256_BIT_KEY"
    app.jwt.signers.use(.hs256(key: jwtKey))

    // MARK: - Metrics
    let prom = PrometheusClient()
    MetricsSystem.bootstrap(prom)
    app.get("metrics") { req in
        req.logger.debug("Scrape /metrics")
        return prom.collect()
    }

    // MARK: - Queues example job
    app.queues.add(SendEmailJob())

    // MARK: - Routes
    try routes(app)
}
