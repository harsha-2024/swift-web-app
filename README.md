
# SwiftLargeWebApp (Vapor 4)

A **large-scale, production-grade web app** scaffold in **Swift** using **Vapor 4**, including:

- REST API (versioned), **JWT auth** (access + refresh), role-based authorization
- **PostgreSQL** (Fluent) with migrations & seeders
- **Redis** for cache, rate limiting, sessions, and **Queues** (background jobs)
- **WebSockets** and **Server-Sent Events** for real-time features
- **File uploads** (local) and S3-ready abstraction
- **Leaf** templated web pages (SSR) + static assets
- **Prometheus metrics** and request logging
- **OpenAPI doc** (`/openapi.yaml`) and Postman collection
- **Docker** support + **docker-compose** (Postgres, Redis, App)
- **Kubernetes** manifests and **GitHub Actions** CI

> ⚠️ This repository is a scaffold with working patterns and placeholder integrations (e.g., Stripe). Use it as a starting point and adapt security/observability to your org’s standards.

## Quick Start

### Prerequisites
- Swift 5.9+
- Docker (optional)

### Option A – Local (with Docker services)
```bash
cp .env.example .env
# edit .env values if needed

# start DB & Redis
docker compose up -d db redis

# run migrations & start app
swift build
swift run Run migrate
swift run Run serve --env production --hostname 0.0.0.0 --port 8080
```

### Option B – Full Docker
```bash
docker compose up --build
```

### Endpoints
- REST API: `http://localhost:8080/api/v1/`
- Web: `http://localhost:8080/`
- WebSocket Echo: `ws://localhost:8080/ws/echo`
- SSE Stream: `http://localhost:8080/events/stream`
- OpenAPI: `http://localhost:8080/openapi.yaml`

### Make a user
```bash
curl -X POST http://localhost:8080/api/v1/auth/register   -H 'Content-Type: application/json'   -d '{"name":"Admin","email":"admin@example.com","password":"Secret123!"}'
```

### Login
```bash
curl -X POST http://localhost:8080/api/v1/auth/login   -H 'Content-Type: application/json'   -d '{"email":"admin@example.com","password":"Secret123!"}'
```

Use returned `accessToken` in `Authorization: Bearer <token>`.

---

## Project Layout
```
Sources/
  App/
    configure.swift           # Application bootstrap
    routes.swift              # Route groups
    Middleware/               # CORS, Error, RateLimit
    Models/                   # Fluent models
    Migrations/               # DB migrations
    Controllers/              # Feature controllers
    Services/                 # Integrations (Email, Payments, Storage, Cache)
    Web/                      # WebSocket/SSE handlers
  Run/
    main.swift                # Entrypoint
Resources/
  Views/                      # Leaf templates
Public/                       # Static files
k8s/                          # K8s manifests
.github/workflows/ci.yml      # CI pipeline
```

## Security Notes
- Set strong `JWT_SIGNING_KEY` and rotate regularly.
- Use HTTPS in production with a reverse proxy or Load Balancer.
- Tune rate limits per route group.
- Validate user input; add further checks as needed.
- Consider using mTLS or a service mesh for internal traffic.

## License
MIT
