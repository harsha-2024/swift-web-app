
# ================== Build Stage ==================
FROM swift:5.9-jammy as build
WORKDIR /app
COPY . .
RUN swift build -c release --static-swift-stdlib

# ================== Run Stage ==================
FROM ubuntu:22.04
WORKDIR /run
RUN apt-get update && apt-get install -y libssl3 ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/.build/release/Run /run/Run
COPY Public /run/Public
COPY Resources /run/Resources
ENV PORT=8080
EXPOSE 8080
CMD ["/run/Run", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
