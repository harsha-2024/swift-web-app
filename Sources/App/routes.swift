
import Vapor

public func routes(_ app: Application) throws {
    app.get("health") { _ in "ok" }

    // Web pages
    app.get { req async throws -> View in
        return try await req.view.render("home")
    }

    // WebSocket echo
    app.webSocket("ws", "echo") { req, ws in
        req.logger.info("WS connected")
        ws.onText { ws, text in
            ws.send("echo: \(text)")
        }
    }

    // SSE sample
    app.get("events", "stream") { req -> EventStream in
        let stream = EventStream()
        req.eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: .seconds(5)) { task in
            stream.write("data: {"time": \(Date())}

")
        }
        return stream
    }

    // API v1
    let api = app.grouped("api", "v1")

    // Auth
    let auth = api.grouped("auth")
    auth.post("register", use: AuthController.register)
    auth.post("login", use: AuthController.login)
    auth.post("refresh", use: AuthController.refresh)

    // Protected routes
    let protect = api.grouped(UserAuthenticator()).grouped(GuardMiddleware())

    protect.get("me", use: UserController.me)

    let products = protect.grouped("products")
    products.get(use: ProductController.index)
    products.post(use: ProductController.create)

    let orders = protect.grouped("orders")
    orders.post(use: OrderController.create)

    // File upload (multipart)
    protect.on(.POST, "upload", body: .collect(maxSize: "10mb"), use: UploadController.upload)

    // Payments (stub)
    protect.post("payments", "intent", use: PaymentController.createIntent)

    app.get("openapi.yaml") { req in
        req.fileio.streamFile(app.directory.workingDirectory + "openapi.yaml")
    }
}
