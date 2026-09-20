# Stage 1: Build binary
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Create unprivileged non-root user
RUN adduser -D -u 10001 appuser

# Copy dependency files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build statically-linked binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/bin/server ./cmd/server

# Stage 2: Runtime image
FROM scratch

# Copy unprivileged user definition
COPY --from=builder /etc/passwd /etc/passwd

# Copy SSL certs for HTTPS client calls if needed
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binary
COPY --from=builder /app/bin/server /server

USER 10001:10001

EXPOSE 8080

ENTRYPOINT ["/server"]
