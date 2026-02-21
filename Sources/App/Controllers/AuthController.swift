
import Vapor
import Fluent
import JWT

struct RegisterDTO: Content { let name: String; let email: String; let password: String }
struct LoginDTO: Content { let email: String; let password: String }
struct TokenResponse: Content { let accessToken: String; let refreshToken: String; let expiresIn: Int }

struct UserPayload: JWTPayload {
    var exp: ExpirationClaim
    var iss: IssuerClaim
    var aud: AudienceClaim
    var sub: SubjectClaim
    var email: String

    func verify(using signer: JWTSigner) throws {
        try exp.verifyNotExpired()
    }
}

enum AuthError: Error { case invalidCredentials }

final class AuthController {
    static func register(_ req: Request) async throws -> HTTPStatus {
        let dto = try req.content.decode(RegisterDTO.self)
        guard try await User.query(on: req.db).filter(\.$email == dto.email).first() == nil else { throw Abort(.conflict, reason: "Email exists") }
        let hash = try Bcrypt.hash(dto.password)
        let user = User(name: dto.name, email: dto.email, passwordHash: hash)
        try await user.save(on: req.db)
        return .created
    }

    static func login(_ req: Request) async throws -> TokenResponse {
        let dto = try req.content.decode(LoginDTO.self)
        guard let user = try await User.query(on: req.db).filter(\.$email == dto.email).first(),
              try Bcrypt.verify(dto.password, created: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }
        return try await issueTokens(for: user, req: req)
    }

    static func refresh(_ req: Request) async throws -> TokenResponse {
        struct RefreshDTO: Content { let refreshToken: String }
        let dto = try req.content.decode(RefreshDTO.self)
        guard let model = try await RefreshToken.query(on: req.db).filter(\.$token == dto.refreshToken).first() else {
            throw Abort(.unauthorized)
        }
        guard model.expiresAt > Date() else {
            try await model.delete(on: req.db)
            throw Abort(.unauthorized)
        }
        let user = try await model.$user.get(on: req.db)
        return try await issueTokens(for: user, req: req)
    }

    private static func issueTokens(for user: User, req: Request) async throws -> TokenResponse {
        let issuer = Environment.get("JWT_ISSUER") ?? "com.example.swiftapp"
        let audience = Environment.get("JWT_AUDIENCE") ?? "swiftapp-users"
        let accessExp = Int(Environment.get("ACCESS_TOKEN_EXP_SECONDS") ?? "900") ?? 900
        let refreshExp = Int(Environment.get("REFRESH_TOKEN_EXP_SECONDS") ?? "2592000") ?? 2592000

        let payload = UserPayload(
            exp: .init(value: Date().addingTimeInterval(TimeInterval(accessExp))),
            iss: .init(value: issuer),
            aud: .init(value: audience),
            sub: .init(value: user.id?.uuidString ?? ""),
            email: user.email
        )
        let access = try req.jwt.sign(payload)

        // create refresh token record
        let refresh = [UUID().uuidString, UUID().uuidString].joined()
        let refreshModel = RefreshToken(userID: user.id!, token: refresh, expiresAt: Date().addingTimeInterval(TimeInterval(refreshExp)))
        try await refreshModel.save(on: req.db)

        return TokenResponse(accessToken: access, refreshToken: refresh, expiresIn: accessExp)
    }
}

struct UserAuthenticator: AsyncRequestAuthenticator {
    typealias User = App.User

    func authenticate(request req: Request) async throws {
        guard let bearer = req.headers.bearerAuthorization else { return }
        do {
            let payload = try req.jwt.verify(bearer.token, as: UserPayload.self)
            guard let userID = UUID(uuidString: payload.sub.value),
                  let user = try await User.find(userID, on: req.db) else { return }
            req.auth.login(user)
        } catch {
            return
        }
    }
}

struct GuardMiddleware: AsyncMiddleware {
    func respond(to req: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard req.auth.has(User.self) else { throw Abort(.unauthorized) }
        return try await next.respond(to: req)
    }
}
