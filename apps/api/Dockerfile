# Stage 1: Build binary
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copy dependency files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build statically-linked binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/bin/server ./cmd/server

# Stage 2: Runtime image
FROM scratch

# Copy SSL certs for HTTPS client calls if needed
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binary
COPY --from=builder /app/bin/server /server

EXPOSE 8080

ENTRYPOINT ["/server"]
